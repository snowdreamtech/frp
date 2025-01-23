FROM snowdreamtech/go:1.23.4-alpine3.21 AS builder

# Switch to the user
USER root

# Set the workdir
WORKDIR /root

ENV FRP_VERSION=0.61.1

RUN apk add --no-cache make \
    && wget -c https://github.com/fatedier/frp/archive/refs/tags/v${FRP_VERSION}.tar.gz \
    && tar zxvf v${FRP_VERSION}.tar.gz \
    && cd frp-${FRP_VERSION} \
    && make \
    && cp -rfv bin conf /root/


FROM snowdreamtech/alpine:3.21.0

# OCI annotations to image
LABEL org.opencontainers.image.authors="Snowdream Tech" \
    org.opencontainers.image.title="Frpc Image Based On Alpine" \
    org.opencontainers.image.description="Docker Images for Frpc on Alpine. (i386, amd64, arm32v6, arm32v7, arm64, ppc64le,riscv64, s390x)" \
    org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/frpc" \
    org.opencontainers.image.base.name="snowdreamtech/frpc:alpine" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/snowdreamtech/frp" \
    org.opencontainers.image.vendor="Snowdream Tech" \
    org.opencontainers.image.version="0.61.1" \
    org.opencontainers.image.url="https://github.com/snowdreamtech/frp"

COPY --from=builder /root/bin/frpc /usr/bin/
COPY --from=builder /root/conf/frpc.toml /etc/frp/

ENTRYPOINT ["/usr/bin/frpc"]

CMD ["-c", "/etc/frp/frpc.toml"]