# frp

[![frp](http://dockeri.co/image/snowdreamtech/frps)](https://hub.docker.com/r/snowdreamtech/frps)
[![frp](http://dockeri.co/image/snowdreamtech/frpc)](https://hub.docker.com/r/snowdreamtech/frpc)

Docker Image packaging for Frp.

(amd64, arm32v6, arm32v7, arm64v8)

### [中文文档](https://www.itcoder.tech/posts/docker-frp/)

## Usage

start frps

```bash
docker run --restart=always --network host -d -v /etc/frp/frps.toml:/etc/frp/frps.toml --name frps snowdreamtech/frps
```

start frpc

```bash
docker run --restart=always --network host -d -v /etc/frp/frpc.toml:/etc/frp/frpc.toml --name frpc snowdreamtech/frpc
```

## Quick reference

* Where to file issues:

[https://github.com/snowdreamtech/frp/issues](https://github.com/snowdreamtech/frp/issues)

* Maintained by:

snowdream <sn0wdr1am@qq.com>

* Supported architectures: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))

frpc:

[amd64](https://cloud.docker.com/u/snowdreamtechamd64/repository/docker/snowdreamtechamd64/frpc), [arm32v6](https://cloud.docker.com/u/snowdreamtecharm32v6/repository/docker/snowdreamtecharm32v6/frpc), [arm32v7](https://cloud.docker.com/u/snowdreamtecharm32v7/repository/docker/snowdreamtecharm32v7/frpc), [arm64v8](https://cloud.docker.com/u/snowdreamtecharm64v8/repository/docker/snowdreamtecharm64v8/frpc)

frps:

[amd64](https://cloud.docker.com/u/snowdreamtechamd64/repository/docker/snowdreamtechamd64/frps), [arm32v6](https://cloud.docker.com/u/snowdreamtecharm32v6/repository/docker/snowdreamtecharm32v6/frps), [arm32v7](https://cloud.docker.com/u/snowdreamtecharm32v7/repository/docker/snowdreamtecharm32v7/frps), [arm64v8](https://cloud.docker.com/u/snowdreamtecharm64v8/repository/docker/snowdreamtecharm64v8/frps)

* Supported Tags:

[Frps](https://cloud.docker.com/u/snowdreamtech/repository/docker/snowdreamtech/frps/tags)

[Frpc](https://cloud.docker.com/u/snowdreamtech/repository/docker/snowdreamtech/frpc/tags)

<!-- ## Sponsors

[![tencentcloud](https://snowdreamtech.oss-cn-beijing.aliyuncs.com/tengxunyun/%E9%A6%96%E5%8D%95%E9%99%90%E6%97%B6%E7%A7%92%E6%9D%80%E4%BF%AE%E6%94%B9/%E9%A6%96%E5%8D%95%E9%99%90%E6%97%B6_470-250.jpg)](https://cloud.tencent.com/act/cps/redirect?redirect=1077&cps_key=d09c5e921f9fcf4ac9516564262f3b99&from=console)

[![aliyun](https://snowdreamtech.oss-cn-beijing.aliyuncs.com/aliyun/%E6%96%B0%E4%BA%BA-%E4%B8%BB/440-240%201.jpg)](https://www.aliyun.com/1111/new?userCode=dbgo15cy) -->

## Contact (备注：frp)

* Email: sn0wdr1am@qq.com
* QQ: 3217680847
* QQ群: 949022145
* WeChat/微信群: sn0wdr1am

## Website

1. [fatedier/frp](https://github.com/fatedier/frp)
1. [Snowdream Tech](http://www.snowdream.tech/)
1. [ITCoder](https://www.itcoder.tech/)

## License

MIT
