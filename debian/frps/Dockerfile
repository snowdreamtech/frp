FROM --platform=$BUILDPLATFORM snowdreamtech/golang:1.23.5-bookworm AS builder

ARG TARGETOS
ARG TARGETARCH

# Switch to the user
USER root

# Set the workdir
WORKDIR /root

ENV FRP_VERSION=0.62.0

RUN set -eux \
    && apt-get -qqy update  \
    && apt-get -qqy install --no-install-recommends \ 
    make \
    && wget -c https://github.com/fatedier/frp/archive/refs/tags/v${FRP_VERSION}.tar.gz \
    && tar zxvf v${FRP_VERSION}.tar.gz \
    && cd frp-${FRP_VERSION} \
    && sed -i 's/CGO_ENABLED=0/CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH}/' Makefile \
    && make \
    && cp -rfv bin conf /root/ \
    && apt-get -qqy --purge autoremove \
    && apt-get -qqy clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*


FROM snowdreamtech/debian:12.10.0

# OCI annotations to image
LABEL org.opencontainers.image.authors="Snowdream Tech" \
    org.opencontainers.image.title="Frps Image Based On Debian" \
    org.opencontainers.image.description="Docker Images for Frps On Debian. (i386,amd64,arm32v5,arm32v7,arm64,mips64le,ppc64le,s390x)" \
    org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/frps" \
    org.opencontainers.image.base.name="snowdreamtech/frps:debian" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/snowdreamtech/frp" \
    org.opencontainers.image.vendor="Snowdream Tech" \
    org.opencontainers.image.version="0.62.0" \
    org.opencontainers.image.url="https://github.com/snowdreamtech/frp"

COPY --from=builder /root/bin/frps /usr/bin/
COPY --from=builder /root/conf/frps.toml /etc/frp/

ENTRYPOINT ["/usr/bin/frps"]

CMD ["-c", "/etc/frp/frps.toml"]