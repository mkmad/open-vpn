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

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.instance_tag]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "openvpn_ssh_firewall" {
  name    = "allow-ssh-ingress-openvpn"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.instance_tag]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow-outbound-traffic" {
  name    = "allow-outbound-traffic"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22", "1194", "5000", "3478", "5349", "8883", "12121"]
  }

  allow {
    protocol = "udp"
    ports    = ["1194", "3478", "5349", "8883", "12121"]
  }

  direction     = "EGRESS"
  target_tags   = [var.instance_tag]
  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-icmp" {
  name    = "allow-icmp"
  network = var.network_name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.instance_tag]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow-multi-robot-comm" {
  name    = "allow-multi-robot-comm"
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["9194", "9195"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.instance_tag]
  direction     = "INGRESS"
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

  direction     = "EGRESS"
  target_tags   = [var.instance_tag]
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

  # Fetched most of the IPs from:
  # 1. https://support.google.com/a/answer/10026322?hl=en
  # 2. https://www.gstatic.com/ipranges/cloud.json
  # 3. https://www.gstatic.com/ipranges/goog.json
  destination_ranges = [
    "8.8.4.0/24",       # IP range for google.com
    "8.8.8.0/24",       # IP range for google.com
    "8.34.208.0/20",    # IP range for google.com
    "8.35.192.0/20",    # IP range for google.com
    "23.236.48.0/20",   # IP range for google.com
    "23.251.128.0/19",  # IP range for google.com
    "34.0.0.0/15",      # IP range for google.com
    "34.2.0.0/16",      # IP range for google.com
    "34.3.0.0/23",      # IP range for google.com
    "34.3.3.0/24",      # IP range for google.com
    "34.3.4.0/24",      # IP range for google.com
    "34.3.8.0/21",      # IP range for google.com
    "34.3.16.0/20",     # IP range for google.com
    "34.3.32.0/19",     # IP range for google.com
    "34.3.64.0/18",     # IP range for google.com
    "34.4.0.0/14",      # IP range for google.com
    "34.8.0.0/13",      # IP range for google.com
    "34.16.0.0/12",     # IP range for google.com
    "34.32.0.0/11",     # IP range for google.com
    "34.64.0.0/10",     # IP range for google.com
    "34.128.0.0/10",    # IP range for google.com
    "35.184.0.0/13",    # IP range for google.com
    "35.192.0.0/14",    # IP range for google.com
    "35.196.0.0/15",    # IP range for google.com
    "35.198.0.0/16",    # IP range for google.com
    "35.199.0.0/17",    # IP range for google.com
    "35.199.128.0/18",  # IP range for google.com
    "35.200.0.0/13",    # IP range for google.com
    "35.208.0.0/12",    # IP range for google.com
    "35.224.0.0/12",    # IP range for google.com
    "35.240.0.0/13",    # IP range for google.com
    "57.140.192.0/18",  # IP range for google.com
    "64.15.112.0/20",   # IP range for google.com
    "64.233.160.0/19",  # IP range for google.com
    "66.22.228.0/23",   # IP range for google.com
    "66.102.0.0/20",    # IP range for google.com
    "66.249.64.0/19",   # IP range for google.com
    "70.32.128.0/19",   # IP range for google.com
    "72.14.192.0/18",   # IP range for google.com
    "74.125.0.0/16",    # IP range for google.com
    "104.154.0.0/15",   # IP range for google.com
    "104.196.0.0/14",   # IP range for google.com
    "104.237.160.0/19", # IP range for google.com
    "107.167.160.0/19", # IP range for google.com
    "107.178.192.0/18", # IP range for google.com
    "108.59.80.0/20",   # IP range for google.com
    "108.170.192.0/18", # IP range for google.com
    "108.177.0.0/17",   # IP range for google.com
    "130.211.0.0/16",   # IP range for google.com
    "136.22.160.0/20",  # IP range for google.com
    "136.22.176.0/21",  # IP range for google.com
    "136.22.184.0/23",  # IP range for google.com
    "136.22.186.0/24",  # IP range for google.com
    "142.250.0.0/15",   # IP range for google.com
    "146.148.0.0/17",   # IP range for google.com
    "152.65.208.0/22",  # IP range for google.com
    "152.65.214.0/23",  # IP range for google.com
    "152.65.218.0/23",  # IP range for google.com
    "152.65.222.0/23",  # IP range for google.com
    "152.65.224.0/19",  # IP range for google.com
    "162.120.128.0/17", # IP range for google.com
    "162.216.148.0/22", # IP range for google.com
    "162.222.176.0/21", # IP range for google.com
    "172.110.32.0/21",  # IP range for google.com
    "172.217.0.0/16",   # IP range for google.com
    "172.253.0.0/16",   # IP range for google.com
    "173.194.0.0/16",   # IP range for google.com
    "173.255.112.0/20", # IP range for google.com
    "192.158.28.0/22",  # IP range for google.com
    "192.178.0.0/15",   # IP range for google.com
    "193.186.4.0/24",   # IP range for google.com
    "142.250.31.132/32",# specific IP for googleusercontent.com, google-analytics.com and googletagmanager.com
    "199.36.153.8/30",  # IP range for googleapis.com, pkg.dev, gcr.io and related services
    "199.36.154.0/23",  # IP range for google.com
    "199.36.156.0/24",  # IP range for google.com
    "199.192.112.0/22", # IP range for google.com
    "199.223.232.0/21", # IP range for google.com
    "207.223.160.0/20", # IP range for google.com
    "208.65.152.0/22",  # IP range for google.com
    "208.68.108.0/22",  # IP range for google.com
    "208.81.188.0/22",  # IP range for google.com
    "208.117.224.0/19", # IP range for google.com
    "209.85.128.0/17",  # IP range for google.com
    "216.58.192.0/19",  # IP range for google.com
    "216.73.80.0/20",   # IP range for google.com
    "216.239.32.0/19",  # IP range for google.com
    "198.185.159.144/32", # specific IP for bearrobotics.ai
    "198.185.159.145/32", # specific IP for bearrobotics.ai
    "198.49.23.144/32",   # specific IP for bearrobotics.ai
    "198.49.23.145/32"    # specific IP for bearrobotics.ai
  ]
}
