terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"  # Optional: specify the version you want to use
    }
  }
}

locals {
  ovpn_files = {
    "setup_openvpn.sh" = "${path.root}/../setup_openvpn.sh",
    "server.conf"      = "${path.root}/../server.conf",
    "client.conf"      = "${path.root}/../client.conf",
    "vars"             = "${path.root}/../vars"
  }
}

module "network" {
  source = "./network"
  region = var.region
}

module "firewall" {
  source       = "./firewall"
  network_name = module.network.network_name
  instance_tag = var.instance_tag
}

module "service_account" {
  source      = "./service_account"
  bucket_name = var.bucket_name
  project_id  = var.project_id
}

module "storage" {
  source                = "./storage"
  project_id            = var.project_id
  region                = var.region
  service_account_email = module.service_account.email
  bucket_name           = var.bucket_name
  ovpn_files            = local.ovpn_files
}

module "instance" {
  source                = "./instances"
  network_name          = module.network.network_name
  zone                  = var.zone
  service_account_email = module.service_account.email
  instance_tag          = var.instance_tag
  instance_image_name   = var.instance_image_name
  instance_name         = var.instance_name
  instance_port         = var.instance_port
  bucket_name           = module.storage.bucket_name
  ovpn_files            = local.ovpn_files
  static_ip             = module.network.static_ip
}

# module "load_balancer" {
#   source               = "./load_balancer"
#   region                = var.region
#   zone                  = var.zone  
#   instance_self_link   = module.instance.instance_self_link  # Pass the self-link of the instance
#   static_ip            = module.network.static_ip
#   instance_tag         = var.instance_tag
#   backend_service_name = "openvpn-backend-service"
# }
