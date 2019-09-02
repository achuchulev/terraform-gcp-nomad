// Provides access to available Google Compute zones in a region for a given project
data "google_compute_zones" "available" {
  region = var.gcp_region
}

// Generates Random Name for Instances
resource "random_pet" "random_name" {
  length    = "4"
  separator = "-"
}

// Create Nomad server instances
resource "google_compute_instance" "nomad_server" {
  count        = var.nomad_server_count
  name         = "${random_pet.random_name.id}-server-0${count.index + 1}"
  machine_type = var.gcp_instance_type_server
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["server"]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image_server
    }
  }

  network_interface {
    subnetwork = var.gcp_subnet_name
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  metadata_startup_script = templatefile("${path.module}/templates/nomad-config.tmpl", { instance_role = "server", nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, gcp_project_id = var.gcp_project_id, secure_gossip = var.secure_gossip, domain_name = var.subdomain_name, zone_name = var.cloudflare_zone })
}

// Create Nomad client instances
resource "google_compute_instance" "nomad_client" {
  count        = var.nomad_client_count
  name         = "${random_pet.random_name.id}-client-0${count.index + 1}"
  machine_type = var.gcp_instance_type_client
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["client"]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image_client
    }
  }

  network_interface {
    subnetwork = var.gcp_subnet_name
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  metadata_startup_script = templatefile("${path.module}/templates/nomad-config.tmpl", { instance_role = "client", nomad_region = var.nomad_region, dc = var.dc, authoritative_region = var.authoritative_region, gcp_project_id = var.gcp_project_id, secure_gossip = var.secure_gossip, domain_name = var.subdomain_name, zone_name = var.cloudflare_zone })
}

// Allow SSH
resource "google_compute_firewall" "allow-nomad-traffic" {
  name        = "${random_pet.random_name.id}-allow-nomad-traffic"
  network     = var.gcp_vpc_network
  source_tags = ["server", "client"]

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
}
  
  // Allow SSH
resource "google_compute_firewall" "allow-ssh-traffic" {
  count       = var.ssh_enabled == "true" ? 1 : 0
  name        = "${random_pet.random_name.id}-allow-ssh-traffic"
  network     = var.gcp_vpc_network
  source_tags = ["server", "client"]

  allow {
    protocol = "tcp"
    ports    = "22"
  }

  source_ranges = [
    "0.0.0.0/0",
  ]
}

// Frontend config

// Set local vars
locals {
  # Nomad servers IP:port sockets
  nomad_servers_socket = join(" ", formatlist("%s %s:%s;", "server", google_compute_instance.nomad_server.*.network_interface.0.network_ip, "4646"))
}

// Create Frontend instance if UI is enabled
resource "google_compute_instance" "frontend_server" {
  count        = var.ui_enabled == "true" ? 1 : 0
  name         = "${var.gcp_region}-${var.dc}-${random_pet.random_name.id}-frontend"
  machine_type = var.gcp_instance_type_frontend
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["nomad-frontend"]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image_frontend
    }
  }

  network_interface {
    subnetwork = var.gcp_subnet_name

    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  metadata_startup_script = templatefile("${path.module}/templates/nginx-config.tmpl", { nomad_region = var.nomad_region })
}

// This makes the nginx configuration 
resource "null_resource" "nginx_config" {

  count = "${var.ui_enabled == "true" ? 1 : 0}"

  # changes to any server instance of the nomad cluster requires re-provisioning
  triggers = {
    nginx_upstream_nodes   = local.nomad_servers_socket
    cloudflare_record_ip   = cloudflare_record.nomad_frontend[count.index].value
    cloudflare_record_name = cloudflare_record.nomad_frontend[count.index].name
  }

  depends_on = [
    google_compute_instance.frontend_server,
    google_compute_instance.nomad_server
  ]

  # script can run on every nomad server instance change
  connection {
    type        = "ssh"
    host        = google_compute_instance.frontend_server[count.index].network_interface[0].access_config[0].nat_ip
    user        = var.ssh_user
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    # script called with private_ips of nomad backend servers
    inline = [
      "sudo /root/nginx-upstream-config.sh '${local.nomad_servers_socket}'",
      "sudo systemctl restart nginx.service",
    ]
  }
}

// Creates a DNS record with Cloudflare
resource "cloudflare_record" "nomad_frontend" {
  count  = var.ui_enabled == "true" ? 1 : 0
  domain = var.cloudflare_zone
  name   = var.subdomain_name
  value  = google_compute_instance.frontend_server[count.index].network_interface[0].access_config[0].nat_ip
  type   = "A"
  ttl    = 3600
}

// Generates a trusted certificate issued by Let's Encrypt
resource "null_resource" "certbot" {
  count = var.ui_enabled == "true" ? 1 : 0

  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cloudflare_record = cloudflare_record.nomad_frontend[count.index].value
  }

  depends_on = [
    cloudflare_record.nomad_frontend,
    null_resource.nginx_config,
  ]

  # certbot script can run on every instance ip change
  connection {
    type        = "ssh"
    host        = google_compute_instance.frontend_server[count.index].network_interface[0].access_config[0].nat_ip
    user        = var.ssh_user
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    # certbot script called with public_ip of frontend server
    inline = [
      "sudo certbot --nginx --non-interactive --agree-tos -m ${var.cloudflare_email} -d ${var.subdomain_name}.${var.cloudflare_zone} --redirect",
    ]
  }
}

resource "google_compute_firewall" "gcp-allow-http-https-traffic" {
  count       = var.ui_enabled == "true" ? 1 : 0
  name        = "${random_pet.random_name.id}-allow-http-https-traffic"
  network     = var.gcp_vpc_network
  source_tags = ["nomad-frontend"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    "0.0.0.0/0",
  ]
}
