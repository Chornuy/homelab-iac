# Define the MikroTik/RouterOS Provider
terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.99.1" # Check for the latest version on Terraform Registry
    }
  }
}

# Provider configuration
# Note: You must enable the API on your MikroTik first:
# /ip service enable api-ssl
provider "routeros" {
  hosturl  = var.hosturl # Your MikroTik IP
  username = var.username
  password = var.password
  insecure = true # Set to true if using self-signed SSL certificates
}

