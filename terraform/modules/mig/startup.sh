#!/bin/bash
# Installs nginx and serves a page showing which instance answered.
set -euo pipefail

if ! command -v nginx >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y nginx
fi

MD="http://metadata.google.internal/computeMetadata/v1/instance"
NAME=$(curl -s -H "Metadata-Flavor: Google" "$MD/name")
ZONE=$(curl -s -H "Metadata-Flavor: Google" "$MD/zone" | awk -F/ '{print $NF}')
IP=$(curl -s -H "Metadata-Flavor: Google" "$MD/network-interfaces/0/ip")

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head><title>github-terraform</title></head>
  <body style="font-family: sans-serif; margin: 3rem;">
    <h1>Deployed with Terraform + GitHub Actions</h1>
    <p>Served by <b>${NAME}</b> in <b>${ZONE}</b> (${IP})</p>
  </body>
</html>
EOF

echo "ok" > /var/www/html/healthz

systemctl enable nginx
systemctl restart nginx
