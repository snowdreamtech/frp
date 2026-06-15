# UniRTM Self-Update 实现方案

## 背景与目标

针对 Go 语言生态中缺乏长期维护且完全可靠的自更新第三方库（如 `go-update`）的现状，并遵循 UniRTM “高性能、可审计性、显式性” 的哲学，我们决定摒弃第三方依赖，采用**分阶段、全自研的“双轨制升级策略”**：

### 阶段一：被动更新检测器 (Update Notifier)

**这是业界最主流的做法（如 gh, kubectl, mise）**。系统在后台静默检查 GitHub Releases API，若发现新版本，则在命令执行完毕后友好的提示用户。这能完美兼容 Homebrew、APT 等系统包管理器，将控制权交还给用户。

### 阶段二：原生手撸的原子自更新 (Native Self-Updater)

实现 `unirtm self-update` 命令，不依赖任何第三方库。采用纯 Go 原生实现，执行**剃刀式升级（Razor Upgrade）**哲学：

> **剃刀原则**：尽可能少地假设，每一步都有验证，升级要么完整成功，要么完整回滚，绝不留下半残状态。

---

## 用户审查项

> [!IMPORTANT]
> 以下两点需要用户在实现前确认：
>
> 1. **发布产物格式**：当前 goreleaser 配置发布的是 `.tar.gz` 压缩包，还是单个裸二进制？解压逻辑依赖这一点。
> 2. **Checksum 文件格式**：GitHub Release 中是否有 `checksums.txt`（SHA-256）？格式是 `goreleaser` 标准格式（`<hash>  <filename>`）还是其他格式？

---

## 核心设计：剃刀式升级流程

### 升级状态机

```
IDLE
  │
  ▼ check
CHECK_VERSION ──(已是最新)──→ DONE
  │
  ▼ download
DOWNLOAD ──(失败)──→ CLEANUP → DONE (no change)
  │
  ▼ verify_checksum
VERIFY ──(失败)──→ CLEANUP → DONE (no change)
  │
  ▼ smoke_test
SMOKE_TEST ──(失败)──→ CLEANUP → DONE (no change)
  │
  ▼ backup_current
BACKUP ──(失败)──→ CLEANUP → DONE (no change)
  │
  ▼ atomic_replace
REPLACE ──(失败)──→ RESTORE_BACKUP → DONE (rolled back)
  │
  ▼ verify_replaced
VERIFY_NEW ──(失败)──→ RESTORE_BACKUP → DONE (rolled back)
  │
  ▼ cleanup_backup
DONE (success)
```

### 关键约束（"剃刀"原则体现）

| 原则 | 具体措施 |
|------|---------|
| **最少假设** | 不假设网络可靠、不假设磁盘可写、不假设权限 |
| **每步验证** | 下载→校验→烟测→替换→再验证，共 5 个门控 |
| **原子替换** | Unix: `rename()`；Windows: 重命名 + 延迟删除 |
| **自动回滚** | 任何步骤失败，立即执行 `RESTORE_BACKUP` |
| **幂等性** | 重复执行同一版本的 self-update 无副作用 |

---

## 命令设计

```
unirtm self-update [flags]

Flags:
  --version string   升级到指定版本（默认: latest）
  --check            只检查是否有新版本，不执行升级
  --rollback         回滚到上一次保留的备份
  --force            即使版本相同也强制重新安装
  --dry-run          模拟升级流程，不实际修改文件
  --timeout int      下载超时（秒，默认 300）
```

### 使用示例

```bash
# 检查是否有新版本
unirtm self-update --check

# 升级到最新版本
unirtm self-update

# 升级到指定版本
unirtm self-update --version 1.2.0

# 出问题时回滚
unirtm self-update --rollback

# 模拟整个升级流程（不修改文件）
unirtm self-update --dry-run
```

---

## 模块分解

### 新增文件

#### [NEW] `cmd/25.selfupdate.go`

CLI 层，解析标志，委托给 service 层。

#### [NEW] `internal/service/selfupdate.go`

核心升级逻辑，包含：

- `SelfUpdateManager` struct
- `Check(ctx) (*ReleaseInfo, error)` — 查询最新版本
- `Update(ctx, opts) (*UpdateResult, error)` — 执行升级

- `Rollback(ctx) error` — 回滚到备份

#### [NEW] `internal/service/selfupdate_test.go`

单元测试（Mock GitHub API、Mock 文件系统操作）。

#### [NEW] `tests/integration/selfupdate_test.go`

集成测试：使用 temp 目录模拟完整升级流程。

---

## 各阶段详细实现

### 阶段 1：版本检查

```go
// ReleaseInfo 代表 GitHub Releases API 响应中的关键字段
type ReleaseInfo struct {
    TagName     string // "v1.2.0"
    Version     string // "1.2.0" (去掉 v 前缀)
    PublishedAt time.Time
    Assets      []ReleaseAsset
    ChecksumURL string // URL of checksums.txt asset
}

// Check 查询 GitHub Releases API 获取最新版本
// 使用 SQLite cache 缓存 1 小时，减少 API 调用
func (m *SelfUpdateManager) Check(ctx context.Context) (*ReleaseInfo, error) {
    // 1. 查询缓存（TTL 1 小时）
    // 2. 若缓存命中，直接返回
    // 3. 请求 https://api.github.com/repos/snowdreamtech/unirtm/releases/latest
    // 4. 写入缓存
    // 5. 返回 ReleaseInfo
}
```

### 阶段 2：平台感知与包管理器检测

**在实际下载前，检测当前二进制的安装来源：**

```go
// DetectInstallSource 检测当前二进制的安装方式
func detectInstallSource(binaryPath string) InstallSource {
    // Homebrew: 路径包含 /Cellar/ 或 /homebrew/
    // Scoop:    路径包含 \scoop\apps\
    // APT/RPM:  路径为 /usr/bin/ 或 /usr/local/bin/ 且存在包管理器锁
    // Go install: 路径包含 /go/bin/
    // 直接安装: 其他情况
}

type InstallSource int
const (
    InstallSourceDirect   InstallSource = iota
    InstallSourceHomebrew
    InstallSourceScoop
    InstallSourceApt
    InstallSourceGoInstall
)
```

如果检测到非直接安装，**输出警告并中止**：

```
⚠️  UniRTM 检测到您通过 Homebrew 安装。
    请使用 Homebrew 升级以避免状态不一致：
      brew upgrade unirtm

    如果您确定要强制使用 self-update，请添加 --force 标志。
```

### 阶段 3：下载与校验

```go
// DownloadAsset 下载目标平台的二进制压缩包
// 使用现有的 download.HTTPDownloader：
//   - 5 次重试 + 指数退避
//   - 连接超时 10s，读超时 300s
//   - 写入临时文件（同目录下的 .new 后缀）
func (m *SelfUpdateManager) downloadAsset(ctx context.Context, asset ReleaseAsset) (string, error)

// VerifyChecksum 下载 checksums.txt 并验证
func (m *SelfUpdateManager) verifyChecksum(ctx context.Context, filePath string, checksumURL string) error
```

### 阶段 4：烟测（Smoke Test）

**这是"剃刀"原则最关键的一步：替换前验证新二进制可运行。**

```go
// smokeTest 运行新二进制的基本自检
func (m *SelfUpdateManager) smokeTest(ctx context.Context, newBinaryPath string) error {
    // 1. chmod +x newBinaryPath
    // 2. 执行 `<newBinaryPath> version --output json`
    // 3. 验证输出包含合法的版本字符串
    // 4. 超时 10 秒
}
```

### 阶段 5：原子替换

**Unix（Linux / macOS）：**

```
[当前二进制] → rename → [当前二进制.bak]
[新二进制.tmp] → rename → [当前二进制]

rename() 系统调用：
- 同一文件系统内：POSIX 保证原子性
- 跨文件系统（罕见）：先 copy + fsync，再 rename
```

**Windows：**

```
运行中的 .exe 不可直接替换。
解决方案：
  1. 将新 .exe 写为 unirtm.new.exe
  2. 创建一个 updater helper 脚本（.bat）：
     - 等待 unirtm 进程退出（使用 taskkill 或 PID 监控）
     - 执行 move /Y unirtm.new.exe unirtm.exe
     - 启动新 unirtm.exe --version 验证
  3. 告知用户重启终端后生效
```

### 阶段 6：替换后验证

```go
// verifyReplaced 验证替换后的二进制
func (m *SelfUpdateManager) verifyReplaced(ctx context.Context, binaryPath string, expectedVersion string) error {
    // 1. 执行 `<binaryPath> version --output json`
    // 2. 解析版本号
    // 3. 比较是否等于 expectedVersion
    // 失败则触发 Rollback
}
```

### 阶段 7：备份管理

```go
// backupDir: ~/.local/share/unirtm/backup/
//   unirtm.1.0.0.bak   ← 保留最近 2 个版本的备份
//   unirtm.1.1.0.bak

// Rollback 回滚到最近一次备份
func (m *SelfUpdateManager) Rollback(ctx context.Context) error {
    // 1. 找到最新的 .bak 文件
    // 2. 烟测验证备份可运行
    // 3. 原子替换回当前位置
    // 4. 验证回滚成功
}
```

---

## 升级结果数据结构

```go
type UpdateResult struct {
    PreviousVersion string
    NewVersion      string
    BinaryPath      string
    BackupPath      string
    Duration        time.Duration
    Source          InstallSource
}
```

---

## 跨平台关键点

| 问题 | Linux/macOS | Windows |
|------|-------------|---------|
| 替换运行中二进制 | ✅ Unix 允许（打开的文件 inode 不变）| ❌ 需要延迟替换 |
| 原子 rename | ✅ `syscall.Rename` 保证 | ⚠️ 同卷可用 `MoveFileEx` |
| 文件权限 | chmod 0755 | 无需 chmod |
| 备份路径 | `~/.local/share/unirtm/backup/` | `%APPDATA%\unirtm\backup\` |
| 临时文件 | 同目录 `.new` 后缀 | 同目录 `.new.exe` 后缀 |

---

## 与现有系统的集成

- **下载器**：直接复用 `internal/pkg/download.HTTPDownloader`（已有重试 + 校验）
- **数据库**：升级记录写入 `audit_log` 表（时间、旧版本、新版本、成功/失败）
- **缓存**：版本检查结果写入 `cache` 表（TTL 1h）
- **日志**：通过现有 zerolog 记录全过程

---

## 验证计划

### 单元测试

```bash
go test ./internal/service/ -run TestSelfUpdate -v
```

覆盖：

- `Check`：Mock HTTP，测试缓存命中 / 缓存穿透 / API 失败
- `smokeTest`：Mock exec，测试版本字符串解析
- `verifyChecksum`：测试 SHA-256 匹配 / 不匹配
- `detectInstallSource`：测试各平台路径识别

### 集成测试

```bash
go test ./tests/integration/ -run TestSelfUpdateIntegration -v
```

使用 temp 目录模拟：完整升级流程 → 回滚流程 → 校验失败中止流程

### 手动验证

```bash
# 1. 模拟升级（不修改文件）
unirtm self-update --dry-run

# 2. 强制重装当前版本（验证原子替换）
unirtm self-update --version $(unirtm version --short) --force

# 3. 验证回滚
unirtm self-update --rollback

# 4. 验证升级记录写入审计日志
unirtm doctor
```
