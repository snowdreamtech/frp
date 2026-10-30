#!/bin/sh
set -e

if [ "$DEBUG" = "true" ]; then echo "→ Starting frpc..."; fi

if [ "$(id -u)" = "0" ]; then
  gosu "${PUID:-0}:${PGID:-0}" /usr/bin/frpc -c /etc/frp/frpc.toml &
else
  /usr/bin/frpc -c /etc/frp/frpc.toml &
fi

if [ "$DEBUG" = "true" ]; then echo "→ frpc started in background."; fi
