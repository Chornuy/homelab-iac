locals {
  first_master_ip = element(split("/", var.nodes[var.first_master].ip), 0)
}

resource "terraform_data" "k8s_init" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = local.first_master_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",

      "sudo kubeadm init --control-plane-endpoint '${local.first_master_ip}:6443' --upload-certs --certificate-key '${var.k8s_cert_key}' --token '${var.k8s_token}' --pod-network-cidr=${var.k8s_pod_cidr} --skip-phases=addon/kube-proxy",

      "mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config",

      "cilium install --set kubeProxyReplacement=true --set k8sServiceHost=${local.first_master_ip} --set k8sServicePort=6443 --set bgpControlPlane.enabled=true --set k8sClientRateLimit.qps=10 --set k8sClientRateLimit.burst=20",
      "cilium status --wait",

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
      ,

      "helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --set defaultSettings.defaultDataPath='/var/lib/longhorn' --set defaultSettings.defaultReplicaCount=${var.longhorn_replica_count} --set defaultSettings.replicaSoftAntiAffinity=${var.longhorn_soft_anti_affinity} --set storageClass.numberOfReplicas=${var.longhorn_replica_count}"
    ]
  }
}

resource "terraform_data" "k8s_join" {
  for_each = { for k, v in var.nodes : k => v if k != var.first_master }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = element(split("/", each.value.ip), 0)
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",
      "sudo kubeadm join ${local.first_master_ip}:6443 --token '${var.k8s_token}' --discovery-token-unsafe-skip-ca-verification ${each.value.type == "master" ? "--control-plane --certificate-key ${var.k8s_cert_key}" : ""}"
    ]
  }

  depends_on = [terraform_data.k8s_init]
}

resource "terraform_data" "node_labels" {
  for_each = var.nodes

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = local.first_master_ip
  }

  provisioner "remote-exec" {
    inline = [
      "until kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | grep -Fw '${lower(each.key)}'; do echo 'Waiting for node ${lower(each.key)} to register...'; sleep 5; done",

      <<-EOT
        for label in ${join(" ", compact(each.value.labels))}; do
          if [ -n "$label" ]; then
            echo "Applying label $label=true to node ${lower(each.key)}"
            kubectl label node ${lower(each.key)} "$label=true" --overwrite
          fi
        done
      EOT
    ]
  }

  depends_on = [terraform_data.k8s_join, terraform_data.k8s_init]
}
