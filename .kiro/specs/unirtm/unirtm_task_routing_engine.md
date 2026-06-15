# UniRTM Multi-modal Task Routing Engine (RFC)

## 1. 背景与动机 (Background & Motivation)

在前端、后端和系统编程中，任务的编排与执行（Task Running）与环境管理（Environment Management）往往是密不可分的工作流。

- 传统的包管理器（如 nvm, pyenv）只负责环境。
- `mise` 内部集成了一个极其复杂的 DAG 任务引擎，以此来吸引需要一站式体验的用户。

然而，UniRTM 坚持“高内聚、低耦合”的架构哲学。我们不希望在核心项目中重写一个功能繁冗的任务调度器，但我们又必须：

1. 满足用户“一键在正确的上下文中执行脚本”的诉求。
2. 平滑兼容现有的 `mise` 配置（其中包含大量的 `[tasks]` 定义）。

为此，我们提出 **“多模态任务路由引擎 (Multi-modal Task Routing Engine)”**，通过插件化和智能嗅探（Sniffing），将重度的任务编排工作委托给专业的第三方工具（如 `go-task`, `make`, `just`），而在没有这些工具时，提供一个轻量级的原生执行器作为兜底。

## 2. 架构设计 (Architecture)

### 2.1 核心接口 (The Runner Interface)

整个架构围绕一个高度抽象的 `Runner` 接口展开。任何一种外部工具，只要实现了该接口，就能被无缝挂载为 UniRTM 的任务执行器。

```go
type Runner interface {
    // Name 返回执行器的唯一标识，如 "go-task", "make", "just", "native"
    Name() string

    // CanExecute 探测当前目录下是否具备该执行器的运行条件
    // 例如：MakeRunner 会检测是否存在 Makefile
    CanExecute(dir string) bool

    // Run 在指定的上下文和环境变量中拉起任务
    Run(ctx context.Context, dir string, taskName string, args []string, env []string) error
}
```

### 2.2 智能嗅探引擎 (Sniffing Engine)

当用户敲下 `unirtm run build` 时，路由引擎将按优先级遍历所有注册的 `Runner`：

1. **优先级 1 (专业编排)**：如果检测到 `Taskfile.yml`，路由给 **GoTaskRunner**。
2. **优先级 2 (通用规范)**：如果检测到 `Makefile`，路由给 **MakeRunner**。
3. **优先级 3 (现代工具)**：如果检测到 `Justfile`，路由给 **JustRunner**。
4. **优先级 4 (兜底方案)**：如果什么都没有，但 `unirtm.toml` 中定义了 `[tasks]`，则路由给 **NativeRunner** 进行基础的 Shell 解释。

### 2.3 环境注入 (Environment Injection)

路由引擎不仅负责寻找执行器，还负责在调用执行器前，将 UniRTM 维护的工具链 `PATH` 和特定环境变量（如 `JAVA_HOME`）序列化为 `env []string`，强行注入给子进程。这保证了无论底层用什么工具跑，任务始终运行在被隔离的干净环境中。

## 3. 分阶段实施路径 (Implementation Phases)

### Phase 1: MVP（最小可行性产品）

* [x] 定义 `task.Runner` 接口。
* [x] 实现 `NativeRunner`，专门解析 `unirtm.toml` / `.mise.toml` 的 `[tasks]` 节点，调用系统 `/bin/sh` 执行，实现最低限度的向下兼容。
* [x] 暴露 CLI 接口 `unirtm run <task>`。

### Phase 2: 外部生态委托

* [x] 实现 `MakeRunner`，探测 `Makefile`，通过 `os/exec` 包装 `make` 命令。
* [x] 实现 `JustRunner`，探测 `Justfile`，包装 `just` 命令。

### Phase 3: 深度内嵌 Go-Task

* [x] 探索直接引入 `github.com/go-task/task/v3` 作为代码依赖。如果遇到 `Taskfile.yml`，不拉起外部进程，直接通过 Go 函数级别调用 Task 的核心引擎，实现真正的“免安装极速执行”。

---
*Created by UniRTM Design Team.*
