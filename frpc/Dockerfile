FROM snowdreamtech/alpine:3.20.0

LABEL maintainer="snowdream <sn0wdr1am@qq.com>"

RUN apk add --no-cache frp \
    && rm -rfv /usr/bin/frps /etc/frp/frps.toml

ENTRYPOINT ["/usr/bin/frpc"]

CMD ["-c", "/etc/frp/frpc.toml"]