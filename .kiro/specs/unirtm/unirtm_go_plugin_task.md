# Go-Plugin Refactoring Tasks

## 阶段 1：定义 gRPC/RPC 接口

- [x] 决定使用轻量级的 `net/rpc` 代替 `gRPC` 避免 `protoc` 编译依赖
- [x] 删除无效的 proto 文件

## 阶段 2：实现 HashiCorp Plugin 封装层

- [x] 添加依赖: `go get github.com/hashicorp/go-plugin`
- [x] 创建 `internal/plugin/shared.go` (握手配置, PluginMap)
- [x] 创建 `internal/plugin/backend_rpc.go` (Backend 的 RPC 适配器)
- [x] 创建 `internal/plugin/provider_rpc.go` (Provider 的 RPC 适配器)

## 阶段 3：重构 PluginManager

- [x] 修改 `internal/service/plugin.go`，使用 `plugin.Client` 代替 `plugin.Open`
- [x] 增加生命周期管理 (Kill 子进程)
- [x] 适配插件发现逻辑 (扫描 `unirtm-plugin-*` 二进制)
- [x] 修改 `cmd/24.plugin.go` 的 install/remove 逻辑，适配二进制插件

## 阶段 4：示例与验证

- [x] 创建 `examples/plugin-go/main.go`
- [x] `go build` 交叉编译测试
- [x] 单元测试与集成测试修复
- [x] 提交代码
