variable "project_id" {
  description = "The GCP project ID"
}

variable "bucket_name" {
  description = "The bucket name used to store ovpn files"
}

resource "google_service_account" "openvpn_service_account" {
  account_id   = "openvpn-sa"
  display_name = "OpenVPN Service Account"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.openvpn_service_account.email}"
}

output "email" {
  value = google_service_account.openvpn_service_account.email
}
