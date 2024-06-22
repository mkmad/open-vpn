resource "google_compute_network" "vpc_network" {
  name = "openvpn-network"
}

variable "region" {
  description = "The GCP region"
}

resource "google_compute_address" "static_ip" {
  name         = "openvpn-static-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

output "network_name" {
  value = google_compute_network.vpc_network.name
}

output "static_ip" {
  value = google_compute_address.static_ip.address
}
