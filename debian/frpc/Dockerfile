FROM snowdreamtech/go:1.23.1-bookworm AS builder

ENV FRP_VERSION=0.61.0

RUN mkdir /workspace

WORKDIR /workspace

RUN set -eux \
    && apt-get -qqy update  \
    && apt-get -qqy install --no-install-recommends \ 
    make \
    && wget -c https://github.com/fatedier/frp/archive/refs/tags/v${FRP_VERSION}.tar.gz \
    && tar zxvf v${FRP_VERSION}.tar.gz \
    && cd frp-${FRP_VERSION} \
    && make \
    && cp -rfv bin conf /workspace/ \
    && apt-get -qqy --purge autoremove \
    && apt-get -qqy clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*


FROM snowdreamtech/debian:12.7.0

# OCI annotations to image
LABEL org.opencontainers.image.authors="Snowdream Tech" \
    org.opencontainers.image.title="Frpc Image Based On Debian" \
    org.opencontainers.image.description="Docker Images for Frpc On Debian. (i386,amd64,arm32v5,arm32v7,arm64,mips64le,ppc64le,s390x)" \
    org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/frpc" \
    org.opencontainers.image.base.name="snowdreamtech/frpc:debian" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/snowdreamtech/frp" \
    org.opencontainers.image.vendor="Snowdream Tech" \
    org.opencontainers.image.version="0.61.0" \
    org.opencontainers.image.url="https://github.com/snowdreamtech/frp"

COPY --from=builder /workspace/bin/frpc /usr/bin/
COPY --from=builder /workspace/conf/frpc.toml /etc/frp/

ENTRYPOINT ["/usr/bin/frpc"]

CMD ["-c", "/etc/frp/frpc.toml"]