# Architecture & Project Structure

> Objective: Define structural, organizational, and design standards to ensure a consistent, maintainable, and cross-platform codebase.

## 1. Cross-Platform Design

- **Path Handling**: Always use `path.join()` or equivalent cross-platform path functions. Never hard-code `/` or `\` separators.
- **Line Endings**: Configure `.gitattributes` to normalize line endings (`* text=auto`). This prevents CRLF/LF conflicts across platforms.
- **Shell Scripts**: When shell scripts are necessary, provide both `.sh` (Unix/POSIX) and `.ps1` or `.cmd` (Windows) variants, or use cross-platform runners (e.g., `python`, `node`).
  - **Preferred Method**: Use direct execution of pre-installed binaries (via `unirtm install`).
  - **Local Path**: For project-specific tools, use `npm run <command>` which safely includes `node_modules/.bin` in the path without `npx` overhead.
- **Environment Variables**:
  - Use `.env` files with a `.env.example` template. Never commit actual `.env.local` files.
  - **UniRTM Prefix Strategy**: All internal configuration MUST support a hierarchical lookup via `internal/pkg/env.Get()`: `UNIRTM_KEY` > `UNIRTM_KEY` > `KEY`.
  - **Network Synchronization**: On startup, prefixed variables (e.g., `UNIRTM_HTTP_PROXY`) MUST be synchronized to native ones (e.g., `HTTP_PROXY`) if native ones are missing, to ensure compatibility with standard libraries.
- **OS Detection**: Detect the operating system at runtime for conditional logic. Use `runtime.GOOS` (Go). Never hard-code OS-specific command paths.
- **Scripting Architecture (SSO)**: All automation tools must follow a **Triple-Entry Unified Pattern**:
  - **Core Logic**: POSIX-compliant Shell (`scripts/*.sh`) sourcing `lib/common.sh`.
  - **Windows Delegation**: Thin PowerShell wrappers (`scripts/*.ps1`) and Batch files (`scripts/*.bat`) that delegate to the shell logic.
  - **Unified Entry Points**: Every tool MUST be accessible via both `Makefile` and `package.json` for consistent developer experience.

## 2. Runtime & Dependency Strategy

- **Runtime Classes**: To balance environment readiness with lean installation, runtimes are classified into two tiers:
  - **Primary (First-Class)**: **Node.js** and **Python**. These are required for the vast majority of CLI tools, linters, and core automation. They are ALWAYS installed during `unirtm install`.
  - **Secondary (On-Demand)**: **Go**, **Rust**, **Java**, **Swift**, **PHP**, etc. These are installed only when project-specific source files (e.g., `go.mod`, `pom.xml`, `Cargo.toml`) are detected.
- **Dependency Isolation**: All project-level dependencies MUST be isolated.
  - **Node.js**: Use local `node_modules`.
  - **Python**: Use a local virtual environment (`.venv`).
  - **Others**: As dictated by their respective build systems, ensuring no global namespace pollution.
- **Tooling Preference**: Prefer tools distributed via `npm` or `pipx` (managed via Python) as they benefit from the maturity of the Primary runtimes and their established mirroring infrastructure.

## 2. Project Organization & Configuration

### Dependency Management

- Always pin dependency versions in lock files (`package-lock.json`, `poetry.lock`, `go.sum`, `Cargo.lock`, `unirtm.lock`, etc.).
- Lock files MUST be committed to version control. The `node_modules/`, `venv/`, `.venv/`, `target/`, `dist/` directories MUST be in `.gitignore`.

### Configuration Hierarchy

- Project-level configuration takes precedence over global configuration.
- Environment-specific overrides (dev, staging, production) MUST use environment variables or dedicated config files (e.g., `.env.production`).
- Sensitive values (API keys, passwords, tokens, certificates) MUST be stored in environment variables or secret management systems, never in source code or config files committed to the repository.

### Standard Project Layout

```text

project-root/
├── .agent/              # AI agent configuration (primary)
│   ├── rules/           # Unified AI rules (Single Source of Truth)
│   └── workflows/       # AI workflows / commands (source of truth)
├── .agents/             # Shared commands source (auto-managed)
│   └── commands/        # Command files (source of truth for all IDEs)
├── .cline/              # Example IDE dir (all IDE dirs follow this pattern)
│   ├── rules/           # Real folder — IDE-specific rules redirect
│   │   └── rules.md     # Real file — redirects to .agent/rules/
│   └── commands/        # Real folder — contains file-level symlinks
├── .github/             # GitHub-specific configuration (Actions, Copilot)
├── .vscode/             # VS Code settings
├── src/                 # Source code
├── tests/               # Test files (mirrors src/ structure)
├── docs/                # Documentation (Chinese user-facing, English technical)
└── scripts/             # Build and utility scripts

```

## 3. AI IDE Integration (Symlink Convention)

All AI IDE directories follow a **hybrid symlink pattern** to maintain a Single Source of Truth while allowing per-IDE customization:

| Directory | Structure | Source |
| ---------------- | ------------------------------------ | -------------------- |
| `.IDE/rules/` | Real folder, real files | IDE-specific content |
| `.IDE/commands/` | Real folder, **file-level symlinks** | `.agents/commands/` |

**Rationale:**

- `rules/` files are real — each IDE may need slightly different redirect content.
- `commands/` files are symlinks — command files are identical across all IDEs; updates to `.agents/commands/` auto-propagate to all IDEs.

**Exception — `.gemini/commands/`:** Gemini CLI requires TOML format. This directory contains both:

- `.md` file-level symlinks → `.agents/commands/` (standard pattern)
- `.toml` companion files (embedded full prompt content, Gemini CLI format)

**Workflow:**

- **Adding a new command**: Edit only `.agents/commands/` — all IDE dirs auto-reflect the change via symlinks. Also add a `.toml` file to `.gemini/commands/`.
- **Adding a new IDE**: Create `.newIDE/rules/rules.md` (real file) and `.newIDE/commands/` (real dir with file-level symlinks).

## 4. AI IDE Configuration Reference

This project uses a **redirect pattern** to maintain a Single Source of Truth: all AI IDE config files point to `.agent/rules/` for actual rules.

### Root-level redirect files

| File | AI IDE |
| ------------------ | ----------------------------- |
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | OpenAI Codex / Generic agents |
| `CONVENTIONS.md` | Generic convention readers |
| `codex.md` | OpenAI Codex |
| `.replit.agent.md` | Replit Agent |
| `.aider.conf.yml` | Aider (YAML format) |
| `.coderabbit.yaml` | CodeRabbit (YAML format) |
| `sweep.yaml` | Sweep AI (YAML format) |
| `.pr_agent.toml` | Qodo PR-Agent (TOML format) |

### IDE-specific directories

Each directory contains a redirect `rules/rules.md` file, plus `commands/` (file symlinks):

| Directory | Rules File | AI IDE |
| --------------- | --------------------------------------------------------------- | ---------------------- |
| `.claude/` | `CLAUDE.md` | Claude Code |
| `.cursor/` | `rules/rules.md`, `rules/rules.mdc` | Cursor |
| `.windsurf/` | `rules/rules.md` | Windsurf |
| `.github/` | `copilot-instructions.md`, `instructions/rules.instructions.md` | GitHub Copilot |
| `.gemini/` | `GEMINI.md` | Gemini |
| `.cline/` | `rules/rules.md` | Cline |
| `.roo/` | `rules/rules.md` | Roo Code |
| `.augment/` | `rules/rules.md` | Augment |
| `.amazonq/` | `rules/rules.md` | Amazon Q |
| `.continue/` | `rules/rules.md` | Continue |
| `.trae/` | `rules/project_rules.md` | Trae |
| `.kiro/` | `steering/rules.md` | Kiro |
| `.goose/` | `.goosehints` | Goose |
| `.junie/` | `guidelines.md` | Junie |
| `.codex/` | `rules/rules.md` | OpenAI Codex |
| `.void/` | `rules/rules.md` | Void IDE |
| `.aide/` | `rules/rules.md` | Aide IDE |
| `.devin/` | `rules/rules.md` | Devin AI |
| `.kilocode/` | `rules/rules.md` | Kilocode |
| `.openhands/` | `microagents/rules.md` | OpenHands |
| `.bob/` | `rules/rules.md` | Bob AI |
| `.cortex/` | `rules/rules.md` | Cortex |
| `.zencoder/` | `rules/rules.md` | Zencoder |
| `.opencode/` | `rules/rules.md` | OpenCode |
| `.pearai/` | `rules/rules.md` | PearAI |
| `.specify/` | `rules/rules.md` | Specify |
| `.melty/` | `rules/rules.md` | Melty |
| `.zed/` | `agent/rules.md` | Zed IDE |
| `.codeium/` | `rules/rules.md` | Codeium |
| `.cody/` | `rules/rules.md` | Sourcegraph Cody |
| `.tabnine/` | `rules/rules.md` | Tabnine |
| `.supermaven/` | `rules/rules.md` | Supermaven |
| `.blackbox/` | `rules/rules.md` | Blackbox |
| `.codegeex/` | `rules/rules.md` | CodeGeeX |
| `.bito/` | `rules/rules.md` | Bito |
| `.aiassistant/` | `rules/project_rules.md` | JetBrains AI Assistant |
| `.adal/` | `rules/rules.md` | ADAL |
| `.commandcode/` | `rules/rules.md` | CommandCode |
| `.codebuddy/` | `rules/rules.md` | CodeBuddy |
| `.crush/` | `rules/rules.md` | Crush |
| `.factory/` | `rules/rules.md` | Factory |
| `.iflow/` | `rules/rules.md` | iFlow |
| `.kode/` | `rules/rules.md` | Kode |
| `.mcpjam/` | `rules/rules.md` | MCP Jam |
| `.mux/` | `rules/rules.md` | Mux |
| `.neovate/` | `rules/rules.md` | Neovate |
| `.pi/` | `rules/rules.md` | Pi IDE |
| `.pochi/` | `rules/rules.md` | Pochi |
| `.qoder/` | `rules/rules.md` | Qoder |
| `.qwen/` | `rules/rules.md` | Qwen |
| `.shai/` | `rules/rules.md` | Shai |
| `.vibe/` | `rules/rules.md` | Vibe |

## 5. Design Principles

- **Layered Architecture**: Organize code in clear architecture layers (e.g., Presentation → Application → Domain → Infrastructure). Dependencies MUST only point inward — outer layers depend on inner layers, never the reverse.
- **API Contracts**: Define all service boundaries with explicit, versioned contracts (OpenAPI/Swagger for REST, `.proto` files for gRPC, GraphQL schema). Contracts MUST be reviewed and version-bumped for breaking changes.
- **Bounded Contexts**: In complex systems, define bounded contexts (DDD) with explicit integration points. Teams own their contexts; cross-context communication goes through well-defined APIs or events.
- **Separation of Concerns**: Keep configuration, business logic, and infrastructure code strictly separated. Business logic MUST NOT contain infrastructure-specific code (SQL queries, HTTP calls, file I/O); use dependency injection and interfaces/adapters.
- **Fail Fast**: Validate inputs and preconditions as early as possible in the call stack. Return clear errors immediately rather than propagating invalid state deeply into business logic.
- **Provider Acceleration**: For tools frequently affected by network restrictions (e.g., Go SDK), implement mirror support via environment variables (e.g., `GO_DOWNLOAD_MIRROR` -> `golang.google.cn`).
- **Asset Matching**: In NativeBackend, implement fuzzy matching and scoring logic to handle non-standard tool asset names across versions.
