# UniRTM Backend Architecture & Evolution Specification

## 1. 核心理念 (Core Philosophy)

UniRTM 的后端架构设计遵循 **“先解决有无（生态挂载），再追求完美（原生智能）”** 的演进策略。在设计和实现各类工具的安装后端（Backend/Provider）时，我们需严格平衡“实现成本”、“生态覆盖率”和“长期维护性”。

## 2. 当前架构现状：Wrapper 模式主导 (v1.0 阶段)

目前，UniRTM 大量采用 **Wrapper（包装器）** 模式来快速补齐与成熟工具（如 `mise`）之间的生态差距。

### 2.1 依赖外部命令的 Provider

* **UbiProvider** (`ubi`)：依赖系统中的 `ubi` 二进制。将复杂的 GitHub Releases 智能探测外包给专业的外部工具。
* **AsdfProvider** (`asdf`)：兼容 asdf 插件规范。利用开源社区现有的 800+ 插件库来完成安装逻辑。
* **Npm/Cargo/Pypi Provider**：直接调用系统原生的 `npm`、`cargo` 和 `pip` 来拉取对应语言的全局包。

### 2.2 原生内置的 Backend

* **GitHub Releases** (基础版)：原生 Go 实现，支持从 GitHub 下载特定的 Release 资产，但在遇到不规范的命名时，严重依赖用户在配置中手动指定确切的匹配规则（缺乏自动推断能力）。

**当前阶段总结**：通过“外部调用的 Wrapper 模式”，UniRTM 实现了“零成本”挂载海量生态工具，满足了 MVP (Minimum Viable Product) 阶段快速验证和兼容 `mise` 配置的核心诉求。

## 3. 未来演进路线：原生智能化 (Native Intelligence)

随着 UniRTM 底层架构（如 SQLite 事务、审计日志等）的稳固，后端的演进方向将是从 **“外部依赖”** 转向 **“内置原生智能化”**。这不仅能消除用户对外部环境（如必须预装 `ubi` 或 `cargo`）的依赖，还能实现极致的零配置开箱即用体验。

### 3.1 演进目标：强化原生的 GitHub Release 后端

未来的 `GitHubBackend` 必须具备类似 `ubi` 的智能推断能力。

**核心能力建设要求**：

1. **OS/Arch 同义词自动映射**：
   - 架构字典：自动等价 `amd64` = `x86_64` = `x64`。
   - 系统字典：自动等价 `darwin` = `macos` = `mac`。
2. **启发式评分机制 (Heuristic Scoring)**：
   - 下载 GitHub API 资产列表后，不是立刻抛弃不精确的匹配，而是对文件名进行多维度打分。
   - 例：命中 `tar.gz` (+10分)，命中 `x86_64` (+20分)，命中 `.sha256` 排除词 (-100分)。最终选择得分最高的资产下载。
3. **C 库环境感知（Linux 独有）**：
   - 自动检测当前系统是 `glibc` (gnu) 还是 `musl` (alpine)，并优先匹配对应的二进制产物。
4. **智能解包与二进制嗅探 (Binary Sniffing)**：
   - 解压下载的 Archive 后，自动扫描内部文件。通过“文件可执行权限位 (+x)”、“同名推断 (工具名等于文件名)”来精准提取真正的执行文件。

### 3.2 兼容性后退机制 (Fallback Mechanism)

在追求智能的同时，必须保留“确定性配置”的后门，避免“黑盒魔法”猜错导致的灾难：

* **显式覆盖 (Override)**：当智能推断失败或选错版本时，允许用户在 `unirtm.toml` 中显式指定 `asset_name_template` 或 `regex` 来强制下载特定文件。
* **云端注册表 (Cloud Registry)**：对于少数极其奇葩且高频使用的工具，在 UniRTM 内部维护一个静态的映射 JSON 清单，遇到该工具时直接走硬编码路径，跳过猜测。

## 4. 废弃与过渡策略 (Deprecation Strategy)

当原生的 `GitHubBackend` 达到足够高的智能水平（准确率 > 95%）时：

1. **平滑迁移**：在控制台输出警告，提示用户将配置文件中的 `ubi:user/repo` 替换为原生的 `github:user/repo`。
2. **逻辑替换**：在内部路由中，逐步将对 `ubi:` 的调用透明地重定向到原生的 `GitHubBackend`。
3. **最终废弃**：保留 `UbiProvider` 的代码仅作兼容使用，甚至在后续大版本中彻底移除对外部 `ubi` 二进制的依赖。

---
**设计结论**：
短期内，我们利用 Wrapper 站在巨人的肩膀上跑赢生态；长期内，我们将“魔法”内化为 Go 原生实现，打造真正轻量、无外部依赖的终极版本管理体验。
