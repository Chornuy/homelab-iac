#cloud-config
# This template is rendered by Terraform

hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

ssh_authorized_keys:
  - ${ssh_key}

packages:
  - curl
  - apt-transport-https
  - parted
  - xfsprogs

write_files:
  - path: /usr/local/bin/my-script
    permissions: '0755'
    content: |
      #!/bin/bash
      echo "System is initializing for Kubernetes..."

runcmd:
  - netplan apply
  # 1. Wait for the Proxmox SCSI controller to present /dev/sdb to the OS
  - until [ -b /dev/sdb ]; do echo "Waiting for sdb block device..."; sleep 1; done

  # 2. Partition /dev/sdb as a single GPT partition (/dev/sdb1)
  - parted -s /dev/sdb mklabel gpt
  - parted -s -a optimal /dev/sdb mkpart primary xfs 0% 100%

  # 3. Format the partition as XFS
  - mkfs.xfs -f /dev/sdb1

  # 4. Mount it at the Longhorn data path
  - mkdir -p /var/lib/longhorn
  - mount -t xfs -o defaults,noatime /dev/sdb1 /var/lib/longhorn

  # 5. Persist the mount across reboots
  - echo '/dev/sdb1 /var/lib/longhorn xfs defaults,noatime 0 0' >> /etc/fstab

  # 6. Longhorn / Kubernetes dependencies
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - systemctl disable --now multipathd || true
  - systemctl enable --now iscsid
