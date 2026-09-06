#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(hostnamectl --static hostname)"
CONF="$DIR/$HOST.conf"

if [[ ! -f "$CONF" ]]; then
  echo "no keyd config for host '$HOST'" >&2
  exit 1
fi

sudo install -D -m 644 -o root -g root "$CONF" /etc/keyd/default.conf
sudo systemctl restart keyd
echo "installed $HOST.conf"
