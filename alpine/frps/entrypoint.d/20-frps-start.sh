#!/bin/sh
set -e

# start frps
if [ -n "$*" ]; then
    su-exec "${PUID}:${PGID}" "$@"
else
    su-exec "${PUID}:${PGID}" /usr/bin/frps -c /etc/frp/frps.toml
fi