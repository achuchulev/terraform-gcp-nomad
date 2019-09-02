#!/usr/bin/env bash

cat <<EOF >/etc/nomad.d/nomad.hcl

data_dir  = "/opt/nomad"

region = "$1"

datacenter = "$2"

bind_addr = "0.0.0.0"

client {
  enabled = true
  server_join {
    retry_join = ["provider=gce project_name=$4 tag_value=server"]
    retry_max = 5
    retry_interval = "15s"
  }
  options = {
    "driver.raw_exec" = "1"
    "driver.raw_exec.enable" = "1"
  }
}

# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "/root/nomad/ssl/nomad-ca.pem"
  cert_file = "/root/nomad/ssl/client.pem"
  key_file  = "/root/nomad/ssl/client-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}
EOF
