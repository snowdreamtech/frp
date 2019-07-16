FROM arm32v6/alpine:3.10

ENV FRP_VERSION 0.24.1
ENV QEMU_USER_STATIC_VERSION 4.0.0-5

VOLUME [ “/sys/fs/cgroup” ]

RUN apk add --no-cache openrc \
    && cd /root \
    &&  wget -c https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_arm.tar.gz \


ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini