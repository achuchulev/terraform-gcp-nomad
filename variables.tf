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

variable "gcp-vpc-network" {}

variable "gcp-subnet1-name" {}

variable "gcp_instance_type" {
  description = "Machine Type. Correlates to an network egress cap."
  default     = "n1-standard-1"
}

variable "gcp_disk_image" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nomad-server-v093"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "nomad_instance_count" {
  default = "3"
}

variable "instance_role" {
  description = "Nomad instance type"
  default     = "server"
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

variable "zone_name" {
  description = "The name of DNS domain"
  default     = "ntry.site"
}

variable "domain_name" {
  description = "The name of subdomain"
  default     = "mynomad"
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
