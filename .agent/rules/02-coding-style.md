# Coding Style & Conventions

> Objective: Define universal coding conventions to ensure consistent, readable, and maintainable code across all languages and projects.

## 1. Git Commit Messages

- Follow **[Conventional Commits](https://www.conventionalcommits.org/)** specification, strictly adhering to the `@commitlint/config-conventional` standard.
- Format: `<type>(<scope>): <description>` — e.g., `feat(auth): add refresh token support`
- Common types:

  | Type       | When to Use                                 |
  | ---------- | ------------------------------------------- |
  | `feat`     | A new feature                               |
  | `fix`      | A bug fix                                   |
  | `docs`     | Documentation only changes                  |
  | `style`    | Formatting, whitespace — no logic change    |
  | `refactor` | Restructuring without behavior change       |
  | `test`     | Adding/updating tests                       |
  | `chore`    | Maintenance, build, tooling                 |
  | `ci`       | CI configuration changes                    |
  | `perf`     | Performance improvement                     |
  | `build`    | Build system or external dependency changes |
  | `revert`   | Reverts a previous commit                   |

- Commit messages MUST be in **English only** (no Chinese characters or punctuation allowed). The **header** (the entire first line) must be written in the imperative mood ("add" not "added") and kept **≤ 120 characters**. It **MUST NOT** end with a period (full stop). The body and footer have **no strict line-length limit** to accommodate URLs and AI-generated text. Use the body for detailed explanations.
- Body (optional): explain **why** the change was made, not what it does — the diff shows what. Separate body from subject with a blank line:

  ```
  feat(auth): add refresh token rotation

  Implements sliding-window refresh token rotation to reduce the
  attack surface of stolen tokens. Old refresh tokens are invalidated
  on use — a second use of the same token triggers session revocation.

  Closes: #234
  ```

- Breaking changes MUST include a `BREAKING CHANGE:` footer: `BREAKING CHANGE: removed /api/v1/users endpoint, use /api/v2/users`.
- Sign commits with GPG where the repository policy requires it (`git commit -S`). Enforce on protected branches.

## 2. AI Agent Operational Standards (AI 代理执行规范)

AI agents (including Antigravity, Cursor, etc.) MUST strictly follow these execution and commit standards to ensure repository integrity and developer control:

- **Atomic Execution & Commit (原子化执行，原子化提交)**:
  - Every independent logical change (e.g., a bug fix, a new feature, a configuration update) MUST be executed and committed as a single, atomic unit.
  - Avoid "mega-commits" that bundle unrelated changes.
  - Avoid partial commits that leave the repository in a broken or inconsistent state.
- **Auto-Commit, NO Auto-Push (自动提交，严禁自动推送)**:
  - AI agents SHOULD automatically `git commit` verified changes to record progress and maintain an audit trail.
  - AI agents **MUST NOT** automatically `git push` to remote repositories unless explicitly and specifically requested by the user for a particular task.
  - This ensures the developer retains final control over the remote state and can perform a final local review/test before sharing changes.
- **Universal Tiered UniRTM Protocol (UTTP - 分层工具协议)**:
  - The project uses a tiered toolchain strategy to balance performance and security:
    - **Tier 1 (Core)**: Minimal set of essential tools defined statically in .unirtm.toml. Installed by default.
    - **Tier 2 (On-demand)**: 80+ language runtimes and security scanners defined in [.unirtm.toml](../../.unirtm.toml). Installed only when needed.
  - **Lock Ritual Protocol**: AI agents MUST NOT manually edit lockfiles for Tier 2 tools. Instead, they MUST use the `make sync-lock` command, which uses a **Manifest Aggregator** to generate a unified, secure `unirtm.lock` for all tiers.
  - **Minimal Local Bootstrap**: AI agents MUST ensure that standard local installations remain fast by keeping the root `.unirtm.toml` lean.

## 3. Code Quality Principles

- **DRY (Don't Repeat Yourself)**: Extract shared logic into reusable functions, modules, or helpers. Duplicated code is a bug waiting to diverge — every copy needs to be kept in sync.
- **KISS (Keep It Simple, Stupid)**: Prefer simple, readable solutions over clever or overly abstract ones. Complexity must earn its keep with measurable benefit.
- **YAGNI (You Aren't Gonna Need It)**: Do not implement features speculatively. Build only what is needed now. Premature abstractions are technical debt.
- **Robustness Principle (Postel's Law)**: Be conservative in what you send, and liberal in what you accept. Handle input variations gracefully (e.g., `v` prefixes in versions) but enforce strict internal standards for data consistency.
- **Single Responsibility**: Functions and classes should do one thing and do it well. If a function needs a conjunction ("and", "or") in its name, split it into two functions.
- **Cyclomatic Complexity**: Keep per-function cyclomatic complexity ≤ 15. Functions exceeding this threshold are strong candidates for decomposition. Most linters (`eslint complexity`, `pylint`, `gocyclo`) can enforce this automatically.
- **SOLID** (for OOP contexts):
  - **S** — Single Responsibility: a class has one reason to change
  - **O** — Open/Closed: open for extension, closed for modification
  - **L** — Liskov Substitution: subtypes must be substitutable for their base types
  - **I** — Interface Segregation: prefer many specific interfaces over one general-purpose one
  - **D** — Dependency Inversion: depend on abstractions, not concretions

## 3. Error Handling

- Always handle errors **explicitly** — never silently swallow exceptions with an empty `catch` or bare `except`:

  ```python
  # ❌ Silent failure — debugging nightmare
  try:
      process_payment(order)
  except:
      pass

  # ✅ Explicit handling with logging
  try:
      process_payment(order)
  except PaymentGatewayError as e:
      logger.error("Payment failed for order %s: %s", order.id, e)
      raise PaymentError(f"Could not process payment: {e}") from e
  ```

- Classify errors by origin:
  - **User errors** (validation failures): return a descriptive, user-safe message with appropriate HTTP 4xx status. Do not expose internal details.
  - **System errors** (unhandled exceptions, OOM): log with full context, return a generic message to the user, alert on-call.
  - **External errors** (downstream API failures): implement retry with backoff, circuit-breaker if applicable, and propagate a meaningful wrapped error.
- Provide **meaningful error messages** that include: what failed, why (if known), and how to resolve it (if applicable).
- Log errors with sufficient context: timestamp, operation name, relevant sanitized input data, trace ID, and a stack trace where applicable.
- Use the language's idiomatic error mechanism:
  - **Rust**: `Result<T, E>` and `Option<T>` — propagate with `?`, wrap with `thiserror`/`anyhow`
  - **Go**: `error` return values — wrap with `fmt.Errorf("context: %w", err)`
  - **TypeScript**: typed errors, `Result` patterns where applicable, discriminated unions for expected error cases
  - **Java/Kotlin**: checked exceptions for expected failure modes; unchecked for programming errors

## 4. Documentation

- All public APIs, exported functions, and non-obvious code blocks MUST have clear **docstrings or inline comments** in **English**:

  ```go
  // ParseConfig reads the configuration from the given file path and returns
  // a validated Config struct. Returns ErrConfigNotFound if the file does not
  // exist, or ErrInvalidConfig if validation fails.
  //
  // The config file must be a valid YAML document satisfying the schema
  // defined in docs/config-schema.json.
  func ParseConfig(path string) (*Config, error) { ... }
  ```

- The canonical `README.md` MUST be in English, while `README_zh-CN.md` and other user-facing documentation MUST be in **Simplified Chinese (简体中文)**.
- Comments explain **why**, not **what**. Avoid comments that merely restate the code:

  ```go
  // ❌ Obvious — restates what the code does
  i++ // increment i by 1

  // ✅ Non-obvious — explains the why
  retries++ // retry count excludes the initial attempt per RFC 9110 §15.1
  ```

- Keep documentation up to date when modifying code. Outdated documentation is worse than no documentation. Add a doc-update checklist item to PR templates.
- API documentation MUST include: parameter types/descriptions, return type, possible errors, and a usage example.
- Document **deprecation** inline with a `@deprecated` tag and migration path before removing any public API.

## 5. Naming Conventions

- Use **descriptive, meaningful names** for variables, functions, classes, and modules. Avoid abbreviations except for universally understood ones (`id`, `url`, `ctx`, `err`, `cfg`, `req`, `res`).
- Follow language-specific conventions consistently throughout the project:

  | Language              | Variables/Functions      | Classes/Types | Constants                      | Files/Modules                     |
  | --------------------- | ------------------------ | ------------- | ------------------------------ | --------------------------------- |
  | JavaScript/TypeScript | `camelCase`              | `PascalCase`  | `UPPER_SNAKE_CASE`             | `kebab-case`                      |
  | Python                | `snake_case`             | `PascalCase`  | `UPPER_SNAKE_CASE`             | `snake_case`                      |
  | Go                    | `camelCase`/`PascalCase` | `PascalCase`  | `UPPER_SNAKE_CASE` (pkg-level) | `snake_case`                      |
  | Java/Kotlin           | `camelCase`              | `PascalCase`  | `UPPER_SNAKE_CASE`             | `PascalCase` / `lowercase.dotted` |
  | Rust                  | `snake_case`             | `PascalCase`  | `UPPER_SNAKE_CASE`             | `snake_case`                      |
  | CSS/HTML              | `kebab-case`             | —             | —                              | `kebab-case`                      |

- Avoid generic names (`data`, `temp`, `result`, `obj`, `value`, `info`, `manager`) except in very local, short-lived scopes. Name things by what they **represent**, not their type.
- Boolean variables and functions MUST use a predicate form: `isEnabled`, `hasPermission`, `canRetry`, `shouldSkip`, `isLoading`, `wasDeleted`.
- Function names should be verbs describing their action: `fetchUser`, `validateEmail`, `sendNotification`, `parseConfig` — not `userFetcher`, `emailValidator`.
- Avoid negative boolean names (`isNotValid`, `isDisabled`) — they create confusing double-negatives in conditionals. Prefer positive forms: `isValid`, `isEnabled`.

## 6. Triple Guarantee Quality Mechanism

- The project enforces a rigorous "**Triple Guarantee**" mechanism to ensure code quality across all stages of development. This is built on two core architectural philosophies: **Shift-Left (防线左移)** for developer experience and **Strict Gatekeeping (严格门禁)** for repository purity. All contributors, including AI agents, MUST adhere to this multi-layered defense strategy:
  1. **First Line of Defense: Agent/Developer Auto-fix (Shift-Left, Incremental Scope)**
     - Developers and AI Agents MUST proactively run formatters and linters (`eslint --fix`, `shfmt -w`, `prettier --write`, `markdownlint-cli2 --fix`) immediately after modifying or generating code.
     - **Scope:** Restricted to the currently open or heavily modified files to save time and maintain focus.
     - **Goal:** Maximum auto-correction and minimum mental burden. Never leave formatting or linting errors for the next stage.
  2. **Second Line of Defense: Git Commit Intercept (Incremental Shift-Left)**
     - Driven by `pre-commit` hooks.
     - **Scope Restriction**: MUST scan **only** the files currently staged for commit (`staged`). This ensures the local commit flow remains near-instantaneous (Shift-Left).
     - **Constraint**: This layer is forbidden from performing full-repository scans to avoid blocking developer velocity.
  3. **Third Line of Defense: CI/CD Strict Checks (Full-Repo Shift-Right)**
     - Driven by GitHub Actions (e.g., `.github/workflows/lint.yml`).
     - **Scope Requirement**: MUST perform a **Full-Repository** scan. This provides the final authoritative gate for repository-wide quality and detects side-effects from deep refactors.
     - **Constraint**: This is the only authorized layer for high-latency, comprehensive audits.
- **Goal: Absolute Synchronization & Strategic Placement (极致同步与战略分层)**
  - Every linting tool MUST strictly and consistently ignore standard dependency/build folders: `node_modules`, `.venv`, `venv`, `env`, `vendor`, `dist`, `build`, `out`, `target`, `.next`, `.nuxt`, `.output`, `__pycache__`, `.specify`.
  - **Shift-Left (Local/Pre-commit)**: Reserved for **lightweight, language-level, and high-frequency** checks.
    - _Examples_: Language linters (ESLint, Ruff, golangci-lint, sqlfluff, ktlint, checkmake), formatters (Prettier, shfmt, google-java-format), infrastructure (tflint, kube-linter v0.8.1+), Docker (hadolint), and critical local security (Gitleaks).
    - _Constraint_: MUST remain fast (seconds) and incrementally triggered by file extensions to maintain developer velocity.
    - > [!TIP]
      > When defining complex shell/PowerShell commands in `.pre-commit-config.yaml`, prefer **block scalars** (`>-` or `|-`) to avoid manual quote escaping. Remember: backslashes (`\`) inside block scalars are treated **literally**; do not use them to escape quotes.
  - **Shift-Right (GitHub Actions Only)**: Reserved for **heavy, high-latency, cross-file, and deep-audit** tools.
    - _Examples_: Vulnerability scanners (Trivy), full-repo security analysis (Semgrep), and remote link checkers (Lychee).
    - _Constraint_: These are the final authoritative gates for repository purity and deep security, but MUST NOT block local commit flows.
