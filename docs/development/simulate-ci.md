# 模拟 CI 环境

本文档说明如何在本地模拟 CI 环境，用于测试 CI 特定的行为和脚本。

## 快速开始

### 方法 1: 使用模拟脚本（推荐）

```bash
# 启用 CI 模式
source scripts/simulate-ci.sh

# 运行测试
unirtm run verify
unirtm run audit

# 禁用 CI 模式
source scripts/simulate-ci.sh reset
```

### 方法 2: 手动设置环境变量

```bash
# 启用 CI 模式
export CI=true
export GITHUB_ACTIONS=true
export _G_IS_CI=1

# 运行测试
unirtm run verify

# 禁用 CI 模式（关闭终端或 unset）
unset CI GITHUB_ACTIONS _G_IS_CI
```

### 方法 3: 单次命令模拟

```bash
# 仅在单个命令中模拟 CI
CI=true GITHUB_ACTIONS=true unirtm run verify

# 或使用 env 命令
env CI=true GITHUB_ACTIONS=true unirtm run audit
```

## CI 环境检测机制

项目使用 `detect_ci_platform()` 和 `is_ci_env()` 函数检测 CI 环境。

### 支持的 CI 平台

检测优先级（从高到低）：

1. **Forgejo Actions**: `FORGEJO_ACTIONS=true`
2. **Gitea Actions**: `GITEA_ACTIONS=true`
3. **GitHub Actions**: `GITHUB_ACTIONS=true`
4. **GitLab CI**: `GITLAB_CI=true`
5. **Drone CI**: `DRONE=true`
6. **Woodpecker CI**: `WOODPECKER_CI=true` 或 `CI=woodpecker`
7. **CircleCI**: `CIRCLECI=true`
8. **Travis CI**: `TRAVIS=true`
9. **Azure Pipelines**: `TF_BUILD=true`
10. **Jenkins**: `JENKINS_URL` 非空
11. **通用 CI**: `CI=true`
12. **本地环境**: 以上都不满足

### 核心环境变量

| 变量 | 用途 | CI 值 | 本地值 |
|------|------|-------|--------|
| `CI` | 通用 CI 标识 | `true` | 未设置 |
| `GITHUB_ACTIONS` | GitHub Actions 标识 | `true` | 未设置 |
| `_G_IS_CI` | 缓存的 CI 状态 | `1` | `0` |
| `GITHUB_STEP_SUMMARY` | CI 摘要文件路径 | GitHub 提供 | `.ci_summary.log` |

## CI 模式下的行为差异

### 1. 工具安装

**本地模式**:

- 缺失的工具会被优雅跳过（`⏭️ Skipped`）
- 不会因为工具缺失而失败

**CI 模式**:

- 缺失的必需工具会导致失败（`❌ Failed`）
- 严格验证工具的可执行性
- 强制刷新 unirtm 缓存

### 2. 安全扫描

**本地模式**:

- 重量级扫描工具（如 trivy, osv-scanner）会被跳过
- 避免长时间等待和网络依赖

**CI 模式**:

- 所有安全扫描工具都会运行
- 扫描失败会导致构建失败

### 3. 测试执行

**本地模式**:

- 测试失败可能只是警告
- 允许部分测试失败以便快速迭代

**CI 模式**:

- 测试失败会导致构建失败
- 严格的质量门控

### 4. 网络配置

**本地模式**:

- 可能使用镜像加速（如 npm 镜像、pip 镜像）
- `ENABLE_GITHUB_PROXY` 可能为 1

**CI 模式**:

- 使用官方源（npm, pip, go proxy）
- `ENABLE_GITHUB_PROXY` 为 0
- 避免镜像不一致问题

## 测试场景

### 场景 1: 测试工具安装脚本

```bash
# 启用 CI 模式
source scripts/simulate-ci.sh

# 测试 setup 脚本（CI 模式下会严格验证）
unirtm run setup

# 检查是否所有工具都正确安装
unirtm run verify
```

### 场景 2: 测试安全扫描

```bash
# 启用 CI 模式
source scripts/simulate-ci.sh

# 运行完整的安全审计（包括重量级工具）
unirtm run audit

# 查看 CI 摘要
cat .ci_summary.log
```

### 场景 3: 测试 pre-commit hooks

```bash
# 启用 CI 模式
source scripts/simulate-ci.sh

# 运行所有 pre-commit hooks
pre-commit run --all-files

# 禁用 CI 模式
source scripts/simulate-ci.sh reset
```

### 场景 4: 测试特定工具的 CI 行为

```bash
# 测试 yamllint 在 CI 模式下的行为
CI=true yamllint .

# 测试 taplo 在 CI 模式下的行为
CI=true taplo fmt --check .
```

## 调试技巧

### 1. 查看 CI 检测结果

```bash
# 方法 1: 使用 detect_ci_platform
source scripts/lib/common.sh
detect_ci_platform

# 方法 2: 使用 is_ci_env
source scripts/lib/common.sh
if is_ci_env; then
  echo "Running in CI"
else
  echo "Running locally"
fi
```

### 2. 查看环境变量

```bash
# 查看所有 CI 相关变量
env | grep -E "^(CI|GITHUB_|GITLAB_|_G_IS_CI)" | sort
```

### 3. 启用详细日志

```bash
# 启用 CI 模式并开启详细日志
source scripts/simulate-ci.sh
export VERBOSE=2
export DEBUG_RESOLVE_BIN=1

# 运行命令查看详细输出
unirtm run verify
```

### 4. 比较本地和 CI 行为

```bash
# 本地模式运行
unirtm run verify > local.log 2>&1

# CI 模式运行
source scripts/simulate-ci.sh
unirtm run verify > ci.log 2>&1

# 比较差异
diff local.log ci.log
```

## 常见问题

### Q1: 为什么模拟 CI 后某些工具安装失败？

**A**: CI 模式下会严格验证工具的可执行性。检查：

- 工具是否在 `.unirtm.toml` 中正确配置
- 工具版本是否与 `scripts/lib/versions.sh` 一致
- unirtm 缓存是否需要刷新：`unirtm cache clear`

### Q2: 如何永久禁用 CI 模式？

**A**: 有几种方法：

```bash
# 方法 1: 使用脚本
source scripts/simulate-ci.sh reset

# 方法 2: 手动 unset
unset CI GITHUB_ACTIONS _G_IS_CI

# 方法 3: 重新打开终端
```

### Q3: CI 模式下网络请求很慢怎么办？

**A**: CI 模式默认使用官方源。如果需要加速：

```bash
# 临时启用镜像（不推荐，可能导致不一致）
export ENABLE_GITHUB_PROXY=1
export NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
```

### Q4: 如何测试特定 CI 平台的行为？

**A**: 设置对应平台的环境变量：

```bash
# 模拟 GitLab CI
export CI=true
export GITLAB_CI=true

# 模拟 Gitea Actions
export CI=true
export GITEA_ACTIONS=true
```

## 最佳实践

1. **提交前测试**: 在提交代码前，使用 CI 模式运行一次完整测试

   ```bash
   source scripts/simulate-ci.sh
   unirtm run verify && unirtm run audit
   ```

2. **隔离测试**: 在单独的终端窗口中启用 CI 模式，避免影响正常开发

3. **清理环境**: 测试完成后记得禁用 CI 模式

   ```bash
   source scripts/simulate-ci.sh reset
   ```

4. **使用 Docker**: 对于完全隔离的 CI 环境测试，使用 devcontainer

   ```bash
   # 在 devcontainer 中自动模拟 CI
   docker compose -f .devcontainer/docker-compose.yml run --rm devcontainer
   ```

## 相关文件

- `scripts/simulate-ci.sh` - CI 模拟脚本
- `scripts/lib/common.sh` - CI 检测函数（`detect_ci_platform`, `is_ci_env`）
- `.github/workflows/` - GitHub Actions 工作流配置
- `.ci_summary.log` - 本地 CI 摘要文件

## 参考资料

- [GitHub Actions 环境变量](https://docs.github.com/en/actions/learn-github-actions/variables)
- [GitLab CI 环境变量](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)
- 项目规则: `.agent/rules/01-general.md` - 环境权重分层
- 项目规则: `.agent/rules/06-ci-testing.md` - CI 测试策略
