# Shell Scripting Guidelines

> Objective: Define standards for writing robust, portable, and safe shell scripts for automation, CI/CD pipelines, and developer tooling, covering safety flags, variables, portability, error handling, and cross-platform compatibility.

## 1. Safety Flags & Script Header

### POSIX Shell as Default (MANDATORY)

**Unless explicitly specified**, ALL shell scripts in this project MUST be written as **POSIX-compliant shell scripts** (`#!/usr/bin/env sh`). Do NOT default to Bash. Rationale:

- Ensures compatibility with minimal environments (Alpine Linux, BusyBox, base Docker images, embedded CI).
- Prevents silent failures when `bash` is not installed.
- Enforces a higher portability standard that benefits all environments.

When Bash-specific features are genuinely required, the script MUST:

1. Use `#!/usr/bin/env bash` (NOT `#!/bin/bash`).
2. Include a comment explaining WHY Bash is required (`# Requires Bash: uses associative arrays`).
3. Explicitly document the Bash version requirement.

> [!WARNING]
> **POSIX `sh` and `local`**: While the official POSIX `sh` specification does not define the `local` keyword, it is supported by almost all modern shells (dash, ash, ksh, bash, zsh). This project **standardizes** on using `local` for variable scoping to ensure script robustness.
> To prevent `shellcheck` warnings (SC3043), we have globally disabled this check in `.shellcheckrc`.

### Global Library (MANDATORY)

To ensure consistency in logging, colors, and argument parsing, ALL functional scripts MUST source the **`.unirtm.toml`** library:

```sh
#!/usr/bin/env sh
set -eu

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard: ensure run from root
guard_project_root

# 2. Argument Parsing (Standardizes --dry-run, -v, -h)
parse_common_args "$@"
```

By sourcing this library, your script automatically gains:

- **`log_info`, `log_success`, `log_warn`, `log_error`**: Standardized colored output.
- **`guard_project_root`**: Safety guard to prevent execution outside the project root.
- **`parse_common_args`**: Unified logic for global flags.

### Bash Header Template (Only When Required)

```bash
#!/usr/bin/env bash
# Description: What this script does
# Requires Bash: <reason>

set -euo pipefail
IFS=$'\n\t'
```

> [!NOTE]
> **`pipefail` and POSIX**: `set -o pipefail` is NOT supported by strictly POSIX-compliant shells (like `dash`). It SHOULD only be used in Bash scripts (`#!/usr/bin/env bash`). For POSIX scripts, rely on `set -eu` and avoid complex pipes that require intermediate status tracking.

### Shebang Selection

- **`#!/usr/bin/env sh`** — **DEFAULT**. Use for all scripts unless Bash features are explicitly required.
- **`#!/usr/bin/env bash`** — Only when Bash-specific features are required (with justification comment).
- **NEVER use `#!/bin/bash`** — Invokes the outdated system Bash 3.x on macOS.

### Embedded Shells & Pre-commit Hooks

- When embedding shell commands inside config files (e.g., `.pre-commit-config.yaml`, `Makefiles`), use `sh -c` not `bash -c`.

### Trap & Cleanup

- Use **`trap`** for cleanup on exit and for signal handling:

  ```bash
  # Create temp file + auto-cleanup
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  trap 'echo "ERROR: Script interrupted" >&2; exit 130' INT TERM

  # Function-based cleanup for complex cleanup logic
  cleanup() {
    local exit_code=$?
    rm -rf "$WORK_DIR"
    if [[ $exit_code -ne 0 ]]; then
      log_error "Script failed with exit code $exit_code"
    fi
  }
  trap cleanup EXIT
  ```

### Execution Mode Guard

- Scripts MUST detect their execution mode at the header:

  ```bash
  # For tool scripts (execute-only) — reject being sourced
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "ERROR: This script must be executed, not sourced." >&2
    return 1
  fi

  # For environment scripts (source-only, e.g., load_env.sh) — reject being executed
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed. Run: . ${BASH_SOURCE[0]}" >&2
    exit 1
  fi
  ```

## 2. Variables & Quoting

### Quoting Rules

- Always **double-quote variable expansions** and command substitutions. Unquoted expansions are subject to word-splitting and pathname expansion:

  ```bash
  # ❌ Unquoted — breaks on spaces, globbing
  cp $source_file $dest_dir
  for file in $(ls $dir); do ...

  # ✅ Quoted — safe with spaces and special characters
  cp "$source_file" "$dest_dir"
  while IFS= read -r file; do ...
  done < <(find "$dir" -type f)
  ```

### Variable Patterns

- Use parameter expansion for safe defaults and required variables:

  ```bash
  # Default value if unset or empty
  LOG_LEVEL="${LOG_LEVEL:-info}"

  # Fail immediately with message if required variable is unset or empty
  : "${DATABASE_URL:?ERROR: DATABASE_URL is required}"
  : "${AWS_REGION:?ERROR: AWS_REGION is required}"

  # Conditional use — expand only if set
  EXTRA_ARGS="${VERBOSE:+--verbose}"
  ```

- Use **`local`** for all variables inside functions to prevent polluting the global scope. This is a project-wide requirement for all functions:

  ```bash
  install_dependency() {
    local package="${1:?Package name required}"
    local version="${2:-latest}"
    local install_path="${INSTALL_DIR}/packages/${package}"
    ...
  }
  ```

  > [!NOTE]
  > We prioritize variable safety (`local`) over strict POSIX pedantry. This extension is widely supported and required for our library architecture.

- Declare constants with **`readonly`**: `readonly MAX_RETRIES=3 TIMEOUT=30`
- Use **`UPPER_SNAKE_CASE`** for exported/environment variables and `lower_snake_case` for local function variables.

- Under strict mode (`set -eu`), accessing an unset variable results in a fatal error.
- **Always use parameter expansion** (`"${VAR:-}"`) for variables that might be optionally set or environment-provided.
- **Numeric Comparisons**: Use a default fallback (usually `:-0`) for numeric evaluations to prevent crashes:

  ```sh
  # ✅ Safe: defaults to 0 if PUID is null or unset
  if [ "${PUID:-0}" -ne 0 ]; then ...

  # ❌ Unsafe: crashes if PUID=""
  if [ "${PUID}" -ne 0 ]; then ...
  ```

- **String Casts**: For boolean-like toggles, prefer string comparison over integer checks to automatically handle null/empty states safely:

  ```sh
  # ✅ Safe string check
  if [ "${KEEPALIVE}" = "1" ]; then ...
  ```

- **Command Hardening**: Use fallbacks during string concatenation for critical commands like `su-exec` to avoid invalid formatting (e.g., `":"` instead of `"0:0"`):

  ```sh
  exec su-exec "${PUID:-0}:${PGID:-0}" "$@"
  ```

## 3. Functions & Structure

### Script Organization

- Define reusable logic as **named functions**. Keep the main script body minimal — just call functions:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  readonly SCRIPT_DIR

  # --- Functions ---
  usage() {
    cat <<-EOF
    Usage: $(basename "$0") [OPTIONS] <argument>

    Options:
      -h, --help     Show this help
      -v, --verbose  Enable verbose output
    EOF
    exit "${1:-0}"
  }

  log_info()  { printf '[INFO]  %s\n' "$*" >&1; }
  log_warn()  { printf '[WARN]  %s\n' "$*" >&2; }
  log_error() { printf '[ERROR] %s\n' "$*" >&2; }

  parse_args() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--help)    usage ;;
        -v|--verbose) set -x; shift ;;
        --)           shift; break ;;
        -*)           log_error "Unknown option: $1"; usage 1 ;;
        *)            POSITIONAL_ARGS+=("$1"); shift ;;
      esac
    done
  }

  main() {
    parse_args "$@"
    run_install
    verify_installation
  }

  # --- Entry point ---
  main "$@"
  ```

- Use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` to reliably determine the script's directory regardless of how it was invoked.
- Write a `usage()` function and call it with `exit 1` when invalid arguments are provided.

## 4. Portability & Best Practices

### POSIX vs Bash

- When targeting `/bin/sh` (Alpine containers, minimal CI images), avoid Bash-specific syntax:

  | Bash-only | POSIX sh alternative |
  | :--- | :--- |
  | `[[ expr ]]` | `[ expr ]` with careful quoting |
  | `${BASH_SOURCE[0]}` | `$0` (less reliable) |
  | `${var,,}` lowercase | `echo "$var" \| tr '[:upper:]' '[:lower:]'` |
  | `${var^^}` uppercase | `echo "$var" \| tr '[:lower:]' '[:upper:]'` |
  | Arrays: `arr=(a b c)` | Space-separated variables or multiple vars |
  | `function foo() {}` | `foo() {}` (no `function` keyword) |
  | `&>>` redirect | `>> file 2>&1` |
  | `source` | `. file` (dot) |
  | `==` in `[ ]` | `=` for string comparison |

### Cross-Platform Patterns

- Test for tool availability with `command -v` — not `which`:

  ```bash
  # ❌ which varies by OS — returns different exit codes, paths, or errors
  which docker

  # ✅ Portable and reliable
  command -v docker &>/dev/null || { log_error "docker is required but not installed"; exit 1; }
  ```

- Avoid GNU-specific flags for cross-platform portability:

  ```bash
  # ❌ GNU grep only
  grep -P '\d+' file.txt      # Perl regex
  sed -i '' 's/old/new/' file # macOS requires '' after -i; Linux doesn't

  # ✅ Portable
  grep -E '[0-9]+' file.txt   # ERE — supported everywhere
  # Use perl for in-place edit portably:
  perl -pi -e 's/old/new/g' file
  ```

- Use **`mktemp`** for temporary files and always clean up in `EXIT` trap:

  ```bash
  TMPFILE=$(mktemp /tmp/myscript.XXXXXX)
  TMPDIR=$(mktemp -d /tmp/myscript-dir.XXXXXX)
  trap 'rm -rf "$TMPFILE" "$TMPDIR"' EXIT
  ```

- Use **`printf`** instead of `echo` for formatted output — `echo` behavior for `-n`, `-e`, and backslashes varies across implementations:

  ```bash
  printf '%s\n' "$message"           # safe, portable
  printf 'File: %s, Size: %d\n' "$f" "$size"  # formatted output
  ```

## 5. Error Handling & Tooling

### Error Patterns

- Print error messages to **stderr** with function context:

  ```bash
  log_error() {
    local func="${FUNCNAME[1]:-main}"
    printf '[ERROR] [%s] %s\n' "$func" "$*" >&2
  }
  ```

- Use meaningful exit codes:
  - `0` — success
  - `1` — general error
  - `2` — misuse of shell command (invalid arguments)
  - `126` — command found but not executable (permission denied)
  - `127` — command not found
  - `128+n` — fatal error signal `n` (e.g., `130` = Ctrl+C, `137` = SIGKILL)

## 6. Cross-Platform Delegation Pattern

For any automation script that must support Windows users, follow the **Single Source of Truth (SSoT) delegation** pattern. All logic lives in `.sh`; wrappers do nothing except forward execution:

```text
script.bat   →   script.ps1   →   script.sh
(CMD entry)      (PS entry)       (POSIX logic, SSoT)
```

### Template: `script.sh` (Primary Logic)

```sh
#!/usr/bin/env sh
# Description: Your script description
set -eu
# ... all logic here ...
```

### Template: `script.ps1` (PowerShell Wrapper)

```powershell
# PowerShell wrapper — delegates to script.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "script.sh" ($args -join " ")
```

### Template: `script.bat` (CMD Wrapper)

```bat
@echo off
REM CMD wrapper — delegates to script.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0script.ps1" %*
```

> **Rule**: Wrappers MUST NOT contain any logic. Copy-pasting the `.sh` logic into `.ps1` is a violation of this rule.

## 7. Linting Requirements (All Script Types)

ALL scripts MUST pass their respective linters before being committed. This is enforced by pre-commit hooks and CI.

| Script Type | Linter | Required Flags |
| :--- | :--- | :--- |
| `.sh` (POSIX) | `shellcheck` | `--shell=sh` |
| `.sh` (Bash) | `shellcheck` | `--shell=bash` |
| `.ps1` | `PSScriptAnalyzer` | `Invoke-ScriptAnalyzer -Path .` |
| `.bat` | manual review | Keep minimal — delegate only |

> **PowerShell Linting Note (`PSAvoidUsingWriteHost`)**:
> Never use `Write-Host` for output in `.ps1` scripts, as it cannot be suppressed, captured, or redirected in older PS versions and breaks CI pipelines. Always use `Write-Output` (or `Write-Warning`/`Write-Error` where semantically appropriate) instead.

```bash
# CI step — lint all shell scripts
find . -name "*.sh" -not -path "*/node_modules/*" \
  -exec shellcheck --shell=sh --severity=warning {} +

# CI step — lint all PowerShell scripts (on Windows runner)
Get-ChildItem -Recurse -Filter "*.ps1" | ForEach-Object {
    Invoke-ScriptAnalyzer -Path $_.FullName -Severity Warning
}
```

Document any necessary `# shellcheck disable=SC2034` exclusions with a reason. Suppressing linter warnings without justification is not permitted.

## 8. High-Performance & Robustness Patterns

### Atomic File Updates (Build-then-Swap)

When a script needs to modify a file, avoid direct append/redirection to the source. Use a temporary file to ensure atomicity.

```sh
# POSIX-compliant atomic update
tmp_file=$(mktemp)
# 1. Process/Build
cat header.txt > "$tmp_file"
sed 's/foo/bar/g' source.txt >> "$tmp_file"
# 2. Atomic Swap
mv "$tmp_file" source.txt
```

### Universal Versioning Detection

Standardize version detection across different ecosystems to ensure a zero-config experience.

```sh
# Helper to extract version from various manifests
get_project_version() {
  if [ -f "package.json" ]; then
    grep '"version":' package.json | head -n 1 | sed 's/.*"version":[[:space:]]*"//;s/".*//'
  elif [ -f "Cargo.toml" ]; then
    grep '^version =' Cargo.toml | head -n 1 | sed -e 's/.*"\(.*\)"/\1/' -e "s/.*'\(.*\)'/\1/"
  elif [ -f "VERSION" ]; then
    cat VERSION | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  fi
}
```

### Execution Context Guard

Prevent scripts from running in unintentional directories.

```sh
# Verify project root
if [ ! -f "CHANGELOG.md" ] || [ ! -d ".git" ]; then
  printf "ERROR: This script must be run from the project root.\n" >&2
  exit 1
fi
```

### Robust Shared Summary Logging

When multiple scripts or multiple invocations of the same script contribute to a single report (e.g., in CI), use a **shared summary file** and top-level guard:

```sh
# ── Shared Summary Management ──
if [ -z "$SHARED_SUMMARY_FILE" ]; then
  # Initialize only ONCE
  SHARED_SUMMARY_FILE=$(mktemp)
  export SHARED_SUMMARY_FILE
  _IS_TOP_LEVEL=true
  # ... Print Header/Legend ...
fi

# ... Log items to $SHARED_SUMMARY_FILE ...

if [ "$_IS_TOP_LEVEL" = "true" ]; then
  # Final Output and Cleanup only ONCE
  cat "$SHARED_SUMMARY_FILE"
  rm -f "$SHARED_SUMMARY_FILE"
fi
```

### Persistent Interactive Prompt Pattern (Next Actions)

Every top-level script MUST provide a standardized "Next Actions" prompt to guide the user. These prompts MUST be guarded by `_IS_TOP_LEVEL` to prevent clutter when scripts are called as dependencies.

```sh
# ── Standardized Next Actions ────────────────────────────────────────────────
if [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\nNext Actions:\n"
    printf "  - Run make verify to ensure project health.\n"
fi
```

### Native Binary Installation vs. Runtime Wrappers

For system-level utilities and linters, prefer **natively managed binaries** in `scripts/setup.sh` over npm/pip wrappers.

- **Rationale**: Avoids API rate limits (e.g., GitHub API downloads during npm install), reduces runtime dependency bloat, and ensures strict version control via `.unirtm.toml`.
- **Example**: `editorconfig-checker` should be installed as a CGO/Go binary via `curl`, not via `npm install`.

### Language-Aware Health Check Pattern

To balance environmental strictness with robustness | **Secondary (On-Demand)** | Go, PHP, Java, Rust, Docker, etc. | **Robust**: Skip with `⏭️` or warn but exit with `0` (FUNCTIONAL). |

- **Language-Aware & Dynamic Detection**: Health checks and tool installations MUST be context-sensitive.

```sh
# check-env.sh implementation pattern

# 1. Detection Helpers (from lib/common.sh)
# has_lang_files "manifests" "extensions"

# 2. Main Health Check Groups
# ── Group: Language Runtimes ──
if has_lang_files "go.mod" "*.go"; then
  check_version "Go" "go" "1.21.0" "go version" 0
else
  # Explicitly log skip for common backend languages
  log_info "⏭️  Go: Skipped (no go files)"
fi

# ── Group: Mobile Support (Selective Display) ──
# Only show group header if relevant files exist
if has_lang_files "Package.swift" "*.swift *.kt *.dart"; then
  log_info "── Mobile Support ──"
  if has_lang_files "Package.swift" "*.swift"; then
    check_version "Swift" "swift" "5.0" "swift --version" 0
  fi
  # ... other mobile tools ...
fi
```

**Key Principles**:

1. **Context Sensitivity**: Do not fail or warn about missing tools that the project doesn't use.
2. **Explicit Skips**: For major backend/frontend languages, explicitly log `⏭️  Skipped` to affirm the check was considered but bypassed.
3. **Clean Signal**: Hide entire groups (e.g., Mobile, Security) if no triggers are found, ensuring developers only see what matters to them.

## 9. Defensive Tool Installation Pattern (MANDATORY)

To ensure "World-Class" stability and performance in polyglot environments, all tool installation functions (e.g., in `setup.sh`) MUST follow the **Defensive & Lazy-Loading** pattern. This prevents "Setup Fatigue" and fragile installations.

### Implementation Template

```sh
install_example_tool() {
  local _T0=$(date +%s)
  local _TITLE="Example Tool"
  local _PROVIDER="npm:@example/cli"

  # 1. Dry Run Guard (Idempotency)
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "$_TITLE" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # 2. Context Sentinel (Environment Isolation)
  if is_heavy_tool && ! is_ci_env; then
    log_summary "Tool Group" "$_TITLE" "⏭️ Local skip" "-" "0"
    return 0
  fi

  # 3. File Sentinel (Lazy Loading)
  # Only install if project actually needs it
  if ! has_lang_files "manifest.json" "*.ext"; then
    log_summary "Tool Group" "$_TITLE" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  # 4. Runtime Prerequisite (Dependency Safety)
  # Verify cargo/npm/go exists before using provider
  if ! command -v npm >/dev/null 2>&1; then
    log_summary "Tool Group" "$_TITLE" "⚠️ npm missing" "-" "0"
    return 0
  fi

  # 5. Execution & Reporting
  local _STAT="✅ unirtm"
  run_unirtm install "$_PROVIDER" || _STAT="❌ Failed"
  log_summary "Tool Group" "$_TITLE" "$_STAT" "$(get_version example-tool)" "$(($(date +%s) - _T0))"
}
```

### Core Requirements

1. **Idempotency**: Every function MUST be safe to run multiple times. Use `DRY_RUN` checks to mock the result without state changes.
2. **Performance (Lazy Loading)**: Never install a language-specific tool unless the corresponding files are detected.
3. **Strict Error Handling**: Use `|| _STAT="❌ Failed"` pattern to ensure the summary table accurately reflects failures without crashing the entire setup sequence.
4. **SSoT Versioning**: Always use `get_version` or `get_unirtm_tool_version` to pull versions from `.unirtm.toml` for the summary table.
5. **Human-Centric Feedback**: Large SDK installations (e.g., Swift, .NET, Java) MUST NOT be silent. Never suppress progress output (`UNIRTM_QUIET=1`) for commands known to take more than a few seconds. Always provide a clear warning using `log_warn` before starting a potentially long download/installation.
6. **Robust Interruption Handling**: All wrapper functions (like `run_unirtm`) MUST check for signal-based exit statuses (e.g., `_STATUS -gt 128`). If a command is interrupted by the user (Ctrl+C), the script MUST NOT attempt to retry and MUST exit immediately to prevent "stuck" states.
7. **UniRTM Command Resilience**: All wrapper functions (like `run_unirtm`) MUST check for signal-based exit statuses (e.g., `_STATUS -gt 128`).
8. **Dynamic Registration Pattern**: To eliminate the "UniRTM Tax" on empty projects, setup modules SHOULD use `unirtm use --local [tool]@[version]` to register runtimes into `.unirtm.toml` only after positive detection of source files. This ensures the project config stays lean while remaining comprehensive in capabilities.

## 10. Language-Specific Best Practices

Refer to the following individual files for deeper language-specific shell patterns:

- [swift.md](./swift.md) — Swift-specific linter and runtime logic.
- [javascript.md](./javascript.md) — Node/npm/pnpm management patterns.
- [rust.md](./rust.md) — Cargo and rustup integration patterns.
