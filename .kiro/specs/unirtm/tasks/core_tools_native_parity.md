# Core Tools 原生化补齐任务清单

## Phase 1: 现代 JS 运行时 (JS Runtimes)

- `[x]` **Bun**
  - `[x]` 实现 `internal/provider/bun.go`
  - `[x]` 实现 `internal/provider/bun_test.go`
  - `[x]` 原子化 Commit
- `[x]` **Deno**
  - `[x]` 实现 `internal/provider/deno.go`
  - `[x]` 实现 `internal/provider/deno_test.go`
  - `[x]` 原子化 Commit

## Phase 2: 系统级与现代语言 (System & Modern Langs)

- `[x]` **Zig**
  - `[x]` 实现 `internal/provider/zig.go`
  - `[x]` 实现 `internal/provider/zig_test.go`
  - `[x]` 原子化 Commit
- `[x]` **Swift**
  - `[x]` 实现 `internal/provider/swift.go`
  - `[x]` 实现 `internal/provider/swift_test.go`
  - `[x]` 原子化 Commit

## Phase 3: BEAM 生态 (BEAM Ecosystem)

- `[x]` **Erlang**
  - `[x]` 实现 `internal/provider/erlang.go`
  - `[x]` 实现 `internal/provider/erlang_test.go`
  - `[x]` 原子化 Commit
- `[x]` **Elixir**
  - `[x]` 实现 `internal/provider/elixir.go`
  - `[x]` 实现 `internal/provider/elixir_test.go`
  - `[x]` 原子化 Commit

## Phase 4: 注册与清理 (Registration)

- `[x]` 在 `internal/provider/registry.go` 中注册所有新 Provider
- `[x]` 验证所有 Core Tools 的原生安装流程
- `[x]` 原子化 Commit
