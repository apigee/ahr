
output aws_vpc_id {
  value = aws_vpc.aws_vpc.id
}

output gcp_vpc_id {
  value = google_compute_network.gcp_vpc.id
}

output aws_vpn_gw_id {
  value = aws_vpn_gateway.aws_vpn_gw.id
}
