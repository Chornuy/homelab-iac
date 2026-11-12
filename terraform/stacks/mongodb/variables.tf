variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = true
}

variable "proxmox_host" {
  description = "Proxmox API/SSH host reachable from where Terraform runs"
  type        = string
}

variable "token_id" {
  type = string
}

variable "token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_snippets_path" {
  description = "Datastore mount path on the Proxmox node where snippets are stored"
  type        = string
  default     = "/mnt/pve/nas_nfs_hdd"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "mongo_user" {
  type    = string
  default = "ubuntu"
}

variable "template_name" {
  type    = string
  default = "mongo-7-db-template"
}

variable "cloudinit_storage" {
  type    = string
  default = "nas_nfs_hdd"
}

variable "mongo_gateway" {
  type    = string
  default = "192.168.20.1"
}

variable "nic_name" {
  type    = string
  default = "vmbr0"
}

variable "mongo_node_root_disk_size" {
  type    = string
  default = "20G"
}

variable "mongo_node_data_disk_size" {
  type    = string
  default = "40G"
}

variable "mongo_node_disk_storage" {
  type    = string
  default = "nvme-zfs"
}

variable "mongo_replica_set_name" {
  type    = string
  default = "rs-homelab"
}

variable "mongo_nodes" {
  type = map(object({
    ip          = string
    cpu         = number
    ram         = number
    deploy_host = string
    network_id  = number
  }))
  default = {
    "mongo-node-0" = { ip = "192.168.20.100/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-1", network_id = 0 }
    "mongo-node-1" = { ip = "192.168.20.101/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-2", network_id = 0 }
    "mongo-node-2" = { ip = "192.168.20.102/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-1", network_id = 0 }
  }
}

variable "mongo_root_user" {
  description = "Database administrator username"
  type        = string
  default     = "siteAdmin"
}

variable "mongo_root_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
