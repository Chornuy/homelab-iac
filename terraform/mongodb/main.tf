resource "random_id" "mongo_cluster_key" {
  byte_length = 756 # MongoDB security requirements mandate between 6 and 1024 bytes
}

resource "local_file" "cloud_init" {
  for_each = var.mongo_nodes
  filename = "${path.module}/files/${each.key}-cloud_init.cfg"
  content = templatefile("${path.module}/files/cloud_config.tpl", {
    ssh_key           = file(var.ssh_key_path)
    hostname          = each.key
    mongo_user        = var.mongo_user
    cluster_key_value = random_id.mongo_cluster_key.b64_std # Pass the dynamic secret key
  })
}

# resource "proxmox_virtual_environment_cluster_firewall_security_group" "mongo_sg" {
#   name        = "mongocluster"
#   description = "Allow SSH and MongoDB from anywhere, drop the rest"
#
#   rule {
#     type    = "in"
#     action  = "ACCEPT"
#     macro   = "SSH"
#     source  = "0.0.0.0/0"
#     comment = "Allow SSH globally"
#   }
#
#   rule {
#     type    = "in"
#     action  = "ACCEPT"
#     proto   = "tcp"
#     dport   = "27017"
#     source  = "0.0.0.0/0"
#     comment = "Allow MongoDB globally"
#   }
# }


resource "terraform_data" "cloud_init_upload" {
  for_each         = var.mongo_nodes
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

# ==============================================================================
# 4. UNIFIED MONGO QEMU VM INSTANCES
# ==============================================================================
resource "proxmox_vm_qemu" "mongo_node" {
  for_each = var.mongo_nodes

  name        = each.key
  target_node = each.value.deploy_host
  description = "MongoDB HA mongo-node-${upper(each.key)} Node"

  clone      = var.template_name
  full_clone = true
  agent      = 1
  memory     = each.value.ram

  cpu {
    cores = each.value.cpu
  }

  os_type = "cloud-init"

  scsihw = "virtio-scsi-single"
  tags   = "database,mongodb,mongocluster,mongo-node-${each.key}"

  cicustom   = "user=${var.cloudinit_storage}:snippets/${each.key}-cloud_init.yml"
  ipconfig0  = "gw=${var.mongo_gateway},ip=${each.value.ip}"
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
      # OS Root Drive Layer
      scsi0 {
        disk {
          size     = var.mongo_node_root_disk_size
          storage  = var.mongo_node_disk_storage
          iothread = true
          # discard  = true
          # ssd      = true
        }
      }
      # Dedicated Database Store Allocation Layer
      scsi1 {
        disk {
          size     = "40G"
          storage  = var.mongo_node_disk_storage
          iothread = true
          format   = "raw"
          # discard  = true
          # ssd      = true
        }
      }
    }
  }

  network {
    id      = each.value.network_id
    model   = "virtio"
    bridge  = var.nic_name
    macaddr = "52:54:00:22:34:${format("%02x", split(".", element(split("/", each.value.ip), 0))[3])}"
  }

  lifecycle {
    ignore_changes = [target_node, sshkeys, network]
  }
}

# ==============================================================================
# 5. AUTOMATED HA REPLICA SET INITIALIZATION
# ==============================================================================
resource "terraform_data" "mongo_cluster_init" {
  connection {
    type        = "ssh"
    user        = var.mongo_user
    private_key = file(var.ssh_private_key_path)
    host        = element(split("/", var.mongo_nodes["mongo-node-0"].ip), 0)
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # Wait for cloud-init to completely wrap up
      while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done

      # 1. Verification Loop: Block orchestration until all targets acknowledge port 27017
      %{for name, node in var.mongo_nodes~}
      until nc -z -v -w5 ${element(split("/", node.ip), 0)} 27017; do echo 'Waiting for database interface on ${name}...'; sleep 5; done
      %{endfor~}

      # 2. Transactional cluster setup execution injection via single seed node
      mongosh --eval '
        rs.initiate({
          _id: "${var.mongo_replica_set_name}",
          members: [
            ${join(",\n            ", [
      for idx, name in keys(var.mongo_nodes) :
      "{ _id: ${idx}, host: \"${element(split("/", var.mongo_nodes[name].ip), 0)}:27017\" }"
])}
          ]
        })
      '
      echo "Waiting for mongo-node-0 to be elected PRIMARY..."
      until mongosh --quiet --eval "db.hello().isWritablePrimary" | grep -q "true"; do
        echo "Still waiting for PRIMARY election status..."
        sleep 3
      done
      echo "Node is now PRIMARY. Safe to provision credentials."

      # 3. Provision the primary admin root cluster account securely
      mongosh admin --eval '
        db.createUser({
          user: "${var.mongo_root_user}",
          pwd: "${var.mongo_root_password}",
          roles: [
            { role: "userAdminAnyDatabase", db: "admin" },
            { role: "readWriteAnyDatabase", db: "admin" },
            { role: "dbAdminAnyDatabase",   db: "admin" },
            { role: "clusterAdmin",         db: "admin" }
          ]
        })
      '

      echo "MongoDB Replica Set and Admin Authentication Provisioned Successfully."
      EOT
]
}

depends_on = [proxmox_vm_qemu.mongo_node]
}

resource "terraform_data" "mongo_config_updater" {
  for_each = var.mongo_nodes

  # This ensures the provisioner re-triggers ONLY if the config file changes
  triggers_replace = [
    md5(templatefile("${path.module}/files/mongod.conf.tpl", {
      repl_set_name = var.mongo_replica_set_name
    }))
  ]

  connection {
    type        = "ssh"
    user        = var.mongo_user
    private_key = file(var.ssh_private_key_path)
    host        = element(split("/", each.value.ip), 0)
  }

  # 1. Render and upload the configuration file safely to a temporary directory
  provisioner "file" {
    content = templatefile("${path.module}/files/mongod.conf.tpl", {
      repl_set_name = var.mongo_replica_set_name
    })
    destination = "/tmp/mongod.conf"
  }

  # 2. Atomic switch, permissions correction, and safe daemon reload
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo chown root:root /etc/mongod.conf",
      "sudo chmod 0644 /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }

  # Crucial: Run this only AFTER the cluster instances are initially provisioned
  depends_on = [proxmox_vm_qemu.mongo_node, terraform_data.mongo_cluster_init]
}
