#!/bin/sh
set -e

# start frpc
if [ -n "$*" ]; then
    su-exec "${PUID}:${PGID}" "$@"
else
    su-exec "${PUID}:${PGID}" /usr/bin/frpc -c /etc/frp/frpc.toml
fi