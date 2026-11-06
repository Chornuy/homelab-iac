output "nodes" {
  description = "Cluster nodes with their Proxmox VMID and IP"
  value = {
    for name, node in module.k8s_node : name => {
      vmid = node.vmid
      ip   = node.default_ipv4_address
    }
  }
}
