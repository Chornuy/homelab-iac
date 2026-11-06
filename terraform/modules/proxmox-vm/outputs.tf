output "vmid" {
  description = "Proxmox VM ID"
  value       = proxmox_vm_qemu.vm.vmid
}

output "name" {
  value = proxmox_vm_qemu.vm.name
}

output "default_ipv4_address" {
  value = proxmox_vm_qemu.vm.default_ipv4_address
}

output "ssh_connection" {
  value = "ssh ${proxmox_vm_qemu.vm.ciuser}@${proxmox_vm_qemu.vm.default_ipv4_address}"
}
