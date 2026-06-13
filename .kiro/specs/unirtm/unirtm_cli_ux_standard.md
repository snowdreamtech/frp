# UniRTM CLI UI/UX 视觉美学与输出排版规范

本规范旨在确立 UniRTM 命令行工具的统一品牌意识与交互美学规范。我们将命令的输出分为 **展示与报表类（Report/Diagnostic/Dashboard）** 以及 **事务与高频脚本类（Transactional/Action-oriented）**，并对大标题标头（Branding Header）及排版进行了精细化收敛，以平衡“强化品牌仪式感”与“保证极致利落的开发体验（DX）”。

---

## 1. 核心原则：建立品牌意识 vs 拒绝重复啰嗦

命令行界面（CLI）既是品牌形象的延伸，也是开发者极高频交互的日常生产力工具。

- **强化品牌仪式感**：在低频、高信息密度的系统状态汇总、体检报告和大盘展示中，通过统一设计的华丽全宽大标题（Branding Header）让用户产生强烈的品牌归属感与专业认同。
- **拒绝重复啰嗦（视觉噪音）**：在用户高频触发、追求速度、有管道（Pipe）链式调用或 CI/CD 自动化需求的事务性、命令性工具中，**严禁添加全宽标头**，保持纯粹利落的单行输出与轻量化状态指示（如 `ℹ` / `✓`）。

---

## 2. 标头规范：`pterm.DefaultHeader`

### 2.1 颜色系统与色彩含义

UniRTM 规定了以下三种核心标头背景色，通过语义化颜色传达当前操作的性质：

| 标头背景色 | 对应代码样式 | 适用场景 | 范例 |
| :--- | :--- | :--- | :--- |
| **品牌洋红色 (Primary)** | `pterm.BgLightMagenta` | 系统级体检、核心信息看板、大盘报告、状态汇总是默认通用颜色。 | `doctor`, `index status`, `env` |
| **警示与自毁红色 (Critical)** | `pterm.BgRed` | 具有破坏性、自毁、且不可逆转的高危动作。 | `implode` |
| **提示与临时蓝色 (Cyan/Blue)** | `pterm.BgCyan` / `BgLightBlue` | 部分临时工具型输出或辅助动作的标识（尽量精简收敛）。 | `fmt` (仅调试/独立运行时) |

### 2.2 标头文字格式

标头文字必须采用统一的英文专有名词，采用驼峰式词首字母大写：

```go
pterm.DefaultHeader.WithFullWidth().
 WithBackgroundStyle(pterm.NewStyle(pterm.BgLightMagenta)).
 WithTextStyle(pterm.NewStyle(pterm.FgBlack)).
 Println("UniRTM <Command_Name>")
```

---

## 3. 展示与报表型命令标头白名单 (有必要添加)

对于以下命令，添加统一大标头能够为用户梳理段落，具有显著的视觉结构收益与品牌意识：

1. **`unirtm doctor`** (系统健康体检):
   - **标头**: `UniRTM System Doctor` (背景色: `BgLightMagenta`)
   - **收益**: 最核心的系统诊断汇总，需要建立仪式感与终极检查的信任。
2. **`unirtm index status`** (本地工具索引状态):
   - **标头**: `UniRTM Local Tool Index Status` (背景色: `BgLightMagenta`)
   - **收益**: 呈现 SQLite 数据库存储大小、健康状态、离线工具大盘，属于标准报表。
3. **`unirtm env`** (当前激活环境详情 - 非 export):
   - **标头**: `UniRTM Active Environment` (背景色: `BgLightMagenta`)
   - **收益**: 汇聚环境变量、优先级 PATH 重载，以大盘视角呈现当前生效的运行环境上下文。
4. **`unirtm cache list`** (缓存诊断分析):
   - **标头**: `UniRTM Directory Cache Analysis` (背景色: `BgLightMagenta`)
   - **收益**: 以大盘和可视网格形式，清点本地下载缓存与未激活插件。
5. **`unirtm backends`** (后端插件注册分析):
   - **标头**: `UniRTM Registered Backends` (背景色: `BgLightMagenta`)
   - **收益**: 列出所有注册后端系统的功能矩阵与适配器状态。

---

## 4. 事务与高频脚本型命令黑名单 (禁止添加)

为了坚决避免**重复啰嗦**，以下高频、事务性、追求纯粹结果的动作类子命令**绝对禁止使用全宽大标头**：

1. **`unirtm index update` / `clear`** (索引刷新与清理):
   - 属于高频工具操作，直接输出 `ℹ Refreshing...` 和 `✓ Success` 即可，若每次刷屏 banner 会破坏操作流。
2. **`unirtm search <query>`** (工具模糊搜索):
   - 用户期望快速在管道或终端里看到搜出来的工具列表，严禁被 banner 拦截破坏可用性。
3. **`unirtm install` / `uninstall` / `use` / `unuse`** (工具生命周期管理):
   - 这些命令频繁在脚本及日常部署中使用，保持简洁的单行动画/状态或进度条输出是最佳 DX 体验。
4. **`unirtm link` / `unlink` / `bin-paths`** (系统集成与路径解析):
   - 很多时候用于被其他 shell 脚本通过 `$(unirtm bin-paths)` 直接捕获路径，若混入 branding header 会直接导致命令破坏不可用。

---

## 5. 输出排版结构规范

报表类输出必须遵循统一的视觉结构排版规范，严禁出现凌乱或硬编码空格：

1. **块标题 (Sections)**:
   - 块标题必须采用 `pterm.DefaultSection.Println("Emoji 标题")`，从而在不同 Shell 主题下均能自动渲染统一的段落粗体和序号线（例如 `# 📊 Database Information`）。
2. **表格排版 (Data Tables)**:
   - 严禁使用手动 `\t` 或硬编码制表符。
   - 展示性列表必须全部采用 `pterm.DefaultTable` 并开启 `WithHasHeader()` 统一绘制，表头字段均进行粗体处理。
3. **布尔状态 (Boolean Status Indicator)**:
   - 必须通过色彩予以归纳：
     - 受信任/激活/存在：`pterm.LightGreen("✓ yes")` 或 `pterm.LightGreen("Healthy")`
     - 不受信任/未激活/缺失：`pterm.LightRed("✗ no")` 或 `pterm.LightRed("Stale")`
