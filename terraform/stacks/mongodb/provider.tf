provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id     = var.token_id
  pm_api_token_secret = var.token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}
