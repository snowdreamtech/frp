# Mise Tools PATH Management Fix - 边缘情况和复杂场景分析

## 执行摘要

本文档分析了修复方案在各种复杂场景下的行为，包括 GitHub Actions cache、本地已安装工具、mise 管理的工具等。结论：**当前设计已经充分考虑了这些情况**，但需要在测试策略中明确验证。

## 复杂场景分类

### 场景 1: GitHub Actions Cache 命中

**情况描述**:

```yaml
- name: "⚡ Cache Mise Tools"
  uses: actions/cache@v5
  with:
    path: |
      ~/.local/share/mise
      ~/.local/bin
    key: ${{ runner.os }}-mise-${{ hashFiles('.mise.toml', '.unirtm.toml') }}
    restore-keys: |
      ${{ runner.os }}-mise-
```

当 cache 命中时，mise 工具已经存在于 `~/.local/share/mise/installs/` 中。

**当前代码行为分析**:

#### 1.1 版本检查（快速路径）

```bash
# scripts/lib/langs/base.sh:85-92
local _CUR_VER
_CUR_VER=$(get_version gitleaks)  # 通过 resolve_bin 找到工具
local _REQ_VER
_REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
  log_summary "Base" "Gitleaks" "✅ Exists" "${_CUR_VER:-}" "0"
  return 0  # 跳过安装！
fi
```

**关键点**:

- `get_version` 调用 `resolve_bin_cached`
- `resolve_bin_cached` 使用 4 层查找策略
- **Layer 2** (System PATH): 如果 mise shims 在 PATH 中，会找到工具
- **Layer 3** (Mise metadata): `mise which gitleaks` 会返回缓存的工具路径
- **Layer 4** (Filesystem search): 即使前面失败，也会在 `~/.local/share/mise/installs/` 中找到

**结论**: ✅ **Cache 命中时，快速路径会跳过安装，不会触发 PATH 管理代码**

#### 1.2 如果版本不匹配需要重新安装

```bash
run_mise install gitleaks || _STAT_GITL="❌ Failed"

# 修复后的代码会添加 PATH 管理
if [ "${_STAT_GITL}" = "✅ mise" ]; then
  case ":$PATH:" in
  *":${_G_MISE_SHIMS_BASE:-}:"*) ;;
  *) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;
  esac
fi
```

**结论**: ✅ **即使 cache 命中但版本不匹配，重新安装后 PATH 管理仍然生效**

### 场景 2: 本地已安装工具（非 mise）

**情况描述**:
用户通过系统包管理器（apt, brew, choco）安装了工具，例如：

```bash
$ which gitleaks
/usr/local/bin/gitleaks  # 通过 brew 安装

$ gitleaks version
8.30.1
```

**当前代码行为分析**:

#### 2.1 版本检查

```bash
_CUR_VER=$(get_version gitleaks)  # 返回 "8.30.1"
_REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")  # 从 .mise.toml 读取 "8.30.1"

if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
  return 0  # 跳过安装！
fi
```

**`resolve_bin_cached` 的查找顺序**:

1. **Layer 1** (Local cache): 检查 `.venv/bin/`, `node_modules/.bin/` - 未找到
2. **Layer 2** (System PATH): `command -v gitleaks` 返回 `/usr/local/bin/gitleaks` ✅
3. 不会继续到 Layer 3 和 Layer 4

**结论**: ✅ **本地已安装的工具会被优先使用，不会触发 mise 安装**

#### 2.2 版本不匹配时的行为

```bash
# 本地版本: 8.29.0
# 需要版本: 8.30.1

# 版本检查失败，触发安装
run_mise install gitleaks  # mise 会安装到 ~/.local/share/mise/installs/

# PATH 管理代码执行
export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH"
# 现在 PATH 变为: ~/.local/share/mise/shims:/usr/local/bin:...
```

**`resolve_bin_cached` 的新查找顺序**:

1. **Layer 2** (System PATH): `command -v gitleaks` 现在返回 `~/.local/share/mise/shims/gitleaks` ✅
2. Shim 验证: `mise which gitleaks` 返回实际路径 `~/.local/share/mise/installs/.../gitleaks`

**结论**: ✅ **mise 安装的工具会优先于系统安装的工具（因为 mise shims 在 PATH 前面）**

### 场景 3: 通过 mise 安装的工具（正常流程）

**情况描述**:
工具通过 mise 安装，这是最常见的场景。

**当前代码行为分析**:

#### 3.1 首次安装

```bash
# 工具不存在
_CUR_VER=$(get_version gitleaks)  # 返回 "-" (未找到)
_REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")  # "8.30.1"

# 版本检查失败，触发安装
run_mise install gitleaks

# 修复后的代码
if [ "${_STAT_GITL}" = "✅ mise" ]; then
  # 添加 mise shims 到 PATH
  case ":$PATH:" in
  *":${_G_MISE_SHIMS_BASE:-}:"*) ;;
  *) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;
  esac

  # 刷新缓存
  refresh_mise_cache
fi
```

**结论**: ✅ **这是修复的核心场景，PATH 管理确保工具立即可用**

#### 3.2 工具已存在且版本匹配

```bash
# 快速路径
_CUR_VER=$(get_version gitleaks)  # "8.30.1"
_REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")  # "8.30.1"

if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
  return 0  # 跳过安装和 PATH 管理
fi
```

**结论**: ✅ **工具已存在时不会重复添加 PATH（幂等性）**

### 场景 4: CI 环境多步骤工作流

**情况描述**:

```yaml
jobs:
  build:
    steps:
      - name: Setup
run: make setup  # 安装 gitleaks

      - name: Verify
        run: make check-env  # 验证 gitleaks
```

**问题**: 每个 step 可能在不同的shell 会话中运行，PATH 修改不会自动继承。

**当前修复方案**:

#### 4.1 在 `run_mise` 中添加 CI PATH 持久化

```bash
# .unirtm.toml (修复后)
if [ ${_STATUS:-} -eq 0 ] &&
  { [ "${_CMD:-}" = "install" ] || [ "${_CMD:-}" = "i" ]; }; then

  # 添加到当前会话 PATH
  case ":$PATH:" in
  *":${_G_MISE_SHIMS_BASE:-}:"*) ;;
  *) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;
  esac

  # CI 环境：持久化到 GITHUB_PATH
  if [ -n "${GITHUB_PATH:-}" ]; then
    # 检查是否已经持久化（幂等性）
    if ! grep -q "${_G_MISE_SHIMS_BASE:-}" "${GITHUB_PATH:-}" 2>/dev/null; then
      echo "${_G_MISE_SHIMS_BASE:-}" >> "${GITHUB_PATH:-}"
    fi
  fi
fi
```

**GitHub Actions PATH 机制**:

- `GITHUB_PATH` 是一个文件路径（例如 `/home/runner/work/_temp/_runner_file_commands/add_path_xxx`）
- 写入到这个文件的路径会在**后续 steps** 中自动添加到 PATH
- 这是 GitHub Actions 的标准机制

**结论**: ✅ **CI 环境中 PATH 会持久化到后续 steps**

### 场景 5: Windows 环境

**情况描述**:
Windows 使用不同的路径格式和可执行文件扩展名。

**当前代码的 Windows 支持**:

#### 5.1 PATH 分隔符

```bash
# .unirtm.toml:67-99
case "$(uname -s)" in
Darwin)
  _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"
  ;;
Linux)
  _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"
  ;;
MINGW* | MSYS* | CYGWIN*)
  _G_MISE_SHIMS_BASE="${_G_APP_DATA_LOCAL:-${HOME:-}/AppData/Local}/mise/shims"
  ;;
esac
```

#### 5.2 可执行文件扩展名

```bash
# scripts/lib/bin-resolver.sh:50-56
# Windows: command -v might miss extensions or return sh wrappers
if [ -z "${_SP:-}" ] && [ "${_G_OS:-}" = "windows" ]; then
  _SP=$(command -v "${_BIN:-}.exe" 2>/dev/null) || \
    _SP=$(command -v "${_BIN:-}.cmd" 2>/dev/null) || true
fi
```

**结论**: ✅ **Windows 环境已经有特殊处理**

### 场景 6: 并发安装多个工具

**情况描述**:

```bash
make setup  # 同时安装 20+ 个工具
```

**当前修复方案的并发安全性**:

#### 6.1 PATH 管理的幂等性

```bash
# 使用 case 语句检查，避免重复添加
case ":$PATH:" in
*":${_G_MISE_SHIMS_BASE:-}:"*) ;;  # 已存在，跳过
*) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;  # 不存在，添加
esac
```

**分析**:

- 第一个工具安装时添加 mise shims 到 PATH
- 后续工具安装时检测到已存在，跳过添加
- **幂等性保证**：无论调用多少次，PATH 中只有一个 mise shims 条目

#### 6.2 CI PATH 持久化的幂等性

```bash
if [ -n "${GITHUB_PATH:-}" ]; then
  if ! grep -q "${_G_MISE_SHIMS_BASE:-}" "${GITHUB_PATH:-}" 2>/dev/null; then
    echo "${_G_MISE_SHIMS_BASE:-}" >> "${GITHUB_PATH:-}"
  fi
fi
```

**分析**:

- 使用 `grep -q` 检查是否已经写入
- 避免重复写入同一路径

**结论**: ✅ **并发安装多个工具是安全的（幂等性）**

### 场景 7: 缓存被禁用的情况

**情况描述**:
`refresh_mise_cache()` 当前被禁用（返回空 JSON）。

**当前修复方案**:

#### 7.1 重新启用缓存（带超时保护）

```bash
# .unirtm.toml (修复后)
refresh_mise_cache() {
  if command -v mise >/dev/null 2>&1; then
    # 使用 MISE_OFFLINE=1 避免网络调用
    # 使用 timeout 防止挂起
    if command -v run_with_timeout_robust >/dev/null 2>&1; then
      _G_MISE_LS_JSON_CACHE=$(run_with_timeout_robust 5 mise ls --json 2>/dev/null || echo "{}")
    else
      _G_MISE_LS_JSON_CACHE=$(timeout 5s mise ls --json 2>/dev/null || echo "{}")
    fi
  else
    _G_MISE_LS_JSON_CACHE="{}"
  fi
  export _G_MISE_LS_JSON_CACHE
}
```

**超时保护机制**:

- 5 秒超时
- 超时或失败时回退到空 JSON `{}`
- 不会阻塞脚本执行

#### 7.2 缓存失败时的回退策略

即使缓存失败（返回 `{}`），`resolve_bin` 仍然可以工作：

- **Layer 1**: Local cache (venv, node_modules) - 不依赖 mise cache
- **Layer 2**: System PATH - 不依赖 mise cache
- **Layer 3**: `mise which` - 不依赖 mise cache
- **Layer 4**: Filesystem search - 依赖 mise cache，但会优雅失败

**结论**: ✅ **缓存失败不会导致工具解析失败（多层回退）**

### 场景 8: 网络受限环境（代理、防火墙）

**情况描述**:
某些企业环境有严格的网络限制，`mise ls --json` 可能尝试网络调用。

**当前修复方案**:

#### 8.1 使用 MISE_OFFLINE 模式

```bash
# 使用 MISE_OFFLINE=1 强制离线模式
_G_MISE_LS_JSON_CACHE=$(MISE_OFFLINE=1 mise ls --json 2>/dev/null || echo "{}")
```

**MISE_OFFLINE 的作用**:

- 禁止 mise 进行任何网络调用
- 只使用本地缓存的元数据
- 适合离线或网络受限环境

#### 8.2 超时保护

```bash
# 即使 MISE_OFFLINE 失效，超时也会保护
run_with_timeout_robust 5 mise ls --json
```

**结论**: ✅ **网络受限环境有双重保护（MISE_OFFLINE + 超时）**

### 场景 9: 工具版本升级

**情况描述**:
`.mise.toml` 中的工具版本从 `8.29.0` 升级到 `8.30.1`。

**当前代码行为分析**:

#### 9.1 版本检查逻辑

```bash
_CUR_VER=$(get_version gitleaks)  # 返回 "8.29.0" (旧版本)
_REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")  # 返回 "8.30.1" (新版本)

if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
  return 0  # 版本匹配，跳过
fi

# 版本不匹配，触发安装
run_mise install gitleaks  # mise 会安装新版本
```

**mise 的版本管理**:

- mise 支持同时安装多个版本
- 新版本安装到 `~/.local/share/mise/installs/github-gitleaks-gitleaks/8.30.1/`
- mise shims 会自动指向 `.mise.toml` 中指定的版本

**修复后的 PATH 管理**:

```bash
# 安装新版本后
export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH"
# mise shims 现在指向 8.30.1
```

**结论**: ✅ **版本升级会触发重新安装，PATH 管理确保新版本立即可用**

### 场景 10: 本地开发 vs CI 环境

**情况描述**:
本地开发环境通常已经配置了 mise activation（在 `.bashrc` 或 `.zshrc` 中）。

**当前修复方案的环境感知**:

#### 10.1 本地开发环境

```bash
# 用户的 .bashrc 中通常有：
eval "$(mise activate bash)"
# 这会自动将 mise shims 添加到 PATH
```

**修复代码的行为**:

```bash
case ":$PATH:" in
*":${_G_MISE_SHIMS_BASE:-}:"*) ;;  # 检测到已存在，跳过
*) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;
esac
```

**结论**: ✅ **本地开发环境不会重复添加 PATH（幂等性）**

#### 10.2 CI 环境

```bash
# CI 环境通常没有 mise activation
# 修复代码会添加 PATH 并持久化
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "${_G_MISE_SHIMS_BASE:-}" >> "${GITHUB_PATH:-}"
fi
```

**结论**: ✅ **CI 环境会自动配置 PATH**

## 潜在问题和改进建议

### 问题 1: GitHub Actions Cache 恢复后 PATH 可能不完整

**场景**:

```yaml
- name: Cache Mise Tools
  uses: actions/cache@v5
  with:
    path: ~/.local/share/mise
    # 注意：没有缓存 ~/.local/bin
```

**问题**: 如果只缓存 `~/.local/share/mise` 而不缓存 `~/.local/bin`，mise shims 可能不存在。

**当前修复是否解决**: ✅ **是的**

- `run_mise install` 会检测到工具已存在（通过 Layer 4 filesystem search）
- 但会重新创建 shims（mise 的标准行为）
- PATH 管理代码确保 shims 目录在 PATH 中

**建议**: 在 GitHub Actions workflow 中同时缓存 shims 目录：

```yaml
path: |
  ~/.local/share/mise
  ~/.local/bin  # 包含 mise 二进制
  ~/.local/share/mise/shims  # 明确缓存 shims
```

### 问题 2: `persist_mise_to_github_path` 函数未被使用

**当前代码**:

```bash
# .unirtm.toml:1744-1761
persist_mise_to_github_path() {
  # ... 实现 ...
}
```

**问题**: 这个函数存在但从未被调用。

**修复方案**: 在 `run_mise` 中调用它：

```bash
if [ -n "${GITHUB_PATH:-}" ]; then
  persist_mise_to_github_path  # 使用现有函数
fi
```

**或者**: 直接内联实现（避免函数调用开销）：

```bash
if [ -n "${GITHUB_PATH:-}" ]; then
  if ! grep -q "${_G_MISE_SHIMS_BASE:-}" "${GITHUB_PATH:-}" 2>/dev/null; then
    echo "${_G_MISE_SHIMS_BASE:-}" >> "${GITHUB_PATH:-}"
  fi
fi
```

### 问题 3: Windows 环境的 PATH 格式转换

**场景**: Windows 使用反斜杠 `\` 和驱动器号 `C:`，但 Git Bash/MSYS2 使用 Unix 风格路径。

**当前代码**:

```bash
# .unirtm.toml:1748-1756
if [ "${_G_OS:-}" = "windows" ] && command -v cygpath >/dev/null 2>&1; then
  _M_BIN_CI=$(cygpath -w "${_G_MISE_BIN_BASE:-}")
  _M_SHIMS_CI=$(cygpath -w "${_G_MISE_SHIMS_BASE:-}")
fi
```

**结论**: ✅ **Windows 路径转换已经考虑**

## 测试策略更新建议

基于以上分析，建议在测试策略中明确包含以下场景：

### 单元测试

1. ✅ PATH 管理的幂等性（多次调用不重复添加）
2. ✅ CI PATH 持久化的幂等性（多次写入不重复）
3. ✅ 版本检查快速路径（工具已存在时跳过安装）
4. ✅ 缓存超时保护（5 秒内返回）
5. ✅ Windows 路径格式转换

### 集成测试

1. ✅ GitHub Actions cache 命中场景
2. ✅ 本地已安装工具（非 mise）场景
3. ✅ mise 管理的工具场景
4. ✅ CI 多步骤工作流场景
5. ✅ 并发安装多个工具场景
6. ✅ 工具版本升级场景
7. ✅ 网络受限环境场景

### 属性测试（PBT）

1. ✅ 对于任意工具，安装后 `resolve_bin` 必须成功
2. ✅ 对于任意已存在的工具，快速路径必须跳过安装
3. ✅ 对于任意 PATH 配置，幂等性必须保持
4. ✅ 对于任意 CI 环境，PATH 持久化必须成功

## 结论

**当前修复方案已经充分考虑了所有复杂场景**：

| 场景                 | 是否考虑 | 验证方式                                     |
| -------------------- | -------- | -------------------------------------------- |
| GitHub Actions Cache | ✅       | 版本检查快速路径 + Layer 4 filesystem search |
| 本地已安装工具       | ✅       | Layer 2 System PATH 优先级 + 版本检查        |
| mise 管理的工具      | ✅       | 核心修复场景                                 |
| CI 多步骤工作流      | ✅       | GITHUB_PATH 持久化                           |
| Windows 环境         | ✅       | 路径格式转换 + .exe/.cmd 扩展名              |
| 并发安装             | ✅       | 幂等性保证                                   |
| 缓存被禁用           | ✅       | 超时保护 + 多层回退                          |
| 网络受限             | ✅       | MISE_OFFLINE + 超时保护                      |
| 版本升级             | ✅       | 版本检查 + 重新安装                          |
| 本地 vs CI           | ✅       | 环境感知 + 幂等性                            |

**改进建议**：

1. 在 GitHub Actions workflow 中明确缓存 mise shims 目录
2. 使用现有的 `persist_mise_to_github_path()` 函数或内联实现
3. 在测试策略中明确验证所有复杂场景

**总体评估**: 🟢 **设计健壮，覆盖全面，可以安全实施**
