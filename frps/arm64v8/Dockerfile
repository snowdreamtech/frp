FROM arm64v8/alpine:3.10

ENV FRP_VERSION 0.27.0

VOLUME [ “/sys/fs/cgroup” ]

COPY qemu-aarch64-static /usr/bin

RUN apk add --no-cache openrc \
    && cd /root \
    &&  wget -c https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_arm64.tar.gz \
    &&  tar zxvf frp_${FRP_VERSION}_linux_arm64.tar.gz  \
    &&  cd frp_${FRP_VERSION}_linux_arm64/ \
    &&  cp frps /usr/bin/ \
    &&  mkdir -p /etc/frp \
    &&  cp frps.ini /etc/frp \
    &&  cd /root \
    &&  rm frp_${FRP_VERSION}_linux_arm64.tar.gz \
    &&  rm -rf frp_${FRP_VERSION}_linux_arm64/ 

ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini