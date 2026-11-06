variable "nodes" {
  description = "Map of cluster nodes (same shape as the stack's cluster_nodes)"
  type = map(object({
    type        = string
    ram         = number
    cpu         = number
    ip          = string
    deploy_host = string
    network_id  = number
    labels      = list(string)
  }))
}

variable "first_master" {
  description = "Key of the node that runs kubeadm init"
  type        = string
  default     = "k8s-master-0"
}

variable "ssh_user" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "k8s_pod_cidr" {
  type = string
}

variable "k8s_token" {
  description = "kubeadm bootstrap token"
  type        = string
  sensitive   = true
}

variable "k8s_cert_key" {
  description = "kubeadm certificate key"
  type        = string
  sensitive   = true
}

variable "bgp_local_asn" {
  type = number
}

variable "bgp_peer_asn" {
  type = number
}

variable "bgp_peer_ip" {
  type = string
}

variable "bgp_hold_time" {
  type = number
}

variable "bgp_keepalive_time" {
  type = number
}

variable "k8s_lb_cidr" {
  type = string
}

variable "longhorn_replica_count" {
  type = number
}

variable "longhorn_soft_anti_affinity" {
  type = string
}
