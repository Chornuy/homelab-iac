# =============================================================================
# PACKER CONFIGURATION FOR K8S (CILIUM/LONGHORN) ON PROXMOX
# =============================================================================

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# -----------------------------------------------------------------------------
# VARIABLES (Keep your existing variable definitions here)
# -----------------------------------------------------------------------------
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
  default = "ubuntu-k8s-template"
}

variable "template_description" {
  type = string
  default = "Ubuntu 22.04 with K8s, Cilium CLI, and Longhorn Deps"
}

variable "proxmox_vm_id" {
  type = number
  default = 2500
}

# -----------------------------------------------------------------------------
# SOURCE: PROXMOX BUILDER
# -----------------------------------------------------------------------------
source "proxmox-iso" "ubuntu" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  template_name        = var.template_name
  template_description = var.template_description
  os                   = "l26"

  boot_wait    = "10s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz -- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<enter><wait><wait>",
    "initrd /casper/initrd",
    "<enter><wait><wait>",
    "boot<enter>"
  ]

  # Hardware Resources (Increased for K8s build overhead)
  cores           = "2"
  memory          = "4096"
  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size    = "20G" # Increased for K8s and Longhorn requirements
    format       = var.proxmox_storage_format
    storage_pool = var.proxmox_storage_pool
    type              = "scsi"
    discard           = true            # Enables TRIM/Unmap for ZFS space reclamation
    ssd               = true            # Optimized for NVMe/SSD latency
    io_thread          = true            # Better performance for high IOPS NVMe
  }

  # Cloud-Init configuration
  # Adding a Cloud-Init drive is highly recommended for Proxmox templates
  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_storage_pool

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }


  # unmount_iso    = true
  boot_iso {
    iso_file = "${var.proxmox_iso_pool}/${var.ubuntu_image}"
    unmount = true
  }
  http_directory = "http"

  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_port     = 22
  ssh_timeout  = "30m"
  vm_id        = var.proxmox_vm_id
}

# -----------------------------------------------------------------------------
# BUILD PIPELINE
# -----------------------------------------------------------------------------
build {
  sources = ["source.proxmox-iso.ubuntu"]

  # 1. Wait for Cloud-Init and Run K8s Prep Script
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 2; done"
    ]
  }

  provisioner "shell" {
    script = "scripts/k8s-prep.sh"
  }

  # 2. Cleanup and unique identity prep
  provisioner "shell" {
    inline = [
      "sudo rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo cloud-init clean",
      "sudo passwd -d ubuntu",
      "echo 'Image build complete.'"
    ]
  }
}
