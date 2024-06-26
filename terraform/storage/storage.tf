variable "project_id" {
  description = "The GCP project ID"
}

variable "service_account_email" {
  description = "The service account email"
}

variable "region" {
  description = "The GCP region"
}

variable "bucket_name" {
  description = "The bucket name used to store ovpn files"
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

resource "google_storage_bucket_iam_member" "bucket_reader" {
  bucket = google_storage_bucket.openvpn_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email}"
}

output "bucket_name" {
  value = google_storage_bucket.openvpn_bucket.name
}
