resource "google_service_account" "openvpn_service_account" {
  account_id   = "openvpn-sa"
  display_name = "OpenVPN Service Account"
}

output "email" {
  value = google_service_account.openvpn_service_account.email
}
