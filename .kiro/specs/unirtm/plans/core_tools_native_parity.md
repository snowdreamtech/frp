# 核心工具“全栈原生化”实施计划

收到指令！我们将贯彻“全栈原生化，绝对零依赖”的极客精神，用 Go 原生代码补齐 UniRTM 对 `mise` 剩下的 6 个核心工具的硬编码内置支持。

这意味着用户在安装这 6 门语言时，将直接调用 UniRTM 内部的高性能逻辑进行下载解压与环境配置，彻底摆脱对 `asdf` 或 `vfox` 插件以及系统本地依赖工具的束缚。

## 目标 Core Tools

1. **Bun** (`bun.go`)
2. **Deno** (`deno.go`)
3. **Elixir** (`elixir.go`)
4. **Erlang** (`erlang.go`)
5. **Swift** (`swift.go`)
6. **Zig** (`zig.go`)

## User Review Required

> [!IMPORTANT]
> 像 Erlang 和 Elixir 这样的语言，其官方经常仅提供源码树，或者不同操作系统的预编译包非常稀碎。为了做到“绝对零依赖”（不依赖本地 `make/gcc` 等工具链去从源码编译），我们原生 Provider 将优先对接它们的**官方预编译二进制发布源（如 GitHub Releases 或官网的 Precompiled binaries）**。您是否同意此策略？

## Proposed Changes

我们将分为三组，保持高频与“原子化”节奏进行提交：

### 阶段 1：现代 JS 运行时双雄

#### [NEW] `internal/provider/bun.go`

- 实现快速解压 `.zip` (支持 macOS/Windows) 与提取可执行文件。
- 设置环境变量，直接暴露 `bun` 和 `bunx`。

#### [NEW] `internal/provider/deno.go`

- 类似 Bun，从 `dl.deno.land` 或 GitHub Releases 拉取。
- 直接暴露 `deno`。

### 阶段 2：系统级与现代语言

#### [NEW] `internal/provider/zig.go`

- 从 `ziglang.org` 下载预编译产物，处理解压并将 `zig` 可执行文件桥接出来。

#### [NEW] `internal/provider/swift.go`

- 针对 macOS，原生集成 `swift` 工具链安装流程；对于 Linux，拉取 `.tar.gz` 解压并配置库路径（`LD_LIBRARY_PATH` 等如有必要）。

### 阶段 3：BEAM 生态

#### [NEW] `internal/provider/erlang.go`

- 拉取基于不同架构预编译的 Erlang/OTP 包，解压后暴露 `erl`, `erlc`, `escript` 等命令。

#### [NEW] `internal/provider/elixir.go`

- 下载 Elixir 预编译包（通常是一个 zip），解析并暴露 `elixir`, `elixirc`, `iex`, `mix` 等。

---

#### [MODIFY] `internal/provider/registry.go`

- 在 `NewRegistry` 注册表中将 `bun`, `deno`, `elixir`, `erlang`, `swift`, `zig` 的默认降级引擎移除，硬链接指向我们全新编写的 `NewXXXProvider()` 原生实现。

## Verification Plan

### Automated Tests

- 为上述 6 个文件分别编写 `bun_test.go`, `deno_test.go` 等。
- 测试 `Name()`, `ListExecutables()` 等基本接口的正确性。

如果您对上述“利用预编译二进制”以保证“零依赖”的策略没有异议，请批准，我将立即进入原子化代码生成环节！
