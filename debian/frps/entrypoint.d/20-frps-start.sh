#!/bin/sh
set -e

# start frps
if [ -n "$*" ]; then
    gosu "${PUID}:${PGID}" "$@"
else
    gosu "${PUID}:${PGID}" /usr/bin/frps -c /etc/frp/frps.toml
fi