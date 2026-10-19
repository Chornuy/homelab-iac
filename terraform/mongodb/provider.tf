terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  # References our vars.tf file to plug in the api_url
  pm_api_url = "https://${var.proxmox_host}:8006/api2/json"
  # Provided in a file, secrets.tfvars containing secret terraform variables
  pm_api_token_id = var.token_id
  # Also provided in secrets.tfvars
  pm_api_token_secret = var.token_secret
  # Defined in vars.tf
  pm_tls_insecure = var.pm_tls_insecure
  pm_log_enable   = true
  # this is useful for logging what Terraform is doing
  pm_log_file = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
