token_id      = ""
token_secret  = ""
proxmox_host  = ""
template_name = "mongo-7-db-template"

mongo_root_user     = "siteAdmin"
mongo_root_password = ""

# Override cluster shape here if needed.
# mongo_nodes = {
#   "mongo-node-0" = { ip = "192.168.20.100/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-1", network_id = 0 }
#   "mongo-node-1" = { ip = "192.168.20.101/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-2", network_id = 0 }
#   "mongo-node-2" = { ip = "192.168.20.102/24", cpu = 2, ram = 4096, deploy_host = "proxmox-pve-node-1", network_id = 0 }
# }
