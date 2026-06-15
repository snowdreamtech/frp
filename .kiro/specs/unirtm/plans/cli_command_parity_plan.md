# CLI 命令对标 mise 补全计划

## 背景

通过与 `mise --help` 的系统性对比，UniRTM 目前已实现 22 个命令（✅），
部分支持 5 个（⚠️），但仍有 **20 个命令缺失**。
本规划将所有缺口命令按优先级分阶段补齐，使 UniRTM 达到与 mise 的命令完整性对等。

### 参考资料

- mise 命令参考：<https://mise.jdx.dev/cli/>
- 对比分析：`.kiro/specs/unirtm/unirtm_vs_mise_commands.md`

---

## User Review Required

> [!IMPORTANT]
> `env` 命令的现有实现与 mise 存在**根本性语义差异**：
>
> - mise `env`：导出激活的工具 PATH 变量，供 `eval "$(mise env)"` 使用，是 shell 集成的核心
> - unirtm `env`（当前）：仅打印版本信息和配置路径
>
> 修复此问题需要修改现有 `env` 命令行为，可能影响现有用户。请确认是否接受此变更。

<!-- separator -->

> [!NOTE]
> `tasks` 子命令（`tasks list/info/deps/edit/add`）将以新子命令组形式实现，
> 与现有 `run` 命令并存，不破坏已有功能。

---

## 命令覆盖现状

| mise 命令 | unirtm 命令 | 状态 |
|-----------|------------|------|
| `activate` | `activate` | ✅ |
| `tool-alias` | `alias` | ✅ |
| `backends` | — | ❌ |
| `bin-paths` | — | ❌ |
| `cache` | `cache` | ✅ |
| `completion` | `completion` | ✅ |
| `config` | `config` | ✅ |
| `deactivate` | `deactivate` | ✅ |
| `doctor` | `doctor` | ✅ |
| `en` | — | ❌ |
| `env` | `env` | ⚠️ 语义不同 |
| `exec` | `exec` | ✅ |
| `fmt` | — | ❌ |
| `generate` | — | ❌ |
| `implode` | — | ❌ |
| `edit` | — | ❌ |
| `install` | `install` | ✅ |
| `install-into` | — | ❌ |
| `latest` | — | ❌ |
| `link` | — | ❌ |
| `lock` | `lock` | ✅ |
| `ls` / `list` | `list` | ⚠️ 缺激活状态 |
| `ls-remote` | `search` | ⚠️ 功能近似 |
| `mcp` | — | ❌ |
| `outdated` | — | ❌ |
| `plugins` | `plugin` | ✅ |
| `prepare` | — | ❌ |
| `prune` | `prune` | ✅ |
| `registry` | — | ❌ |
| `reshim` | `reshim` | ✅ |
| `run` | `run` | ✅ |
| `search` | `search` | ⚠️ |
| `self-update` | — | ❌ |
| `set` | — | ❌ |
| `settings` | `settings` | ✅ |
| `shell` | `shell` | ✅ |
| `shell-alias` | — | ❌ |
| `sync` | `migrate` | ⚠️ |
| `tasks` | — | ❌ |
| `test-tool` | — | ❌ |
| `token` | — | ❌ |
| `tool` | — | ❌ |
| `tool-stub` | — | ❌ |
| `trust` | `trust` | ✅ |
| `uninstall` | `uninstall` | ✅ |
| `unset` | — | ❌ |
| `unuse` / `rm` | — | ❌ |
| `upgrade` / `up` | `update` | ⚠️ |
| `use` | `use` | ✅ |
| `version` | `version` | ✅ |
| `watch` | `watch` | ✅ |
| `where` | `where` | ✅ |
| `which` | `which` | ✅ |
| — | `migrate` | 🆕 UniRTM 独有 |

---

## Proposed Changes

---

### Phase 1：核心补全（高频刚需）

#### [MODIFY] `cmd/9.env.go` — `env` 命令语义升级

**现状**：打印版本信息和配置路径
**目标**：输出可被 `eval` 消费的 Shell 环境变量导出语句

```bash
# 使用方式（对标 mise）
eval "$(unirtm env)"

# 输出示例
export PATH="/home/user/.local/share/unirtm/installs/node/20.0.0/bin:$PATH"
export NODE_VERSION="20.0.0"
```

保留 `--json` 标志输出结构化数据，保留 `-v` 打印版本信息（迁移兼容）。

---

#### [NEW] `cmd/32.outdated.go` — `outdated` 命令

列出有新版本可用的工具。

```bash
unirtm outdated             # 列出所有过时工具
unirtm outdated node        # 检查指定工具
unirtm outdated --json      # JSON 输出
```

输出格式（对标 mise）：

```
Tool    Current  Latest   Backend
node    20.0.0   22.14.0  github
go      1.22.0   1.24.2   github
```

实现：调用各 backend 的 `GetLatestVersion()` 与已安装版本对比。

---

#### [NEW] `cmd/33.latest.go` — `latest` 命令

查询工具的最新可用版本号。

```bash
unirtm latest node          # 22.14.0
unirtm latest node --json
unirtm latest go 1.22       # 1.22.x 的最新补丁版
```

---

#### [MODIFY] `cmd/11.list.go` — `list` 命令增强

在已安装列表中增加「激活状态」列，显示当前 shim 指向的版本。

```
Tool    Version  Status    Install Path
node    22.14.0  active    ~/.local/share/unirtm/installs/node/22.14.0
node    20.0.0   —         ~/.local/share/unirtm/installs/node/20.0.0
go      1.24.2   active    ~/.local/share/unirtm/installs/go/1.24.2
```

---

#### [NEW] `cmd/34.set.go` — `set` / `unset` 命令

在 unirtm.toml 中读写环境变量（`direnv` 替代核心）。

```bash
unirtm set NODE_ENV=production      # 写入当前目录 unirtm.toml
unirtm set --global NODE_ENV=prod   # 写入全局配置
unirtm unset NODE_ENV               # 从配置文件删除
```

---

#### [NEW] `cmd/35.tool.go` — `tool` 命令

查询单个工具的完整信息。

```bash
unirtm tool node
# 输出：
# Tool:     node
# Backend:  github (nodejs/node)
# Installed: 20.0.0, 22.14.0
# Active:   22.14.0
# Shim:     ~/.local/share/unirtm/shims/node
# Config:   .unirtm.toml (line 3)
```

---

### Phase 2：工具链管理完善

#### [NEW] `cmd/36.bin-paths.go` — `bin-paths` 命令

列出所有激活 runtime 的 bin 目录（Shell hook 依赖此命令）。

```bash
unirtm bin-paths
# ~/.local/share/unirtm/installs/node/22.14.0/bin
# ~/.local/share/unirtm/installs/go/1.24.2/bin
# ~/.local/share/unirtm/shims
```

---

#### [NEW] `cmd/37.backends.go` — `backends` 命令

列出 UniRTM 已注册的所有 backend 及其状态。

```bash
unirtm backends
unirtm backends ls          # 别名
unirtm backends info github # 查看 github backend 详情
```

---

#### [NEW] `cmd/38.registry.go` — `registry` 命令

列出注册表中所有可安装的工具（backend 支持的全量列表）。

```bash
unirtm registry             # 分页列出所有工具
unirtm registry --search go # 过滤
unirtm registry --json
```

---

#### [NEW] `cmd/39.tasks.go` — `tasks` 子命令组

完整任务管理层（与已有 `run` 并存）。

```bash
unirtm tasks                # 等同 tasks list
unirtm tasks list           # 列出所有任务（含来源文件）
unirtm tasks info <task>    # 显示任务详情、依赖关系
unirtm tasks deps           # 显示任务依赖 DAG
unirtm tasks add <name>     # 在配置文件中添加新任务模板
unirtm tasks edit <task>    # 打开 $EDITOR 编辑任务
```

---

#### [NEW] `cmd/40.fmt.go` — `fmt` 命令

格式化 unirtm.toml / unirtm.yaml 配置文件。

```bash
unirtm fmt                  # 格式化当前目录配置
unirtm fmt --check          # 检查格式（CI 用，不修改）
```

---

#### [NEW] `cmd/41.link.go` — `link` 命令

将系统中已有的工具版本软链接进 UniRTM 管理体系。

```bash
unirtm link node 20.0.0 /usr/local/bin/node
unirtm link go 1.22.0 $(which go)
```

---

#### [NEW] `cmd/42.unuse.go` — `unuse` / `rm` / `remove` 命令

从 unirtm.toml 移除工具条目（`use` 的反操作）。

```bash
unirtm unuse node           # 从配置文件移除 node
unirtm rm node              # 别名
unirtm remove node          # 别名
```

---

### Phase 3：高级 / 实验性功能

#### [MODIFY] `cmd/unirtm_selfupdate_plan.md` → [NEW] `cmd/43.self-update.go`

更新 UniRTM 自身二进制（已有规划文档）。

```bash
unirtm self-update
unirtm self-update --version 1.2.0
```

---

#### [NEW] `cmd/44.implode.go` — `implode` 命令

彻底卸载 UniRTM 及所有数据目录（需要二次确认）。

```bash
unirtm implode
unirtm implode --yes        # 跳过确认
```

---

#### [NEW] `cmd/45.generate.go` — `generate` 命令

生成各类配置文件模板。

```bash
unirtm generate github-action    # 生成 GitHub Actions 工作流
unirtm generate pre-commit       # 生成 pre-commit hook 配置
unirtm generate shell-alias      # 生成 shell alias（u/m 等快捷命令）
```

---

#### [NEW] `cmd/46.en.go` — `en` 命令

在新的 sub-shell 中运行 UniRTM 环境（比 `activate` 更轻量）。

```bash
unirtm en                   # 打开已激活环境的新 shell
unirtm en -- bash -c "node --version"
```

---

#### [NEW] `cmd/47.shell-alias.go` — `shell-alias` 命令

管理 UniRTM 的 shell 别名（如 `u`、`m`）。

```bash
unirtm shell-alias          # 列出已配置别名
unirtm shell-alias add u    # 添加别名
unirtm shell-alias remove u # 删除别名
```

---

#### [NEW] `cmd/48.install-into.go` — `install-into` 命令

安装工具到自定义目标路径（monorepo / 沙箱场景）。

```bash
unirtm install-into ./tools node 20.0.0
```

---

#### [NEW] `cmd/49.edit.go` — `edit` 命令

打开 `$EDITOR` 编辑配置文件。

```bash
unirtm edit                 # 编辑当前目录配置
unirtm edit --global        # 编辑全局配置
```

---

#### [NEW] `cmd/50.token.go` — `token` 命令

显示 UniRTM 当前使用的 git provider token（调试用）。

```bash
unirtm token                # 显示当前 GitHub token（掩码）
unirtm token github         # 指定 provider
```

---

#### [NEW] `cmd/51.mcp.go` — `mcp` 命令（实验性）

运行 Model Context Protocol (MCP) 服务器，供 AI 工具调用。

```bash
unirtm mcp                  # 启动 MCP server（stdio 模式）
```

---

## Verification Plan

### 自动化测试

每个新命令需提供对应测试文件 `cmd/XX_test.go`，覆盖：

- 基本 flag 解析
- 正常输出格式（文本 / JSON）
- 错误路径（工具不存在、权限不足等）

### 集成测试

- `env` 升级：`eval "$(unirtm env)"` 测试 PATH 注入
- `outdated` + `latest`：mock backend 返回版本，验证对比逻辑
- `set` / `unset`：修改后验证 TOML 文件内容
- `tasks` 子命令：基于已有任务配置验证输出

### 手动验证

- 在 macOS / Linux 分别运行每个命令
- `--help` 输出格式与 mise 对齐

---

## 实施顺序建议

```
Phase 1（4-6 天）:
  env 升级 → outdated → latest → list 增强 → set/unset → tool

Phase 2（5-7 天）:
  bin-paths → backends → registry → tasks 子命令 → fmt → link → unuse

Phase 3（按需）:
  self-update → implode → generate → en → shell-alias
  install-into → edit → token → mcp
```
