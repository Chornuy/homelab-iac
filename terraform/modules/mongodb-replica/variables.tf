variable "nodes" {
  type = map(object({
    ip          = string
    cpu         = number
    ram         = number
    deploy_host = string
    network_id  = number
  }))
}

variable "seed_node" {
  description = "Node that runs rs.initiate"
  type        = string
  default     = "mongo-node-0"
}

variable "replica_set_name" {
  type = string
}

variable "ssh_user" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "root_user" {
  type = string
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "mongod_conf" {
  description = "Rendered mongod.conf content pushed to every node"
  type        = string
}
