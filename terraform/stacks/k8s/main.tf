locals {
  first_master = "k8s-master-0"

  total_node_count            = length(var.cluster_nodes)
  longhorn_replica_count      = local.total_node_count >= 3 ? 3 : local.total_node_count
  longhorn_soft_anti_affinity = local.total_node_count < 3 ? "true" : "false"

  k8s_token = "${random_id.k8s_token_id.hex}.${random_id.k8s_token_secret.hex}"
}

resource "random_id" "k8s_token_id" {
  byte_length = 3
}

resource "random_id" "k8s_token_secret" {
  byte_length = 8
}

resource "random_id" "k8s_cert_key" {
  byte_length = 32
}

module "cloud_init" {
  source   = "../../modules/cloud-init-snippet"
  for_each = var.cluster_nodes

  template_path = "${path.module}/files/cloud_config.tpl"
  template_vars = {
    hostname = each.key
    k8s_user = var.k8s_user
    ssh_key  = file(pathexpand(var.ssh_public_key_path))
  }

  snippet_name          = "${each.key}-cloud_init.yml"
  filename              = "${path.module}/.generated/${each.key}-cloud_init.cfg"
  proxmox_host          = var.proxmox_host
  proxmox_snippets_path = var.proxmox_snippets_path
  ssh_private_key_path  = var.ssh_private_key_path
}

module "k8s_node" {
  source   = "../../modules/proxmox-vm"
  for_each = var.cluster_nodes

  name        = each.key
  target_node = each.value.deploy_host
  description = "K8S ${upper(each.value.type)} Node"

  template_name = var.k8s_template_name
  cores         = each.value.cpu
  memory        = each.value.ram

  disk_size      = var.k8s_node_root_disk_size
  data_disk_size = var.k8s_node_data_disk_size
  storage        = var.k8s_node_disk_storage

  ip_address        = each.value.ip
  gateway           = var.k8s_gateway
  network_id        = each.value.network_id
  bridge            = var.nic_name
  cloudinit_storage = var.cloudinit_storage
  cloudinit_snippet = "user=${var.cloudinit_storage}:snippets/${each.key}-cloud_init.yml"
  mac_prefix        = "52:54:00:12:34"
  tags              = ["k8s", "ubuntu", "k8s_${each.value.type}"]

  depends_on = [module.cloud_init]
}

module "k8s_bootstrap" {
  source = "../../modules/k8s-bootstrap"

  nodes        = var.cluster_nodes
  first_master = local.first_master
  ssh_user     = var.k8s_user

  ssh_private_key_path = var.ssh_private_key_path

  k8s_pod_cidr = var.k8s_pod_cidr
  k8s_token    = local.k8s_token
  k8s_cert_key = random_id.k8s_cert_key.hex

  bgp_local_asn      = var.bgp_local_asn
  bgp_peer_asn       = var.bgp_peer_asn
  bgp_peer_ip        = var.bgp_peer_ip
  bgp_hold_time      = var.bgp_hold_time
  bgp_keepalive_time = var.bgp_keepalive_time
  k8s_lb_cidr        = var.k8s_lb_cidr

  longhorn_replica_count      = local.longhorn_replica_count
  longhorn_soft_anti_affinity = local.longhorn_soft_anti_affinity

  depends_on = [module.k8s_node]
}
