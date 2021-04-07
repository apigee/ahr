


# AWS: Security Group: rule for 7000,7001 cassanrda traffic
resource "aws_security_group_rule" "cs-inode" {
  type              = "ingress"
  from_port         = 7000
  to_port           = 7001
  protocol          = "tcp"
  cidr_blocks       = [ "0.0.0.0/0" ]
  security_group_id = aws_vpc.aws_vpc.default_security_group_id
}

# GCP: Firewall Rule: rule for 7000,7001 cassanrda traffic
resource "google_compute_firewall" "allow_cs-inode" {
  name = "${var.gcp_vpc}-allow-cs"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports = [ "7000", "7001" ]
  }
}
