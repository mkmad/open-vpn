variable "network_name" {
  description = "The name of the VPC network"
}

variable "instance_tag" {
  description = "The network tag to apply to the instance and firewall rule"
}

resource "google_compute_firewall" "openvpn_firewall" {
  name    = "openvpn-firewall"
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  # allow from any IP address
  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.instance_tag]

  direction = "INGRESS"
}

resource "google_compute_firewall" "openvpn_ssh_firewall" {
  name    = "allow-ssh-ingress-openvpn"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  target_tags = [var.instance_tag]

  direction = "INGRESS"
}

resource "google_compute_firewall" "allow-outbound-traffic" {
  name    = "allow-outbound-traffic"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22", "5000", "3478", "5349", "8883", "12121"]
  }

  allow {
    protocol = "udp"
    ports    = ["3478", "5349", "8883", "12121"]
  }

  direction = "EGRESS"
  target_tags = [var.instance_tag]

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-icmp" {
  name    = "allow-icmp"
  network = var.network_name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.instance_tag]

  direction = "INGRESS"
}

resource "google_compute_firewall" "allow-multi-robot-comm" {
  name    = "allow-multi-robot-comm"
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["9194", "9195"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.instance_tag]

  direction = "INGRESS"
}

resource "google_compute_firewall" "allow-google-dns" {
  name    = "allow-google-dns"
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  direction = "EGRESS"
  target_tags = [var.instance_tag]

  destination_ranges = ["8.8.8.8", "8.8.4.4"]
}

# Allow outbound traffic to specific domains (example IP ranges)
resource "google_compute_firewall" "allow-outbound-urls" {
  name    = "allow-outbound-urls"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  direction = "EGRESS"
  target_tags = [var.instance_tag]

  destination_ranges = [
    "34.202.0.0/16",   # example IP range for *.bearrobotics.ai
    "35.184.0.0/13",   # example IP range for *.google.com
    "35.191.0.0/16",   # example IP range for *.googleusercontent.com
    "34.170.0.0/16",   # example IP range for *.pkg.dev
    "35.186.0.0/16",   # example IP range for *.googleapis.com
    "34.64.0.0/10",    # example IP range for gcr.io
    "216.239.32.0/19", # example IP range for google.com and related services
    "199.36.154.0/23"  # example IP range for google-analytics.com and googletagmanager.com
  ]
}