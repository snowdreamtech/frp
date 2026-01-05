# frp

![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/frps)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/frps/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/frps)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/frps)


![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/frpc)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/frpc/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/frpc)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/frpc)

Docker Images for Frp Based on Alpine and Debian.

 (amd64, arm32v5, arm32v6, arm32v7, arm64v8, i386, mips64le, ppc64le,riscv64, s390x)
 
### [Documentation](https://gofrp.org/en/)
### [中文文档](https://gofrp.org/zh-cn/docs/)

## Usage

### Basic

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.toml:/etc/frp/frps.toml --name frps snowdreamtech/frps
docker run --restart=always --network host -d -v /etc/frp/frpc.toml:/etc/frp/frpc.toml --name frpc snowdreamtech/frpc
```

### Alpine

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.toml:/etc/frp/frps.toml --name frps snowdreamtech/frps:alpine
docker run --restart=always --network host -d -v /etc/frp/frpc.toml:/etc/frp/frpc.toml --name frpc snowdreamtech/frpc:alpine
```

### Debian

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.toml:/etc/frp/frps.toml --name frps snowdreamtech/frps:debian
docker run --restart=always --network host -d -v /etc/frp/frpc.toml:/etc/frp/frpc.toml --name frpc snowdreamtech/frpc:debian
```

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.toml:/etc/frp/frps.toml --name frps snowdreamtech/frps:trixie
docker run --restart=always --network host -d -v /etc/frp/frpc.toml:/etc/frp/frpc.toml --name frpc snowdreamtech/frpc:trixie
```

## Quick reference

* Where to file issues:

[https://github.com/snowdreamtech/frp/issues](https://github.com/snowdreamtech/frp/issues)

* Where to join discussions:

[https://github.com/snowdreamtech/frp/discussions](https://github.com/snowdreamtech/frp/discussions)

* Maintained by:

snowdream <sn0wdr1am@qq.com>

* Supported architectures: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))

Alpine (linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x)

Debian (linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64,linux/mips64le,linux/ppc64le,linux/s390x)

* Supported Tags:

Alpine:

    - latest
    - 0.62-alpine3.22
    - 0.66.0-alpine3.22
    - 0.62-alpine
    - 0.66.0-alpine
    - alpine3.22
    - alpine
    - 0.62
    - 0.66.0

Debian:

    - trixie
    - debian
    - 0.62-trixie
    - 0.66.0-trixie
    - 0.62-debian
    - 0.66.0-debian

## Ads

1. [腾讯云](https://cloud.tencent.com/act/cps/redirect?redirect=2446&cps_key=d09c5e921f9fcf4ac9516564262f3b99&from=console)
1. [阿里云](https://www.aliyun.com/minisite/goods?userCode=dbgo15cy)
1. [华为云](https://activity.huaweicloud.com/cps.html?fromacct=7766b6ea-375c-416d-9ca5-bdbef333b645&utm_source=V1g3MDY4NTY=&utm_medium=cps&utm_campaign=201905)
1. [Bandwagonhost/搬瓦工](https://bandwagonhost.com/aff.php?aff=41583)
1. [Vultr](https://www.vultr.com/?ref=7265819)

## Contact (备注：frp)

* Email: sn0wdr1am@qq.com
* QQ: 3217680847
* QQ群: 949022145
* WeChat/微信群: sn0wdr1am

## Website

1. [fatedier/frp](https://github.com/fatedier/frp)
1. [snowdreamtech/frp](https://github.com/snowdreamtech/frp)
1. [frpc images on Github](https://github.com/snowdreamtech/frp/pkgs/container/frpc) 
1. [frps images on Github](https://github.com/snowdreamtech/frp/pkgs/container/frps)
1. [frpc images on Docker Hub ](https://hub.docker.com/r/snowdreamtech/frpc) 
1. [frps images on Docker Hub ](https://hub.docker.com/r/snowdreamtech/frps)

## License

MIT

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=snowdreamtech/frp&type=Date)](https://star-history.com/#snowdreamtech/frp&Date)
