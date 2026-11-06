variable "template_path" {
  description = "Absolute path to the template file to render"
  type        = string
}

variable "template_vars" {
  description = "Variables passed to templatefile()"
  type        = map(any)
  default     = {}
}

variable "snippet_name" {
  description = "Filename of the snippet on the Proxmox datastore (e.g. mongo-node-0-cloud_init.yml)"
  type        = string
}

variable "filename" {
  description = "Local path where the rendered snippet is written (keep it gitignored)"
  type        = string
}

variable "proxmox_host" {
  description = "Management address of the Proxmox node"
  type        = string
}

variable "proxmox_snippets_path" {
  description = "Datastore mount path on the Proxmox node, e.g. /mnt/pve/proxmox_nfs_ssd"
  type        = string
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}