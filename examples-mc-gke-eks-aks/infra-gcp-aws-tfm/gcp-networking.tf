
resource "google_compute_network" "gcp_vpc" {
  name = var.gcp_vpc
  auto_create_subnetworks = "false"
}

resource "google_compute_firewall" "allow_internal" {
  name = "${var.gcp_vpc}-allow-internal"
  network = google_compute_network.gcp_vpc.name

  allow { protocol = "icmp" }
  allow { protocol = "tcp" }
  allow { protocol = "udp" }

  source_ranges = [ var.gcp_vpc_cidr ]
}

resource "google_compute_firewall" "allow_ssh" {
  name = "${var.gcp_vpc}-allow-ssh"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports = [ "22" ]
  }
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name = "gcp-subnet"
  ip_cidr_range = var.gcp_vpc_subnet_cidr
  network = google_compute_network.gcp_vpc.name
  region = var.gcp_region
}


# vpn connection

resource "google_compute_address" "gcp_vpn_ip" {
  name   = "gcp-vpn-ip"
  region = var.gcp_region
}


resource "google_compute_vpn_gateway" "gcp_vpn_gw" {
  name    = var.gcp_aws_vpc_target_gw
  network = google_compute_network.gcp_vpc.name
  region  = var.gcp_region
}


resource "google_compute_forwarding_rule" "fr_aws_esp" {
  name        = "fr-${var.gcp_aws_vpc_gw_name}-aws-esp"
  ip_protocol = "ESP"

  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gw.self_link
  region = var.gcp_region
}

resource "google_compute_forwarding_rule" "fr_aws_udp500" {
  name        = "fr-${var.gcp_aws_vpc_gw_name}-aws-udp500"
  ip_protocol = "UDP"
  port_range  = "500"

  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gw.self_link
  region = var.gcp_region
}

resource "google_compute_forwarding_rule" "fr_aws_udp4500" {
  name        = "fr-${var.gcp_aws_vpc_gw_name}-aws-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"

  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gw.self_link
  region = var.gcp_region
}


resource "google_compute_vpn_tunnel" "aws_tunnel1" {
  name          = var.gcp_aws_vpn_tunnel1
  peer_ip       = aws_vpn_connection.aws_gcp_vpn_connection.tunnel1_address
  ike_version = 2
  shared_secret = aws_vpn_connection.aws_gcp_vpn_connection.tunnel1_preshared_key

  local_traffic_selector = [ "0.0.0.0/0" ]
  remote_traffic_selector = [ "0.0.0.0/0" ]

  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gw.id
  region = var.gcp_region

  depends_on = [
    google_compute_forwarding_rule.fr_aws_esp,
    google_compute_forwarding_rule.fr_aws_udp500,
    google_compute_forwarding_rule.fr_aws_udp4500,
  ]
}

resource "google_compute_route" "route1" {
  name       = "${var.gcp_aws_vpn_tunnel1}-route"
  network = google_compute_network.gcp_vpc.name
  dest_range = var.aws_vpc_cidr
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.aws_tunnel1.id
}


resource "google_compute_vpn_tunnel" "aws_tunnel2" {
  name          = var.gcp_aws_vpn_tunnel2
  peer_ip       = aws_vpn_connection.aws_gcp_vpn_connection.tunnel2_address
  ike_version = 2
  shared_secret = aws_vpn_connection.aws_gcp_vpn_connection.tunnel2_preshared_key

  local_traffic_selector = [ "0.0.0.0/0" ]
  remote_traffic_selector = [ "0.0.0.0/0" ]

  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gw.id
  region = var.gcp_region

  depends_on = [
    google_compute_forwarding_rule.fr_aws_esp,
    google_compute_forwarding_rule.fr_aws_udp500,
    google_compute_forwarding_rule.fr_aws_udp4500,
  ]
}

resource "google_compute_route" "route" {
  name       = "${var.gcp_aws_vpn_tunnel2}-route"
  network = google_compute_network.gcp_vpc.name
  dest_range = var.aws_vpc_cidr
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.aws_tunnel2.id
}

