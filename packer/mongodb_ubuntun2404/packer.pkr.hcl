packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "proxmox_iso_pool" {
  type = string
  default = "local:iso"
}

variable "ubuntu_image" {
  type = string
  default = "ubuntu-22.04.1-live-server-amd64.iso"
}

variable "proxmox_storage_pool" {
  type = string
  default = "nvme-zfs"
}

variable "proxmox_storage_format" {
  type = string
  default = "raw"
}

variable "template_name" {
  type = string
  default = "mongo-7-db-template"
}

variable "template_description" {
  type = string
  default = "Ubuntu 22.04 with K8s, Cilium CLI, and Longhorn Deps"
}

variable "proxmox_vm_id" {
  type = number
  default = 900
}

source "proxmox-iso" "mongodb-node" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  template_name        = var.template_name
  template_description = var.template_description


  # VM Hardware Configuration
  vm_id                    = var.proxmox_vm_id
  vm_name                  = "ubuntu-mongodb-ha-template"

  cores                    = 2
  memory                   = 4096 # MongoDB loves RAM for its execution cache
  os                       = "l26"
  scsi_controller = "virtio-scsi-single"
  
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
    firewall = true
  }

  boot_iso {
    iso_file = "${var.proxmox_iso_pool}/${var.ubuntu_image}"
    unmount = true
  }

  # scsi_controller = "virtio-scsi-pci"
  
  disks {
    disk_size    = "20G" # Increased for K8s and Longhorn requirements
    format       = var.proxmox_storage_format
    storage_pool = var.proxmox_storage_pool
    type              = "scsi"
    discard           = true            # Enables TRIM/Unmap for ZFS space reclamation
    ssd               = true            # Optimized for NVMe/SSD latency
    io_thread          = true            # Better performance for high IOPS NVMe
  }


  # SSH configuration for Packer to run the provisioner script
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "30m"
  ssh_port     = 22

  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_storage_pool

  serials = ["socket"]
  # Ensure your video driver is set to standard or compatible
  vga {
    type = "std"
  }

  boot_wait    = "10s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz -- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<enter><wait><wait>",
    "initrd /casper/initrd",
    "<enter><wait><wait>",
    "boot<enter>"
  ]
  http_directory = "http"
}

build {
  sources = ["source.proxmox-iso.mongodb-node"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 2; done"
    ]
  }

  # Run the shell script to install MongoDB and open up clustering parameters
  provisioner "shell" {
    script = "scripts/install-mongodb.sh"
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}

