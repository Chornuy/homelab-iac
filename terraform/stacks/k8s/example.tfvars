token_id     = ""
token_secret = ""
proxmox_host = "proxmox-pve-node-1"

# Override cluster shape here if needed.
# cluster_nodes = {
#   "k8s-master-0" = { type = "master", ram = 8192, cpu = 2, ip = "192.168.20.80/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = [""] }
#   "k8s-worker-0" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.90/24", deploy_host = "proxmox-pve-node-1", network_id = 0, labels = ["node-role.kubernetes.io/worker"] }
#   "k8s-worker-1" = { type = "worker", ram = 8192, cpu = 2, ip = "192.168.20.91/24", deploy_host = "proxmox-pve-node-2", network_id = 0, labels = ["node-role.kubernetes.io/worker"] }
# }
