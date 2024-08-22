provider "google" {
  project = var.project_id
  region  = var.region
}

provider "tls" {
  # No specific configuration needed, but this ensures the provider is initialized
}