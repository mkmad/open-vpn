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
