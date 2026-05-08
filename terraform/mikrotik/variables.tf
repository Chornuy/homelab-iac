# TF vars for spinning up VMs

variable "hosturl" {
  default = "http://192.168.0.1"
}

variable "username" {
  default = "admin"
}

variable "password" {}

variable "local_domain" {
  type = string
  default = "lan"
}

variable "static_ip_hosts" {
  type = map(object({
    ip  = string
    mac = string
  }))
  description = "Single source of truth for node names, IPs, and MACs"
  default = {
    "proxmox-pve-node-1" = { ip = "192.168.20.10", mac = "E8:6A:64:99:6E:B3" }
    "proxmox-pve-node-2" = { ip = "192.168.20.20", mac = "E8:6A:64:FF:DE:60" }
    "odroid-xu4-1"       = { ip = "192.168.0.78", mac = "00:1E:06:36:99:CB" }
    "odroid-c2-1"        = { ip = "192.168.0.228", mac = "00:1E:06:34:54:BB" }
    "odroid-c2-2"        = { ip = "192.168.0.69", mac = "00:1E:06:34:77:68" }
  }
}