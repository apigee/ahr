

# IP Address for Local network gateway 1
resource "google_compute_address" "gcp_az_vpc_gw1_ip" {
  name = var.gcp_az_vpc_gw1_ip_name
  region = var.gcp_region
  project = var.gcp_project_id
}

/* https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-activeactive-rm-powershell#part-2---establish-an-active-active-cross-premises-connection

# IP Address for Local network gateway 2
resource "google_compute_address" "gcp_az_vpc_gw2_ip" {
  name   = var.gcp_az_vpc_gw2_ip_name
  region = var.gcp_region
  project = var.gcp_project_id
}
*/

# GCP: to Azure: target vpn gateway and forwarding rules
resource "google_compute_vpn_gateway" "gcp_az_vpc_tgt_gw" {
  name = var.gcp_az_vpc_tgt_gw
  network = module.gcp_and_aws_infra.gcp_vpc_id
  region = var.gcp_region
}

resource "google_compute_forwarding_rule" "fr1_gcp_az_vpc_tgt_gw_az_esp" {
  name = "fr1-${var.gcp_az_vpc_tgt_gw}-az-esp"
  ip_protocol = "ESP"
  ip_address = google_compute_address.gcp_az_vpc_gw1_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}
resource "google_compute_forwarding_rule" "fr1_gcp_az_vpc_tgt_gw_az_udp500" {
  name = "fr1-${var.gcp_az_vpc_tgt_gw}-az-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address = google_compute_address.gcp_az_vpc_gw1_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}
resource "google_compute_forwarding_rule" "fr1_gcp_az_vpc_tgt_gw_az_udp4500" {
  name = "fr1-${var.gcp_az_vpc_tgt_gw}-az-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address = google_compute_address.gcp_az_vpc_gw1_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}

/* TODO: active-activee cross full mesh

resource "google_compute_forwarding_rule" "fr2_gcp_az_vpc_tgt_gw_az_esp" {
  name = "fr2-${var.gcp_az_vpc_tgt_gw}-az-esp"
  ip_protocol = "ESP"
  ip_address = google_compute_address.gcp_az_vpc_gw2_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}
resource "google_compute_forwarding_rule" "fr2_gcp_az_vpc_tgt_gw_az_udp500" {
  name = "fr2-${var.gcp_az_vpc_tgt_gw}-az-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address = google_compute_address.gcp_az_vpc_gw2_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}
resource "google_compute_forwarding_rule" "fr2_gcp_az_vpc_tgt_gw_az_udp4500" {
  name = "fr2-${var.gcp_az_vpc_tgt_gw}-az-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address = google_compute_address.gcp_az_vpc_gw2_ip.address
  target = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region
}
*/

# GCP: Create the Cloud VPN tunnels

resource "google_compute_vpn_tunnel" "gcp_az_vpn_tunnel1" {
  name = var.gcp_az_vpn_tunnel1
  peer_ip = data.azurerm_public_ip.az_gcp_vnet_gw_ip1_ref.ip_address

  ike_version = 2
  shared_secret = random_id.az_psk1.b64_std

  local_traffic_selector = [ "0.0.0.0/0" ]
  remote_traffic_selector = [ "0.0.0.0/0" ]

  target_vpn_gateway = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region

  depends_on = [
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_esp,
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_udp500,
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_udp4500,
  ]
}

resource "google_compute_route" "gcp_az_vpc_vpn_route1" {
  name       = var.gcp_az_vpc_vpn_route1
  network    = var.gcp_vpc

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.gcp_az_vpn_tunnel1.id
  
  dest_range = var.az_vnet_cidr
}


resource "google_compute_vpn_tunnel" "gcp_az_vpn_tunnel2" {
  name = var.gcp_az_vpn_tunnel2
  peer_ip = data.azurerm_public_ip.az_gcp_vnet_gw_ip2_ref.ip_address

  ike_version = 2
  shared_secret = random_id.az_psk2.b64_std

  local_traffic_selector = [ "0.0.0.0/0" ]
  remote_traffic_selector = [ "0.0.0.0/0" ]

  target_vpn_gateway = google_compute_vpn_gateway.gcp_az_vpc_tgt_gw.id
  region = var.gcp_region

  depends_on = [
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_esp,
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_udp500,
    google_compute_forwarding_rule.fr1_gcp_az_vpc_tgt_gw_az_udp4500,
  ]
}

resource "google_compute_route" "gcp_az_vpc_vpn_route2" {
  name       = var.gcp_az_vpc_vpn_route2
  network    = var.gcp_vpc

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.gcp_az_vpn_tunnel2.id
  
  dest_range = var.az_vnet_cidr
}
