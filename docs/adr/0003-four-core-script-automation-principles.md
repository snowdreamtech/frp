# ADR 0003: Four Core Script Automation Principles

## Status

Accepted

## Context

The template's shell scripts (`scripts/setup.sh`, `scripts/lib/`, etc.) form the backbone of the
automated developer experience across all platforms. Without guiding principles, automation scripts
tend to degrade into fragile, poorly observable, incompatible black boxes that fail silently and in
opaque ways.

As the script library grew to cover macOS (Homebrew/MacPorts), Linux (Debian, RedHat, Alpine), and
Windows (via Git Bash delegation), we needed a unifying design philosophy to ensure all scripts
remained maintainable, predictable, and trustworthy.

## Decision

We adopt **Four Core Script Automation Principles** as the mandatory design contract for all
scripts in `scripts/`:

### Principle 1: Idempotency

Every script MUST be safely re-executable without side effects or errors. Running `unirtm run setup` ten
times must produce the same result as running it once. This means:

- Tools are only installed if not already present at the required version.
- Configuration files are only modified if the target state has not been reached.
- Setup steps explicitly check for prior completion before re-executing.

### Principle 2: Cross-Platform Compatibility

Scripts MUST run identically across all three target OS families without manual adaptation:

- **macOS**: Homebrew (primary), MacPorts (fallback).
- **Linux**: Debian/Ubuntu (`apt-get`), RedHat/Fedora (`dnf`/`yum`), Alpine (`apk`).
- **Windows**: Via delegation chain (`setup.bat` → `setup.ps1` → Git Bash → `setup.sh`).

The OS and CPU architecture are detected dynamically at runtime. No function may hard-code a
platform-specific path or binary name without a corresponding runtime guard.

### Principle 3: Observability

Every script MUST provide structured, human-readable feedback using standard ANSI colors:

- **Blue**: Progress, scanning, information.
- **Green**: Success, resource created.
- **Yellow**: Warning, dry-run mode, non-blocking issues.
- **Red**: Fatal error, critical failure.

Every long-running operation MUST emit progress indicators. The user must never be left wondering
whether a script is still running or has silently failed.

### Principle 4: Graceful Error Handling

Scripts MUST:

- Run with `set -e` (exit on error) and `set -u` (exit on undefined variable).
- Trap interrupts and clean up temporary files even on failure.
- Emit a human-readable error message with the failing command and context before exiting.
- Never silently swallow errors or continue in a potentially broken state.

## Consequences

### Positive

- **Reliability**: Scripts that follow these principles have a predictably low failure rate in
  CI and DevContainer environments, where they run without human supervision.
- **Contributor Ergonomics**: New contributors can understand and extend a script with confidence,
  knowing the design contract guarantees consistent behavior.
- **Reduced Support Burden**: The majority of "it works on my machine" issues are eliminated
  because Principle 2 ensures the same code path runs everywhere.

### Negative

- **Extra Development Effort**: Writing an idempotent, cross-platform, observable, error-safe
  script takes significantly more time than a quick-and-dirty single-platform script. This overhead
  is accepted as a long-term cost reduction.

## Alternatives Considered

### Option A: Platform-Specific Scripts

Maintain separate scripts for macOS, Linux, and Windows with no shared code.

- **Reason rejected:** The combinatorial maintenance burden grows with each new feature. A fix
  applied to the macOS script must be manually replicated to the Linux and Windows versions, leading
  to inevitable drift.

### Option B: Python or Node.js Cross-Platform Runner

Use a higher-level language (Python or Node.js) for all automation to gain native cross-platform
support and richer libraries.

- **Reason rejected:** Requires Python or Node.js to be pre-installed before `unirtm run setup` can run,
  creating a bootstrapping paradox. POSIX shell is universally available on all target platforms and
  has zero external dependencies.

### Option C: .unirtm.toml-only Automation

Express all automation as .unirtm.toml targets with no shell scripts.

- **Reason rejected:** GNU Make has subtle cross-platform differences, particularly regarding
  Windows compatibility. Complex conditional logic (OS detection, retry loops) is unwieldy in
  .unirtm.toml syntax. A hybrid approach (`.unirtm.toml` targets invoke `scripts/*.sh`) is used instead.
