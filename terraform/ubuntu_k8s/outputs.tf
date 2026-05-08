# Output definitions for the cloudinit_test VM

# output "vm_id" {
#   description = "The Proxmox VM ID"
#   value       = proxmox_vm_qemu.cloud_init_upload.vmid
# }
#
# output "vm_name" {
#   description = "The name of the VM"
#   value       = proxmox_vm_qemu.cloudinit_test.name
# }
#
# output "vm_ip_address" {
#   description = "The primary IP address of the VM (requires QEMU agent)"
#   value       = proxmox_vm_qemu.cloudinit_test.default_ipv4_address
# }
#
# output "vm_ssh_connection" {
#   description = "Convenience string for SSH connection"
#   value       = "ssh ${proxmox_vm_qemu.cloudinit_test.ciuser}@${proxmox_vm_qemu.cloudinit_test.default_ipv4_address}"
# }
#
# output "vm_status" {
#   description = "The current status of the VM"
#   value       = "Created on node: ${proxmox_vm_qemu.cloudinit_test.target_node}"
# }
