FROM snowdreamtech/alpine:3.20.0

LABEL maintainer="snowdream <sn0wdr1am@qq.com>"

RUN apk add --no-cache frp@community=0.59.0-r0\
    && rm -rfv /usr/bin/frpc /etc/frp/frpc.toml

ENTRYPOINT ["/usr/bin/frps"]

CMD ["-c", "/etc/frp/frps.toml"]