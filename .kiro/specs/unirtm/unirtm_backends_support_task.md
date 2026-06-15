# 多生态 Backend / Provider 支持任务

## Phase 1: asdf 支持 (内置)

- [x] 创建 `internal/backend/asdf.go`
  - 实现 `ListVersions` (执行 `bin/list-all`)
  - 实现 Github 仓库克隆逻辑 (从 `github.com/asdf-vm/asdf-plugins` 或直接拉取对应的插件仓库)
- [x] 创建 `internal/provider/asdf.go`
  - 实现 `Install` (执行 `bin/download` 和 `bin/install`)
  - 实现 `GenerateShims` (基于 `bin/list-bin-paths` 或默认 `bin/`)
- [x] 在 Registry 中注册 `asdf`
- [x] 测试 `unirtm install asdf:nodejs@20.0.0`

## Phase 2: npm & pypi 支持 (内置)

- [x] 创建 `internal/backend/npm.go` (请求 `registry.npmjs.org`)
- [x] 创建 `internal/provider/npm.go` (执行 `npm install -g --prefix`)
- [x] 创建 `internal/backend/pypi.go` (请求 `pypi.org/pypi/<pkg>/json`)
- [x] 创建 `internal/provider/pypi.go` (使用 `python -m venv` 及 `pip install`)
- [x] 注册并在 Registry 中暴露
- [x] 测试 `npm` 与 `pypi`

## Phase 3: cargo 支持 (内置)

- [x] 创建 `internal/backend/cargo.go` (请求 `crates.io/api/v1/crates/<pkg>`)
- [x] 创建 `internal/provider/cargo.go` (执行 `cargo install --root`)
- [x] 注册并在 Registry 中暴露
- [x] 测试 `cargo` 后端

## Phase 4: ubi 强化 (github + generic)

- [x] 增强 `internal/backend/github.go`，支持多资产正则匹配 (`Resolving` 逻辑优化)
- [x] 增强 `internal/provider/generic.go`
  - 增加 `.tar.gz`, `.zip` 解压逻辑
  - 自动探测解压后的可执行文件 (赋予 `+x` 权限)
- [x] 测试基于 GitHub Releases 的工具安装
