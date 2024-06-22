variable "network_name" {
  description = "The name of the VPC network"
}

resource "google_compute_firewall" "openvpn_firewall" {
  name    = "openvpn-firewall"
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  source_ranges = ["0.0.0.0/0"]
}
