variable "name" {
  type = string
}

variable "target_node" {
  description = "Proxmox node to deploy on"
  type        = string
}

variable "description" {
  type    = string
  default = ""
}

variable "template_name" {
  description = "Packer template to clone from"
  type        = string
}

variable "full_clone" {
  type    = bool
  default = true
}

variable "cores" {
  type = number
}

variable "sockets" {
  type    = number
  default = 1
}

variable "memory" {
  description = "RAM in MiB"
  type        = number
}

variable "onboot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "disk_size" {
  description = "Root disk size, e.g. 32G"
  type        = string
}

variable "data_disk_size" {
  description = "Optional second disk size, e.g. 40G. Null = no data disk"
  type        = string
  default     = null
}

variable "storage" {
  type = string
}

variable "data_storage" {
  type    = string
  default = null
}

variable "discard" {
  type    = bool
  default = true
}

variable "ip_address" {
  description = "Static IP in CIDR form"
  type        = string
}

variable "gateway" {
  type = string
}

variable "cloudinit_storage" {
  description = "Datastore for the cloud-init disk"
  type        = string
}

variable "cloudinit_snippet" {
  description = "cicustom value, e.g. user=storage:snippets/file.yml"
  type        = string
}

variable "network_id" {
  type    = number
  default = 0
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "mac_prefix" {
  description = "First 5 octets of the MAC; last octet is derived from the IP"
  type        = string
  default     = "52:54:00:22:34"
}