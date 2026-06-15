# Backend 生态补齐与原子化集成总结

在本次迭代中，我们系统性地扩展了 UniRTM 的底层生态，以实现与 `mise` 对后端（Backend / Provider）100% 的对齐。通过本次补充，UniRTM 不仅支持标准的二进制下载，还原生无缝接入了各大主流语言包管理器以及代码托管平台的 API。

## 核心实现列表

| 生态/后端 | 目录映射 | 类型 | 支持状态 | 核心逻辑 |
|----------|---------|------|----------|---------|
| **RubyGems** | `gem` | `Backend` & `Provider` | ✅ 已支持 | 封装 `gem install`，支持版本查询与隔离安装。 |
| **.NET Tools** | `dotnet` | `Backend` & `Provider` | ✅ 已支持 | 封装 `dotnet tool install`，通过 NuGet API 查询。 |
| **Conda** | `conda` | `Backend` & `Provider` | ✅ 已支持 | 封装 `conda create` 隔离数据科学依赖环境。 |
| **GitLab** | `gitlab` | `Backend` | ✅ 已支持 | 对接 GitLab v4 Releases API，支持鉴权下载。 |
| **Forgejo** | `forgejo` | `Backend` | ✅ 已支持 | 兼容 Gitea/Forgejo Swagger Releases API。 |
| **Vfox** | `vfox` | `Backend` & `Provider` | ✅ 已支持 | 封装 `vfox install` 以支持其丰富的 Lua 插件生态。 |
| **SPM** | `spm` | `Backend` & `Provider` | ✅ 已支持 | 针对 Swift 支持 `git clone` 与 `swift build -c release`。 |
| **S3** | `s3` | `Backend` | ✅ 已支持 | 原生支持从 Amazon S3 Bucket 拉取二进制产物。 |

## 工程化亮点

> [!TIP]
> **原子化提交流程**
> 本次重构我们严格遵循了原子化原则：每新增一个生态支持（包括 `Backend`, `Provider` 及其 `_test.go`），我们都通过隔离的 Commit 进行提交，总共生成了 8 个语义化 Commit（例如 `feat(ecosystem): add gem backend and provider...`）。这使得整个项目的变更历史非常清晰且可追溯。

<!-- separator -->

> [!NOTE]
> **接口驱动与高内聚**
> 所有的扩展点都实现了 `internal/backend/backend.go` 和 `internal/provider/provider.go` 中定义的标准接口，并在 `registry.go` 中进行统一的注册。未来即便要增减生态，只需要在对应的独立文件中修改，**完全不会影响系统的主干逻辑**。

## 后续建议

目前所有主流的后端都已经支持。如果需要进一步完善测试环境：

1. 对于类似 **Conda, Gem, Dotnet** 这种依赖本地工具链的 Provider，在 CI 流水线中需要提前预装对应 CLI，否则在实际运行时会抛出 "xxx is required but not found in PATH"。
2. 建议通过环境变量规范化类似 `GITLAB_TOKEN`, `FORGEJO_TOKEN` 的配置鉴权流程。
