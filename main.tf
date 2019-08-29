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

  metadata_startup_script = templatefile("./templates/configuration.tmpl", { instance_role = var.instance_role, nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, gcp_project_id = var.gcp_project_id, secure_gossip = var.secure_gossip, domain_name = var.domain_name, zone_name = var.zone_name })

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
