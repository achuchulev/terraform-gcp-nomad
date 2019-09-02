output "server_private_ips" {
  value = google_compute_instance.nomad_server.*.network_interface.0.network_ip
}

output "client_private_ips" {
  value = google_compute_instance.nomad_client.*.network_interface.0.network_ip
}

output "frontend_public_ip" {
  value = google_compute_instance.frontend_server[*].network_interface[0].access_config[0].nat_ip
}
