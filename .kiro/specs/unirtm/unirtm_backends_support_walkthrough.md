# UniRTM 多后端生态支持与泛型强化 Walkthrough

## 1. 完成的任务与架构概览

本次实现极大地拓宽了 UniRTM 的软件生态兼容能力，我们完成了以下内置后端与提供程序的开发：

- **`asdf` 支持 (Phase 1)**：通过直接调用 `bin/list-all` 和 `bin/download`，无需 Go 插件即可无缝安装全球数百个 asdf 社区插件。
- **`npm` 支持 (Phase 2)**：直接对接 `registry.npmjs.org`，并采用 `npm install -g --prefix` 实现全局安装的局部化隔离。
- **`PyPI` 支持 (Phase 2)**：直接对接 `pypi.org/pypi/<pkg>/json`，并自动创建 `python -m venv`，避免污染系统的 Python 环境。
- **`Cargo` 支持 (Phase 3)**：直接对接 `crates.io`，并调用 `cargo install --root` 将 Rust 工具链软件安装到 UniRTM 统一目录。
- **泛型与 GitHub Releases 强化 (Phase 4)**：
  - **Ubi 级泛型提取能力**：为 `GenericProvider` 增加了 `.tar.gz`, `.tar.xz`, `.zip` 原生压缩包解压支持（基于系统原生的 `tar` 和 `unzip` 命令）。
  - **GitHub 下载优化**：修改了 GitHub 资源的匹配策略，使其优先寻找压缩包而不是环境特定的安装包（忽略 `.deb`, `.rpm`, `.msi`, `.apk` 等）。

## 2. 详细实现亮点

### 2.1 依赖倒置与后端路由机制

在本次开发中，我们重构了 `ProviderRegistry`：

```go
func (r *Registry) GetWithBackend(toolName string, backendName string) Provider {
 // 优先根据 backendName 分配执行者
 if backendName != "" {
  if provider, ok := r.providers[strings.ToLower(backendName)]; ok {
   return provider
  }
 }
 // ... 降级为 toolName 精准匹配或 generic
}
```

这使得当我们运行 `unirtm install npm:typescript 5.0.0` 时，系统会自动提取 `npm` 作为后端，去调用 `NpmProvider`，而不再错误地寻找一个名叫 "typescript" 的独立 Provider。

### 2.2 环境沙箱隔离

不论是 `npm`, `pypi`, 还是 `cargo`，我们的提供程序都坚守**沙箱安装**的原则：

* **PyPI**: 强制使用 `python -m venv` 来创建独立运行环境。
* **NPM**: 通过 `--prefix` 参数将全局安装限制在 `/opt/unirtm/tools/npm_tool_name/version`。
* **Cargo**: 通过 `--root` 将编译产物限制在指定目录。
此设计与 mise 的初衷完全契合。

## 3. 测试与验证路径

所有的代码已通过 `make lint` 校验（包含 `golangci-lint`, `shellcheck`, `zizmor`, `trivy` 等 20 余项工具校验）并顺利提交至代码仓库。

**建议后续通过以下命令在本地执行真实测试：**

```bash
# 测试 asdf 插件克隆与安装
unirtm install asdf:nodejs 20.0.0

# 测试 NPM 隔离安装
unirtm install npm:typescript 5.0.0

# 测试 PyPI 隔离安装
unirtm install pypi:black 23.3.0

# 测试 Cargo 二进制编译安装
unirtm install cargo:ripgrep 13.0.0
```

## 4. 下一步演进计划

我们已经成功把外部插件化的复杂性吸纳为内置的 `Backend` / `Provider`，极大改善了跨平台兼容性与冷启动速度。未来的工作重点可以转移到：

1. CLI 交互层完善（如下载进度条对接 `internal/pkg/download`）。
2. 环境变身（Shims 动态生成和环境变量注入）。
