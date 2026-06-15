# Project Structure

A map of every directory and file in the template and what it does.

## Top-Level Overview

```text
project-root/
├── .agent/                   # 🤖 The Brain — Canonical AI configuration
│   ├── rules/                # 📏 80+ unified AI behavioral rules (SSoT)
│   └── workflows/            # 🛠️ SpecKit workflow definitions
│
├── .github/                  # 🐙 GitHub integration
│   ├── workflows/            # ⚙️  CI/CD pipelines
│   ├── ISSUE_TEMPLATE/       # 📋 Bug report, feature request templates
│   ├── DISCUSSION_TEMPLATE/  # 💬 Community discussion templates
│   ├── instructions/         # 🧠 GitHub Copilot custom instructions
│   ├── prompts/              # ✍️  GitHub Copilot reusable prompts
│   └── agents/               # 🧩 GitHub Copilot agent definitions
│
├── .devcontainer/            # 🐳 DevContainer configuration
│   ├── Dockerfile            # Container image definition
│   ├── devcontainer.json     # VS Code DevContainer settings
│   └── docker-compose.yaml  # Multi-service configuration
│
├── .vscode/                  # 💻 VS Code workspace settings
│   ├── tasks.json            # Make command shortcuts
│   └── launch.json           # Debug configurations (Go, Python, Node, Vue, React)
│
├── .cursor/                  # AI IDE directories (50+ total)
├── .cline/                   # Each mirrors .agent/rules/ and .agent/workflows/
├── .windsurf/
├── .aide/
├── ... (50+ more)
│
├── scripts/
│   └── init-project.sh       # 💧 Project hydration / instantiation script
│
├── docs/                     # 📖 VitePress documentation site (this site)
│
├── AGENTS.md                 # AI agent entry point (OpenAI Codex / AGENTS-spec)
├── CLAUDE.md                 # Claude Code entry point
├── CONVENTIONS.md            # Human-readable project conventions
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # Contributor guide
├── CODE_OF_CONDUCT.md        # Community standards
├── SECURITY.md               # Security policy and disclosure
├── SUPPORT.md                # Support channels
├── ROADMAP.md                # Future plans
├── LICENSE                   # MIT License
│
├── .unirtm.toml                  # 🔧 Unified task runner
├── .editorconfig             # Editor-agnostic formatting rules
├── .pre-commit-config.yaml   # Pre-commit hook definitions (40+ hooks)
├── commitlint.config.js      # Conventional Commits enforcement
├── eslint.config.mjs         # JavaScript/TypeScript linting
├── .stylelintrc.json         # CSS/SCSS linting
├── .yamllint.yml             # YAML linting
├── ruff.toml                 # Python linting and formatting
└── sweep.yaml                # Automated code maintenance
```

## The `.agent/` Directory

This is the heart of the template, the Single Source of Truth for all AI behavior:

### `.agent/rules/`

Contains 80+ Markdown rule files that govern how AI assistants should behave in this project. Structured in two tiers:

**Core Rules** (apply to all projects):

| File                   | Coverage                                             |
| ---------------------- | ---------------------------------------------------- |
| `01-general.md`        | Language, communication, idempotency, cross-platform |
| `02-coding-style.md`   | Commit messages, code quality, naming conventions    |
| `03-architecture.md`   | Project structure, AI IDE integration                |
| `04-security.md`       | Credentials, access control, scanning                |
| `05-dependencies.md`   | Locking, auditing, release process                   |
| `06-ci-testing.md`     | Test types, CI pipeline, quality gates               |
| `07-git.md`            | Commits, branching, pull requests                    |
| `08-dev-env.md`        | DevContainer, scripts, pre-commit hooks              |
| `09-ai-interaction.md` | Safety, code generation, communication               |
| `10-ui-ux.md`          | Frontend: styling, accessibility, i18n               |
| `11-deployment.md`     | Containerization, secrets, IaC                       |

**Language/Framework Rules** (loaded dynamically based on project stack):
`go.md`, `python.md`, `typescript.md`, `react.md`, `vue.md`, `docker.md`, `kubernetes.md`, and 70+ more.

### `.agent/workflows/`

Contains SpecKit workflow definitions — step-by-step AI agent instructions for managing the feature development lifecycle.

## The AI IDE Directories

Every supported AI IDE has its own directory that contains:

- `rules/` — Redirect/mirror of `.agent/rules/`
- `commands/` or `workflows/` — Shortcuts to `.agent/workflows/`

This follows each IDE's own naming convention while maintaining a unified source.
