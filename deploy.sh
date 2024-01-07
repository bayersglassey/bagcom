#!/bin/bash
set -euo pipefail

# Set up $IP
. ./ip.sh

echo "### Updating website files..." >&2
rsync -v -a --delete -e ssh ./dst/ bagcom@$IP:/srv/bagcom/www/

echo "### Updating nginx..." >&2
scp nginx.conf root@$IP:/etc/nginx/nginx.conf
ssh root@$IP 'systemctl restart nginx'
