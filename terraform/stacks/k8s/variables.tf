variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = true
}

variable "proxmox_host" {
  description = "Proxmox API/SSH host (node name or IP) reachable from where Terraform runs"
  type        = string
  default     = "proxmox-pve-node-1"
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

variable "nic_name" {
  type    = string
  default = "vmbr0"
}

variable "cloudinit_storage" {
  type    = string
  default = "nas_nfs_hdd"
}

variable "k8s_pod_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "k8s_user" {
  description = "SSH user baked into the k8s template"
  type        = string
  default     = "ubuntu"
}

variable "k8s_gateway" {
  type    = string
  default = "192.168.20.1"
}

variable "k8s_node_root_disk_size" {
  type    = string
  default = "32G"
}

variable "k8s_node_data_disk_size" {
  type    = string
  default = "30G"
}

variable "k8s_node_disk_storage" {
  type    = string
  default = "nvme-zfs"
}

variable "k8s_template_name" {
  type    = string
  default = "ubuntu-k8s-template"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "bgp_local_asn" {
  type    = number
  default = 64513
}

variable "bgp_peer_asn" {
  type    = number
  default = 64512
}

variable "bgp_peer_ip" {
  type    = string
  default = "192.168.20.1"
}

variable "bgp_hold_time" {
  type    = number
  default = 180
}

variable "bgp_keepalive_time" {
  type    = number
  default = 60
}

variable "k8s_lb_cidr" {
  type    = string
  default = "172.16.10.0/24"
}

variable "cluster_nodes" {
  type = map(object({
    type        = string
    ram         = number
    cpu         = number
    ip          = string
    deploy_host = string
    network_id  = number
    labels      = list(string)
  }))
  default = {
    "k8s-master-0" = { type = "master", ram = 8192, cpu = 2, ip = "192.168.20.80/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = [""] }
    "k8s-worker-0" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.90/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = ["node-role.kubernetes.io/worker"] }
    "k8s-worker-1" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.91/24", deploy_host = "proxmox-pve-node-2", network_id = 0, labels = ["node-role.kubernetes.io/worker"] }
  }
}
