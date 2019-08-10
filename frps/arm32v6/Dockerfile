FROM arm32v6/alpine:3.10

MAINTAINER snowdream <sn0wdr1am@icloud.com>

ENV FRP_VERSION 0.28.2

VOLUME [ "/sys/fs/cgroup" ]

COPY qemu-arm-static /usr/bin

RUN apk add --no-cache openrc \
    && cd /root \
    &&  wget -c https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_arm.tar.gz \
    &&  tar zxvf frp_${FRP_VERSION}_linux_arm.tar.gz  \
    &&  cd frp_${FRP_VERSION}_linux_arm/ \
    &&  cp frps /usr/bin/ \
    &&  mkdir -p /etc/frp \
    &&  cp frps.ini /etc/frp \
    &&  cd /root \
    &&  rm frp_${FRP_VERSION}_linux_arm.tar.gz \
    &&  rm -rf frp_${FRP_VERSION}_linux_arm/ 

ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini