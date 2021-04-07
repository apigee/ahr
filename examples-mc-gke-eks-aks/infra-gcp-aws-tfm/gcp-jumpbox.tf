


resource "google_compute_instance" "vm_gcp" {
  name         = "vm-gcp"
  machine_type = "f1-micro"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.gcp_vpc.name
    subnetwork = google_compute_subnetwork.gcp_subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = "${var.gcp_os_username}:${file(var.gcp_ssh_pub_key_file)}"
  }
}

output "gcp_jumpbox_ip" {
  value = google_compute_instance.vm_gcp.network_interface.0.access_config.0.nat_ip
}