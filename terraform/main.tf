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
  source = "./service_account"
}

module "storage" {
  source                = "./storage"
  project_id            = var.project_id
  region                = var.region
  service_account_email = module.service_account.email
}

module "instance" {
  source                = "./instances"
  network_name          = module.network.network_name
  zone                  = var.zone
  static_ip             = module.network.static_ip
  service_account_email = module.service_account.email
  instance_tag          = var.instance_tag
  instance_image_name   = var.instance_image_name
  instance_name         = var.instance_name
  instance_port         = var.instance_port
}
