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

```
git clone https://github.com/achuchulev/terraform-gcp-nomad.git
cd terraform-gcp-nomad
```

### Create `terraform.tfvars` file

#### Inputs

| Name  |	Description |	Type |  Default |	Required
| ----- | ----------- | ---- |  ------- | --------
| gcp_credentials_file_path | Locate the GCP credentials .json file. | string  | - | yes
| gcp_project_id | GCP Project ID. | string  | - | yes
| gcp_region | GCP region | string  | us-east4 | yes
| gcp-vpc-network | VPC network CIDR block | string  | - | yes
| gcp_subnet1_cidr | VPC subnet CIDR block | string  | - | yes
| gcp_instance_type_server | Server instance Machine Type | string  | `n1-standard-1` | no
| gcp_instance_type_client | Client instance Machine Type | string   | `n1-standard-1` | no
| gcp_disk_image_server | Boot disk for `gcp_instance_type_server` | string  | yes | no
| gcp_disk_image_client | Boot disk for `gcp_instance_type_client` | string  | yes | no
| ssh_user | The name of ssh user | string  | "ubuntu" | no
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

