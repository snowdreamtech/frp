# Alpine Linux Node.js 最佳解决方案

## 问题分析

### 方案一的问题 ❌

```toml
# .unirtm.toml
[settings]
node.flavor = "musl"  # ⚠️ 会影响所有系统！
```

**问题**:

- 在 Ubuntu/Debian (glibc) 上也会下载 musl 版本
- musl 二进制在 glibc 系统上可能有兼容性问题
- 性能可能更差（musl 在 glibc 系统上不是最优）

### 方案二的问题 ❌

```dockerfile
RUN apk add --no-cache nodejs npm
```

**问题**:

- Alpine 官方包版本滞后（通常不是最新版）
- 难以指定精确版本（如 25.9.0）
- 不同 Alpine 版本提供的 Node.js 版本不同

**Alpine 版本对应**:

- Alpine 3.19: Node.js 20.x
- Alpine 3.20: Node.js 22.x
- Alpine edge: Node.js 23.x (不稳定)

---

## 推荐方案：条件配置

### 方案 3: 使用环境变量（推荐）✅

在不同环境使用不同配置，而不是在 `.unirtm.toml` 中硬编码。

#### Dockerfile 配置（方案 3）

```dockerfile
FROM alpine:3.19

# 安装基础依赖
RUN apk add --no-cache bash curl git ca-certificates

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# ⭐ 关键：只在 Alpine 上配置 musl
ENV UNIRTM_NODE_MIRROR_URL="https://unofficial-builds.nodejs.org/download/release/"
ENV UNIRTM_NODE_FLAVOR="musl"

# 复制配置文件（不包含 node.flavor 设置）
COPY .unirtm.toml .

# 安装工具（会自动使用环境变量）
RUN unirtm install
```

#### .unirtm.toml 配置（方案 3）

```toml
# .unirtm.toml - 不包含 node.flavor 设置
[tools]
node = "25.9.0"  # 可以指定精确版本
python = "3.14.3"
go = "1.26.2"

# ⚠️ 不要在这里设置 node.flavor
# [settings]
# node.flavor = "musl"  # ❌ 会影响所有系统
```

#### 本地开发（macOS/Linux）

```bash
# 不设置任何环境变量，使用默认的 glibc 版本
unirtm install
```

---

## 方案 4: 多阶段构建 + 官方包（生产推荐）✅

结合两种方案的优点：开发用 unirtm，生产用官方包。

### Dockerfile（方案 4）

```dockerfile
# ============================================
# 阶段 1: 构建阶段（使用 unirtm 获取最新版本）
# ============================================
FROM alpine:3.19 AS builder

# 安装构建依赖
RUN apk add --no-cache bash curl git ca-certificates

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 配置 Node.js musl 构建
ENV UNIRTM_NODE_MIRROR_URL="https://unofficial-builds.nodejs.org/download/release/"
ENV UNIRTM_NODE_FLAVOR="musl"

# 复制配置并安装
COPY .unirtm.toml package*.json ./
RUN unirtm install

# 安装项目依赖
RUN unirtm exec -- npm ci --production

# ============================================
# 阶段 2: 运行阶段（最小化镜像）
# ============================================
FROM alpine:3.19

# 只安装运行时依赖
RUN apk add --no-cache libstdc++ libgcc

# 从构建阶段复制 Node.js 和应用
COPY --from=builder /root/.local/share/unirtm/installs/node /usr/local/
COPY --from=builder /app /app

WORKDIR /app
CMD ["node", "index.js"]
```

**优势**:

- ✅ 可以使用最新版本的 Node.js
- ✅ 最终镜像很小（只包含必要文件）
- ✅ 不影响本地开发环境

---

## 方案 5: 使用 .tool-versions 条件配置 ✅

unirtm 支持根据环境变量选择不同的配置文件。

### 项目结构（方案 5）

```
.
├── .unirtm.toml              # 默认配置（glibc）
├── .unirtm.alpine.toml       # Alpine 专用配置
└── Dockerfile
```

### .unirtm.toml（默认配置）

```toml
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

# 默认不设置 flavor（使用 glibc）
```

### .unirtm.alpine.toml（Alpine 专用）

```toml
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

[settings]
node.mirror_url = "https://unofficial-builds.nodejs.org/download/release/"
node.flavor = "musl"
```

### Dockerfile（方案 5）

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache bash curl git ca-certificates
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制 Alpine 专用配置
COPY .unirtm.alpine.toml .unirtm.toml

RUN unirtm install
```

### 本地开发

```bash
# 使用默认配置（glibc）
unirtm install
```

**优势**:

- ✅ 配置分离，互不影响
- ✅ 可以指定精确版本
- ✅ 本地和 Alpine 环境都能正常工作

---

## 方案 6: 使用 Docker 官方 Node.js Alpine 镜像（最简单）✅

如果主要需求是 Node.js，直接使用官方镜像。

```dockerfile
# 使用官方 Node.js Alpine 镜像（包含最新版本）
FROM node:25.9.0-alpine3.19

# 安装 unirtm 用于其他工具
RUN apk add --no-cache bash curl git
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置（注释掉 node）
COPY .unirtm.toml .

# 只安装其他工具（不安装 node）
RUN unirtm install
```

### .unirtm.toml（方案 6）

```toml
[tools]
# node = "25.9.0"  # ⚠️ 注释掉，使用 Docker 镜像自带的
python = "3.14.3"
go = "1.26.2"

# 其他开发工具
"github:astral-sh/ruff" = "0.15.9"
```

**优势**:

- ✅ 最简单，无需配置
- ✅ 官方支持，版本齐全
- ✅ 可以指定精确版本（通过镜像 tag）
- ✅ 镜像优化好，体积小

---

## 推荐选择

根据不同场景选择合适的方案：

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| **纯 Node.js 应用** | 方案 6 (官方镜像) | 最简单，官方支持 |
| **多语言项目** | 方案 3 (环境变量) | 灵活，不影响本地开发 |
| **生产优化** | 方案 4 (多阶段构建) | 镜像最小，安全性高 |
| **复杂配置** | 方案 5 (条件配置) | 配置清晰，易维护 |

---

## 完整示例：方案 3 + 方案 6 组合

### 项目结构（完整示例）

```
.
├── .unirtm.toml
├── Dockerfile.alpine       # Alpine 专用
├── Dockerfile.node-alpine  # 使用官方 Node 镜像
└── docker-compose.yml
```

### .unirtm.toml（完整示例）

```toml
# 本地开发配置（glibc）
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

# 开发工具
"github:astral-sh/ruff" = "0.15.9"
"github:gitleaks/gitleaks" = "8.30.1"
```

### Dockerfile.node-alpine（推荐）

```dockerfile
FROM node:25.9.0-alpine3.19

# 安装基础工具
RUN apk add --no-cache bash curl git ca-certificates

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置
COPY .unirtm.toml package*.json ./

# 安装其他工具（跳过 node）
RUN unirtm install python go

# 安装 npm 依赖
RUN npm ci

WORKDIR /app
COPY . .

CMD ["node", "index.js"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.node-alpine
    volumes:
      - .:/app
    ports:
      - "3000:3000"
```

---

## 性能对比

| 方案 | 镜像大小 | 构建时间 | Node.js 版本 | 复杂度 |
|------|---------|---------|-------------|--------|
| 方案 1 (musl) | ~150MB | 2-3分钟 | 最新 | 中 |
| 方案 2 (apk) | ~100MB | 30秒 | 滞后 | 低 |
| 方案 3 (环境变量) | ~150MB | 2-3分钟 | 最新 | 中 |
| 方案 4 (多阶段) | ~50MB | 3-5分钟 | 最新 | 高 |
| 方案 5 (条件配置) | ~150MB | 2-3分钟 | 最新 | 中 |
| 方案 6 (官方镜像) | ~120MB | 1分钟 | 最新 | 低 |

---

## 最终建议

### 对于你的项目

**推荐使用方案 6（官方 Node.js Alpine 镜像）+ 方案 3（环境变量）的组合**：

1. **Dockerfile 使用官方镜像**

   ```dockerfile
   FROM node:25.9.0-alpine3.19
   ```

2. **.unirtm.toml 保持简洁**

   ```toml
   # 本地开发用 glibc 版本
   node = "25.9.0"
   ```

3. **CI/CD 中使用环境变量**

   ```yaml
   # .github/workflows/ci.yml
   env:
     UNIRTM_NODE_FLAVOR: musl  # 仅在 Alpine 容器中设置
   ```

这样：

- ✅ 本地开发不受影响（使用 glibc）
- ✅ Alpine 容器使用官方镜像（简单可靠）
- ✅ 可以指定精确版本
- ✅ 配置清晰，易于维护

---

## 参考资源

- [Docker Hub - Node.js Official Images](https://hub.docker.com/_/node)
- [Node.js Unofficial Builds](https://unofficial-builds.nodejs.org/)
- [unirtm Environment Variables](https://github.com/snowdreamtech/UniRTMconfiguration.html#environment-variables)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)
