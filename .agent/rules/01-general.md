# General Configuration Best Practices

> This file defines the core behavior and operational standards, focusing on general best practices independent of specific tools.

## 1. Language & Communication

- MUST use **Simplified Chinese (简体中文)** for all user-facing communication and documentation (README, user guides, error messages presented to end-users).
- Code, code comments, Git commit messages, and internal API documentation MUST be in **English**.
- Documentation is layered: technical specs and inline docs → English; product documentation and user-facing changelogs → Simplified Chinese.
- Never use machine-translated text directly. All Chinese documentation must be written or reviewed by a human fluent in Chinese.
- **Emoji usage**: use moderately to emphasize key points and mark structure, while maintaining professionalism and technical rigor. Avoid emoji in code comments, commit messages, or error messages.
- For technical documentation targeted at international audiences, provide both English and Simplified Chinese versions. The English version is the canonical technical reference; the Chinese version is the accessibility surface.

## 2. Standards & Idempotency

- Maintain **idempotency** in all scripts, infrastructure, and configuration: running any operation multiple times MUST produce the same result as running it once. Idempotency validation: re-run the script/apply and verify state is identical without errors or unintended duplication.
- Prefer **declarative** over imperative configuration (e.g., desired-state IaC like Terraform/Ansible over ad-hoc shell scripts). Declarative configs are self-documenting and inherently idempotent when applied correctly.
- Avoid side effects in initialization code. Setup scripts must be safe to re-run without human intervention.
- **Objective Truth over Subjective Assumption**: All technical decisions, including version pinning, configuration defaults, and feature availability, MUST be based on objective facts verified through documentation, search, or direct testing. NEVER assume or "guess" a version number or a tool's behavior based on similar tools. If uncertainty exists, it MUST be explicitly stated and resolved through verification before implementation.
- **Robustness Principle (输入宽容、输出严谨)**: All components, scripts, and APIs MUST be tolerant of variations in input while remaining strict and standardized in their output.
  - **Input Tolerance**: Support variations such as case-insensitive version prefixes (`v`, `V`), trailing slashes in URLs, or flexible boolean strings (`true`, `1`, `yes`).
  - **Output Strictness**: Guarantee consistent, predictable, and standardized output formats (e.g., pure numeric version strings, canonicalized paths, strictly formatted JSON).

### 2.1 The Four Core Script Automation Principles (四大核心脚本规范)

All automation scripts (especially those in `scripts/`) MUST strictly adhere to these four rigid architectural benchmarks to guarantee performance, reliability, and cross-platform idempotency:

1. **On-Demand Loading (按需加载，按需运行):**
   - Scripts MUST exclusively install and invoke language tooling (linters, formatters, SDKs) ONLY when their specific source files are detected in the project tree (e.g., via `has_lang_files`). Global pre-installations are strictly forbidden to mitigate the "UniRTM Tax" and avoid "ghost tool" resolution.
2. **Environment Weight Tiering (轻量级放本地，重量级放CI):**
   - Operations required before a local Git commit (e.g., source formatting, lightweight syntax linting) MUST run locally.
   - Heavyweight operations that are slow or severely network-dependent (e.g., pulling CVE vulnerability databases, large dependency audits like `trivy` or `osv-scanner`) MUST be locked behind an `is_ci_env` guard and gracefully skipped locally to prevent developer disruption.
3. **Zero-Error Core Commands (确保核心套件正常无报错):**
   - The unified command suite (`unirtm install`, `make verify`, `make audit`) MUST always exit cleanly with `0` errors across all valid environments and must fail elegantly or skip rather than crashing on missing optional dependencies.
4. **Universal Best Practices & Poly-Arch Constraints (最佳实践与多系统双架构统一):**
   - The installation pipelines and lint operations for all languages MUST implement the ecosystem's globally accepted "Best Practices".
   - Compatibility MUST be natively maintained for all Target OSs (`windows`, `linux`, `macos`) and Target Architectures (`x86_64`, `arm64`). Arbitrary Bash fallback scripts for downloads (like heavy `curl` wrappers) are completely prohibited; delegate such logic natively to the toolchain orchestrator (`unirtm` TOML configuration arrays like `asset = [{match="aarch64"}]`).

- **CLI-First Efficiency**: When performing research, validation, or environment inspection, command-line tools (CLI) MUST be prioritized over browser-based methods. Browser interaction should only be used as a secondary fallback when CLI tools are unavailable or insufficient for the task, to minimize latency and improve execution speed.
- When a non-idempotent operation is unavoidable, guard it explicitly:

  ```bash
  # Idempotency guard examples
  [ -f /etc/myapp/config ] && exit 0          # file-based guard
  psql -c "CREATE TABLE IF NOT EXISTS ..."    # SQL-level guard
  kubectl apply --dry-run=client -f manifest  # Kubernetes dry-run validation
  ```

- Document the reason and guard mechanism for every non-idempotent operation.
- **No Temporary Files in Git**: All temporary files created during debugging, testing, or development (e.g., `test.txt`, `tmp.json`, empty debug scripts) MUST NEVER be committed to version control. They must be deleted immediately after testing or placed in a `.gitignore`'d directory (e.g., `.tmp/`). AI agents must proactively revert any such accidental commits before merging.
- **CI/CD Orchestration (Deadlock-Free Logic)**: All workflows MUST define concurrency at the **job-level** with unique prefixes. Avoid top-level concurrency for reusable workflows to prevent deadlocks in nested contexts.
- **CI Reporting Standard (Dual-Sentinel Pattern)**: When scripts span multiple GHA steps, use both file-based checks (`GITHUB_STEP_SUMMARY`) and environment-based guards (`GITHUB_ENV`) to prevent duplicate report headers or legends.

## 3. Cross-Platform Compatibility

- **Full Compatibility**: All scripts, tooling, and automation MUST support **Linux (Debian/RedHat/Alpine)**, **macOS**, and **Windows** simultaneously.
- Avoid hard-coding system-specific paths or commands. Adapt dynamically:
  - Use `path.join()` (Node.js), `os.path.join()` / `pathlib.Path` (Python), `filepath.Join()` (Go).
  - Detect OS at runtime: `process.platform`, `sys.platform`, `runtime.GOOS`.
- **No Absolute Local Paths**: All paths in scripts, configurations, documentation, and source code MUST be **relative** to the project root or the current file. Never use paths starting with `/Users/`, `C:\`, or `~`. This is critical for portability across different developer machines and CI environments.
- **Cross-Platform Shell Delegation Pattern (MANDATORY)**: When shell scripts are required, provide **three** script variants following a strict delegation chain to ensure a Single Source of Truth (SSoT):
  1. **`script.sh`** — POSIX-compliant shell script containing **all primary logic**.
  2. **`script.ps1`** — PowerShell wrapper that detects `sh` and delegates: `Invoke-ShellDelegation "script.sh" ($args -join " ")`.
  3. **`script.bat`** — CMD wrapper that delegates to PowerShell: `powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0script.ps1" %*`.

  Wrappers MUST NOT duplicate logic. Their only purpose is to bridge the platform gap into the `.sh` script.

- **Lint Requirements**: All three script types MUST pass their respective linters before commit:
  - `.sh` — **ShellCheck** (with `--shell=sh` for POSIX compliance)
  - `.ps1` — **PSScriptAnalyzer** (`Invoke-ScriptAnalyzer`)
  - `.bat` — No dedicated linter; keep minimal (delegate only, no logic)

- Normalize line endings: configure `.gitattributes` with `* text=auto` to prevent CRLF/LF conflicts across platforms:

  ```gitattributes
  # .gitattributes — normalize line endings
  * text=auto
  *.sh  text eol=lf     # shell scripts always LF
  *.ps1 text eol=crlf   # PowerShell scripts always CRLF
  *.bat text eol=crlf   # batch files always CRLF
  *.png binary          # binary files — no normalization
  ```

- Test on all target platforms in CI using matrix builds: `runs-on: [ubuntu-latest, macos-latest, windows-latest]`.
- Cross-platform gotchas to avoid:
  - `sed -i` behaves differently on macOS (requires `''` after `-i`) vs Linux
  - `ls`, `date`, `xargs`, `find` often have BSD (macOS) vs GNU (Linux) flag differences
  - PATH separator: `:` on Unix, `;` on Windows
  - Case sensitivity: Linux is case-sensitive, macOS is case-insensitive by default, Windows is case-insensitive

## 4. Network Operations

- **Retry Mechanism**: When using network tools (`curl`, `wget`, scripts) to download resources, a retry mechanism **MUST** be configured:

  ```bash
  # curl with retry
  curl --retry 5 --retry-delay 2 --retry-connrefused --fail \
       --connect-timeout 10 --max-time 60 \
       -o output.tar.gz "$URL"

  # wget with retry
  wget --tries=5 --waitretry=3 --timeout=60 -O output.tar.gz "$URL"
  ```

  Implement exponential backoff (1s → 2s → 4s → 8s) with a maximum of 5 attempts for application-level retries.

- **Proxy**: When downloading GitHub resources, the `GITHUB_PROXY` **MUST** be set and prefixed to all GitHub URLs to ensure stable access in restricted network environments. The default proxy for this project is `https://gh-proxy.sn0wdr1am.com/`:

  ```bash
  GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"
  curl "${GITHUB_PROXY}https://github.com/org/repo/archive/main.tar.gz" -o repo.tar.gz
  ```

- **Checksum Verification**: Validate downloaded artifacts with SHA-256 before using them. Store checksums in version-controlled `checksums.sha256`:

  ```bash
  sha256sum --check checksums.sha256   # Linux
  shasum -a 256 --check checksums.sha256  # macOS
  ```

- Configure connection and read timeouts for all HTTP clients. Never use an infinite timeout in production code.
- For services behind a proxy, support `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` environment variables.

## 5. Security & Audit

- **Explicit Definition**: All configurations (GPG, SSH, signing keys, certificates) MUST explicitly specify key parameters (Key ID, fingerprint, expiry) to ensure auditability and reproducibility:

  ```bash
  # ❌ Ambiguous — which key?
  gpg --sign file.tar.gz

  # ✅ Explicit Key ID — auditable and reproducible
  gpg --sign --local-user 0xABCD1234 file.tar.gz
  ```

- **Clean Config**: Configuration files should remain "clean" — avoid irrelevant version numbers, greetings, or non-functional comments (`no-emit-version`, `no-greeting`).
- Avoid printing sensitive information (API tokens, passwords, PII, internal IPs) in logs, console output, or error messages. Sanitize before logging:

  ```bash
  # ❌ Logs secret
  echo "Connecting with password: $DB_PASSWORD"

  # ✅ Masked
  echo "Connecting to database as: $DB_USER"
  ```

- Follow the **Principle of Least Privilege**: grant only the minimum permissions required. Escalate permissions temporarily and explicitly, then revoke immediately.
- Sensitive data classification (handle accordingly):
  - **Critical**: credentials, private keys, session tokens — never log, never expose in URLs, encrypt at rest.
  - **Sensitive**: email addresses, user IDs, IP addresses — mask in logs, protect in transit.
  - **Internal**: configuration values, internal URLs — restrict access, do not expose publicly.
- Use **short-lived credentials** over long-lived static keys: prefer OAuth tokens, AWS STS, Workload Identity, and mTLS client certificates with short TTLs.

## 6. Documentation Standards

- Every repository MUST have a `README_zh-CN.md` (Simplified Chinese) and `README.md` (English) at the root with:
  - Project description and purpose
  - Prerequisites (runtime versions, system dependencies)
  - Quick start instructions (< 5 commands to run the project)
  - Link to full documentation and contributing guide
  - Build status and coverage badges

- All public APIs MUST be documented. Use the format appropriate for the language:

  ```typescript
  /**
   * Authenticate a user with email and password.
   *
   * @param email - The user's email address (must be verified)
   * @param password - The plaintext password (min 8 chars)
   * @returns A signed JWT access token (expires in 24h)
   * @throws {AuthenticationError} If credentials are invalid
   * @throws {AccountLockedError} If the account is locked after 5 failed attempts
   *
   * @example
   * const token = await authenticate("user@example.com", "password123");
   */
  async function authenticate(email: string, password: string): Promise<string> { ... }
  ```

- Architecture Decision Records (ADRs) MUST be created for all significant architectural decisions. Store them in `docs/adr/`:

  ```
  docs/adr/
  ├── 0001-use-postgresql-over-mongodb.md
  ├── 0002-adopt-event-sourcing.md
  └── 0003-use-graphql-for-public-api.md
  ```

  Each ADR MUST include: context, decision, consequences (positive and negative), and alternatives considered.

- Keep documentation in sync with code. A PR that changes behavior MUST also update the relevant documentation. Failed documentation reviews are sufficient cause to request changes on a PR.

## 7. Operational Runbooks

- Every production service MUST have a runbook in `docs/runbooks/` covering:
  - **Service overview**: purpose, dependencies, SLA
  - **Common operations**: deploy, rollback, scale, restart
  - **Alerts and diagnostics**: what each alert means, diagnostic commands:

    ```bash
    # Check service health
    kubectl get pods -n production -l app=myservice
    kubectl logs -n production -l app=myservice --tail=100 | grep ERROR

    # Check database connections
    kubectl exec -n production deploy/myservice -- \
      psql "$DATABASE_URL" -c "SELECT count(*) FROM pg_stat_activity;"
    ```

  - **Escalation path**: who to contact for each class of incident (P1, P2, P3)
  - **Recovery procedures**: step-by-step restoration from backup or rollback

- Link every monitoring alert directly to its runbook URL. Dead alert-to-runbook links are treated as documentation debt.
- Review runbooks annually and after every P1/P2 incident. Stale runbooks are often worse than no runbook.
