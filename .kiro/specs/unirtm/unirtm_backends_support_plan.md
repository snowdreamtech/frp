# 多生态 Backend / Provider 支持计划 (asdf, npm, pypi, cargo, ubi)

## 背景与目标

为了让 UniRTM 在生态兼容性上完全媲美甚至超越 `mise`，我们需要支持更多的语言包管理器后端，以及兼容庞大的 `asdf` 插件生态。

用户的核心诉求是：**能否同步支持 asdf 插件、npm 后端、PyPI 后端、Cargo 后端、Ubi 后端？**

**答案是：完全可以，并且架构上非常契合。**
UniRTM 将把这些常见的生态作为 **内置核心组件（Built-in Core Implementations）** 直接打包到二进制中，实现开箱即用，而不需要用户额外下载 Go Plugin。

---

## 用户审查项

> [!IMPORTANT]
>
> 1. **实现策略（Built-in vs Go-Plugin）**：为了提供极佳的开箱即用体验（类似 `mise`），我建议将 `asdf`、`npm`、`pypi`、`cargo` 直接写在 `internal/backend/` 和 `internal/provider/` 目录下，作为原生内置支持，而不是分离成独立二进制插件。您是否同意此设计？
> 2. **Ubi 后端的复用**：`ubi` (Universal Binary Installer) 本质上是解析 GitHub Releases 并下载二进制文件。我们目前已经实现了 `github` Backend 和 `generic` Provider。我们可以在此基础上强化 `generic`，或者专门写一个 `ubi` Backend，您的倾向是？（推荐直接强化内置的 `github` + `generic` 组合）。
> 3. **优先顺序**：这 5 个后端的开发工作量较大，您希望优先实现哪一个作为切入点？（通常建议先做 `asdf`，因为它可以直接白嫖社区 800+ 现成的工具）。

---

## 架构与实现方案

### 1. asdf 插件支持 (AsdfBackend & AsdfProvider)

- **原理**：`asdf` 插件本质上是一个包含特定 Bash 脚本的 Git 仓库。
- **Backend 职责**：执行 `<plugin-dir>/bin/list-all` 来获取所有可用版本。
- **Provider 职责**：
  - `Install`：执行 `<plugin-dir>/bin/download` 和 `<plugin-dir>/bin/install`。
  - `GenerateShims`：解析 `<plugin-dir>/bin/list-bin-paths`（或默认 `bin/` 目录）来生成 shims。
- **难点**：需要实现一个简易的 Git 仓库克隆和更新逻辑（如果插件未下载，则从 github/asdf-vm/asdf-plugins 的 registry 中拉取仓库地址）。

### 2. npm 后端 (NpmBackend & NpmProvider)

- **原理**：复用系统中已有的 `npm`（或 `pnpm`/`yarn`）或者通过 HTTP API 独立解析。
- **Backend 职责**：调用 `https://registry.npmjs.org/<pkg>` API 解析 JSON 获取所有的 tags 和 versions。
- **Provider 职责**：使用 `npm install -g <pkg>@<ver> --prefix <unirtm-install-path>` 将工具直接安装到隔离目录。

### 3. PyPI / Python 后端 (PypiBackend & PypiProvider)

- **原理**：复用系统 Python 的 `pip` 或直接拉取 wheel 包。
- **Backend 职责**：调用 `https://pypi.org/pypi/<pkg>/json` 解析所有版本号。
- **Provider 职责**：通过 `python -m venv <install-path>` 创建隔离环境，并在其中执行 `pip install <pkg>==<ver>`。这样彻底隔离工具依赖，不会污染系统。

### 4. Cargo / Rust 后端 (CargoBackend & CargoProvider)

- **原理**：复用系统的 `cargo` 命令。
- **Backend 职责**：调用 `https://crates.io/api/v1/crates/<pkg>` 解析所有发布版本。
- **Provider 职责**：执行 `cargo install <pkg> --version <ver> --root <install-path>`。

### 5. Ubi 后端强化 (Ubi / GitHub Releases)

- **原理**：直接从 GitHub 下载跨平台预编译的压缩包。
- **Backend 职责**：完善我们现有的 `github` Backend，增加对多资产（Assets）名字正则匹配的精准度。
- **Provider 职责**：完善 `generic` Provider，增加对 `.tar.gz`, `.zip`, `.tar.xz` 的自动解压与可执行文件探测逻辑，并自动创建 shim。

---

## 路线图 (Roadmap)

如果同意，我们将分成以下几个 PR/任务 阶段来执行：

- **Phase 1**: 实现并跑通 `asdf` 核心机制（这是扩展性最大的）。
- **Phase 2**: 实现 `npm` 和 `pypi`（这俩 HTTP API 解析最简单）。
- **Phase 3**: 实现 `cargo`。
- **Phase 4**: 增强 `github + generic` 实现免配置的 `ubi` 体验。
