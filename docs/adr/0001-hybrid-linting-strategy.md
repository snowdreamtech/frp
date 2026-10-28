# ADR 0001: Hybrid Linting and Code Quality Strategy

## Status

Accepted

## Context

The `snowdreamtech-template-docs` project serves as a foundational AI IDE template designed for multi-language, cross-platform, and all-weather development. Given the diverse ecosystem of languages (Go, Python, Rust, TS/JS, Shell, IaC) and operating systems (macOS, Linux, Windows), enforcing code quality and security consistently without crippling local developer velocity is a significant challenge.

Traditional approaches often either overload the developer's local machine with heavy, slow linters, or rely entirely on CI pipelines, delaying feedback loops.

## Decision

We have adopted a **Hybrid Linting Strategy** that strictly decouples lightweight local validation from comprehensive CI-driven auditing.

### 1. Local Environment: Speed and Safety First

Local linting is orchestrated via `pre-commit` hooks, supplemented by a `postinstall` bridge in `package.json` to automatically bind hooks for Node.js developers.

- **Tooling Choice:** We deliberately use fast, isolated tools. For instance, we use `dockerfile-utils` locally instead of `hadolint` to ensure extremely rapid syntax checking of Dockerfiles.
- **Python Execution:** Tools like `ruff`, `yamllint`, and `checkmake` are strictly bound to the local `.venv/bin/` path inside `.pre-commit-config.yaml`. This ensures that hooks never fail due to global environment pollution or unactivated virtual environments.
- **Formatters:** We push all formatting (Prettier, Ruff format, Shfmt) to the local pre-commit stage to prevent meaningless "style fix" commits in PR reviews.

### 2. CI Environment: Deep and Comprehensive Auditing

The CI pipeline (`.github/workflows/lint.yml`) acts as the ultimate gatekeeper and runs the "Heavy" linters that are deemed too intrusive or slow for every local commit.

- **Heavy Linters:** Tools such as `golangci-lint`, `ansible-lint`, `cargo clippy`, and `hadolint` are exclusively run in CI.
- **Security & Integrity:** Actions like `govulncheck` (Go vulnerability scanning) and `sort-package-json --check` run in CI to catch structural and security regressions before they hit the main branch.

### 3. Cross-Platform Delegation (Windows Support)

To maintain a single source of truth for tool installation (`scripts/setup.sh`) across Linux, macOS, and Windows:

- Windows setup (`scripts/setup.ps1` -> `scripts/setup.bat`) acts purely as a delegation chain. It searches for a POSIX-compliant shell (e.g., Git Bash) and passes execution to `setup.sh`.
- `setup.sh` handles dynamic OS/Architecture detection (e.g., downloading `.zip` or `.exe` releases for Windows binaries like `tflint` and `kube-linter` directly) to ensure absolute cross-platform parity.

## Consequences

### Positive

- **Developer Velocity:** Local commits remain lightning fast (typically sub-second) since heavy analysis is deferred.
- **Uncomprounirtmd Quality:** The CI pipeline guarantees that no code is merged without passing industry-standard deep static analysis (`golangci-lint`, `hadolint`).
- **Zero Configuration:** Developers across Windows, macOS, and Linux can simply run `unirtm run setup` or `pnpm install` and immediately receive identical local protection shields without manual intervention.

### Negative

- **Slight Asymmetry:** Developers may occasionally see a CI build fail for a rule (e.g., a `hadolint` specific best-practice) that their local environment (`dockerfile-utils`) did not complain about. This trade-off is accepted in favor of local commit speed.

## Alternatives Considered

### Option A: CI-Only Linting

Run all linters exclusively in the CI pipeline and skip local pre-commit hooks entirely.

- **Reason rejected:** Feedback loops are too slow. Developers only discover style or lint violations after pushing, which interrupts flow and can clog PR queues with trivial fix commits.

### Option B: Full Local Linting (All-In Locally)

Run every linter, including heavy ones like `golangci-lint` and `ansible-lint`, as part of every local commit hook.

- **Reason rejected:** Unacceptably slow local commit times — `golangci-lint` alone can take 30–120 seconds on a cold cache, destroying developer velocity for frequent microcommits.

### Option C: Lint-on-Save Only (IDE Integration)

Rely on IDE plugins (ESLint, Pylance, etc.) for linting and abandon both pre-commit hooks and a CLI-driven CI strategy.

- **Reason rejected:** Requires every developer to have identical IDE plugin configurations and active plugins, which cannot be enforced, breaking the "Zero Configuration" guarantee. It also does not serve terminal-only environments (CI, headless containers).
