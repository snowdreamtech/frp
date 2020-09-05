# frp

[![frp](http://dockeri.co/image/snowdreamtech/frps)](https://hub.docker.com/r/snowdreamtech/frps)
[![frp](http://dockeri.co/image/snowdreamtech/frpc)](https://hub.docker.com/r/snowdreamtech/frpc)

Docker Image packaging for Frp.

(amd64, arm32v6, arm32v7, arm64v8, i386)

### [中文文档](https://www.itcoder.tech/posts/docker-frp/)

## Usage

start frps

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.ini:/etc/frp/frps.ini --name frps snowdreamtech/frps
```

start frpc

```bash
docker run --restart=always --network host -d -v /etc/frp/frpc.ini:/etc/frp/frpc.ini --name frpc snowdreamtech/frpc
```

## Quick reference

* Where to file issues:

[https://github.com/snowdreamtech/frp/issues](https://github.com/snowdreamtech/frp/issues)

* Maintained by:

snowdream <sn0wdr1am@icloud.com>

* Supported architectures: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))

frpc:

[amd64](https://cloud.docker.com/u/snowdreamtechamd64/repository/docker/snowdreamtechamd64/frpc), [arm32v6](https://cloud.docker.com/u/snowdreamtecharm32v6/repository/docker/snowdreamtecharm32v6/frpc), [arm32v7](https://cloud.docker.com/u/snowdreamtecharm32v7/repository/docker/snowdreamtecharm32v7/frpc), [arm64v8](https://cloud.docker.com/u/snowdreamtecharm64v8/repository/docker/snowdreamtecharm64v8/frpc), [i386](https://cloud.docker.com/u/snowdreamtechi386/repository/docker/snowdreamtechi386/frpc)

frps:

[amd64](https://cloud.docker.com/u/snowdreamtechamd64/repository/docker/snowdreamtechamd64/frps), [arm32v6](https://cloud.docker.com/u/snowdreamtecharm32v6/repository/docker/snowdreamtecharm32v6/frps), [arm32v7](https://cloud.docker.com/u/snowdreamtecharm32v7/repository/docker/snowdreamtecharm32v7/frps), [arm64v8](https://cloud.docker.com/u/snowdreamtecharm64v8/repository/docker/snowdreamtecharm64v8/frps), [i386](https://cloud.docker.com/u/snowdreamtechi386/repository/docker/snowdreamtechi386/frps)

* Supported Tags:

[Frps](https://cloud.docker.com/u/snowdreamtech/repository/docker/snowdreamtech/frps/tags)

[Frpc](https://cloud.docker.com/u/snowdreamtech/repository/docker/snowdreamtech/frpc/tags)

## Sponsors

[![tencent cloud](https://upload-dianshi-1255598498.file.myqcloud.com/%E5%8D%81%E5%B9%B4%E6%B7%B1%E8%89%B2_345%20200-9da3bd26b593519373f731a7e00a7e0d10e5fb04.jpg)](https://cloud.tencent.com/act/cps/redirect?redirect=1067&cps_key=7ad172f808f30965a01c05887137e4d8&from=console)

[![aliyun](https://img.alicdn.com/tfs/TB1EYNWOEH1gK0jSZSyXXXtlpXa-440-240.png)](https://www.aliyun.com/daily-act/ecs/activity_selection?userCode=dbgo15cy)

## Contact (备注：frp)

* Email: 3217680847#qq.com
* QQ: 3217680847
* QQ群: 82695646
* WeChat: sn0wdr1am86

## Website

1. [fatedier/frp](https://github.com/fatedier/frp)
1. [Snowdream Tech](http://www.snowdream.tech/)
1. [ITCoder](https://www.itcoder.tech/)

## License

Apache 2.0
