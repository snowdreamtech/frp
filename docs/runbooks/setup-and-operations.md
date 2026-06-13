# Runbook: Setup and Operations

**Service**: Snowdream Tech AI IDE Template
**Audience**: Contributors and operators
**Last updated**: 2026-03-22

---

## 1. Service Overview

### What It Does

The Snowdream Tech AI IDE Template provides a foundational, enterprise-grade scaffold for
multi-AI IDE collaboration. It maintains a Single Source of Truth (`.agent/rules/`) for AI
behavioral rules distributed to 50+ IDEs via a symlink/redirect pattern.

### Dependencies

| Dependency | Version  | Purpose                      |
| ---------- | -------- | ---------------------------- |
| `unirtm`     | ≥ 2024.x | Toolchain version management |
| `make`     | System   | Task orchestration           |
| `git`      | ≥ 2.x    | Version control and hooks    |
| `node`     | ≥ 20.x   | Documentation (VitePress)    |
| `python`   | ≥ 3.10.x | Pre-commit hooks             |

### SLA Targets

| Metric                | Target       |
| --------------------- | ------------ |
| CI pipeline (lint)    | ≤ 10 minutes |
| Pre-commit hooks      | ≤ 5 seconds  |
| Runbook response (P1) | ≤ 24 hours   |

---

## 2. Common Operations

### Bootstrap a New Environment

```bash
# Clone the repository and initialize
git clone <repo-url>
cd <repo>
git config core.ignorecase false   # MANDATORY on macOS/Windows
unirtm run setup                          # installs unirtm + core tools
unirtm run install                        # installs project dependencies (Node, Python venv)
unirtm run verify                         # validates everything is green
```

### Run Quality Checks

```bash
unirtm run lint          # run all local linters
unirtm run audit         # run security audit (Gitleaks + dependency scan)
unirtm run verify        # run all checks in sequence
```

### Update Dependencies

```bash
# Node packages (documentation)
cd docs && pnpm update

# Python packages (pre-commit hooks)
pre-commit autoupdate

# Tool versions
unirtm upgrade
```

### Build Documentation

```bash
cd docs && pnpm run build       # production build
cd docs && pnpm run dev         # development server (hot-reload)
```

### Create a Release

1. Merge all feature/fix branches to `dev`.
2. Open a Release PR: `dev` → `main`.
3. release-please bot will label and create the release commit.
4. Merge the release PR; GoReleaser will tag and publish.

---

## 3. Alerts and Diagnostics

### CI Lint Failed

**Symptom**: `lint.yml` GitHub Action fails.

**Diagnosis**:

```bash
# Reproduce locally
unirtm run lint

# Check specific linter output
unirtm run lint 2>&1 | grep -A5 "error\|failed"
```

**Likely causes**:

- Markdown formatting (`markdownlint-cli2`)
- YAML syntax (`yamllint`)
- Shell script issues (`shellcheck`)

**Solution**: Fix the reported issues, then `git commit --amend` or add a fix commit.

---

### Pre-commit Hook Fails on macOS

**Symptom**: `unirtm run install` completes but hooks fail with Python/binary not found errors.

**Diagnosis**:

```bash
# Check venv
ls .venv/bin/python
pre-commit --version
```

**Solution**:

```bash
# Rebuild the venv
rm -rf .venv
unirtm run install
```

---

### Gitleaks False Positive

**Symptom**: `gitleaks quality check` fails on a known-safe value.

**Diagnosis**:

```bash
gitleaks detect --source . --verbose 2>&1 | grep "Finding"
```

**Solution**: Add the fingerprint to `.gitleaksignore`:

```bash
# Get the fingerprint from the gitleaks output, then:
echo "<fingerprint>" >> .gitleaksignore
```

---

### Broken Symlinks After Clone

**Symptom**: IDE shows errors; symlink targets are missing.

**Diagnosis**:

```bash
find . -xtype l   # list broken symlinks
```

**Solution**:

```bash
# Re-initialize symlinks
unirtm run setup
```

---

## 4. Escalation Path

| Severity      | Contact                                             | Channel          |
| ------------- | --------------------------------------------------- | ---------------- |
| P1 — Critical | [snowdreamtech@qq.com](mailto:snowdreamtech@qq.com) | Email            |
| P2 — High     | GitHub issue                                        | `bug` label      |
| P3 — Low      | GitHub discussion                                   | `question` label |

---

## 5. Recovery Procedures

### Reset to Clean State

```bash
git stash                    # save local changes
git checkout main            # switch to main
git pull origin main         # fetch latest
unirtm run setup                   # re-initialize toolchain
unirtm run install                 # re-install dependencies
unirtm run verify                  # confirm clean state
```

### Rollback a Bad Commit

```bash
# View recent history
git log --oneline -10

# Revert a specific commit (non-destructive)
git revert <commit-sha>
git push origin dev
```

### Emergency: Force a CI Re-run

```bash
# Trigger workflow re-run via GitHub CLI
gh run rerun <run-id>
```
