#!/bin/sh
set -e

if [ "$DEBUG" = "true" ]; then echo "→ Starting frps..."; fi

if [ "$(id -u)" = "0" ]; then
    gosu "${PUID:-0}:${PGID:-0}" /usr/bin/frps -c /etc/frp/frps.toml &
else
    /usr/bin/frps -c /etc/frp/frps.toml &
fi

if [ "$DEBUG" = "true" ]; then echo "→ frps started in background."; fi
