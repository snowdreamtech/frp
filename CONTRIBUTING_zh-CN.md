# 贡献指南

首先，感谢您考虑为 **Snowdream Tech AI IDE Template** 贡献力量！正是有了像您这样的人，这个模板才成为一个如此优秀的基础工具。

## 🤝 如何贡献

我们欢迎各种形式的贡献，包括错误修复、新的 AI Agent 规则、文档改进以及 CI/CD 增强。

### 1. 设置开发环境

我们的项目采用了标准化的环境，目标平台为 **Node.js 22** 和 **Python 3.12**。

请按照以下统一的顺序设置您的本地开发环境：

1. **环境准备与依赖安装**: `unirtm install` (安装开发所需核心工具与项目依赖)
2. **验证**: `make verify` (最终项目健康检查)

### 2. 一般工作流

1. **Fork** GitHub 上的仓库。
2. **Clone** 您 fork 的仓库到本地。
3. 从 `main` **创建分支**，使用具有描述性的分支名称（例如：`feat/add-new-ai-rule`, `fix/ci-memory-leak`）。
4. **开发** 您的特性或修复 bug。
5. 遵循我们的 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/) 标准进行 **Commit**。我们强烈建议使用我们的交互式 Commitizen CLI 来自动组装 commit 消息。只需运行 `npm run commit` 或使用 `git commit` 手动撰写规范化消息。
6. **Push** 到您的 fork。
7. 对我们的 `main` 分支提交 **Pull Request (PR)**。

### 3. 开发者原创证明 (DCO)

为了在法律上保护仓库，所有 commit **必须**包含签署（Sign-off）。这表示您有权提交您所贡献的代码。

您可以通过使用 `-s` 或 `--signoff` 标志轻松签署您的 commit：

```bash
git commit -s -m "fix(script): resolve posix portability issue"
```

### 4. 代码与架构规范

在提交规则或代码之前，您 **必须** 阅读我们的内部架构指南：

- [01-general.md](.agent/rules/01-general.md): 核心原则和语言规则。
- [02-coding-style.md](.agent/rules/02-coding-style.md): CI/CD 和脚本回退要求。
- [shell.md](.agent/rules/shell.md): 严格的 POSIX shell 移植规则。

_任何未能通过强制性 CI 工作流检查或违反架构标准的 Pull Request 都将不被合并。_

感谢您帮助我们构建终极的 SSOT AI IDE 模板！
