# TF vars for spinning up VMs

variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = true
}

#Establish which Proxmox host you'd like to spin a VM up on
variable "proxmox_host" {
  default = "proxmox-pve-node-1"
}

#Specify which template name you'd like to use
variable "template_name" {
  default = "ubuntu-k8s-template"
}
#Establish which nic you would like to utilize
variable "nic_name" {
  default = "vmbr0"
}

variable "cloudinit_storage" {
  default = "proxmox_nfs_ssd"
}

variable "k8s_pod_cidr" {
  default = "10.244.0.0/16"
}

variable "k8s_cert_key" {
  default = "8344e45d56b068798517592965f3a093ed03f56e9c9162973a903025287f3299"
}

variable "k8s_token_key" {
  default = "abcdef.1234567890abcdef"
}

variable "k8s_user" {
  description = "k8s user"
  default     = "ubuntu"
}

variable "k8s_gateway" {
  default = "192.168.20.1"
}

variable "k8s_node_root_disk_size" {
  default = "32G"
}

variable "k8s_node_data_disk_size" {
  default = "30G"
}

variable "k8s_node_disk_storage" {
  default = "nvme-zfs"
}

variable "k8s_template_name" {
  default = "ubuntu-k8s-template"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key used for provisioning"
  default     = "~/.ssh/id_ed25519"
}

variable "bgp_local_asn" {
  default = "64513"
}
variable "bgp_peer_asn" { default = "64512" }
variable "bgp_peer_ip" { default = "192.168.20.1" }
variable "bgp_hold_time" { default = 180 }
variable "bgp_keepalive_time" { default = 60 }

variable "k8s_lb_cidr" { default = "172.16.10.0/24" }
#Blank var for use by terraform.tfvars
variable "token_secret" {
}

#Blank var for use by terraform.tfvars
variable "token_id" {
}

# TF vars for spinning up VMs

variable "mikrotik_hosturl" {
  default = "http://192.168.0.1"
}

variable "mikrotik_username" {
  default = "admin"
}

variable "mikrotik_password" {}


variable "cluster_nodes" {
  type = map(object({
    type        = string # "master" or "worker"
    ram         = number
    cpu         = number
    ip          = string
    deploy_host = string
    network_id  = number
    labels      = list(string)
  }))
  default = {
    "k8s-master-0" = { type = "master", ram = 8192, cpu = 2, ip = "192.168.20.80/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = [""] }
    "k8s-master-1" = { type = "master", ram = 8192, cpu = 2, ip = "192.168.20.81/24", deploy_host = "proxmox-pve-node-2", network_id = 0, labels = [""] }
    "k8s-worker-0" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.90/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = ["worker"] }
    "k8s-worker-1" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.91/24", deploy_host = "proxmox-pve-node-2", network_id = 0, labels = ["worker"] }
  }
}