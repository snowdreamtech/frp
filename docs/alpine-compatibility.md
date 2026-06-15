# Alpine Linux (musl libc) 兼容性指南

## 概述

Alpine Linux 使用 musl libc 而不是 glibc，这会影响某些预编译二进制的兼容性。本文档说明如何在 Alpine 上正确配置核心运行时。

## 核心运行时兼容性

### 1. Go ✅ 完全兼容

**状态**: 开箱即用，无需特殊配置

**原因**: Go 官方二进制是静态链接的，不依赖 libc

```toml
# .unirtm.toml - 无需修改
go = "1.26.2"
```

**验证**:

```bash
ldd $(which go)
# 输出: not a dynamic executable (静态链接)
```

---

### 2. Python ✅ 支持 musl

**状态**: unirtm 自动检测并使用 musl 版本

**原因**: python-build-standalone 项目提供 musl 预编译包

```toml
# .unirtm.toml - 无需修改
python = "3.14.3"
```

**unirtm 自动选择**:

- glibc 系统: `x86_64-unknown-linux-gnu`
- musl 系统: `x86_64-unknown-linux-musl`

**验证**:

```bash
ldd $(unirtm where python)/bin/python3
# Alpine 上会显示 musl 依赖
```

---

### 3. Node.js ⚠️ 需要配置

**状态**: 需要使用非官方构建版本

**原因**: 官方 Node.js 二进制使用 glibc，不兼容 Alpine

#### 解决方案 1: 使用非官方 musl 构建（推荐）

```bash
# 配置 unirtm 使用非官方构建
unirtm settings set node.mirror_url=https://unofficial-builds.nodejs.org/download/release/
unirtm settings set node.flavor=musl
```

或在配置文件中设置：

```toml
# .unirtm.toml
[settings]
node.mirror_url = "https://unofficial-builds.nodejs.org/download/release/"
node.flavor = "musl"

[tools]
node = "25.9.0"
```

#### 解决方案 2: 使用 Alpine 官方包

```dockerfile
# Dockerfile
FROM alpine:3.19

# 使用 Alpine 官方 Node.js 包
RUN apk add --no-cache nodejs npm

# 然后使用 unirtm 管理其他工具
```

#### 解决方案 3: 从源码编译（不推荐）

```bash
# 需要安装编译依赖
apk add --no-cache python3 make g++ linux-headers

# unirtm 会自动从源码编译（较慢）
unirtm settings set node.compile=true
```

---

## 推荐的 Alpine Dockerfile 配置

### 方案 A: 完全使用 unirtm（推荐用于开发环境）

```dockerfile
FROM alpine:3.19

# 安装基础依赖
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates

# 安装 unirtm
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 配置 Node.js 使用 musl 构建
RUN unirtm settings set node.mirror_url=https://unofficial-builds.nodejs.org/download/release/ && \
    unirtm settings set node.flavor=musl

# 复制配置文件
COPY .unirtm.toml .

# 安装所有工具
RUN unirtm install

# Go 和 Python 会自动使用兼容的版本
# Node.js 会使用 musl 构建
```

### 方案 B: 混合使用（推荐用于生产环境）

```dockerfile
FROM alpine:3.19

# 使用 Alpine 官方包安装核心运行时（更稳定）
RUN apk add --no-cache \
    nodejs \
    npm \
    python3 \
    py3-pip \
    go \
    bash \
    curl \
    git

# 安装 unirtm 用于管理开发工具
RUN curl https://unirtm.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置文件（注释掉 node/python/go）
COPY .unirtm.toml .

# 只安装开发工具（linters, formatters 等）
RUN unirtm install
```

对应的 `.unirtm.toml`:

```toml
# 生产环境配置 - 使用系统包
# node = "25.9.0"  # 注释掉，使用 apk 安装
# python = "3.14.3"  # 注释掉，使用 apk 安装
# go = "1.26.2"  # 注释掉，使用 apk 安装

# 开发工具仍然使用 unirtm
"github:astral-sh/ruff" = "0.15.9"
"github:gitleaks/gitleaks" = "8.30.1"
# ... 其他工具
```

---

## 性能对比

| 运行时 | glibc (标准) | musl (Alpine) | 性能差异 |
|--------|-------------|---------------|---------|
| Go | 静态链接 | 静态链接 | 无差异 ✅ |
| Python | 官方构建 | musl 构建 | ~5% 慢 ⚠️ |
| Node.js | 官方构建 | 非官方构建 | ~3-5% 慢 ⚠️ |

**注意**: 性能差异主要来自 musl 的内存分配器，对大多数应用影响不大。

---

## 常见问题

### Q1: 为什么 Node.js 在 Alpine 上安装失败？

**A**: 默认情况下，unirtm 尝试下载 glibc 版本的 Node.js，不兼容 Alpine。

**解决**: 配置使用 musl 构建：

```bash
unirtm settings set node.flavor=musl
unirtm settings set node.mirror_url=https://unofficial-builds.nodejs.org/download/release/
```

### Q2: Python 在 Alpine 上需要特殊配置吗？

**A**: 不需要。unirtm 会自动检测 musl 并下载正确的版本。

### Q3: 应该使用 Alpine 官方包还是 unirtm？

**A**:

- **生产环境**: 推荐使用 Alpine 官方包（更稳定、更小）
- **开发环境**: 可以使用 unirtm（版本管理更灵活）

### Q4: 如何验证使用的是 musl 版本？

**A**:

```bash
# 检查二进制依赖
ldd $(unirtm where node)/bin/node
# 应该显示 musl 相关的库

# 或检查文件类型
file $(unirtm where node)/bin/node
# 应该包含 "dynamically linked" 和 musl 路径
```

---

## 最佳实践

### ✅ 推荐做法

1. **Go**: 直接使用 unirtm，无需特殊配置
2. **Python**: 直接使用 unirtm，自动处理 musl
3. **Node.js**: 配置使用 musl 构建或使用 Alpine 官方包
4. **生产环境**: 优先使用 Alpine 官方包
5. **开发环境**: 可以使用 unirtm + musl 构建

### ❌ 避免做法

1. 不要在 Alpine 上使用默认的 Node.js 配置（会失败）
2. 不要从源码编译（除非必要，非常慢）
3. 不要混用 glibc 和 musl 二进制

---

## 参考资源

- [Node.js Unofficial Builds](https://unofficial-builds.nodejs.org/)
- [python-build-standalone](https://github.com/indygreg/python-build-standalone)
- [unirtm Node.js 文档](https://github.com/snowdreamtech/UniRTMlang/node.html)
- [Alpine Linux 包搜索](https://pkgs.alpinelinux.org/packages)
- [musl libc 官网](https://musl.libc.org/)

---

## 工具安装架构

本项目使用 `install_tool_safe()` 模式进行工具安装，该模式自动处理平台特定的二进制名称，包括 Alpine Linux 的特殊情况。

### 二进制名称解析

工具安装系统会自动检测平台并解析正确的二进制名称：

**Linux (glibc):**

- `ec-linux-amd64` (x86_64)
- `ec-linux-arm64` (ARM64)

**Linux (musl/Alpine):**

- 相同的二进制名称，但链接到 musl libc
- 系统自动检测并使用兼容的版本

**macOS:**

- `ec-darwin-amd64` (Intel)
- `ec-darwin-arm64` (Apple Silicon)

**Windows:**

- `ec-windows-amd64.exe`

### Alpine 特定考虑

1. **二进制兼容性检查**: 安装后自动验证二进制是否可执行
2. **版本验证**: 确保工具在 musl 环境下正常工作
3. **回退机制**: 如果预编译二进制不兼容，提供清晰的错误信息

### 性能特征

在 Alpine Linux 上：

- 二进制验证: < 5 秒
- 平台特定解析: < 3 秒
- 缓存效果: 与其他平台相同（~50% 加速）

详见 [工具安装架构文档](./reference/tool-installation.md)。

---

## 更新日志

- 2026-04-10: 初始版本
- 包含 Go、Python、Node.js 的 Alpine 兼容性说明
- 提供 Dockerfile 示例和最佳实践
- 2025-01-15: 添加工具安装架构说明
- 记录二进制名称解析和性能特征
