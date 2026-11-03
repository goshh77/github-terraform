#!/bin/bash
# Bootstraps the private app VM with a Postgres client so it can talk to Cloud SQL.
set -euo pipefail

if [ ! -f /var/lib/startup-done ]; then
  apt-get update -y
  apt-get install -y postgresql-client jq
  touch /var/lib/startup-done
fi
