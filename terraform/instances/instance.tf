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
}

variable "instance_tag" {
  description = "The network tag to apply to the instance and firewall rule"
}

variable "instance_image_name" {
  description = "The instance image used to create the VM instance"
}

variable "instance_name" {
  description = "The instance image used to create the VM instance"
}

variable "instance_port" {
  description = "The instance image used to create the VM instance"
}

resource "google_compute_instance" "openvpn_instance" {
  name         = var.instance_name
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.instance_image_name
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

  tags = [var.instance_tag]

  metadata_startup_script = <<-EOF
    #cloud-config
    runcmd:
      - |
        if [ ! -f /var/log/first-boot.log ]; then
          sudo apt update
          sudo apt install -y git
          sudo git clone https://github.com/mkmad/open-vpn.git /home/$(whoami)/open-vpn
          cd /home/$(whoami)/open-vpn
          sudo chmod +x setup_openvpn.sh
          sudo ./setup_openvpn.sh --clients 3 --server_ip ${var.static_ip} --server_port ${var.instance_port}
          sudo touch /var/log/first-boot.log
        fi
        sudo systemctl stop openvpn-server@server.service
        sudo systemctl start openvpn-server@server.service        
  EOF
}
