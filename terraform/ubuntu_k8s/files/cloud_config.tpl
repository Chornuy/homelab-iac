#cloud-config
# This template is rendered by Terraform

hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

ssh_authorized_keys:
  - ${ssh_key}

# Using the built-in packages module is safer than runcmd for basic installs
packages:
  - curl
  - apt-transport-https

write_files:
  - path: /usr/local/bin/my-script
    permissions: '0755'
    content: |
      #!/bin/bash
      echo "System is initializing for Kubernetes..."

fs_setup:
  - filesystem: xfs
    device: /dev/sdb1
    partition: auto

disk_setup:
  - /dev/sdb:
      layout: [100]
      overwrite: false

mounts:
  - [ /dev/sdb1, /var/lib/longhorn, xfs, "defaults,noatime", "0", "0" ]

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  # Mounting Longhorn volumes (if any)
  - systemctl disable --now multipathd || true
  - mkdir -p /mnt/longhorn-data
  - mount -a
  # Longhorn dependency checklist (crucial for Ubuntu templates)
  - systemctl enable --now iscsid