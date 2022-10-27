FROM i386/alpine:3.15

LABEL maintainer="snowdream <sn0wdr1am@icloud.com>"

ENV FRP_VERSION 0.45.0

RUN cd /root \
    &&  wget --no-check-certificate -c https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_386.tar.gz \
    &&  tar zxvf frp_${FRP_VERSION}_linux_386.tar.gz  \
    &&  cd frp_${FRP_VERSION}_linux_386/ \
    &&  cp frps /usr/bin/ \
    &&  mkdir -p /etc/frp \
    &&  cp frps.ini /etc/frp \
    &&  cd /root \
    &&  rm frp_${FRP_VERSION}_linux_386.tar.gz \
    &&  rm -rf frp_${FRP_VERSION}_linux_386/ 

ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini