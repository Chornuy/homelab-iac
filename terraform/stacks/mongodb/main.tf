resource "random_id" "mongo_cluster_key" {
  byte_length = 32
}

module "cloud_init" {
  source   = "../../modules/cloud-init-snippet"
  for_each = var.mongo_nodes

  template_path = "${path.module}/files/cloud_config.tpl"
  template_vars = {
    hostname          = each.key
    mongo_user        = var.mongo_user
    ssh_key           = file(pathexpand(var.ssh_key_path))
    cluster_key_value = random_id.mongo_cluster_key.b64_std
  }

  snippet_name          = "${each.key}-cloud_init.yml"
  filename              = "${path.module}/.generated/${each.key}-cloud_init.cfg"
  proxmox_host          = var.proxmox_host
  proxmox_snippets_path = var.proxmox_snippets_path
  ssh_private_key_path  = var.ssh_private_key_path
}

module "mongo_node" {
  source   = "../../modules/proxmox-vm"
  for_each = var.mongo_nodes

  name        = each.key
  target_node = each.value.deploy_host
  description = "MongoDB replica set member ${each.key}"

  template_name = var.template_name
  cores         = each.value.cpu
  memory        = each.value.ram

  disk_size      = var.mongo_node_root_disk_size
  data_disk_size = var.mongo_node_data_disk_size
  storage        = var.mongo_node_disk_storage

  ip_address        = each.value.ip
  gateway           = var.mongo_gateway
  network_id        = each.value.network_id
  bridge            = var.nic_name
  cloudinit_storage = var.cloudinit_storage
  cloudinit_snippet = "user=${var.cloudinit_storage}:snippets/${each.key}-cloud_init.yml"
  mac_prefix        = "52:54:00:22:34"
  tags              = ["database", "mongodb", "mongocluster", each.key]

  depends_on = [module.cloud_init]
}

module "mongo_replica" {
  source = "../../modules/mongodb-replica"

  nodes            = var.mongo_nodes
  seed_node        = "mongo-node-0"
  replica_set_name = var.mongo_replica_set_name

  ssh_user             = var.mongo_user
  ssh_private_key_path = var.ssh_private_key_path

  root_user     = var.mongo_root_user
  root_password = var.mongo_root_password

  mongod_conf = templatefile("${path.module}/files/mongod.conf.tpl", {
    repl_set_name = var.mongo_replica_set_name
  })

  depends_on = [module.mongo_node]
}
