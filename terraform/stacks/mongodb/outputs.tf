output "nodes" {
  description = "Replica set members with their Proxmox VMID and IP"
  value = {
    for name, node in module.mongo_node : name => {
      vmid = node.vmid
      ip   = node.default_ipv4_address
    }
  }
}
