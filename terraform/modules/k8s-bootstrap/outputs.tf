output "first_master_ip" {
  description = "IP of the node that ran kubeadm init"
  value       = local.first_master_ip
}
