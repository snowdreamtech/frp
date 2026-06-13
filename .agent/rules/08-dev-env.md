# Local Development & Environment Guidelines

> Objective: Define standards for environment consistency, developer experience, cross-platform compatibility, and effective local debugging.

## 1. Environment Consistency

- Use **`unirtm`** as the **mandatory polyglot toolchain orchestrator** to pin exact runtime versions and Tool Executors. Versions MUST be committed to the repository in `.unirtm.toml`.

  ```toml
  # .unirtm.toml — polyglot version manager (Single Source of Truth)
  [tools]
  node   = "20.18.3"
  python = "3.12.9"
  pnpm   = "10.5.2"
  uv     = "0.6.3"
  ```

  Other managers (`nvm`, `pyenv`, `asdf`) are **deprecated** in this project to prevent toolchain fragmentation.

- All three of these SHOULD agree to avoid version ambiguity between tools: `.nvmrc` / `.node-version`, `engines` field in `package.json`, and `.unirtm.toml`.

### Cross-Platform Tooling & Providers

- **Avoid Legacy `asdf` Plugins**: When specifying tools in `.unirtm.toml`, strictly avoid using `asdf:` prefixed plugins (e.g., `asdf:unirtm-plugins/unirtm-pipx`). `asdf` plugins are heavily reliant on POSIX Bash scripts (`bin/download`, `bin/install`), which inherently fail on native Windows CI environments (e.g., GitHub Actions `windows-latest` running `pwsh`) due to path translation conflicts, missing POSIX utilities, and symlink permission restrictions.
- **Prefer Native & Universal Providers**: Always default to `unirtm`'s built-in core backends (e.g., `pipx`, `node`, `python`, `go`) which are written in Rust and provide flawless cross-platform support. If a core backend is unavailable, use native package manager providers (`npm:`, `cargo:`, `go:`) or direct GitHub releases (`github:`) over complex wrapper systems to guarantee execution speed and reliability across macOS, Linux, and Windows.

### Environment Variables

- Provide a `.env.example` file listing all required environment variables with placeholder values and clear descriptions:

  ```bash
  # .env.example — commit this file, never the real .env

  # Database
  DATABASE_URL=postgres://user:password@localhost:5432/myapp_dev

  # Auth
  JWT_SECRET=<generate-with: openssl rand -hex 32>
  JWT_EXPIRES_IN=7d

  # External APIs
  STRIPE_SECRET_KEY=sk_test_<your-test-key>        # Stripe Dashboard → Developers
  SENDGRID_API_KEY=SG.<your-api-key>               # SendGrid → Settings → API Keys

  # Feature Flags
  ENABLE_NEW_CHECKOUT=false
  ```

- Never commit a real `.env`. Add `*.env` (except `.env.example`) to `.gitignore`. For team secret sharing, use **Doppler**, **1Password CLI**, or **dotenv-vault** with encrypted `.env.vault`.
- Document ALL required environment variables. Undocumented variables are a source of confusion and broken onboarding.

## 2. Development Container

### devcontainer.json

- Provide a **`devcontainer.json`** (VS Code Dev Containers / GitHub Codespaces) or a **`docker-compose.yml`** for the full development stack. This ensures any developer can reproduce the environment in one command:

  ```json
  // .devcontainer/devcontainer.json
  {
    "name": "MyApp Development",
    "image": "mcr.microsoft.com/devcontainers/node:22-bookworm",
    "forwardPorts": [3000, 5432, 6379],
    "postCreateCommand": "npm ci && cp .env.example .env",
    "features": {
      "ghcr.io/devcontainers/features/docker-in-docker:2": {},
      "ghcr.io/devcontainers/features/git:1": {}
    },
    "customizations": {
      "vscode": {
        "extensions": ["dbaeumer.vscode-eslint", "esbenp.prettier-vscode", "ms-vscode.vscode-typescript-next"]
      }
    },
    "mounts": ["source=${localWorkspaceFolder}/.env,target=/workspaces/myapp/.env,type=bind"]
  }
  ```

- The devcontainer image MUST be pinned to a specific tag or SHA digest. Never use `latest` in a devcontainer image reference — it breaks reproducibility.
- For services requiring GPU compute (ML/AI workloads), provide a separate `devcontainer.gpu.json` or Docker Compose profile.

## 3. Scripts & Commands

### Standard Task Targets

- Define all common developer tasks as scripts in `Makefile`, `package.json` (`scripts`), or a `scripts/` directory. Mandatory targets:

  | Target          | Purpose                                      |
  | --------------- | -------------------------------------------- |
  | `dev` / `start` | Run the application locally with hot reload  |
  | `test`          | Run the full test suite                      |
  | `test:unit`     | Run unit tests only (fast feedback)          |
  | `lint`          | Run all linters and formatters in check mode |
  | `lint:fix`      | Auto-fix linting and formatting issues       |
  | `typecheck`     | Run type checker without emitting files      |
  | `build`         | Produce a production-ready artifact          |
  | `clean`         | Remove generated artifacts and caches        |
  | `db:migrate`    | Apply pending database migrations            |
  | `db:seed`       | Seed the development database                |

  ```makefile
  # Makefile
  .PHONY: dev test lint build clean
  dev:     ## Start development server with hot reload
           npm run dev
  test:    ## Run full test suite
           npm run test
  lint:    ## Lint and format check
           npm run lint && npm run typecheck
  build:   ## Production build
           npm run build
  ```

- Scripts MUST use explicit exit codes (`0` = success, non-zero = failure). Always `set -euo pipefail` (bash) to prevent silent failures.
- Use cross-platform compatible tooling (`python`, Node.js scripts, or direct binaries via `unirtm install`) when the project targets Windows contributors. Avoid `npx` startup overhead.

## 4. Pre-commit Hooks

### Hook Configuration

- Use **Husky + lint-staged** (Node.js), **pre-commit** (Python), or equivalent to run fast checks before every commit:

  ```json
  // package.json — lint-staged config
  {
    "lint-staged": {
      "*.{ts,tsx,js,jsx}": ["eslint --fix --max-warnings 0", "prettier --write"],
      "*.{css,scss}": ["prettier --write", "stylelint --fix"],
      "*.{md,json,yaml,yml}": ["prettier --write"],
      "*.sh": ["shellcheck --severity=warning"]
    }
  }
  ```

  ```yaml
  # .pre-commit-config.yaml (Python projects)
  repos:
    - repo: https://github.com/astral-sh/ruff-pre-commit
      rev: v0.9.0
      hooks:
        - id: ruff
          args: [--fix]
        - id: ruff-format
    - repo: https://github.com/pre-commit/pre-commit-hooks
      rev: v5.0.0
      hooks:
        - id: detect-private-key
        - id: check-merge-conflict
  ```

- Keep pre-commit hooks **fast** (target < 5 seconds). Run hooks only on staged files. Move slow checks (full test suite, E2E) to CI.
- Commit message validation with **commitlint** enforcing Conventional Commits:

  ```javascript
  // commitlint.config.js
  export default { extends: ["@commitlint/config-conventional"] };
  ```

- Pre-commit configuration MUST be committed to the repository so all team members use identical hooks. Document how to install hooks in `CONTRIBUTING.md`.

## 5. Debugging & Observability

### Debug Configuration

- Configure **structured local logging** with log-level support. Provide one-line instructions to enable verbose logging:

  ```bash
  LOG_LEVEL=debug npm run dev     # Node.js
  RUST_LOG=debug cargo run        # Rust
  DEBUG=* node server.js          # Express/Node.js debug namespace
  ```

- Provide **launch configurations** committed to the repository for debugger attach:

  ```json
  // .vscode/launch.json
  {
    "version": "0.2.0",
    "configurations": [
      {
        "type": "node",
        "request": "attach",
        "name": "Attach to Node.js",
        "port": 9229,
        "sourceMaps": true,
        "outFiles": ["${workspaceFolder}/dist/**/*.js"]
      },
      {
        "type": "node",
        "request": "launch",
        "name": "Run Tests (Vitest)",
        "program": "${workspaceFolder}/node_modules/vitest/vitest.mjs",
        "args": ["run", "--reporter=verbose"]
      }
    ]
  }
  ```

- Maintain a `CONTRIBUTING.md` with step-by-step local setup instructions, prerequisites, and a **troubleshooting section**. A new team member MUST be able to run the project within 15 minutes.
- Document the approved **profiling approach** per language:
  - Node.js: `node --prof server.js` + `node --prof-process isolate-*.log`
  - Python: `py-spy record -o profile.svg -- python myapp.py`
  - Go: `go tool pprof` + `runtime/pprof` package
  - Rust: `cargo flamegraph`

## 6. Onboarding Automation

- Provide a **`scripts/setup.sh` (or `setup.ps1`)** that automates the full onboarding sequence: runtime installation, tool setup, and repository hydration. This project uses `unirtm install` as the unified entry point:

  ```bash
  # Install all toolchains and project dependencies in one command
  unirtm install
  ```

- **Unified Install Principle**: All setup, dependency installation, and hook activation are unified under `unirtm install`. Language-specific installation logic is handled transparently by unirtm backends based on `.unirtm.toml` declarations. This eliminates the need for per-language shell script modules and reduces maintenance overhead.

- Track **onboarding time**: periodically measure how long it takes a new developer to go from `git clone` to a passing test run. The target is **≤ 15 minutes**. Failures to meet this SLA MUST be treated as developer experience bugs.

- Track **onboarding time**: periodically measure how long it takes a new developer to go from `git clone` to a passing test run. The target is **≤ 15 minutes**. Failures to meet this SLA MUST be treated as developer experience bugs.

- **Language-Aware & Dynamic Detection**: Tool installations MUST be context-sensitive.
  - **Prerequisite Detection**: Secondary tools (e.g., `golangci-lint`, `asdf:ghc`) MUST only be installed if corresponding source files or manifests are detected.
  - **Dynamic Heavy Tools Execution**: To avoid the "UniRTM Tax" (slow compilation or resolution of massive security tools like `zizmor`), do NOT add them permanently to the global `.unirtm.toml`. Instead, track their versions in a central manifest (e.g., `.unirtm.toml`) and execute them strictly on-demand using `unirtm exec tool@version -- cmd`. This ensures the core environment remains maximally lightweight.
  - **Availability-First Detection (Security)**: Security scanners (e.g., `osv-scanner`, `zizmor`) MUST prioritize local availability. If the tool is present in the local environment, it MUST be reported as `✅ Active` and participate in the audit workflow, even if categorized as a Tier 3/CI-only tool.
  - **Strict CI vs. Permissive Local Orchestration**: All audit and linting scripts MUST be environment-aware (e.g., via `is_ci_env`). In CI pipelines, missing required tools MUST trigger a strict, fatal error (`exit 1`) to enforce security gates. In local development, the absence of those same tools MUST degrade gracefully to a non-blocking warning (e.g., `⏭️ Skipped`) to preserve developer velocity.

- **Grouped UX & Selective Display**:
  - Output MUST be organized into logical groups (e.g., Core Infrastructure, Security & Quality, Language Runtimes).
  - Groups that are entirely irrelevant (e.g., "Mobile Support" in a CLI-only project) SHOULD be hidden to maintain a high signal-to-noise ratio.
  - Status Reporting MUST follow these conventions:
    - `✅ Active`: Binary resolved and version matches recommended standards.
    - `⏭️ Optional`: Tier 3 tool missing in local dev (CI-only by default).
    - `⏭️ Skipped`: Feature-specific tool skipped because corresponding files are missing.
    - `❌ Missing`: Critical tool missing or version mismatch; causes failure.

## 7. Recommended Project Lifecycle

To maintain consistency and high quality, developers and AI agents MUST follow these standardized command sequences.

### Initialization Sequence (首次初始化)

Follow this order when setting up a new repository or onboarding to a new machine:

1. **unirtm install**: Install all toolchains, project dependencies, and activate git hooks.
2. **make verify**: Perform a final comprehensive health and quality check.

### Daily Development Loop (日常开发循环)

Follow this iterative cycle for consistent delivery:

1. **unirtm install**: Ensure local dependencies are synchronized with the lockfile.
2. **make lint**: Verify code adherence to project rules.
3. **make audit**: Run security and vulnerability scans (Mandatory before PR).
