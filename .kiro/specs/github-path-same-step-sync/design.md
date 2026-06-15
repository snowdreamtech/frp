# GitHub PATH 同步 Bugfix Design

## Overview

本 bugfix 旨在修复 CI 环境中 `run_mise()` 函数的 PATH 同步问题。当前实现仅将工具路径写入 `$GITHUB_PATH` 文件以实现跨 step 持久化，但 GitHub Actions 的 `GITHUB_PATH` 机制只在不同 step 之间生效，不会自动更新当前 shell 的 `$PATH` 环境变量。修复策略是在写入 `$GITHUB_PATH` 后，立即读取该文件并将路径应用到当前 shell 的 `$PATH`，确保工具在同一 step 内立即可用。

## Glossary

- **Bug_Condition (C)**: 在 CI 环境中，`run_mise install` 成功安装工具后，工具路径被写入 `$GITHUB_PATH` 文件，但当前 shell 的 `$PATH` 未包含该路径
- **Property (P)**: 安装工具后，工具路径应同时存在于 `$GITHUB_PATH` 文件和当前 shell 的 `$PATH` 环境变量中
- **Preservation**: 非 CI 环境的行为、已存在路径的幂等性检查、错误处理逻辑必须保持不变
- **run_mise()**: `.unirtm.toml` 中的函数，负责执行 mise 命令并管理工具安装
- **$GITHUB_PATH**: GitHub Actions 提供的特殊文件路径，写入该文件的路径会在后续 step 中自动添加到 `$PATH`
- **$\_G_MISE_SHIMS_BASE**: mise shims 目录的全局变量，通常为 `~/.local/share/mise/shims`
- **mise where**: mise 命令，返回已安装工具的安装路径

## Bug Details

### Bug Condition

当在 CI 环境的同一个 shell step 中通过 `run_mise install` 安装工具后，立即调用该工具或 `resolve_bin` 函数时，系统无法找到可执行文件。这是因为 `run_mise()` 函数将工具路径写入 `$GITHUB_PATH` 文件，但该机制仅在不同 step 之间生效，不会影响当前正在运行的 shell 进程的 `$PATH` 环境变量。

**Formal Specification:**

```
FUNCTION isBugCondition(context)
  INPUT: context of type ExecutionContext
  OUTPUT: boolean

  RETURN context.environment = "CI"
         AND context.miseInstallSucceeded = true
         AND context.pathWrittenToGitHubPath = true
         AND context.currentShellPath NOT CONTAINS context.toolBinPath
         AND context.sameShellStep = true
END FUNCTION
```

### Examples

- **Example 1**: 在 CI workflow 中执行 `make setup && make install && make check-env`，`check-env.sh` 报告 "❌ Zizmor: Not found"，即使 `run_mise install pipx:zizmor` 已成功执行并将路径写入 `$GITHUB_PATH`
- **Example 2**: 动态安装 `go:github.com/google/osv-scanner/v2/cmd/osv-scanner` 后，立即调用 `resolve_bin osv-scanner` 返回空，因为 `~/.local/share/mise/installs/go-github.com-google-osv-scanner-v2/latest/bin` 未在当前 shell 的 `$PATH` 中
- **Example 3**: 安装 Gitleaks 后，同一 step 中执行 `gitleaks detect` 失败，提示 "command not found"，但在下一个 step 中可以正常使用
- **Edge Case**: 在本地开发环境（非 CI）中，`run_mise install` 正常工作，因为 mise 会自动激活工具或通过 shims 机制使工具可用

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**

- 在非 CI 环境（本地开发环境）中，`run_mise install` 必须继续正常工作，不依赖 `$GITHUB_PATH` 机制
- 工具路径已经在 `$PATH` 中存在时，必须跳过重复添加，保持幂等性
- 工具路径已经在 `$GITHUB_PATH` 文件中时，必须跳过重复写入
- mise shims 目录（`$_G_MISE_SHIMS_BASE`）已经在 `$PATH` 中时，必须避免重复添加
- `run_mise install` 失败或超时时，必须继续执行现有的重试和错误处理逻辑
- 在不同的 GitHub Actions step 之间，必须继续通过 `$GITHUB_PATH` 机制正确传递工具路径
- 安装需要后端管理器的工具（如 `cargo:*`、`go:*`、`npm:*`）时，必须继续执行现有的依赖检查逻辑
- 使用 Adaptive Lock Forgiveness (ALF) 机制处理 `go:` 前缀工具时，必须继续正确调整 `MISE_LOCKED` 参数

**Scope:**
所有不涉及 CI 环境中同一 step 内工具可用性的场景都应完全不受影响。这包括：

- 本地开发环境的工具安装和使用
- 跨 step 的工具路径传递（已通过 `$GITHUB_PATH` 正常工作）
- 工具安装失败的错误处理流程

## Hypothesized Root Cause

基于 bug 描述和代码分析，最可能的问题是：

1. **单向写入机制**: `run_mise()` 函数在 CI 环境中将路径写入 `$GITHUB_PATH` 文件，但没有同步更新当前 shell 的 `$PATH` 环境变量。GitHub Actions 的 `GITHUB_PATH` 机制是异步的，只在 step 结束后由 runner 读取并应用到下一个 step。

2. **缺少立即同步逻辑**: 当前代码在写入 `$GITHUB_PATH` 后没有执行 `export PATH="<new_path>:$PATH"` 操作，导致当前 shell 会话无法感知新添加的路径。

3. **时序问题**: 代码逻辑是：
   - 安装工具 → 写入 `$GITHUB_PATH` → 返回
   - 但缺少：安装工具 → 写入 `$GITHUB_PATH` → 读取 `$GITHUB_PATH` → 更新当前 `$PATH`

4. **幂等性考虑不足**: 虽然代码检查了路径是否已在 `$GITHUB_PATH` 文件中，但没有确保当前 shell 的 `$PATH` 也包含这些路径（可能因为 shell 重启或环境变化导致不一致）。

## Correctness Properties

Property 1: Bug Condition - 同步 GITHUB_PATH 到当前 Shell PATH

_For any_ 在 CI 环境中成功执行 `run_mise install` 的场景，修复后的函数 SHALL 在写入 `$GITHUB_PATH` 文件后，立即读取该文件的所有路径并将其添加到当前 shell 的 `export PATH` 中，确保工具在同一 shell 会话中立即可用。

Validates: Requirements 2.1, 2.2, 2.3, 2.4

Property 2: Preservation - 非 CI 环境和幂等性

_For any_ 不满足 bug condition 的场景（非 CI 环境、路径已存在、安装失败等），修复后的代码 SHALL 产生与原始代码完全相同的行为，保持所有现有的性能优化、错误处理和幂等性检查。

Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8

## Fix Implementation

### Changes Required

假设我们的根因分析正确：

**File**: `.unirtm.toml`

**Function**: `run_mise()`

**Specific Changes**:

1. **添加 GITHUB_PATH 同步函数**: 在 `run_mise()` 函数后添加一个新的辅助函数 `_sync_github_path_to_current_shell()`，负责读取 `$GITHUB_PATH` 文件并将路径同步到当前 shell 的 `$PATH`

2. **在写入 GITHUB_PATH 后调用同步函数**: 在 `run_mise()` 函数中，每次写入 `$GITHUB_PATH` 文件后（第 752 行和第 766 行），立即调用 `_sync_github_path_to_current_shell()` 函数

3. **实现幂等性检查**: 同步函数必须检查路径是否已在当前 `$PATH` 中，避免重复添加（使用 `case ":$PATH:" in *":$new_path:"*) ;; esac` 模式）

4. **处理路径格式**: 确保路径格式正确处理（去除尾部换行符、处理空行、处理 Windows 路径格式）

5. **添加调试日志**: 在同步操作时添加 `log_debug` 日志，便于排查问题

### Pseudocode for Sync Function

```
FUNCTION _sync_github_path_to_current_shell()
  INPUT: none (reads from $GITHUB_PATH environment variable)
  OUTPUT: none (modifies $PATH environment variable)

  IF $GITHUB_PATH is empty OR file does not exist THEN
    RETURN
  END IF

  # Read all paths from GITHUB_PATH file
  FOR EACH line IN read_file($GITHUB_PATH) DO
    # Skip empty lines
    IF line is empty THEN
      CONTINUE
    END IF

    # Remove trailing whitespace/newlines
    path := trim(line)

    # Check if path already in current $PATH (idempotent)
    IF ":$PATH:" CONTAINS ":$path:" THEN
      CONTINUE
    END IF

    # Add to current shell PATH
    export PATH="$path:$PATH"
    log_debug("Synced GITHUB_PATH to current shell: $path")
  END FOR
END FUNCTION
```

### Integration Points

修改后的 `run_mise()` 函数在以下两个位置调用同步函数：

**Location 1**: 在写入工具 bin 目录到 `$GITHUB_PATH` 后（约第 752 行）

```sh
if [ -n "${GITHUB_PATH:-}" ]; then
  if ! grep -qxF "${_TOOL_BIN_DIR:-}/bin" "${GITHUB_PATH:-}" 2>/dev/null; then
    echo "${_TOOL_BIN_DIR:-}/bin" >>"${GITHUB_PATH:-}"
    log_debug "Persisted tool bin to GITHUB_PATH: ${_TOOL_BIN_DIR:-}/bin"
    # NEW: Sync to current shell immediately
    _sync_github_path_to_current_shell
  fi
fi
```

**Location 2**: 在写入 mise shims 目录到 `$GITHUB_PATH` 后（约第 766 行）

```sh
if [ -n "${GITHUB_PATH:-}" ] && [ -n "${_G_MISE_SHIMS_BASE:-}" ]; then
  if ! grep -qxF "${_G_MISE_SHIMS_BASE:-}" "${GITHUB_PATH:-}" 2>/dev/null; then
    echo "${_G_MISE_SHIMS_BASE:-}" >>"${GITHUB_PATH:-}"
    log_debug "Persisted mise shims to GITHUB_PATH: ${_G_MISE_SHIMS_BASE:-}"
    # NEW: Sync to current shell immediately
    _sync_github_path_to_current_shell
  fi
fi
```

## Testing Strategy

### Validation Approach

测试策略遵循两阶段方法：首先在未修复的代码上运行探索性测试以确认 bug 存在，然后验证修复后的代码正确工作并保持现有行为不变。

### Exploratory Bug Condition Checking

**Goal**: 在实施修复之前，在未修复的代码上演示 bug。确认或反驳根因分析。如果反驳，需要重新假设。

**Test Plan**: 编写测试模拟 CI 环境，设置 `GITHUB_PATH` 环境变量，执行 `run_mise install` 安装工具，然后立即检查当前 shell 的 `$PATH` 是否包含工具路径。在未修复的代码上运行这些测试以观察失败并理解根因。

**Test Cases**:

1. **Same Step Tool Availability Test**: 在 CI 环境中安装 `pipx:zizmor`，立即调用 `resolve_bin zizmor`（在未修复代码上将失败）
2. **GITHUB_PATH Write Test**: 验证路径被写入 `$GITHUB_PATH` 文件，但当前 `$PATH` 不包含该路径（在未修复代码上将失败）
3. **Mise Shims Sync Test**: 安装工具后，检查 `$_G_MISE_SHIMS_BASE` 是否在当前 `$PATH` 中（在未修复代码上将失败）
4. **Multiple Tools Test**: 连续安装多个工具，检查所有工具路径是否都在当前 `$PATH` 中（在未修复代码上将失败）

**Expected Counterexamples**:

- 工具路径存在于 `$GITHUB_PATH` 文件中，但不在当前 shell 的 `$PATH` 环境变量中
- `resolve_bin` 无法找到刚安装的工具
- 可能原因：缺少从 `$GITHUB_PATH` 到当前 `$PATH` 的同步机制

### Fix Checking

**Goal**: 验证对于所有满足 bug condition 的输入，修复后的函数产生预期行为。

**Pseudocode:**

```
FOR ALL context WHERE isBugCondition(context) DO
  result := run_mise_fixed("install", context.tool)
  ASSERT result.success = true
  ASSERT context.toolBinPath IN current_shell_PATH
  ASSERT context.toolBinPath IN GITHUB_PATH_file
  ASSERT resolve_bin(context.tool) returns valid_path
END FOR
```

**Test Cases**:

1. **Immediate Tool Availability**: 安装工具后，立即调用 `command -v <tool>` 应返回有效路径
2. **PATH Synchronization**: 验证 `$GITHUB_PATH` 文件中的所有路径都存在于当前 `$PATH` 中
3. **Resolve Bin Success**: 安装工具后，`resolve_bin <tool>` 应立即返回有效路径
4. **Check Env Success**: 执行 `make setup && make install && make check-env` 应全部通过

### Preservation Checking

**Goal**: 验证对于所有不满足 bug condition 的输入，修复后的函数产生与原始函数相同的结果。

**Pseudocode:**

```
FOR ALL context WHERE NOT isBugCondition(context) DO
  ASSERT run_mise_original(context) = run_mise_fixed(context)
END FOR
```

**Testing Approach**: 推荐使用基于属性的测试进行 preservation checking，因为：

- 它自动生成跨输入域的许多测试用例
- 它捕获手动单元测试可能遗漏的边缘情况
- 它为所有非 buggy 输入提供强有力的保证，确保行为不变

**Test Plan**: 首先在未修复的代码上观察非 CI 环境和其他场景的行为，然后编写基于属性的测试捕获该行为。

**Test Cases**:

1. **Non-CI Environment Preservation**: 在本地开发环境中安装工具，验证行为与修复前完全相同（不依赖 `$GITHUB_PATH`）
2. **Idempotency Preservation**: 重复安装同一工具，验证路径不会重复添加到 `$PATH`
3. **Error Handling Preservation**: 模拟安装失败、超时等场景，验证错误处理逻辑不变
4. **ALF Mechanism Preservation**: 安装 `go:` 前缀工具，验证 Adaptive Lock Forgiveness 机制正常工作
5. **Backend Manager Check Preservation**: 安装 `cargo:*`、`npm:*` 工具，验证依赖检查逻辑不变
6. **Cross-Step PATH Persistence**: 在不同 step 中验证 `$GITHUB_PATH` 机制继续正常工作

### Unit Tests

- 测试 `_sync_github_path_to_current_shell()` 函数的幂等性（重复调用不会重复添加路径）
- 测试空 `$GITHUB_PATH` 文件的处理
- 测试包含空行和尾部换行符的 `$GITHUB_PATH` 文件
- 测试 Windows 路径格式的处理（如果适用）
- 测试同步函数在 `$GITHUB_PATH` 不存在时的行为

### Property-Based Tests

- 生成随机工具列表，验证所有工具安装后路径都在当前 `$PATH` 中
- 生成随机 CI/非 CI 环境配置，验证行为正确性
- 生成随机路径顺序，验证幂等性（路径不会重复）
- 测试大量工具安装场景，验证性能和正确性

### Integration Tests

- 完整 CI workflow 测试：`make setup && make install && make check-env` 在单个 step 中全部通过
- 跨 step 测试：验证第一个 step 安装的工具在第二个 step 中可用
- 混合场景测试：部分工具在 `.mise.toml` 中，部分动态安装，验证所有工具都可用
- 真实 CI 环境测试：在 GitHub Actions 中运行完整 workflow，验证所有安全扫描工具正常工作
