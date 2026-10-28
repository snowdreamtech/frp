# Project Structure

A map of every directory and file in the template and what it does.

## Top-Level Overview

```text
project-root/
├── .github/                  # 🐙 GitHub integration & CI/CD workflows
│   ├── workflows/            # ⚙️  CI/CD pipelines
│   ├── ISSUE_TEMPLATE/       # 📋 Bug report, feature request templates
│   └── DISCUSSION_TEMPLATE/  # 💬 Community discussion templates
│
├── .devcontainer/            # 🐳 DevContainer configuration
├── .vscode/                  # 💻 VS Code workspace settings
│
├── scripts/                  # 🛠️ Automation scripts
├── docs/                     # 📖 VitePress documentation site
│
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # Contributor guide
├── CODE_OF_CONDUCT.md        # Community standards
├── SECURITY.md               # Security policy and disclosure
├── SUPPORT.md                # Support channels
├── ROADMAP.md                # Future plans
├── LICENSE                   # MIT License
│
├── .unirtm.toml              # 🔧 Repository toolchain and quality guard contract
├── unirtm.lock               # 🔒 Pinned tool versions and integrity hashes
├── .editorconfig             # Editor-agnostic formatting rules
├── .pre-commit-config.yaml   # Pre-commit hook definitions
├── commitlint.config.js      # Conventional Commits enforcement
├── eslint.config.mjs         # JavaScript/TypeScript linting
├── .stylelintrc.json         # CSS/SCSS linting
├── .yamllint.yml             # YAML linting
└── ruff.toml                 # Python linting and formatting
```

## AI Agent Integration: Zero Repository Pollution

This template employs a **Zero-Footprint Architecture** for AI IDEs and agents:

- **Model Context Protocol (MCP)**: Instead of polluting project roots with 50+ proprietary dot-directories (`.cursor/`, `.windsurf/`, `.cline/`), UniRTM provides a built-in standard MCP server via `unirtm mcp`.
- **Global Rules & Workflows**: AI coding rules and Spec Kit workflows are provided dynamically to AI agents through standard MCP prompts, resources (`unirtm://config`, `unirtm://conventions`), and tools (`quality_check`, `get_rule`).
- **Clean Repositories**: Any AI IDE or agent (Cursor, Windsurf, Claude Desktop, Zed, UniAgent) connects via standard MCP over stdio without committing any tool-specific proxy files.
