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

variable "objects" {
  type = list(object({
    name = string,
    content = string,
  }))
  description = "The ovpn files objects."
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

resource "google_storage_bucket_object" "openvpn_objects" {
  for_each = {for index, obj in var.objects : obj.name => obj }
  bucket = google_storage_bucket.openvpn_bucket.name
  name = each.value.name
  content = each.value.content
}

output "bucket_name" {
  value = google_storage_bucket.openvpn_bucket.name
}
