variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region"
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  default     = "us-central1-a"
}

variable "instance_tag" {
  description = "The network tag to apply to the instance and firewall rule"
  default     = "openvpn-instance"
}

variable "instance_image_name" {
  description = "The instance image used to create the VM instance"
  default     = "ubuntu-2004-focal-v20240614"
}

variable "instance_name" {
  description = "The instance image used to create the VM instance"
  default     = "openvpn-instance"
}

variable "instance_port" {
  description = "The instance port used to create the VM instance"
  default     = "1194"
}

variable "bucket_name" {
  description = "The bucket name used to store ovpn files"
  default     = "openvpn-bucket"
}

variable "ovpn_files" {
  description = "Map of OpenVPN configuration files to be stored and used"
  type = map(string)
  default = {}
}
