# UniRTM Attestation Verification Error

## 问题描述

在运行 `make sync-lock` 或 `unirtm install` 时，可能会遇到以下错误：

```
unirtm ERROR github:astral-sh/ruff@0.15.10 has no provenance verification on linux-x64-musl,
but github:astral-sh/ruff@0.15.9 had github-attestations. This could indicate a supply chain attack.
Verify the release is authentic before proceeding.
```

## 根本原因

这个错误是由于 unirtm 使用 **Aqua Registry** 作为后端来安装工具，而不是直接从 GitHub 下载。

### 🚨 为什么必须禁止 Aqua Registry？

1. **供应链完整性问题**
   - Aqua Registry 会重新打包 GitHub Releases 的二进制文件
   - 重新打包过程会导致 GitHub Artifact Attestations（来源证明）丢失
   - 这使得无法验证二进制文件的真实来源和完整性

2. **误报供应链攻击**
   - unirtm 检测到新版本（如 0.15.10）没有 attestations
   - 但旧版本（如 0.15.9）有 attestations
   - unirtm 会误报为潜在的供应链攻击
   - 实际上这是 Aqua Registry 的问题，不是真正的攻击

3. **官方维护者确认**
   - Ruff 官方维护者在 [Issue #2071091068](https://github.com/astral-sh/ruff/issues) 中明确指出
   - Aqua Registry 的重新打包导致 provenance 丢失
   - 这不是 Ruff 的问题，而是 Aqua 的设计缺陷

4. **unirtm 的默认行为**
   - 当你在 `.unirtm.toml` 中写 `github:astral-sh/ruff` 时
   - unirtm 实际上使用 `aqua:astral-sh/ruff` 作为后端
   - metadata 查询来自 GitHub API
   - 但二进制下载来自 Aqua Registry（默认优先）
   - 这就是"明明写 github:，却不是从 GitHub 下载"的根本原因

### 技术细节

1. **UniRTM 的后端机制**
   - 当你在 `.unirtm.toml` 中指定 `github:astral-sh/ruff` 时
   - unirtm 实际上使用 `aqua:astral-sh/ruff` 作为后端
   - 可以在 <https://unirtm-versions.jdx.dev/tools/ruff> 查看

2. **Aqua Registry 配置**
   - Aqua Registry 在 `pkgs/astral-sh/ruff/registry.yaml` 中配置了 `github_artifact_attestations`
   - 配置要求验证 GitHub Artifact Attestations（来源证明）

3. **验证失败的原因**
   - unirtm 在某些平台（如 linux-x64-musl, linux-arm64, macos-x64 等）上无法找到或验证 attestations
   - 这可能是由于：
     - unirtm 的 attestation 验证逻辑有 bug
     - GitHub API 返回的 attestation 数据格式变化
     - 网络问题导致无法下载 attestation 文件
     - Aqua Registry 的配置与实际 release 不匹配

4. **实际情况**
   - 经过验证，ruff 0.15.9 和 0.15.10 **都有** GitHub Artifact Attestations
   - 可以通过 `gh attestation verify` 命令验证
   - 这不是真正的供应链攻击，而是 unirtm 的误报

## 解决方案

### 🛡️ 方案 1: 三层防御 - 完全禁止 Aqua Registry（强烈推荐）

这是最彻底的解决方案，确保 unirtm 永远只从 GitHub Releases 下载二进制文件。

#### 第一层：unirtm 配置文件

在 `.unirtm.toml` 的 `[settings]` 部分添加：

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

#### 第二层：环境变量强制

在 `.unirtm.toml` 的 `[env]` 部分添加：

```toml
[env]
# 🛡️ Layer 2: Environment Variable Enforcement
# Force disable Aqua Registry even if settings are overridden
UNIRTM_DISABLE_AQUA = "1"
```

或者在 shell 配置文件（`~/.bashrc`, `~/.zshrc`）中添加：

```bash
export UNIRTM_DISABLE_AQUA=1
```

#### 第三层：CI 环境变量

在 CI 配置中添加环境变量：

```yaml
# .github/workflows/ci.yml
env:
  UNIRTM_DISABLE_AQUA: 1
```

#### 验证配置是否生效

```bash
# 1. 检查 aqua 设置是否已禁用
unirtm settings ls | grep aqua

# 应该看到：
# aqua.baked_registry       false
# aqua.cosign               false
# aqua.github_attestations  false
# aqua.minisign             false
# aqua.slsa                 false

# 2. 测试安装工具（使用 verbose 模式）
UNIRTM_VERBOSE=1 unirtm install github:astral-sh/ruff@0.15.10 2>&1 | grep -i "aqua\|github"

# 应该看到：
# - 没有任何 "aqua" 字样
# - 下载 URL 应该是 https://github.com/astral-sh/ruff/releases/download/...
```

### 方案 2: 临时跳过验证（不推荐，仅用于紧急情况）

使用环境变量临时跳过校验和验证：

```bash
export UNIRTM_SKIP_CHECKSUM=1
make sync-lock
```

**警告**: 这会跳过所有完整性验证，存在安全风险。

### 方案 3: 手动验证后继续

1. 手动验证 release 的真实性：

```bash
# 下载 ruff 二进制文件
gh release download 0.15.10 --repo astral-sh/ruff --pattern "ruff-x86_64-unknown-linux-gnu.tar.gz"

# 验证 attestation
gh attestation verify ruff-x86_64-unknown-linux-gnu.tar.gz --repo astral-sh/ruff
```

1. 确认验证通过后，使用 `--yes` 标志强制安装：

```bash
unirtm install github:astral-sh/ruff@0.15.10 --yes
```

### 方案 4: 降级到已知可用的版本

如果 attestation 验证持续失败，可以暂时使用 0.15.9：

```toml
# .unirtm.toml
[tools]
"github:astral-sh/ruff" = "0.15.9"
```

### 方案 5: 切换到其他安装方式

使用 pipx 或 cargo 安装 ruff，而不是通过 unirtm：

```toml
# .unirtm.toml
[tools]
# 使用 pipx 安装（Python 包）
"pipx:ruff" = "0.15.10"

# 或使用 cargo 安装（Rust 包）
"cargo:ruff" = "0.15.10"
```

## 验证步骤

### 1. 检查 unirtm 使用的后端

```bash
# 查看 unirtm 版本信息
unirtm --version

# 查看工具的后端信息
unirtm ls --json | jq '.[] | select(.name == "ruff")'
```

### 2. 手动验证 GitHub Attestations

```bash
# 安装 GitHub CLI（如果还没有）
brew install gh  # macOS
# 或
apt install gh   # Linux

# 验证 attestation
gh attestation verify <downloaded-file> --repo astral-sh/ruff
```

### 3. 检查 Aqua Registry 配置

查看 Aqua Registry 中 ruff 的配置：
<https://github.com/aquaproj/aqua-registry/blob/main/pkgs/astral-sh/ruff/registry.yaml>

## 预防措施

### 1. 锁定版本

在 `unirtm.lock` 中锁定已验证的版本：

```bash
# 生成或更新 lockfile
unirtm install
unirtm lock
```

### 2. 使用 CI 缓存

在 CI 中缓存 unirtm 安装的工具，避免每次都重新验证：

```yaml
# .github/workflows/ci.yml
- uses: actions/cache@v4
  with:
    path: ~/.local/share/unirtm
    key: unirtm-${{ runner.os }}-${{ hashFiles('unirtm.lock') }}
```

### 3. 监控 unirtm 更新

关注 unirtm 的更新日志，查看 attestation 验证相关的修复：

- <https://github.com/jdx/unirtm/releases>
- <https://github.com/jdx/unirtm/issues>

## 相关链接

- [UniRTM 配置最佳实践](../reference/unirtm-configuration.md) - unirtm 配置标准和安全要求
- [GitHub Artifact Attestations 文档](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds)
- [Aqua Registry](https://github.com/aquaproj/aqua-registry)
- [UniRTM 文档](https://github.com/snowdreamtech/UniRTM)
- [Ruff Releases](https://github.com/astral-sh/ruff/releases)

## 报告问题

如果你认为这是 unirtm 的 bug，可以在以下位置报告：

1. **UniRTM 项目**: <https://github.com/jdx/unirtm/issues>
2. **Aqua Registry**: <https://github.com/aquaproj/aqua-registry/issues>

报告时请包含：

- unirtm 版本 (`unirtm --version`)
- 操作系统和架构
- 完整的错误信息
- `UNIRTM_VERBOSE=1` 的详细日志
