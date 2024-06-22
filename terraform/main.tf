module "network" {
  source = "./network"
}

module "firewall" {
  source       = "./firewall"
  network_name = module.network.network_name
}

module "service_account" {
  source = "./service_account"
}

module "storage" {
  source = "./storage"
  project_id = var.project_id
  service_account_email = module.service_account.email
}

module "instance" {
  source                = "./instances"
  network_name          = module.network.network_name
  static_ip             = module.network.static_ip
  service_account_email = module.service_account.email
}
