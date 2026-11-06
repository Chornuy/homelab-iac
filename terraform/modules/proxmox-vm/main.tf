locals {
  ip_host = split("/", var.ip_address)[0]
  octets  = split(".", local.ip_host)
  macaddr = "${var.mac_prefix}:${format("%02x", tonumber(local.octets[3]))}"
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.name
  target_node = var.target_node
  description = var.description

  clone      = var.template_name
  full_clone = var.full_clone
  agent      = 1
  memory     = var.memory
  onboot     = var.onboot
  tags       = join(",", var.tags)

  os_type = "cloud-init"
  scsihw  = "virtio-scsi-single"

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "host"
  }

  cicustom  = var.cloudinit_snippet
  ipconfig0 = "gw=${var.gateway},ip=${var.ip_address}"

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
          size     = var.disk_size
          storage  = var.storage
          iothread = true
          discard  = var.discard
        }
      }
      dynamic "scsi1" {
        for_each = var.data_disk_size == null ? [] : [var.data_disk_size]
        content {
          disk {
            size     = scsi1.value
            storage  = var.data_storage != null ? var.data_storage : var.storage
            iothread = true
            discard  = var.discard
          }
        }
      }
    }
  }

  network {
    id      = var.network_id
    model   = "virtio"
    bridge  = var.bridge
    macaddr = local.macaddr
  }

  lifecycle {
    ignore_changes = [target_node, disks, sshkeys, network]
  }
}