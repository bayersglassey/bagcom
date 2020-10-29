#!/bin/sh
set -euo pipefail

# Set up $IP
. ./ip.sh

ssh bagcom@$IP 'cd /srv/bagcom && git pull'
