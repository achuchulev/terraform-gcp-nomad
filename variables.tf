variable "gcp_credentials_file_path" {
  description = "Locate the GCP credentials .json file"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "gcp_region" {
  description = "Default to N.Virginia region"
  default     = "us-east4"
}

variable "gcp_vpc_network" {}

variable "gcp_subnet_name" {}

variable "gcp_instance_type_server" {
  description = "Machine Type"
  default     = "n1-standard-1"
}

variable "gcp_instance_type_client" {
  description = "Machine Type"
  default     = "n1-standard-1"
}

variable "gcp_disk_image_server" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nomad-server-v093"
}

variable "gcp_disk_image_client" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nomad-client-v093"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "nomad_server_count" {
  default = "3"
}

variable "nomad_client_count" {
  default = "1"
}

variable "dc" {
  type    = string
  default = "dc1"
}

variable "nomad_region" {
  type    = string
  default = "global"
}

variable "authoritative_region" {
  type    = string
  default = "global"
}

variable "secure_gossip" {
  description = "Used by Nomad to enable gossip encryption"
  default     = "null"
}

variable "tcp_ports_nomad" {
  description = "Specifies the network ports used for different services required by the Nomad agent"
  type        = list(string)
  default     = ["4646", "4647", "4648"]
}

variable "udp_ports_nomad" {
  description = "Specifies the network ports used for different services required by the Nomad agent"
  type        = list(string)
  default     = ["4648"]
}

variable "ssh_enabled" {
  description = "Set to false to prevent ssh access any of the resources"
  default     = "true"
}

// Frontend VARs

variable "ui_enabled" {
  description = "Set to false to prevent the frontend from creating thus accessing Nomad UI"
  default     = "true"
}

variable "gcp_instance_type_frontend" {
  description = "Machine Type. Correlates to an network egress cap."
  default     = "n1-standard-1"
}

variable "gcp_disk_image_frontend" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nginx-v001"
}

variable "cloudflare_email" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "cloudflare_token" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "cloudflare_zone" {
  description = "Used by Nomad frontend"
  default     = "null"
}

variable "subdomain_name" {
  description = "Used by Nomad frontend"
  default     = "null"
}

