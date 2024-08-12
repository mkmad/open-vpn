variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region"
}

variable "service_account_email" {
  description = "The service account email"
}

variable "bucket_name" {
  description = "The bucket name used to store ovpn files"
}

variable "ovpn_files" {
  description = "Map of OpenVPN configuration files to be stored"
  type = map(string)
}

resource "google_storage_bucket" "openvpn_bucket" {
  name     = "${var.bucket_name}-${var.project_id}"
  location = var.region
}

resource "google_storage_bucket_iam_member" "bucket_writer" {
  bucket = google_storage_bucket.openvpn_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_storage_bucket_object" "ovpn_files" {
  for_each = var.ovpn_files

  name   = each.key
  bucket = google_storage_bucket.openvpn_bucket.name
  source = each.value
}

output "bucket_name" {
  value = google_storage_bucket.openvpn_bucket.name
}
