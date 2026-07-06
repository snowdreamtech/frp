# Frp

![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/frps)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/frps/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/frps)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/frps)

![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/frpc)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/frpc/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/frpc)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/frpc)

Docker 基础模板，提供标准化的容器基础，具有灵活的入口点系统、多架构支持以及跨 Alpine、Debian 和 Rocky Linux 发行版的一致配置模式。

## [Documentation](https://gofrp.org/en/)

## [中文文档](https://gofrp.org/zh-cn/docs/)

## 概述

Docker 基础模板作为构建容器化应用程序的基础起点。它提供：

- **标准化的 Dockerfile**，包含 OCI 注释和最佳实践
- **灵活的入口点系统**，支持自定义初始化脚本
- **一致的环境变量配置**，适用于所有变体
- **多架构支持**，适用于多样化的硬件平台
- **用户/组管理**，支持 PUID/PGID 进行权限处理
- **三种发行版变体**：Alpine（轻量级）、Debian（默认/广泛兼容）、Rocky（企业级）

## 快速开始

```bash
# 拉取并运行默认的 Debian 变体
docker pull snowdreamtech/frpc:debian
docker run -d --name=frpc -e TZ=Asia/Shanghai snowdreamtech/frpc:debian

# 或使用 docker-compose
docker-compose up -d
```

## 发行版变体

### Debian（默认）

推荐用于大多数用例的变体，提供广泛的兼容性和丰富的软件包可用性。

```bash
docker run -d \
  --name=frpc \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/frpc:debian
```

**支持的架构**：i386、amd64、arm32v5、arm32v7、arm64、ppc64le、riscv64、s390x

**基础镜像**：`snowdreamtech/debian:13.5.0`

### Alpine

轻量级变体，针对最小镜像大小和快速启动时间进行了优化。

```bash
docker run -d \
  --name=frpc \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/frpc:alpine
```

**支持的架构**：i386、amd64、arm32v6、arm32v7、arm64、ppc64le、riscv64、s390x

**基础镜像**：`snowdreamtech/alpine:3.24.0`

### Rocky

基于 Rocky Linux 的企业级变体，适用于需要 RHEL 兼容性的生产环境。

```bash
docker run -d \
  --name=frpc \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/frpc:rocky
```

**支持的架构**：amd64、arm64、ppc64le、s390x

**基础镜像**：`snowdreamtech/rocky:10.2.0`

## 构建说明

### 单架构构建

```bash
# 构建 Debian 变体
docker build -t snowdreamtech/frpc:debian ./docker/debian/

# 构建 Alpine 变体
docker build -t snowdreamtech/frpc:alpine ./docker/alpine/

# 构建 Rocky 变体
docker build -t snowdreamtech/frpc:rocky ./docker/rocky/
```

### 多架构构建

使用 `docker buildx` 为多个架构构建镜像：

```bash
# 创建并使用 buildx 构建器
docker buildx create --use --name build --node build --driver-opt network=host

# 为多个架构构建 Debian
docker buildx build \
  --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x \
  -t snowdreamtech/frpc:debian \
  ./docker/debian/ \
  --push

# 为多个架构构建 Alpine
docker buildx build \
  --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x \
  -t snowdreamtech/frpc:alpine \
  ./docker/alpine/ \
  --push

# 为多个架构构建 Rocky
docker buildx build \
  --platform=linux/amd64,linux/arm64,linux/ppc64le,linux/s390x \
  -t snowdreamtech/frpc:rocky \
  ./docker/rocky/ \
  --push
```

## 环境变量

所有变体都支持以下环境变量进行运行时配置：

| 变量 | 默认值 | 描述 |
|----------|---------|-------------|
| `KEEPALIVE` | `0` | 保持容器运行（1=启用，0=禁用）|
| `CAP_NET_BIND_SERVICE` | `0` | 启用绑定到特权端口（<1024）|
| `LANG` | `C.UTF-8` | UTF-8 字符支持的区域设置 |
| `UMASK` | `022` | 默认文件创建掩码 |
| `DEBUG` | `false` | 在入口点脚本中启用调试输出 |
| `PGID` | `0` | 自定义用户创建的主组 ID |
| `PUID` | `0` | 自定义用户创建的用户 ID |
| `USER` | `root` | 自定义用户创建的用户名 |
| `WORKDIR` | `/root` | 工作目录路径 |
| `TZ` | - | 时区（例如 `Asia/Shanghai`、`America/New_York`）|

**Debian 特定**：

| 变量 | 默认值 | 描述 |
|----------|---------|-------------|
| `DEBIAN_FRONTEND` | `noninteractive` | Debian 软件包安装模式 |

### 自定义用户创建

在构建时创建具有特定 UID/GID 的非 root 用户：

```bash
docker build \
  --build-arg PUID=1000 \
  --build-arg PGID=1000 \
  --build-arg USER=appuser \
  -t snowdreamtech/frpc:debian-custom \
  ./docker/debian/
```

或在运行时（需要重新构建镜像）：

```bash
docker run -d \
  --name=frpc \
  -e PUID=1000 \
  -e PGID=1000 \
  -e USER=appuser \
  snowdreamtech/frpc:debian
```

**注意**：仅当 `PUID≠0`、`PGID≠0` 且 `USER≠root` 时才会创建用户。

## Docker Compose 示例

### 简单配置

```yaml
services:
  frp:
    image: snowdreamtech/frpc:debian
    container_name: frpc
    environment:
      - TZ=Asia/Shanghai
    restart: unless-stopped
```

### 高级配置

```yaml
services:
  frp:
    image: snowdreamtech/frpc:debian
    container_name: frpc
    environment:
      - TZ=Asia/Shanghai
      - DEBUG=true
      - KEEPALIVE=1
    volumes:
      - /path/to/data:/data
    restart: unless-stopped
```

## 语义化版本标签

镜像遵循语义化版本控制，格式为：`{major}.{minor}.{patch}-{variant}`

示例：

- `snowdreamtech/frpc:0.69.1-debian`
- `snowdreamtech/frpc:0.69.1-alpine`
- `snowdreamtech/frpc:0.69.1-rocky`

此格式允许：

- **完整版本固定**：`0.69.1-debian`（精确版本）
- **变体最新标签**：`latest-debian`（跟踪 Debian 最新版本）
- **全局最新标签**：`latest`（跟踪最新版本，默认指向 Debian）

## 架构支持

每个发行版变体都支持多个 CPU 架构，可在多样化的硬件平台上部署：

| 变体 | 架构 |
|---------|---------------|
| **Debian** | i386、amd64、arm32v5、arm32v7、arm64、ppc64le、riscv64、s390x |
| **Alpine** | i386、amd64、arm32v6、arm32v7、arm64、ppc64le、riscv64、s390x |
| **Rocky** | amd64、arm64、ppc64le、s390x |

Docker 在拉取镜像时会自动为您的平台选择适当的架构。

## 入口点系统

基础模板包含一个灵活的入口点系统，在启动应用程序之前执行自定义初始化脚本。

### 工作原理

1. `docker-entrypoint.sh` 脚本在容器启动时运行
2. 它按字典顺序执行 `/usr/local/bin/entrypoint.d/` 中的所有可执行脚本
3. 每个脚本都接收容器的命令行参数
4. 如果任何脚本失败，容器将停止（快速失败行为）

### 添加自定义初始化

在派生的 Dockerfile 中创建自定义初始化脚本：

```dockerfile
FROM snowdreamtech/frpc:debian

# 添加您的自定义初始化脚本
COPY my-init.sh /usr/local/bin/entrypoint.d/20-my-init.sh
RUN chmod +x /usr/local/bin/entrypoint.d/20-my-init.sh

# 您的应用程序设置
COPY app /app
CMD ["/app/start.sh"]
```

### 调试模式

启用调试输出以排查入口点执行问题：

```bash
docker run -e DEBUG=true snowdreamtech/frpc:debian
```

输出示例：

```
→ [ENTRYPOINT] Executing all scripts in /usr/local/bin/entrypoint.d
→ Running /usr/local/bin/entrypoint.d/10-frp-init.sh
→ [ENTRYPOINT] Done.
```

## 开发

### 前置要求

- Docker（>= 20.10）
- Docker Buildx 插件

### 本地构建

```bash
# 构建所有变体
make build

# 构建特定变体
docker build -t frpc:debian ./docker/debian/
docker build -t frpc:alpine ./docker/alpine/
docker build -t frpc:rocky ./docker/rocky/
```

### 测试

```bash
# 测试默认配置
docker run --rm frpc:debian id

# 测试自定义用户创建
docker build --build-arg PUID=1000 --build-arg PGID=1000 --build-arg USER=testuser -t frpc:debian-test ./docker/debian/
docker run --rm frpc:debian-test id
# 预期输出：uid=1000(testuser) gid=1000(testuser)

# 测试 DEBUG 模式
docker run --rm -e DEBUG=true frpc:debian
```

## 参考资料

1. [使用 buildx 构建多平台 Docker 镜像](https://icloudnative.io/posts/multiarch-docker-with-buildx/)
2. [如何使用 docker buildx 构建跨平台 Go 镜像](https://waynerv.com/posts/building-multi-architecture-images-with-docker-buildx/#buildx-%E7%9A%84%E8%B7%A8%E5%B9%B3%E5%8F%B0%E6%9E%84%E5%BB%BA%E7%AD%96%E7%95%A5)
3. [Building Multi-Arch Images for Arm and x86 with Docker Desktop](https://www.docker.com/blog/multi-arch-images/)
4. [How to Rapidly Build Multi-Architecture Images with Buildx](https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/)
5. [Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
6. [docker/buildx](https://github.com/docker/buildx)

## 联系方式（备注：frp）

* Email: <sn0wdr1am@qq.com>
* QQ: 3217680847
* QQ群: 949022145
* WeChat/微信群: sn0wdr1am

## 许可证

MIT
