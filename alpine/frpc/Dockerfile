FROM snowdreamtech/alpine:3.20.3

# OCI annotations to image
LABEL org.opencontainers.image.authors="Snowdream Tech" \
      org.opencontainers.image.title="Frpc Image Based On Alpine" \
      org.opencontainers.image.description="Docker Images for Frpc on Alpine. (i386, amd64, arm32v6, arm32v7, arm64, ppc64le,riscv64, s390x)" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/frpc" \
      org.opencontainers.image.base.name="snowdreamtech/frpc:alpine" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/snowdreamtech/frp" \
      org.opencontainers.image.vendor="Snowdream Tech" \
      org.opencontainers.image.version="0.60.0" \
      org.opencontainers.image.url="https://github.com/snowdreamtech/frp"

RUN apk add --no-cache frp@community=0.60.0-r1\
    && rm -rfv /usr/bin/frps /etc/frp/frps.toml

ENTRYPOINT ["/usr/bin/frpc"]

CMD ["-c", "/etc/frp/frpc.toml"]