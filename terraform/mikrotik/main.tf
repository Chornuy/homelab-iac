locals {
  lab_vlan_id = 20
  # The physical port connected to your unmanaged switch
  trunk_port = "ether1"
}

# 1. THE VLAN INTERFACE
resource "routeros_interface_vlan" "lab_vlan" {
  name      = "vlan-lab"
  vlan_id   = local.lab_vlan_id
  interface = "bridge" # Attach to bridge so it works across all ports
}

# 2. IP ADDRESS FOR THE LAB GATEWAY
resource "routeros_ip_address" "lab_gateway" {
  address   = "192.168.20.1/24"
  interface = routeros_interface_vlan.lab_vlan.name
  network   = "192.168.20.0"
}

# 3. DHCP SERVER SETUP
# Define the range of IPs for dynamic allocation (e.g., .100 to .200)
resource "routeros_ip_pool" "lab_pool" {
  name   = "lab-pool"
  ranges = ["192.168.20.2-192.168.20.200"]
}

# Create the DHCP Server instance
resource "routeros_ip_dhcp_server" "lab_dhcp" {
  dynamic_lease_identifiers = "client-mac,client-id"
  interface    = routeros_interface_vlan.lab_vlan.name
  name         = "dhcp-lab"
  address_pool = routeros_ip_pool.lab_pool.name
  disabled     = false
}

# 5. STATIC LEASES (Assigning specific IPs to Proxmox Nodes)
# This ensures Proxmox stays on DHCP but always gets these IPs
resource "routeros_ip_dhcp_server_lease" "proxmox_node_1" {
  address     = "192.168.20.10"
  mac_address = "E8:6A:64:99:6E:B3" # Put your Proxmox MAC here
  server      = routeros_ip_dhcp_server.lab_dhcp.name
  comment     = "Proxmox Node 1"
}

# Define the gateway and DNS settings for DHCP clients
resource "routeros_ip_dhcp_server_network" "lab_dhcp_net" {
  address    = "192.168.20.0/24"
  gateway    = "192.168.20.1"
  dns_server = ["192.168.20.1", "192.168.0.1", "1.1.1.1", "8.8.8.8"]
  comment    = "Lab VLAN DHCP Network"
}

resource "routeros_ip_dhcp_server_lease" "node_leases" {
  for_each = var.static_ip_hosts

  address     = each.value.ip
  mac_address = each.value.mac
  server      = routeros_ip_dhcp_server.lab_dhcp.name
  comment     = "Managed by Terraform: ${each.key}"
}

locals {
  # Generate both short and FQDN records from the same map
  dns_entries = flatten([
    for name, data in var.static_ip_hosts : [
      {
        fqdn    = name
        address = data.ip
      },
      {
        fqdn    = "${name}.${var.local_domain}"
        address = data.ip
      }
    ]
  ])
}

resource "routeros_ip_dns_record" "node_dns" {
  for_each = { for entry in local.dns_entries : entry.fqdn => entry }

  name    = each.value.fqdn
  address = each.value.address
  type    = "A"
  ttl     = "5m"
}

# 4. BRIDGE VLAN SETTINGS
resource "routeros_interface_bridge_vlan" "lab_vlan_assignment" {
  bridge   = "bridge"
  vlan_ids = [local.lab_vlan_id]
  tagged   = ["bridge", local.trunk_port]
}

resource "routeros_ip_firewall_filter" "allow_home_to_lab" {
  chain       = "forward"
  action      = "accept"
  src_address = "192.168.0.0/24" # Adjust if your home net is different
  dst_address = "192.168.20.0/24"
}

resource "routeros_ip_firewall_filter" "allow_lab_to_home" {
  chain       = "forward"
  action      = "accept"
  src_address = "192.168.20.0/24"
  dst_address = "192.168.0.0/24"
}


# 6. BGP PREPARATION (For Cilium)
resource "routeros_routing_bgp_instance" "main" {
  name      = "default"
  as        = 64512
  router_id = "192.168.20.1"
  routing_table = "main"
}

resource "routeros_routing_bgp_template" "cilium" {
  name             = "cilium-template"
  as               = 64512
  address_families = "ip"
}
