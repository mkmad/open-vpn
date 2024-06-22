variable "network_name" {
  description = "The name of the VPC network"
}

variable "static_ip" {
  description = "The static IP address"
}

variable "service_account_email" {
  description = "The service account email"
}

variable "zone" {
  description = "The GCP zone"
  default     = "us-central1-a"
}

resource "google_compute_instance" "openvpn_instance" {
  name         = "openvpn-instance"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20220406"
    }
  }

  network_interface {
    network = var.network_name

    access_config {
      nat_ip = var.static_ip
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #cloud-config
    runcmd:
      - |
        if [ ! -f /var/log/first-boot.log ]; then
          sudo apt update
          sudo apt install -y git
          git clone https://github.com/mkmad/open-vpn.git /home/${USER}/open-vpn
          cd /home/${USER}/open-vpn
          chmod +x setup_openvpn.sh
          ./setup_openvpn.sh --clients 3 --server_ip ${var.static_ip} --server_port 1194
          touch /var/log/first-boot.log
        fi
  EOF
}
