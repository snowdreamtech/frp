# UniRTM `trust` 命令实施计划

## 1. 目标与动机

防御“供应链投毒”，防止用户在克隆恶意开源仓库后，由于 UniRTM 自动加载仓库根目录下的 `.unirtm.toml` 配置文件而导致恶意工具链路径覆盖或被注入恶意环境变量。

我们需要实现类似 `mise trust` 的机制：对于非系统级和非全局的本地配置文件（Project/Local），在初次读取时进行安全拦截，要求用户显式授权。

## 2. 设计方案

### 2.1 信任管理器 (TrustManager)

新增 `internal/config/trust.go` 文件，封装信任状态的管理：

- **存储位置**：`~/.config/unirtm/trusted_configs` （按行存储已信任配置文件的绝对路径）。
- **核心方法**：
  - `IsTrusted(path string) bool`：判断给定路径是否受信任。
  - `Trust(path string) error`：将绝对路径加入白名单。
  - `Untrust(path string) error`：将路径从白名单移除。

### 2.2 拦截逻辑 (manager.go)

修改 `internal/config/manager.go`：
在 `LoadHierarchy` 中，当加载 `Project` (`./unirtm.toml`) 和 `Local` (`./.unirtm.local.toml`) 层级的配置文件时，调用 `IsTrusted()` 检查。

- 如果不受信任：通过 `pterm.Warning` 向用户打印显眼的警告，提示使用 `unirtm trust <path>` 来信任该文件，**并跳过该文件的加载**（不抛出阻断性 Error 以免整个 UniRTM 瘫痪，但忽略配置）。
- 系统和全局配置文件 (`/etc/unirtm/*`, `~/.config/unirtm/*`) 默认受信任。

### 2.3 CLI 命令

- 新增 `cmd/26.trust.go`：实现 `unirtm trust [path]` 命令。如果用户不提供路径，则默认信任当前目录下的 `unirtm.toml` / `.unirtm.toml`。
- 新增 `cmd/27.untrust.go`：实现 `unirtm untrust [path]`，用于撤销信任。

## 3. 实施步骤

1. [ ] 创建 `internal/config/trust.go` 并实现 `TrustManager`。
2. [ ] 在 `internal/config/manager.go` 的 `LoadHierarchy` 流程中注入拦截逻辑。
3. [ ] 创建 CLI `cmd/26.trust.go` 和 `cmd/27.untrust.go`。
4. [ ] 添加并运行对应的测试，提交代码。
