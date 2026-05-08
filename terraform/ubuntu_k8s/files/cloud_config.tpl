#cloud-config
# This template is rendered by Terraform

hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

ssh_authorized_keys:
  - ${ssh_key}

# Using the built-in packages module is safer than runcmd for basic installs
packages:
  - qemu-guest-agent
  - curl
  - apt-transport-https

write_files:
  - path: /usr/local/bin/my-script
    permissions: '0755'
    content: |
      #!/bin/bash
      echo "System is initializing for Kubernetes..."

runcmd:
  - echo "AAARGH - Cloud-init is running"
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
