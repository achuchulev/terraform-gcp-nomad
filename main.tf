// Generates Random Name for Instances
resource "random_pet" "random_name" {
  length    = "4"
  separator = "-"
}

// Provides access to available Google Compute zones in a region for a given project
data "google_compute_zones" "available" {
  region = var.gcp_region
}

// Creates Nomad instances
resource "google_compute_instance" "nomad_instance" {
  count        = var.nomad_instance_count
  name         = "${random_pet.random_name.id}-${var.instance_role}-0${count.index + 1}"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image
    }
  }

  network_interface {
    subnetwork = var.gcp-subnet1-name
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  allow_stopping_for_update = true

  tags = [var.instance_role]

  metadata_startup_script = <<EOF
# create dir for nomad configuration
mkdir -p /etc/nomad.d
chmod 700 /etc/nomad.d

# download and run nomad configuration script
curl -o /tmp/nomad-${var.instance_role}-config.sh https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/scripts/nomad-${var.instance_role}-config.sh
chmod +x /tmp/nomad-${var.instance_role}-config.sh
/tmp/nomad-${var.instance_role}-config.sh ${var.nomad_region} ${var.dc} ${var.authoritative_region} ${var.gcp_project_id} ${var.secure_gossip}
rm -rf /tmp/*

# create dir for certificates and copy cfssl.json configuration file to increase the default certificate expiration time for nomad
mkdir -p ~/nomad/ssl
curl -o ~/nomad/ssl/cfssl.json https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/config/cfssl.json

# download CA certificates
curl -o ~/nomad/ssl/nomad-ca-key.pem https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/ca_certs/nomad-ca-key.pem
curl -o ~/nomad/ssl/nomad-ca.csr https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/ca_certs/nomad-ca.csr
curl -o ~/nomad/ssl/nomad-ca.pem https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/ca_certs/nomad-ca.pem

# generate nomad node certificates
echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -config=nomad/ssl/cfssl.json -hostname='${var.instance_role}.${var.nomad_region}.nomad,localhost,127.0.0.1' - | cfssljson -bare nomad/ssl/${var.instance_role}

# copy nomad.service
curl -o /etc/systemd/system/nomad.service https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad_instance/master/config/nomad.service
echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare nomad/ssl/cli

# enable and start nomad service
systemctl enable nomad.service
systemctl start nomad.service

# enable Nomad's CLI command autocomplete support. Skip if installed
grep "complete -C /usr/bin/nomad nomad" ~/.bashrc &>/dev/null || nomad -autocomplete-install

# export the URL of the Nomad agent
echo 'export NOMAD_ADDR=https://${var.domain_name}.${var.zone_name}' >> ~/.profile
EOF

}

# Allow SSH
resource "google_compute_firewall" "gcp-allow-nomad-traffic" {
  count   = var.instance_role == "server" ? 1 : 0
  name    = "${var.gcp-vpc-network}-gcp-allow-nomad-traffic"
  network = var.gcp-vpc-network

  allow {
    protocol = "tcp"
    ports    = var.tcp_ports_nomad
  }

  allow {
    protocol = "udp"
    ports    = var.udp_ports_nomad
  }

  source_ranges = [
    "0.0.0.0/0",
  ]

  source_tags = ["server", "client"]
}
