#!/usr/bin/env bash

# download nomad backend configuration script
curl -o /root/nginx-upstream-config.sh https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad/master/scripts/nginx-upstream-config.sh
chmod +x /root/nginx-upstream-config.sh

# download and run nginx configuration script
curl -o /root/nginx.sh https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad/master/scripts/nginx.sh
chmod +x /root/nginx.sh
/root/nginx.sh ${nomad_region}

# create dir for certificates and download CA certificates and cfssl.json configuration file to increase the default certificate expiration time for nomad
mkdir -p /root/nomad/ssl
curl -o /root/nomad/ssl/nomad-ca-key.pem https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad/master/ca_certs/nomad-ca-key.pem
curl -o /root/nomad/ssl/nomad-ca.pem https://raw.githubusercontent.com/achuchulev/terraform-gcp-nomad/master/ca_certs/nomad-ca.pem

# issue nomad node certificates
echo '{}' | cfssl gencert -ca=/root/nomad/ssl/nomad-ca.pem -ca-key=/root/nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare /root/nomad/ssl/cli

# Create cron job to check and renew public certificate on expiration
crontab <<EOF
0 12 * * * /usr/bin/certbot renew --quiet
EOF
