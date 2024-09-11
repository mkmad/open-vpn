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
  description = "The instance name used to create the VM instance"
}

variable "instance_port" {
  description = "The port used by the instance"
}

variable "bucket_name" {
  description = "The bucket name used to store ovpn files"
}

variable "ovpn_files" {
  description = "Map of OpenVPN configuration files to be downloaded"
  type        = map(string)
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
    # No external IP assigned, forcing NAT for outbound traffic

    access_config {
      nat_ip = var.static_ip
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = [var.instance_tag]

  metadata_startup_script = <<-EOF
    #!/bin/bash

    # Install persistent iptables if not present
    if ! dpkg -l | grep -qw iptables-persistent; then
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
    fi
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    # Set up NAT using iptables
    EXTERNAL_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
    iptables -t nat -A POSTROUTING -o $EXTERNAL_INTERFACE -j MASQUERADE
    iptables-save > /etc/iptables/rules.v4

    # Download OpenVPN configuration files from the bucket and set up OpenVPN
    mkdir -p /home/$(whoami)/open-vpn
    for file in ${join(" ", keys(var.ovpn_files))}; do
      gsutil cp gs://${var.bucket_name}/$file /home/$(whoami)/open-vpn/
    done

    cd /home/$(whoami)/open-vpn
    sudo chmod +x setup_openvpn.sh
    sudo ./setup_openvpn.sh --clients 3 --server_ip ${var.static_ip} --server_port ${var.instance_port} --bucket_name ${var.bucket_name}
    
    # Restart OpenVPN to apply the configuration
    sudo systemctl stop openvpn-server@server.service
    sudo systemctl start openvpn-server@server.service
  EOF
}

output "instance_self_link" {
  value = google_compute_instance.openvpn_instance.self_link
}
