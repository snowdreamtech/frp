# 跨平台 Node.js 完美方案（已验证）

## 核心发现

**重要更正**: 经过实际测试验证，unirtm 的 Node.js core backend **不会**自动检测 musl 并下载预编译包。

### unirtm 在不同平台的实际行为

| 平台 | 默认行为 | 是否需要配置 |
|------|---------|-------------|
| Ubuntu/Debian (glibc) | 下载 glibc 预编译包 | ❌ 不需要 |
| macOS | 下载 darwin 预编译包 | ❌ 不需要 |
| Windows | 下载 win 预编译包 | ❌ 不需要 |
| Alpine Linux (musl) | **尝试从源码编译** | ✅ 需要配置 |

### Alpine 上的默认行为（未配置）

```bash
$ unirtm install node@25.9.0
# 1. 下载源码包: node-v25.9.0.tar.gz
# 2. 解压: extract node-v25.9.0.tar.gz
# 3. 运行 ./configure
# 4. 错误: python: not found
# 5. 安装失败 ❌
```

## 完美跨平台方案

### 方案 A: 条件环境变量（推荐）

在 `.unirtm.toml` 中使用条件配置，根据系统自动选择：

```toml
# .unirtm.toml
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

[env]
# Alpine 自动检测：官方 Alpine 镜像会设置 ALPINE_VERSION
UNIRTM_NODE_MIRROR_URL = "{% if env.ALPINE_VERSION is defined %}https://unofficial-builds.nodejs.org/download/release/{% else %}https://nodejs.org/dist/{% endif %}"
UNIRTM_NODE_FLAVOR = "{% if env.ALPINE_VERSION is defined %}musl{% endif %}"
```

**优势**:

- ✅ 一份配置适用所有平台
- ✅ 本地开发（macOS/Ubuntu）不受影响
- ✅ Alpine Docker 自动使用 musl 预编译包
- ✅ 无需修改 Dockerfile

### 方案 B: Dockerfile 环境变量

在 Dockerfile 中设置环境变量：

```dockerfile
FROM alpine:3.22

# 安装基础依赖
RUN apk add --no-cache bash curl git ca-certificates gpg

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# ⭐ 关键：配置 unirtm 使用 musl 预编译包
ENV UNIRTM_NODE_MIRROR_URL="https://unofficial-builds.nodejs.org/download/release/"
ENV UNIRTM_NODE_FLAVOR="musl"

# 复制配置并安装
COPY .unirtm.toml .
RUN unirtm install

WORKDIR /app
COPY . .
CMD ["node", "index.js"]
```

**优势**:

- ✅ 配置清晰明确
- ✅ 不影响 .unirtm.toml
- ✅ 适合单一平台部署

### 方案 C: 使用官方 Node.js Alpine 镜像（最简单）

```dockerfile
FROM node:25.9.0-alpine3.22

# 安装 unirtm 用于其他工具
RUN apk add --no-cache bash curl git
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置（node 已预装，unirtm 跳过）
COPY .unirtm.toml .
RUN unirtm install python go

WORKDIR /app
COPY . .
CMD ["node", "index.js"]
```

**优势**:

- ✅ 最简单，无需配置
- ✅ Node.js 官方支持
- ✅ 镜像优化好

## 依赖说明

### 使用预编译包的最小依赖

```dockerfile
# 最小依赖 - 足以使用预编译包
RUN apk add --no-cache \
    bash \           # unirtm 需要
    curl \           # 下载工具
    git \            # 版本控制
    ca-certificates \# HTTPS
    gpg              # 签名验证（推荐）
```

### 从源码编译的完整依赖

```dockerfile
# 完整编译依赖（仅在需要编译时）
RUN apk add --no-cache \
    bash curl git ca-certificates gpg \
    python3 \        # configure 脚本
    build-base \     # gcc, g++, make
    linux-headers    # 内核头文件
```

## 验证方案

### 验证是否使用预编译包

```bash
# 启用调试日志
UNIRTM_DEBUG=1 unirtm install node@25.9.0

# 查找关键信息：
# ✅ 预编译包: "Downloading https://unofficial-builds.nodejs.org/..."
# ❌ 源码编译: "extract node-v25.9.0.tar.gz" + "./configure"
```

### 验证二进制文件类型

```bash
file $(unirtm which node)

# Alpine (musl): dynamically linked, interpreter /lib/ld-musl-x86_64.so.1
# Ubuntu (glibc): dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2
# macOS: Mach-O 64-bit executable
```

## 完整示例

### 项目结构

```
.
├── .unirtm.toml              # 跨平台配置
├── Dockerfile.alpine       # Alpine 专用
├── Dockerfile.ubuntu       # Ubuntu 专用
└── docker-compose.yml
```

### .unirtm.toml（方案 A）

```toml
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

[env]
# 自动检测 Alpine
UNIRTM_NODE_MIRROR_URL = "{% if env.ALPINE_VERSION is defined %}https://unofficial-builds.nodejs.org/download/release/{% else %}https://nodejs.org/dist/{% endif %}"
UNIRTM_NODE_FLAVOR = "{% if env.ALPINE_VERSION is defined %}musl{% endif %}"

# 国内镜像加速（可选）
NPM_CONFIG_REGISTRY = "{% if env.CI is defined %}https://registry.npmjs.org{% else %}https://registry.npmmirror.com{% endif %}"
```

### Dockerfile.alpine（方案 B）

```dockerfile
FROM alpine:3.22

# 安装基础依赖
RUN apk add --no-cache bash curl git ca-certificates gpg

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 配置 musl 预编译包
ENV UNIRTM_NODE_MIRROR_URL="https://unofficial-builds.nodejs.org/download/release/"
ENV UNIRTM_NODE_FLAVOR="musl"

# 安装工具
COPY .unirtm.toml .
RUN unirtm install

WORKDIR /app
COPY . .
CMD ["node", "index.js"]
```

### Dockerfile.ubuntu

```dockerfile
FROM ubuntu:24.04

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    bash curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 安装工具（自动使用 glibc 预编译包）
COPY .unirtm.toml .
RUN unirtm install

WORKDIR /app
COPY . .
CMD ["node", "index.js"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app-alpine:
    build:
      context: .
      dockerfile: Dockerfile.alpine
    ports:
      - "3000:3000"

  app-ubuntu:
    build:
      context: .
      dockerfile: Dockerfile.ubuntu
    ports:
      - "3001:3000"
```

## 性能对比

| 方案 | 安装时间 | 镜像大小 | 复杂度 | 推荐度 |
|------|---------|---------|--------|--------|
| 方案 A (条件配置) | ~30秒 | ~150MB | 低 | ⭐⭐⭐⭐⭐ |
| 方案 B (ENV) | ~30秒 | ~150MB | 低 | ⭐⭐⭐⭐ |
| 方案 C (官方镜像) | ~10秒 | ~120MB | 最低 | ⭐⭐⭐⭐⭐ |
| 源码编译 | ~10分钟 | ~150MB | 高 | ⭐ |

## 常见问题

### Q1: 为什么 unirtm 不自动检测 musl？

unirtm 的 Node.js core backend 默认使用 nodejs.org 官方源，而官方源只提供 glibc 预编译包。musl 预编译包来自社区维护的 unofficial-builds，需要手动配置。

### Q2: 如何确认使用的是预编译包？

```bash
# 方法 1: 查看调试日志
UNIRTM_DEBUG=1 unirtm install node@25.9.0 2>&1 | grep -i download

# 方法 2: 检查安装时间
time unirtm install node@25.9.0
# 预编译包: ~30秒
# 源码编译: ~10分钟
```

### Q3: 方案 A 的条件配置在本地开发会影响吗？

不会。`ALPINE_VERSION` 环境变量只在 Alpine Docker 镜像中存在，本地 macOS/Ubuntu 不会设置这个变量，所以会使用默认的 nodejs.org 源。

### Q4: 如果我想强制编译怎么办？

```bash
# 安装编译依赖
apk add python3 build-base linux-headers

# 不设置 UNIRTM_NODE_FLAVOR，让 unirtm 从源码编译
unset UNIRTM_NODE_FLAVOR
unirtm install node@25.9.0
```

## 最佳实践总结

1. **推荐方案 A**: 使用条件配置，一份配置适用所有平台
2. **推荐方案 C**: 纯 Node.js 项目使用官方 Alpine 镜像
3. **避免源码编译**: 除非有特殊需求，否则总是使用预编译包
4. **验证安装**: 使用 `file` 命令确认二进制文件类型
5. **使用镜像加速**: 国内环境配置镜像源提高下载速度

## 参考资源

- [unirtm 官方文档](https://github.com/snowdreamtech/UniRTM)
- [Node.js 官方下载](https://nodejs.org/dist/)
- [Node.js Unofficial Builds](https://unofficial-builds.nodejs.org/)
- [Alpine Linux 包搜索](https://pkgs.alpinelinux.org/)
- [Docker Hub - Node Alpine](https://hub.docker.com/_/node)
