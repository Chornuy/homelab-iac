# 1. THE DATA STRUCTURE
# This replaces master_count, worker_count, and various IP list variables.


resource "routeros_routing_bgp_connection" "k8s_peers" {
  for_each = { for k, v in var.cluster_nodes : k => v if v.type == "master" }
  # for_each = var.cluster_nodes
  as = var.bgp_peer_asn
  name           = each.key
  instance       = "default"
  templates = ["cilium-template"]
  multihop = true
  nexthop_choice = "force-self"

  connect   = false
  listen    = true

  remote {
    address = "${element(split("/", each.value.ip), 0)}/32"
    as = var.bgp_local_asn
  }

  local {
    address = var.bgp_peer_ip
    role    = "ebgp"
  }
  # Increase timers for Lab Stability
  # If the VM lags during cloud-init, the router won't kill the session as fast.
  hold_time      =  "${var.bgp_hold_time}s"
  keepalive_time = "${var.bgp_keepalive_time}s"

  # Passive means the MikroTik waits for the VM to start the talk.
  # This prevents the router from "spamming" a VM that is still booting.

}

# 2. CLOUD-INIT GENERATION & UPLOAD (Unified)
resource "local_file" "cloud_init" {
  for_each = var.cluster_nodes
  filename = "${path.module}/files/${each.key}-user_data_cloud_init.cfg"
  content = templatefile("${path.module}/files/cloud_config.tpl", {
    ssh_key  = file("~/.ssh/id_ed25519.pub")
    hostname = each.key
    k8s_user = var.k8s_user
  })
}


variable "proxmox_snippets_path" {
  default = "/mnt/pve/proxmox_nfs_ssd"
}

resource "terraform_data" "cloud_init_upload" {
  for_each         = var.cluster_nodes
  triggers_replace = [md5(local_file.cloud_init[each.key].content)]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = var.proxmox_host # The management IP of your PVE cluster
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /var/lib/vz/snippets"]
  }

  provisioner "file" {
    source      = local_file.cloud_init[each.key].filename
    destination = "${var.proxmox_snippets_path}/snippets/${each.key}-cloud_init.yml"
  }
}

# 3. UNIFIED VM RESOURCE
resource "proxmox_vm_qemu" "k8s_node" {
  for_each = var.cluster_nodes

  name        = each.key
  target_node = each.value.deploy_host # Maps to your PVE node 1 or 2
  description = "K8S ${upper(each.value.type)} Node"


  clone      = var.k8s_template_name
  full_clone = true
  agent      = 1
  memory     = each.value.ram

  cpu {
    cores = each.value.cpu
  }

  os_type = "cloud-init"
  scsihw  = "virtio-scsi-single"
  tags    = "k8s,ubuntu,k8s_${each.value.type}"

  # Logic to determine which cloud-init snippet to use
  cicustom   = "user=${var.cloudinit_storage}:snippets/${each.key}-cloud_init.yml"
  ipconfig0  = "gw=${var.k8s_gateway},ip=${each.value.ip}"
  depends_on = [terraform_data.cloud_init_upload]

  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.cloudinit_storage
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size     = var.k8s_node_root_disk_size
          storage  = var.k8s_node_disk_storage
          iothread = true
        }
      }
      scsi1 {
        disk {
          size     = var.k8s_node_data_disk_size
          storage  = var.k8s_node_disk_storage
          iothread = true
        }
      }
    }
  }

  network {
    id     = each.value.network_id
    model  = "virtio"
    bridge = var.nic_name
    macaddr = "52:54:00:12:34:${format("%02x", split(".", element(split("/", each.value.ip), 0))[3])}"
  }

  lifecycle {
    ignore_changes = [disks, target_node, sshkeys, network]
  }
}

# 4. K8S BOOTSTRAP (Logical Split)
# Primary Master (Index 0)
resource "terraform_data" "k8s_init" {
  connection {
    type        = "ssh"
    user        = var.k8s_user
    private_key = file(var.ssh_private_key_path)
    host        = element(split("/", var.cluster_nodes["k8s-master-0"].ip), 0)
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",

      # 1. Initialize Kubernetes
      "sudo kubeadm init --control-plane-endpoint '${element(split("/", var.cluster_nodes["k8s-master-0"].ip), 0)}:6443' --upload-certs --certificate-key '${var.k8s_cert_key}' --token '${var.k8s_token_key}' --pod-network-cidr=${var.k8s_pod_cidr} --skip-phases=addon/kube-proxy",

      # 2. Setup Kubeconfig
      "mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config",

      # 3. Install Cilium
      "cilium install --set kubeProxyReplacement=true --set k8sServiceHost=${element(split("/", var.cluster_nodes["k8s-master-0"].ip), 0)} --set k8sServicePort=6443 --set bgpControlPlane.enabled=true --set k8sClientRateLimit.qps=10 --set k8sClientRateLimit.burst=20",
      "cilium status --wait",

      # 4. Apply BGP V2 Configuration (The Here-Doc as a list item)
      <<-EOT
        cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumBGPPeerConfig
metadata:
  name: cilium-peer
spec:
  timers:
    holdTimeSeconds: ${var.bgp_hold_time}
    keepAliveTimeSeconds: ${var.bgp_keepalive_time}
  ebgpMultihop: 2
  gracefulRestart:
    enabled: true
    restartTimeSeconds: 120
  families:
    - afi: ipv4
      safi: unicast
      advertisements:
        matchLabels:
          advertise: "bgp"
---
apiVersion: cilium.io/v2
kind: CiliumBGPClusterConfig
metadata:
  name: mikrotik-cluster-peering
spec:
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/control-plane: ""
  bgpInstances:
  - name: "64512"
    localASN: ${var.bgp_local_asn}
    peers:
    - name: "mikrotik-router"
      peerASN: ${var.bgp_peer_asn}
      peerAddress: ${var.bgp_peer_ip}
      peerConfigRef:
        name: "cilium-peer"
---
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: bgp-advertisements
  labels:
    advertise: bgp
spec:
  advertisements:
    - advertisementType: "Service"
      service:
        addresses:
          - LoadBalancerIP
      selector:
        matchLabels:
          io.cilium/bgp-advertisement: "true"
---
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: main-pool
spec:
  blocks:
    - cidr: ${var.k8s_lb_cidr}
EOF
      EOT
    ]
  }
  depends_on = [proxmox_vm_qemu.k8s_node]
}

# All other nodes (Secondary Masters & Workers)
resource "terraform_data" "k8s_join" {
  for_each = { for k, v in var.cluster_nodes : k => v if k != "k8s-master-0" }

  connection {
    type        = "ssh"
    user        = var.k8s_user
    private_key = file(var.ssh_private_key_path)
    host        = element(split("/", each.value.ip), 0)
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",
      "sudo kubeadm join ${element(split("/", var.cluster_nodes["k8s-master-0"].ip), 0)}:6443 --token '${var.k8s_token_key}' --discovery-token-unsafe-skip-ca-verification ${each.value.type == "master" ? "--control-plane --certificate-key ${var.k8s_cert_key}" : ""}"
    ]
  }
  depends_on = [terraform_data.k8s_init]
}

resource "terraform_data" "node_labels" {
  for_each = var.cluster_nodes

  connection {
    type        = "ssh"
    user        = var.k8s_user
    private_key = file(var.ssh_private_key_path)
    host        = element(split("/", var.cluster_nodes["k8s-master-0"].ip), 0)
  }

  provisioner "remote-exec" {
    inline = [
      # Wait for the node to appear in kubectl get nodes
      "until kubectl get node ${each.key}; do sleep 5; done",
      # Apply any custom labels from your variable map
      # "kubectl label node ${each.key} ${join(" ", [for l in each.value.labels: "${l}=true" if l != ""])} --overwrite"
    ]
  }

  depends_on = [terraform_data.k8s_join, terraform_data.k8s_init]
}