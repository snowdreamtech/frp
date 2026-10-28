# Alpine Linux + unirtm 快速启动指南

## 问题诊断

如果你在 Alpine 上遇到 unirtm 安装失败，通常是因为缺少基础依赖。

### 常见错误信息

```bash
# 错误 1: Python 未找到
./configure: exec: line 8: python: not found
unirtm ERROR sh failed

# 错误 2: Bash 未找到
env: 'bash': No such file or directory

# 错误 3: GPG 未找到（警告）
unirtm WARN gpg not found, skipping verification
```

## 快速解决方案

### 步骤 1: 安装基础依赖

```bash
# 最小依赖（足以使用预编译包）
apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    gpg \
    python3
```

### 步骤 2: 安装 unirtm

```bash
curl https://unirtm.run | sh
export PATH="$HOME/.local/bin:$PATH"
```

### 步骤 3: 安装工具

```bash
# 安装 Node.js（会自动下载 musl 预编译包）
unirtm install node@25.9.0

# 安装 Python
unirtm install python@3.14.3

# 安装 Go
unirtm install go@1.26.2

# 激活工具
unirtm use node@25.9.0 python@3.14.3 go@1.26.2
```

## 完整 Dockerfile 示例

### 最小镜像（使用预编译包）

```dockerfile
FROM alpine:3.22

# 安装基础依赖
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    gpg \
    python3

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置并安装工具
COPY .unirtm.toml .
RUN unirtm install

WORKDIR /app
COPY . .

CMD ["node", "index.js"]
```

### 完整镜像（支持源码编译）

```dockerfile
FROM alpine:3.22

# 安装完整依赖（包括编译工具）
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    gpg \
    python3 \
    build-base \
    linux-headers \
    binutils-gold

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置并安装工具
COPY .unirtm.toml .
RUN unirtm install

WORKDIR /app
COPY . .

CMD ["node", "index.js"]
```

## 依赖说明

### 基础依赖（必需）

| 包 | 用途 | 是否必需 |
|---|------|---------|
| `bash` | unirtm 和构建脚本需要 | ✅ 必需 |
| `curl` | 下载 unirtm 和工具 | ✅ 必需 |
| `git` | 版本控制和某些工具安装 | ✅ 必需 |
| `ca-certificates` | HTTPS 下载 | ✅ 必需 |
| `gpg` | 验证下载签名 | ⚠️ 推荐 |
| `python3` | Node.js configure 脚本 | ✅ 必需 |

### 编译依赖（可选）

仅在需要从源码编译时需要：

| 包 | 用途 |
|---|------|
| `build-base` | gcc, g++, make 等编译工具 |
| `linux-headers` | Linux 内核头文件 |
| `binutils-gold` | 更快的链接器 |

## 验证安装

```bash
# 检查 unirtm 版本
unirtm --version

# 检查已安装的工具
unirtm list

# 检查 Node.js
node --version
npm --version

# 检查 Python
python --version

# 检查 Go
go version

# 验证二进制文件类型（确认是 musl）
file $(unirtm which node)
# 应该显示: dynamically linked, interpreter /lib/ld-musl-x86_64.so.1
```

## 性能优化

### 使用国内镜像加速

在 `.unirtm.toml` 中配置：

```toml
[env]
# Node.js 镜像
UNIRTM_NODE_MIRROR_URL = "https://npmmirror.com/mirrors/node/"
NPM_CONFIG_REGISTRY = "https://registry.npmmirror.com"

# Python 镜像
PIP_INDEX_URL = "https://mirrors.aliyun.com/pypi/simple"
PYTHON_BUILD_MIRROR_URL = "https://mirrors.aliyun.com/python/"

# Go 镜像
GOPROXY = "https://mirrors.aliyun.com/goproxy/,direct"
UNIRTM_GO_DOWNLOAD_MIRROR = "https://mirrors.aliyun.com/golang/"
UNIRTM_GO_SKIP_CHECKSUM = "1"
```

### 多阶段构建优化

```dockerfile
# ============================================
# 阶段 1: 构建阶段
# ============================================
FROM alpine:3.22 AS builder

# 安装完整依赖
RUN apk add --no-cache \
    bash curl git ca-certificates gpg python3 \
    build-base linux-headers binutils-gold

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 安装工具
COPY .unirtm.toml .
RUN unirtm install

# 构建应用
WORKDIR /app
COPY . .
RUN unirtm exec -- npm ci --production

# ============================================
# 阶段 2: 运行阶段（最小化）
# ============================================
FROM alpine:3.22

# 只安装运行时依赖
RUN apk add --no-cache libstdc++ libgcc

# 从构建阶段复制工具和应用
COPY --from=builder /root/.local/share/unirtm/installs /root/.local/share/unirtm/installs
COPY --from=builder /app /app

# 设置环境变量
ENV PATH="/root/.local/share/unirtm/installs/node/25.9.0/bin:$PATH"

WORKDIR /app
CMD ["node", "index.js"]
```

## 故障排除

### 问题 1: unirtm 安装卡住

```bash
# 检查网络连接
ping -c 3 unirtm.run

# 使用代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
curl https://unirtm.run | sh
```

### 问题 2: 工具安装失败

```bash
# 启用详细日志
UNIRTM_DEBUG=1 unirtm install node@25.9.0

# 清除缓存重试
rm -rf ~/.cache/unirtm
unirtm install node@25.9.0
```

### 问题 3: 预编译包不可用

```bash
# 检查可用版本
unirtm ls-remote node

# 如果没有 musl 预编译包，安装编译依赖
apk add build-base linux-headers binutils-gold

# 重新安装
unirtm install node@25.9.0
```

### 问题 4: ARM64 架构支持

```bash
# 检查架构
uname -m
# aarch64 或 x86_64

# ARM64 的 Node.js musl 预编译包可能不完整
# 建议使用官方 Node.js Alpine 镜像
docker pull node:25.9.0-alpine3.22
```

## 最佳实践

1. **始终安装基础依赖**: 即使使用预编译包也需要 bash 和 python3
2. **使用镜像加速**: 在国内环境配置镜像源
3. **多阶段构建**: 生产环境使用多阶段构建减小镜像体积
4. **固定版本**: 使用精确版本号而不是 `latest`
5. **验证安装**: 使用 `file` 命令确认二进制文件类型

## 参考资源

- [unirtm 官方文档](https://github.com/snowdreamtech/UniRTM)
- [Alpine Linux 包搜索](https://pkgs.alpinelinux.org/)
- [Node.js Unofficial Builds](https://unofficial-builds.nodejs.org/)
- [Docker Hub - Alpine](https://hub.docker.com/_/alpine)
- [Docker Hub - Node Alpine](https://hub.docker.com/_/node)
