# UniRTM 配置最佳实践

本文档定义了项目中 unirtm 工具管理器的配置标准和最佳实践。

## 核心原则

### 🛡️ 供应链安全优先

unirtm 必须配置为只从官方源下载二进制文件，禁止使用可能破坏供应链完整性的中间层。

### 📦 两层工具管理

- **Tier 1 (Core)**: 所有项目必需的工具，在 `.unirtm.toml` 中定义
- **Tier 2 (On-demand)**: 特定语言/领域工具，按需安装

## 必需配置

### 禁止 Aqua Registry 后端

**规则**: 必须禁用 Aqua Registry 作为 unirtm 的后端。

**原因**:

1. Aqua Registry 会重新打包 GitHub Release 二进制文件
2. 重新打包导致 GitHub Artifact Attestations（来源证明）丢失
3. 无法验证二进制文件的真实来源和完整性
4. unirtm 会误报供应链攻击警告

**配置** (`.unirtm.toml`):

```toml
[settings]
# 🛡️ Supply Chain Security: Disable Aqua Registry Backend
# CRITICAL: Force unirtm to download binaries ONLY from GitHub Releases,
# not from Aqua Registry which may repackage binaries and lose provenance.
aqua.baked_registry = false
aqua.github_attestations = false
aqua.slsa = false
aqua.cosign = false
aqua.minisign = false
```

**环境变量强制**:

```toml
[env]
# 🛡️ Layer 2: Environment Variable Enforcement
# Force disable Aqua Registry even if settings are overridden
UNIRTM_DISABLE_AQUA = "1"
```

### ASDF 兼容性

**规则**: 保持 `asdf_compat = true` 以支持 `.tool-versions` 文件格式。

**原因**:

- 允许与 asdf 生态系统的工具和配置兼容
- 不影响供应链安全（仅文件格式兼容）
- 便于从 asdf 迁移到 unirtm

**配置**:

```toml
[settings]
asdf_compat = true
```

**注意**: `asdf_compat` 与 Aqua Registry 无关，它只是文件格式兼容性开关。

## 验证配置

### 检查 Aqua 是否已禁用

```bash
# 1. 检查 unirtm 设置
unirtm settings ls | grep aqua

# 应该看到所有 aqua.* 设置都是 false:
# aqua.baked_registry       false
# aqua.cosign               false
# aqua.github_attestations  false
# aqua.minisign             false
# aqua.slsa                 false

# 2. 检查环境变量
env | grep UNIRTM_DISABLE_AQUA
# 应该输出: UNIRTM_DISABLE_AQUA=1

# 3. 验证下载源（使用 verbose 模式）
UNIRTM_VERBOSE=1 unirtm install github:astral-sh/ruff@0.15.10 2>&1 | grep -i "download"
# 应该看到 URL 来自 https://github.com/.../releases/download/...
# 不应该看到任何 "aqua" 字样
```

### 自动化验证脚本

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Verifying unirtm configuration..."

# Test 1: Check aqua settings
if unirtm settings ls | grep -q "aqua.baked_registry.*false"; then
    echo "✅ Aqua Registry is disabled"
else
    echo "❌ Aqua Registry is NOT disabled"
    exit 1
fi

# Test 2: Check environment variable
if env | grep -q "UNIRTM_DISABLE_AQUA=1"; then
    echo "✅ UNIRTM_DISABLE_AQUA is set"
else
    echo "❌ UNIRTM_DISABLE_AQUA is NOT set"
    exit 1
fi

# Test 3: Check asdf compatibility
if unirtm settings ls | grep -q "asdf_compat.*true"; then
    echo "✅ ASDF compatibility is enabled"
else
    echo "⚠️  ASDF compatibility is disabled"
fi

echo "🎉 Configuration verified!"
```

## 网络加速配置

### 镜像源配置

为了提高下载速度，可以配置镜像源（仅限非 CI 环境）：

```toml
[env]
# GitHub Proxy Acceleration - Enable locally, disable in CI
ENABLE_GITHUB_PROXY = "{% if env.CI is defined %}0{% else %}1{% endif %}"
GITHUB_PROXY = "https://gh-proxy.sn0wdr1am.com/"

# Node.js mirror
NPM_CONFIG_REGISTRY = "{% if env.CI is defined %}https://registry.npmjs.org{% else %}https://registry.npmmirror.com{% endif %}"
NODEJS_ORG_MIRROR = "{% if env.CI is defined %}https://nodejs.org/dist/{% else %}https://npmmirror.com/mirrors/node/{% endif %}"

# Python mirror
PIP_INDEX_URL = "{% if env.CI is defined %}https://pypi.org/simple{% else %}https://mirrors.aliyun.com/pypi/simple{% endif %}"

# Go mirror
GOPROXY = "{% if env.CI is defined %}https://proxy.golang.org,direct{% else %}https://mirrors.aliyun.com/goproxy/,direct{% endif %}"
UNIRTM_GO_DOWNLOAD_MIRROR = "{% if env.CI is defined %}https://dl.google.com/go/{% else %}https://mirrors.aliyun.com/golang/{% endif %}"
```

**重要**: 镜像源配置不影响供应链安全，因为：

1. 只用于加速下载，不改变二进制来源
2. unirtm 仍然验证 checksum
3. CI 环境使用官方源确保一致性

## 工具提供者选择

### 优先级顺序

1. **npm 包** (最优先) - 预编译二进制，安装快速

   ```toml
   "npm:@taplo/cli" = "0.7.0"
   "npm:prettier" = "3.8.1"
   ```

2. **GitHub Releases** - 官方发布的二进制

   ```toml
   "github:astral-sh/ruff" = "0.15.9"
   "github:koalaman/shellcheck" = "0.11.0"
   ```

3. **pipx** - Python 工具隔离安装

   ```toml
   "pipx:yamllint" = "1.38.0"
   "pipx:pre-commit" = "4.5.1"
   ```

4. **cargo/go** - 从源码编译（最慢，仅必要时使用）

   ```toml
   "cargo:cargo-audit" = "0.22.1"
   "go:golang.org/x/vuln/cmd/govulncheck" = "1.1.4"
   ```

### ❌ 禁止使用的提供者

- **aqua:** - 已通过配置全局禁用
- **asdf:** - 不要使用 `asdf:` 前缀（使用 `github:` 或其他直接源）

### 特殊情况处理

#### GitHub 源码编译 vs npm 预编译

**错误示例**:

```toml
# ❌ 从 GitHub 源码编译 taplo（需要 15+ 分钟）
"github:tamasfe/taplo" = "0.10.0"
```

**正确示例**:

```toml
# ✅ 使用 npm 预编译二进制（~1 秒安装）
"npm:@taplo/cli" = "0.7.0"
```

## 常见问题

### Q: 为什么不能使用 Aqua Registry？

A: Aqua Registry 会重新打包二进制文件，导致：

- GitHub Artifact Attestations 丢失
- 无法验证供应链完整性
- unirtm 误报供应链攻击
- 违反安全最佳实践

详见: [UniRTM Attestation Error 故障排除](../troubleshooting/unirtm-attestation-error.md)

### Q: asdf_compat 和 Aqua Registry 有什么关系？

A: 没有关系。

- `asdf_compat` 只是文件格式兼容性开关
- 它允许 unirtm 读取 `.tool-versions` 文件
- 不影响工具下载来源或供应链安全

### Q: 如何确认工具来自 GitHub 而不是 Aqua？

A: 使用 verbose 模式检查下载 URL：

```bash
UNIRTM_VERBOSE=1 unirtm install github:astral-sh/ruff@0.15.10 2>&1 | grep -E "download|url"
```

应该看到:

- ✅ `https://github.com/astral-sh/ruff/releases/download/...`
- ❌ 不应该有任何 "aqua" 字样

### Q: CI 环境需要特殊配置吗？

A: 不需要。`.unirtm.toml` 中的配置对所有环境生效：

- Aqua 在所有环境都被禁用
- 镜像源通过 Tera 模板自动切换
- CI 使用官方源，本地使用镜像加速

## 相关文档

- [UniRTM Attestation Error 故障排除](../troubleshooting/unirtm-attestation-error.md)
- [工具安装参考](./tool-installation.md)
- [Alpine 兼容性](../alpine-compatibility.md)
- [安全最佳实践](../rules/04-security.md)

## 更新历史

- 2026-04-15: 添加三层防御机制，禁用 Aqua Registry
- 2026-04-15: 明确 asdf_compat 与 Aqua 无关
- 2026-04-15: 添加验证脚本和常见问题
