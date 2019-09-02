# Terraform module to deploy Nomad cluster (clients and servers) on GCP with|without Frontend for UI

## Prerequisites

- git
- terraform ( > 0.12 )
- GCP subscription
- Claudflare subscription
- own domain managed by Claudflare
- an ssh key
- pre-built nomad server, client and frontend images on GCP or bake your own using [Packer](https://www.packer.io)
- subnet that has one of below:
  - "private_ip_google_access" enabled
  - Cloud NAT

## How to use

### Clone the repo

#### Create `terraform.tfvars` file

```

gcp_credentials_file_path = "/path/to/gcloud/credentials.json"
gcp_project_id            = "project_name"
gcp-vpc-network           = "gcp_vpc_network_name"
gcp-subnet-name           = "gcp_vpc_sunnet_name"
secure_gossip             = "1/+0vQt75rYWJadtpEdEtg=="
cloudflare_email          = "me@example.com"
cloudflare_token          = "cloudflare_token"
cloudflare_zone           = "example.net"
subdomain_name            = "nomad-ui"
```

#### Create `variables.tf` file

```
variable "gcp_credentials_file_path" {}
variable "gcp_project_id" {}
variable "gcp_vpc_network" {}
variable "gcp_subnet_name" {}
variable "secure_gossip" {}
variable "cloudflare_email" {}
variable "cloudflare_token" {}
variable "cloudflare_zone" {}
variable "subdomain_name" {}
```

#### Inputs

| Name  |	Description |	Type |  Default |	Required
| ----- | ----------- | ---- |  ------- | --------
| gcp_credentials_file_path | Locate the GCP credentials .json file. | string  | - | yes
| gcp_project_id | GCP Project ID. | string  | - | yes
| gcp_region | GCP region | string  | us-east4 | yes
| gcp-vpc-network | VPC network CIDR block | string  | - | yes
| gcp_subnet_cidr | VPC subnet CIDR block | string  | - | yes
| gcp_instance_type_server | Server instance Machine Type | string  | `n1-standard-1` | no
| gcp_instance_type_client | Client instance Machine Type | string   | `n1-standard-1` | no
| gcp_disk_image_server | Boot disk for `gcp_instance_type_server` | string  | yes | no
| gcp_disk_image_client | Boot disk for `gcp_instance_type_client` | string  | yes | no
| ssh_user | The name of ssh user | string  | `ubuntu` | no
| nomad_server_count | Count of Nomad server instances | number  | `3` | no
| nomad_client_count  | Count of Nomad client instances | number | `1` | no
| dc | The name of Nomad DC | string | `dc1` | no
| nomad_region | The name of Nomad region | string  | `global` | no
| authoritative_region | The name of Nomad authoritative region  | string  | `global` | no
| secure_gossip | 16 bytes encryption key used by Nomad to enable gossip encryption  | string  | `null` | yes
| tcp_ports_nomad | The list of tcp  ports to be allowed | list(string) | `"4646", "4647", "4648"` | no
| udp_ports_nomad | The list of udp  ports to be allowed | list(string) | `"4648"` | no
| ssh_enabled | Set to false to prevent ssh access any of the resources | bool | `true` | no
| ui_enabled | Set to false to prevent the frontend from creating thus accessing Nomad UI | bool | `true` | no
| gcp_instance_type_frontend |  Frontend instance Machine Type | string  | `n1-standard-1` | no
| gcp_disk_image_frontend | Boot disk for `gcp_instance_type_frontend` | string  | yes | no
| cloudflare_email | email of cloudflare user  | string  | `null` | yes
| cloudflare_token | cloudflare token  | string  | `null` | yes
| cloudflare_zone | The name of DNS domain  | string  | `null` | yes
| subdomain_name | The name of subdomain  | string  | `null` | yes


#### Create `main.tf` file

```
module "nomad_cluster_on_gcp" {
  source = "git@github.com:achuchulev/terraform-gcp-nomad.git"
  
  gcp_credentials_file_path = var.gcp_credentials_file_path
  gcp_project_id            = var.gcp_project_id
  gcp-vpc-network           = var.gcp_vpc_network
  gcp-subnet-name           = var.gcp_subnet_name
  secure_gossip             = var.secure_gossip
  cloudflare_email          = var.cloudflare_email
  cloudflare_token          = var.cloudflare_token
  cloudflare_zone           = var.cloudflare_zone
  subdomain_name            = var.subdomain_name
}

```

#### Create `outputs.tf` file

```
output "server_private_ips" {
  value = module.nomad_cluster_on_gcp.server_private_ips
}

output "client_private_ips" {
  value = module.nomad_cluster_on_gcp.client_private_ips
}

output "frontend_public_ip" {
  value = module.nomad_cluster_on_gcp.frontend_public_ip
}
```

### Initialize terraform and plan/apply

```
terraform init
terraform plan
terraform apply
```

- `Terraform apply` will:
  - deploy nomad servers and client(s)
  - secure Nomad traffic with mutual TLS
  - deploy and configure frontnend server for UI using nginx as reverse proxy if enabled
  
  
#### Outputs

| Name  |	Description 
| ----- | ----------- 
| server_private_ips | Private IPs of Nomad servers
| client_private_ips  | Private IPs of Nomad clients
| frontend_public_ip  | Public IP of Frontend

