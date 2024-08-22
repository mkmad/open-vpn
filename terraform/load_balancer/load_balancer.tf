variable "zone" {
  description = "The GCP zone"
}

variable "region" {
  description = "The GCP region"
}

variable "static_ip" {
  description = "The reserved static IP address"
}

variable "instance_self_link" {
  description = "The self-link of the compute instance"
}

variable "instance_tag" {
  description = "The network tag applied to the instance and firewall rule"
}

variable "backend_service_name" {
  description = "The name of the backend service"
}

# # Target pool for the NLB
# resource "google_compute_target_pool" "openvpn_target_pool" {
#   name        = "openvpn-target-pool"
#   region      = var.region
#   instances   = [var.instance_self_link]
# }


# # Network Load Balancer for OpenVPN traffic
# resource "google_compute_forwarding_rule" "openvpn_nlb_forwarding_rule_udp" {
#   name                  = "openvpn-nlb-forwarding-rule-udp"
#   region                = var.region  # Ensure the region matches with the IP address
#   load_balancing_scheme = "EXTERNAL" 
#   ip_protocol           = "UDP"
#   port_range            = "1194"
#   target                = google_compute_target_pool.openvpn_target_pool.self_link
#   ip_address            = var.static_ip  # Use the regional IP address
# }
