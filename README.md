# Terraform module to deploy Nomad cluster (clients and servers) on GCP with|without Frontend for UI. Kitchen test is included

## Prerequisites

- git
- terraform ( >= 0.12 )
- GCP subscription
- Claudflare subscription
- own domain managed by Claudflare
- an ssh key
- pre-built nomad server, client and frontend images on GCP or bake your own using [Packer](https://www.packer.io)
- subnet that has one of below:
  - "private_ip_google_access" enabled
  - Cloud NAT
- selenium-server
- java jdk
- GeckoDriver

## How to use

### Clone the repo

#### Create `terraform.tfvars` file

```

gcp_credentials_file_path = "/path/to/gcloud/credentials.json"
gcp_project_id            = "project_name"
gcp_vpc_network           = "gcp_vpc_network_name"
gcp_subnet_name           = "gcp_vpc_sunnet_name"
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
| gcp_vpc_network | The name of VPC network | string  | - | yes
| gcp_subnet_name | The name of VPC subnet | string  | - | yes
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
  gcp_vpc_network           = var.gcp_vpc_network
  gcp_subnet_name           = var.gcp_subnet_name
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

output "frontend_public_ip" {
  value = module.nomad_cluster_on_gcp.ui_url
}
```

### Initialize terraform and plan/apply

```
$ terraform init
$ terraform plan
$ terraform apply
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

## How to test

### on Mac

#### Prerequisites

##### Install selenium and all its dependencies

```
$ brew install selenium-server-standalone
$ brew cask install java

### for firefox
$ brew install geckodriver 

### for chrome
$ brew cask install chromedriver 
```

##### Install rbenv to use ruby version 2.3.1

```
$ brew install rbenv
$ rbenv install 2.3.1
$ rbenv local 2.3.1
$ rbenv versions
```

##### Add the following lines to your ~/.bash_profile:

```
eval "$(rbenv init -)"
true
export PATH="$HOME/.rbenv/bin:$PATH"
```

##### Reload profile: 

`$ source ~/.bash_profile`

##### Install bundler

```
$ gem install bundler
$ bundle install
```

#### Run the test: 

```
$ bundle exec kitchen list
$ bundle exec kitchen converge
$ bundle exec kitchen verify
$ bundle exec kitchen destroy
```

### on Linux

#### Prerequisites

##### Install selenium and all its dependencies

```
$ gem install kitchen-terraform
$ gem install selenium-webdriver
$ apt-get install default-jdk

## Geckodriver
$ wget https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-linux64.tar.gz
$ sudo sh -c 'tar -x geckodriver -zf geckodriver-v0.23.0-linux64.tar.gz -O > /usr/bin/geckodriver'
$ sudo chmod +x /usr/bin/geckodriver
$ rm geckodriver-v0.23.0-linux64.tar.gz

## Chromedriver
$ wget https://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip
$ unzip chromedriver_linux64.zip
$ sudo chmod +x chromedriver
$ sudo mv chromedriver /usr/bin/
$ rm chromedriver_linux64.zip
```

#### Run kitchen test 

```
$ kitchen list
$ kitchen converge
$ kitchen verify
$ kitchen destroy
```

### Sample output

```
Target:  local://

  Command: `terraform output`
     ✔  stdout should include "client_private_ips"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  Command: `terraform output`
     ✔  stdout should include "server_private_ips"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  Command: `terraform output`
     ✔  stdout should include "frontend_public_ip"
     ✔  stderr should include ""
     ✔  exit_status should eq 0
  HTTP GET on https://nomad-ui.example.com/ui/jobs
     ✔  status should cmp == 200

Test Summary: 10 successful, 0 failures, 0 skipped
```
