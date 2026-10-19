#!/bin/bash
set -e

echo "=== Updating System Repositories ==="
sudo apt-get update -y
sudo apt-get install -y gnupg curl unzip

echo "=== Installing MongoDB Community Edition ==="
# Import the public GPG key for the official MongoDB repository
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg --output /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes

# Add the repository vector to your sources list
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

echo "=== Configuring MongoDB Network Bindings and HA Replica Set ==="
# 1. Allow MongoDB to bind to your Proxmox LAN interface IPs, not just localhost
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# 2. Append the Replica Set cluster identification block to the configuration file
sudo tee -a /etc/mongod.conf <<EOF

replication:
  replSetName: "rs-homelab"
EOF

# Disable Transparent HugePages (THP) for MongoDB
sudo tee /etc/systemd/system/disable-thp.service << 'EOF'
[Unit]
Description=Disable Transparent Huge Pages (THP) for MongoDB Performance
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=mongod.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
EOF

# Enable the service so it executes on every boot automatically
sudo systemctl daemon-reload
sudo systemctl enable disable-thp.service
sudo ufw disable


echo "=== Baking Percona MongoDB Exporter ==="
wget -q https://github.com/percona/mongodb_exporter/releases/download/v0.40.0/mongodb_exporter-0.40.0.linux-amd64.tar.gz -O /tmp/mongodb_exporter.tar.gz
tar -xvf /tmp/mongodb_exporter.tar.gz -C /tmp/
sudo mv /tmp/mongodb_exporter-0.40.0.linux-amd64/mongodb_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mongodb_exporter
rm -rf /tmp/mongodb_exporter*

sudo useradd --system --no-create-home --shell /bin/false mongodb_exporter || true

sudo tee /etc/systemd/system/mongodb_exporter.service << 'EOF'
[Unit]
Description=MongoDB Exporter
After=network.target mongod.service
Wants=mongod.service

[Service]
User=mongodb_exporter
Group=mongodb_exporter
Type=simple
ExecStart=/usr/local/bin/mongodb_exporter --mongodb.uri=mongodb://127.0.0.1:27017 --collect-all
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

echo "=== Baking Promtail Agent ==="
wget -q https://github.com/grafana/loki/releases/download/v2.9.4/promtail-linux-amd64.zip -O /tmp/promtail.zip
sudo unzip /tmp/promtail.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/promtail-linux-amd64
rm -rf /tmp/promtail.zip

sudo mkdir -p /etc/promtail

# Create a default placeholder config (Will be safely overwritten by Cloud-Init)
sudo tee /etc/promtail/config.yml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://127.0.0.1:3100/loki/api/v1/push

scrape_configs:
- job_name: mongodb
  static_configs:
  - targets:
      - localhost
    labels:
      job: mongodb
      host: localhost
      __path__: /var/log/mongodb/mongod.log
EOF

sudo tee /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail Log Shipper
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail-linux-amd64 -config.file=/etc/promtail/config.yml
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable mongodb_exporter.service

echo "=== Cleaning Up & Disabling Daemons for Cloud-Init Handover ==="
sudo systemctl daemon-reload
sudo systemctl disable mongod
sudo systemctl disable mongodb_exporter
sudo systemctl disable promtail