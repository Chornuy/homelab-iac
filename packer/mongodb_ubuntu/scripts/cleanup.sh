#!/usr/bin/env bash
set -eux

# Stop the cloud-init service from caching the Packer environment
sudo systemctl stop cloud-init || true

# Purge ALL network configurations stamped by the installer
sudo rm -f /etc/netplan/*.yaml
sudo rm -f /etc/netplan/*.yml

# Clean out the cloud-init machine cache lines entirely
sudo cloud-init clean --logs --seed

# Truncate the machine-id so it doesn't cache the DHCP client token
sudo truncate -s 0 /etc/machine-id