#!/bin/sh
set -euo pipefail

# Set up $IP
. ./ip.sh

rsync -v -a --delete -e ssh ./dst/ bagcom@$IP:/srv/bagcom/www/
