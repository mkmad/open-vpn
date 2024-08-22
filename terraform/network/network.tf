variable "region" {
  description = "The GCP region"
}

resource "google_compute_network" "vpc_network" {
  name = "openvpn-network"
}

# This creates a regional static IP address (for Regional Load Balancer)
resource "google_compute_address" "static_ip" {
  name         = "openvpn-static-ip"
  address_type = "EXTERNAL"
  region       = var.region  # Ensure the region is specified correctly
}

resource "google_compute_address" "nat_ip" {
  name         = "openvpn-nat-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_router" "nat_router" {
  name    = "openvpn-router"
  region  = var.region
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat_config" {
  name                                = "openvpn-nat"
  router                              = google_compute_router.nat_router.name
  region                              = var.region
  nat_ip_allocate_option              = "MANUAL_ONLY"
  nat_ips                             = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

output "network_name" {
  value = google_compute_network.vpc_network.name
}

output "static_ip" {
  value = google_compute_address.static_ip.address
}

output "nat_ip" {
  value = google_compute_address.nat_ip.address
}
