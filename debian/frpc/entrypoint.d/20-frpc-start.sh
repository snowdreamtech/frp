#!/bin/sh
set -e

# start frpc
if [ -n "$*" ]; then
    gosu "${PUID}:${PGID}" "$@"
else
    gosu "${PUID}:${PGID}" /usr/bin/frpc -c /etc/frp/frpc.toml
fi