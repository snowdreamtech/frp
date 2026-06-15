# 深度内嵌 Go-Task 实施计划 (Phase 3)

本计划探讨并实施对 `github.com/go-task/task/v3` 的函数级别直接调用（深度内嵌），实现不需要用户事先安装 `go-task` 即可急速执行 `Taskfile.yml` 的特性。

## 调研与背景上下文

在先前的探索中，我们执行了 `go get github.com/go-task/task/v3`，发现 `go-task` 作为库被引入时，会附带极为庞大的依赖树，这其中包括：

- AWS SDK (`aws-sdk-go-v2`)
- Google Cloud SDK (`cloud.google.com/go`)
- HashiCorp `go-getter`
- 众多模板引擎、加密和云存储依赖库

**这些依赖主要是为了支持 `Taskfile.yml` 中的远程引入（Remote Taskfiles）功能。**

> [!WARNING]
> 将 `go-task` 作为原生依赖静态编译入 `UniRTM`，预估会导致 `UniRTM` 的二进制文件体积增加约 **30MB 到 50MB**，并可能延长编译时间。我们需要在“真正的免安装极速执行体验”与“CLI 瘦客户端原则”之间做出权衡。

## 实施方案

如果确认推进，我们将对现有的 `GoTaskRunner` 进行重构：

### 1. 修改 `GoTaskRunner` 的执行逻辑

#### [MODIFY] `internal/task/go_task.go`

原有的 `os/exec` 拉起独立进程的代码将被废弃。新代码将通过构造 `task.Executor` 来直接执行任务。

```go
package task

import (
 "context"
 "os"
 "path/filepath"

 gotask "github.com/go-task/task/v3"
 "github.com/go-task/task/v3/taskfile/ast"
)

type GoTaskRunner struct{}

func NewGoTaskRunner() *GoTaskRunner {
 return &GoTaskRunner{}
}

func (r *GoTaskRunner) Name() string {
 return "go-task"
}

func (r *GoTaskRunner) CanExecute(dir string) bool {
    // 逻辑不变，依然探测 Taskfile.yml
    // ...
}

func (r *GoTaskRunner) Run(ctx context.Context, dir string, taskName string, args []string, env []string) error {
 // 将 env []string 解析为 map 或者设置到当前进程的 os.Setenv（由于 Go-Task 自动继承 os.Environ()）
    // 为了防止污染主进程环境变量，更优雅的做法是修改 Go-Task Executor 的配置，但如果不行，我们会利用 os.Setenv 并加锁/还原。

 e := &gotask.Executor{
  Dir:    dir,
  Stdout: os.Stdout,
  Stderr: os.Stderr,
  Stdin:  os.Stdin,
 }

 if err := e.Setup(); err != nil {
  return err
 }

    // 组装要执行的任务
    calls := []ast.Call{
        {Task: taskName},
    }

 return e.Run(ctx, calls...)
}
```

### 2. 环境变量隔离注入

`GoTaskRunner` 不像 `exec.Cmd` 能够安全地传入一个独立的 `Env` 切片。
由于 `go-task` 会从系统上下文中获取环境变量，我们将需要：

1. 提取传入的 `env []string` 注入到 `os.Environ()` 层面，并使用 `sync.Mutex` 或类似机制保证执行期间并发安全。
2. 任务执行完成后，恢复原有的环境变量。

## User Review Required

> [!IMPORTANT]
> **我们需要在以下两点做出架构决策（请回复您的意见）：**
>
> 1. **体积权衡**：您是否接受将 `UniRTM` 的二进制体积膨胀数倍以换取“深度内嵌”免安装带来的极速体验？如果不接受，我们可以保持目前的 `os/exec` 包装器形式，将 `go-task` 视为一个普通的外部工具（通过 UniRTM 安装和调用）。
>
> 2. **环境变量安全性**：函数级调用 Go-Task，我们需要在 Go 进程中临时修改 `os.Setenv`。在多线程或并行任务场景下，临时修改进程全局的环境变量是不安全的。我们可以实施但不推荐。您希望：
>    - (A) 接受临时修改环境变量的方案。
>    - (B) 取消深度内嵌，回退/保留当前的子进程 `os/exec` 方案（该方案由于开启了新进程，隔离性极佳）。
