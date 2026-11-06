#cloud-config
# This template is rendered by Terraform

hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

users:
  - name: ${mongo_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}

ssh_authorized_keys:
  - ${ssh_key}

# Using the built-in packages module is safer than runcmd for basic installs
packages:
  - curl
  - apt-transport-https

runcmd:
  - netplan apply
  # 1. Wait up to 15 seconds for the Proxmox SCSI controller to fully present /dev/sdb to the OS
  - until [ -b /dev/sdb ]; do echo "Waiting for sdb block device..."; sleep 1; done

  # 2. Partition /dev/sdb cleanly into a single GPT partition (/dev/sdb1)
  - parted -s /dev/sdb mklabel gpt
  - parted -s -a optimal /dev/sdb mkpart primary xfs 0% 100%

  # 3. Format the new block partition to high-performance XFS
  - mkfs.xfs -f /dev/sdb1

  # 4. Mount it temporarily to fix ownership configurations
  - mount -t xfs -o defaults,noatime /dev/sdb1 /var/lib/mongodb
  - chown -R mongodb:mongodb /var/lib/mongodb

  # 5. Append the layout permanently to /etc/fstab so it mounts automatically on future VM reboots
  - echo '/dev/sdb1 /var/lib/mongodb xfs defaults,noatime 0 0' >> /etc/fstab
  - chown -R mongodb:mongodb /var/lib/mongodb


  # 6. WRITE THE KEYFILE HERE (Now safely hitting the active XFS mount surface)
  - |
    cat << 'EOF' > /var/lib/mongodb/pve-cluster-keyfile
    ${cluster_key_value}
    EOF

  # 7. Restrict file permissions and fix the ownership recursively
  - chmod 0400 /var/lib/mongodb/pve-cluster-keyfile
  - chown -R mongodb:mongodb /var/lib/mongodb

  # 6. Finally, spin up the MongoDB cluster engine safely on the XFS drive
  - systemctl daemon-reload
  - systemctl enable mongod
  - systemctl start mongod
