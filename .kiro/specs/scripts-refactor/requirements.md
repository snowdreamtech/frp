# Scripts 重构需求文档

## 1. 项目概述

### 1.1 背景

当前 `scripts/` 目录包含跨平台自动化脚本，用于项目设置、依赖管理、代码质量检查等。现有实现存在以下问题：

- `resolve_bin` 函数在复杂环境下可能挂起
- JSON 解析使用 awk，在复杂数据结构下不够健壮
- 缺少统一的超时机制
- 进程管理和清理不够完善

### 1.2 目标

重构 `.unirtm.toml` 和相关模块，实现：

1. **零挂起保证**：所有可能阻塞的操作必须有超时机制
2. **健壮的 bin 解析**：在复杂环境下可靠地定位可执行文件
3. **优雅的超时处理**：超时后正确清理进程，避免僵尸进程
4. **高性能 JSON 解析**：使用 Node.js/Python 替代 awk

## 2. 核心需求

### 2.1 resolve_bin 函数重构

#### 2.1.1 当前问题

```sh
# 当前实现的问题：
# 1. mise which 可能挂起（网络问题、配置错误）
# 2. find 命令在大目录树中很慢
# 3. awk JSON 解析不够健壮
_MW=$(mise which "${_BIN:-}" 2>/dev/null) || true
_FOUND_BIN=$(find "${_MC_PATH:-}" -maxdepth 3 -name "${_BIN:-}" -type f -perm +111 2>/dev/null | head -n 1) || true
```

#### 2.1.2 新需求

- **超时保护**：所有外部命令调用必须有超时（默认 5 秒）
- **分层查找策略**：
  1. 本地缓存（venv, node_modules）- 无超时
  2. 系统 PATH - 快速查找
  3. mise 元数据 - 带超时
  4. 文件系统搜索 - 带超时和深度限制
- **失败降级**：每层失败后优雅降级到下一层
- **调试日志**：记录每层查找的耗时和结果

### 2.2 JSON 解析优化

#### 2.2.1 当前问题

```sh
# awk 解析 JSON 的问题：
# 1. 不支持嵌套结构
# 2. 转义字符处理不完整
# 3. 大文件可能卡住
_MISE_VER_OUT=$(echo "${_G_MISE_LS_JSON_CACHE:-}" | awk -v plugin="${_M_PLUGIN:-}" '...')
```

#### 2.2.2 新需求

- **使用 Node.js 或 Python**：
  - 优先使用 Node.js（项目已有依赖）
  - Python 作为后备（系统通常预装）
  - awk 作为最后的降级方案
- **超时机制**：JSON 解析必须在 3 秒内完成
- **错误处理**：解析失败时返回空值，不中断脚本

### 2.3超时机制标准化

#### 2.3.1 统一超时函数

创建 `run_with_timeout_robust` 函数：

- 支持 `timeout`/`gtimeout` 命令
- Bash 原生超时实现（后备）
- 进程组清理（避免僵尸进程）
- 信号处理（SIGTERM → SIGKILL 升级）

#### 2.3.2 超时配置

```sh
# 默认超时值（秒）
TIMEOUT_RESOLVE_BIN=5      # bin 解析
TIMEOUT_JSON_PARSE=3       # JSON 解析
TIMEOUT_MISE_WHICH=5       # mise which 命令
TIMEOUT_FIND_BINARY=10     # 文件系统搜索
TIMEOUT_NETWORK=30         # 网络操作
```

### 2.4 进程管理增强

#### 2.4.1 进程清理

- 使用进程组（`setsid` 或 `()`）
- 超时后发送 SIGTERM，等待 2 秒
- 仍未退出则发送 SIGKILL
- 清理所有子进程

#### 2.4.2 僵尸进程预防

- 使用 `wait` 正确回收子进程
- trap EXIT 确保清理
- 记录未清理的进程（调试模式）

## 3. 性能要求

### 3.1 响应时间

- `resolve_bin`（缓存命中）：< 10ms
- `resolve_bin`（mise 查找）：< 100ms
- `resolve_bin`（文件系统搜索）：< 500ms
- JSON 解析（< 1MB）：< 50ms
- 超时触发后清理：< 3 秒

### 3.2 资源使用

- 内存：单个函数调用 < 10MB
- CPU：避免 100% 占用超过 1 秒
- 文件描述符：正确关闭所有打开的 fd

## 4. 兼容性要求

### 4.1 平台支持

- Linux（Debian, RedHat, Alpine）
- macOS（Intel, Apple Silicon）
- Windows（Git Bash, MSYS2, WSL）

### 4.2 Shell 兼容性

- POSIX sh（主要实现）
- Bash 4.0+（高级特性）
- 避免 Bash 5.0+ 特性

### 4.3 工具依赖

- **必需**：sh, find, grep, sed
- **推荐**：timeout/gtimeout, Node.js/Python
- **可选**：jq（JSON 解析后备）

## 5. 测试要求

### 5.1 单元测试

使用 BATS（Bash Automated Testing System）：

- `resolve_bin` 各层查找逻辑
- 超时机制触发和清理
- JSON 解析正确性
- 错误处理和降级

### 5.2 集成测试

- 完整的 `make setup` 流程
- CI 环境模拟
- 网络故障模拟
- 超时场景模拟

### 5.3 性能测试

- 基准测试（benchmark）
- 压力测试（大量并发调用）
- 内存泄漏检测

## 6. 文档要求

### 6.1 代码文档

- 每个函数必须有 Purpose/Params/Returns/Examples
- 复杂逻辑必须有内联注释
- 超时值必须注释原因

### 6.2 用户文档

- 更新 `scripts/README.md`
- 添加故障排查指南
- 性能调优建议

## 7. 迁移策略

### 7.1 向后兼容

- 保持现有函数签名
- 新增可选参数（不破坏现有调用）
- 废弃的函数保留 6 个月

### 7.2 渐进式重构

1. **Phase 1**：添加新的超时函数
2. **Phase 2**：重构 `resolve_bin`
3. **Phase 3**：优化 JSON 解析
4. **Phase 4**：全面测试和文档更新

## 8. 验收标准

### 8.1 功能验收

- [ ] 所有现有脚本正常运行
- [ ] 超时机制在所有平台生效
- [ ] 无僵尸进程残留
- [ ] JSON 解析 100% 正确

### 8.2 性能验收

- [ ] `resolve_bin` 平均耗时 < 100ms
- [ ] 超时后 3 秒内完成清理
- [ ] 内存使用无泄漏

### 8.3 质量验收

- [ ] 所有测试通过（单元 + 集成）
- [ ] ShellCheck 无警告
- [ ] 代码覆盖率 > 80%

## 9. 风险和缓解

### 9.1 风险识别

| 风险                   | 影响 | 概率 | 缓解措施     |
| ---------------------- | ---- | ---- | ------------ |
| 超时机制在某些平台失效 | 高   | 中   | 多层后备方案 |
| Node.js/Python 不可用  | 中   | 低   | awk 降级方案 |
| 性能回归               | 中   | 中   | 基准测试对比 |
| 破坏现有脚本           | 高   | 低   | 全面回归测试 |

### 9.2 回滚计划

- 保留原始 `common.sh` 为 `common.sh.backup`
- Git tag 标记重构前版本
- 提供快速回滚脚本

## 10. 时间线

### 10.1 开发计划

- Week 1: 超时机制和 JSON 解析
- Week 2: resolve_bin 重构
- Week 3: 测试和文档
- Week 4: Code Review 和发布

### 10.2 里程碑

- M1: 超时函数完成（Day 3）
- M2: JSON 解析完成（Day 7）
- M3: resolve_bin 完成（Day 14）
- M4: 测试覆盖 80%（Day 21）
- M5: 发布 v1.0（Day 28）
