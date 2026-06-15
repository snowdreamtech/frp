# CLI 命令对标 mise 补全任务清单

> 参考规划：`.kiro/specs/unirtm/plans/cli_command_parity_plan.md`
> 对比来源：`mise --help` vs `unirtm --help`（2026-05-10 对比）

---

## Phase 1：核心补全（高频刚需）✅ 已完成

- `[x]` **`env` 命令语义升级**
  - `[x]` 修改 `cmd/3.env.go`，增加 shell 变量导出模式
  - `[x]` 支持 `eval "$(unirtm env)"` 用法（输出 `export PATH=...`）
  - `[x]` 支持 fish (`set -gx`) 和 nushell (`$env.PATH`)
  - `[x]` 保留 `--info` 兼容旧版打印行为
  - `[x]` 编写测试（8 个测试通过）
  - `[x]` 原子化 Commit: a84e683

- `[x]` **`outdated` 命令**
  - `[x]` 实现 `cmd/32.outdated.go`
  - `[x]` 调用 backend `ResolveVersion(latest)` 与已安装版本对比
  - `[x]` 支持表格 / JSON 输出
  - `[x]` 支持 `unirtm outdated <tool>` 单工具检查
  - `[x]` 编写测试（3 个测试通过）
  - `[x]` 原子化 Commit: 7ede4b7

- `[x]` **`latest` 命令**
  - `[x]` 实现 `cmd/33.latest.go`
  - `[x]` 支持版本前缀过滤 `unirtm latest go 1.22`
  - `[x]` 支持 `--json` 输出，plain 输出仅版本号（可脚本化）
  - `[x]` 支持 `backend:tool` 和 `--backend` flag
  - `[x]` 编写测试（3 个测试通过）
  - `[x]` 原子化 Commit: b3249dc

- `[x]` **`list` 命令增强**
  - `[x]` 修改 `cmd/8.list.go`，增加「STATUS」列
  - `[x]` 区分 `active ✓`（绿色）/ `─`（未激活）
  - `[x]` 添加 `ls` 别名
  - `[x]` 编写测试
  - `[x]` 原子化 Commit: 780e825

- `[x]` **`set` / `unset` 命令**
  - `[x]` 实现 `cmd/34.set.go`（含 `set` 和 `unset` 子命令）
  - `[x]` 支持 `--global` 写入全局配置
  - `[x]` 读写 unirtm.toml 中的 `[env]` 字段
  - `[x]` 新增 `env.GetGlobalConfigPath()` 到 paths.go
  - `[x]` 编写测试（8 个测试通过）
  - `[x]` 原子化 Commit: 1482084

- `[x]` **`tool` 命令**
  - `[x]` 实现 `cmd/35.tool.go`
  - `[x]` 显示：tool / backend / installed versions / active version / shim / install dir
  - `[x]` 查询 backend 显示最新可用版本
  - `[x]` 支持 `--json` 输出
  - `[x]` 编写测试（5 个测试通过）
  - `[x]` 原子化 Commit: 44e2eee

---

## Phase 2：工具链管理完善 ✅ 已完成

- `[x]` **`bin-paths` 命令**
  - `[x]` 实现 `cmd/36.bin-paths.go`
  - `[x]` 列出所有激活 runtime 的 bin 目录路径
  - `[x]` 原子化 Commit: 83f1ef4

- `[x]` **`backends` 命令**
  - `[x]` 实现 `cmd/37.backends.go`
  - `[x]` 子命令：`ls`（列出）、`info <name>`（详情）
  - `[x]` 显示每个 backend 的名称、状态、支持的工具数
  - `[x]` 支持 `--json` 输出
  - `[x]` 原子化 Commit: 40ff89f

- `[x]` **`registry` 命令**
  - `[x]` 实现 `cmd/38.registry.go`
  - `[x]` 列出所有注册工具（分页 / 过滤 `--search`）
  - `[x]` 支持 `--json` 输出
  - `[x]` 原子化 Commit: 1c50061

- `[x]` **`tasks` 子命令组**
  - `[x]` 实现 `cmd/39.tasks.go`
  - `[x]` 子命令：`list`、`info <task>`、`deps`、`add <name>`、`edit <task>`
  - `[x]` `tasks list` 显示任务名、来源文件、描述
  - `[x]` `tasks deps` 显示任务依赖 DAG（文本格式）
  - `[x]` 编写测试
  - `[x]` 原子化 Commit: 19696d7

- `[x]` **`fmt` 命令**
  - `[x]` 实现 `cmd/40.fmt.go`
  - `[x]` 格式化 unirtm.toml（键排序、对齐、统一缩进）
  - `[x]` 支持 `--check` 模式（CI 用，仅检查不修改）
  - `[x]` 原子化 Commit: 5d9807a

- `[x]` **`link` 命令**
  - `[x]` 实现 `cmd/41.link.go`
  - `[x]` 软链接已有工具路径进 UniRTM 管理体系
  - `[x]` 写入安装记录至数据库
  - `[x]` 原子化 Commit: 7f7ecd3

- `[x]` **`unuse` / `rm` / `remove` 命令**
  - `[x]` 实现 `cmd/42.unuse.go`
  - `[x]` 注册 `rm` 和 `remove` 为别名
  - `[x]` 从 unirtm.toml 中删除工具条目（不删除已安装文件）
  - `[x]` 原子化 Commit: 7f7ecd3

---

## Phase 3：高级 / 实验性功能 ✅ 已完成

- `[x]` **`self-update` 命令**
  - `[x]` 实现 `cmd/43.self-update.go`
  - `[x]` 支持 `--version <version>` 指定目标版本
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`implode` 命令**
  - `[x]` 实现 `cmd/44.implode.go`
  - `[x]` 需要用户二次确认（交互 prompt）
  - `[x]` 支持 `--yes` / `-y` 跳过确认（脚本模式）
  - `[x]` 清理：数据目录 + shims + 数据库 + 缓存
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`generate` 命令**
  - `[x]` 实现 `cmd/45.generate.go`
  - `[x]` 子命令：`github-action`、`pre-commit`、`shell-alias`
  - `[x]` 输出生成的文件内容（支持 `--output` 指定路径）
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`en` 命令**
  - `[x]` 实现 `cmd/46.en.go`
  - `[x]` 在新 sub-shell 中运行 UniRTM 激活环境
  - `[x]` 支持 `-- <cmd>` 直接执行命令
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`shell-alias` 命令**
  - `[x]` 实现 `cmd/47.shell-alias.go`
  - `[x]` 子命令：`list`、`add <alias>`、`remove <alias>`
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`install-into` 命令**
  - `[x]` 实现 `cmd/48.install-into.go`
  - `[x]` 安装工具到指定自定义路径
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`edit` 命令**
  - `[x]` 实现 `cmd/49.edit.go`
  - `[x]` 打开 `$EDITOR` / `$VISUAL` 编辑配置文件
  - `[x]` 支持 `--global` 编辑全局配置
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`token` 命令**
  - `[x]` 实现 `cmd/50.token.go`
  - `[x]` 显示当前各 provider 使用s的 token（掩码处理）
  - `[x]` 支持 `unirtm token github` 指定 provider
  - `[x]` 原子化 Commit: ae0129f

- `[x]` **`mcp` 命令（实验性）**
  - `[x]` 实现 `cmd/51.mcp.go`
  - `[x]` 运行 MCP server（stdio 模式，供 AI 工具调用）
  - `[x]` 暴露：install / list / outdated / tool 等工具为 MCP tools
  - `[x]` 原子化 Commit: ae0129f

---

## 统计

| Phase | 命令数 | 状态 |
|-------|--------|------|
| Phase 1 — 核心补全 | 6 | ✅ 已完成（2026-05-10）|
| Phase 2 — 管理完善 | 8 | ✅ 已完成（2026-05-10）|
| Phase 3 — 高级功能 | 9 | ✅ 已完成（2026-05-10）|
| **合计** | **23** | 23/23 完成 |
