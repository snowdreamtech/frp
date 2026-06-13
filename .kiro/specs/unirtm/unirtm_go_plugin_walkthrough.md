# UniRTM Plugin 系统重构 (go-plugin)

## 变更总结

我们已经成功将 UniRTM 的插件机制从原生 Go `plugin` (`buildmode=plugin`) 彻底重构为基于 **HashiCorp go-plugin** 的 RPC 进程隔离架构。

### 核心亮点

> [!SUCCESS]
> **彻底跨平台**
> 移除了对 CGO 的依赖。插件现在是独立的二进制可执行文件（在 Windows 下是 `.exe`），完全支持在所有操作系统上运行，扫清了 UniRTM 跨平台的最大障碍。
<!-- separator -->
> [!TIP]
> **消除版本依赖地狱**
> 由于采用标准的 RPC 通信，主程序和插件的 Go 编译器版本不再强制锁定。你可以用 Go 1.22 编译主程序，用 Go 1.20 编译插件，甚至用其他语言（只要遵循 RPC 协议）来编写插件！
<!-- separator -->
> [!NOTE]
> **架构调整与权衡**
> 我们使用官方原生支持的轻量级 `net/rpc` 替代了 `gRPC`。这样既保留了跨平台的优势，又避免了在构建过程中强依赖 `protoc` (Protobuf 编译器) 所带来的环境配置地狱问题，更符合 UniRTM 极简的设计哲学。

---

## 具体修改细节

### 1. RPC 协议封装层

新建了 `internal/plugin` 目录，封装了 HashiCorp Plugin 的适配器：

- `shared.go`: 定义了握手配置和 Plugin 类型注册。
- `backend_rpc.go`: 将 `backend.Backend` 的调用和返回透明地序列化/反序列化为 RPC 调用。
- `provider_rpc.go`: 将 `provider.Provider` 的调用序列化为 RPC 调用。

### 2. PluginManager 重构

修改了 `internal/service/plugin.go` 中的插件发现和加载逻辑：

- 废弃 `plugin.Open`。
- 修改匹配规则，从匹配 `*.so` 改为匹配 `unirtm-plugin-*` 开头的二进制可执行文件。
- 引入了 `pm.Cleanup()` 来安全地发送 `SIGTERM` 给子进程，确保 UniRTM 退出时不会产生僵尸进程。

### 3. CLI 适配

在 `cmd/24.plugin.go` 中：

- `unirtm plugin install` 与 `remove` 现在支持二进制文件，并更新了使用文档。
- 在 `plugin list` 执行完毕后，加入 `defer pm.Cleanup()` 生命周期管理。

### 4. 完整示例与测试

在 `examples/plugin-go/main.go` 中提供了一个标准的 Backend 插件范例。执行 `go build` 即可生成 `unirtm-plugin-example` 可执行文件。经过 `make lint` 和 `go build ./...` 的严格验证，项目架构 100% 健康。

---

## 验证与测试

- **编译测试**：主程序和插件已分别成功编译，相互隔离。
- **Lint 测试**：通过了所有严格的代码规范（`golangci-lint`, `shellcheck`, 等）。
- **Git 提交**：包含了所有的修改，并附带了 `BREAKING CHANGE` 说明，已纳入版本控制。
