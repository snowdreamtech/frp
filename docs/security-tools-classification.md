# Security Tools Classification

## Overview

This document defines the classification and behavior of security scanning tools in the project's CI/CD pipeline and local development environment.

## Classification System

Security tools are classified into two tiers based on their scope and criticality:

### Tier 1: Universal Security Scanners

**Classification**: Critical CI-only (1, 1)

**Tools**:

- **OSV-scanner**: Multi-language vulnerability scanner
- **Zizmor**: GitHub Actions workflow security scanner

**Behavior**:

- **Local Development**: Skipped (not checked)
- **CI Environment**: **Required** - check-env will fail if missing

**Rationale**:
These tools provide universal security coverage regardless of project language or technology stack. They are always applicable and should always be present in CI environments to ensure baseline security compliance.

**Installation**:

```bash
# In CI workflows
unirtm run setup security
```

---

### Tier 2: Language-Specific Security Tools

**Classification**: Optional CI-only (0, 1)

**Tools**:

- **Govulncheck**: Go vulnerability scanner
- **Cargo-audit**: Rust dependency auditor
- **npm-audit**: Node.js dependency auditor
- **Pip-audit**: Python dependency auditor

**Behavior**:

- **Local Development**: Skipped (not checked)
- **CI Environment**: **Optional** - check-env will warn if missing but not fail

**Rationale**:
These tools are language-specific and only relevant when the corresponding language files are present in the project. They are installed on-demand and should not block CI pipelines for projects that don't use those languages.

**Installation**:

```bash
# Installed automatically when language files are detected
unirtm run setup go      # Installs govulncheck
unirtm run setup rust    # Installs cargo-audit
unirtm run setup node    # npm-audit is part of npm
unirtm run setup python  # Installs pip-audit
```

---

## Behavior Matrix

| CRITICAL | CI_ONLY | Classification | Local Behavior | CI Behavior | Use Case |
|----------|---------|----------------|----------------|-------------|----------|
| 1 | 1 | Critical CI-only | Skip | **Must exist** (fail if missing) | Universal security scanners |
| 0 | 1 | Optional CI-only | Skip | Optional (warn if missing) | Language-specific security tools |
| 1 | 0 | Critical Always | Must exist | Must exist | Core infrastructure (Git, Make) |
| 0 | 0 | Optional Always | Optional | Optional | Language runtimes, linters |

---

## Implementation

### In `scripts/check-env.sh`

```bash
# Universal Security Scanners - Critical CI-only (1, 1)
check_tool_version "OSV-scanner" "osv-scanner" \
  "$(get_unirtm_tool_version osv-scanner)" \
  "osv-scanner --version" \
  1 \  # CRITICAL=1 (required)
  1 \  # CI_ONLY=1 (CI only)
  "osv-scanner" "OSV_FORCE_INSTALL"

check_tool_version "Zizmor" "zizmor" \
  "$(get_unirtm_tool_version zizmor)" \
  "zizmor --version" \
  1 \  # CRITICAL=1 (required)
  1 \  # CI_ONLY=1 (CI only)
  "zizmor" "ZIZMOR_FORCE_INSTALL"

# Language-Specific Security Tools - Optional CI-only (0, 1)
if has_lang_files "go.mod" "*.go"; then
  check_tool_version "Govulncheck" "govulncheck" \
    "latest" "govulncheck ./..." \
    0 \  # CRITICAL=0 (optional)
    1 \  # CI_ONLY=1 (CI only)
    "govulncheck" "GOVULN_FORCE_INSTALL"
fi

if has_lang_files "Cargo.toml" "*.rs"; then
  check_tool_version "Cargo-audit" "cargo-audit" \
    "latest" "cargo-audit --version" \
    0 \  # CRITICAL=0 (optional)
    1 \  # CI_ONLY=1 (CI only)
    "cargo-audit" "CA_FORCE_INSTALL"
fi

if [ -f "package.json" ]; then
  check_tool_version "npm-audit" "npm" \
    "$(get_version npm)" "npm audit --version" \
    0 \  # CRITICAL=0 (optional)
    1 \  # CI_ONLY=1 (CI only)
    "npm" "NPM_AUDIT_FORCE_INSTALL"
fi

if has_lang_files "requirements.txt pyproject.toml" "*.py"; then
  check_tool_version "Pip-audit" "pip-audit" \
    "$(get_unirtm_tool_version pip-audit)" \
    "pip-audit --version" \
    0 \  # CRITICAL=0 (optional)
    1 \  # CI_ONLY=1 (CI only)
    "pip-audit" "PA_FORCE_INSTALL"
fi
```

---

## CI Workflow Requirements

### For Workflows Using Universal Security Scanners

Workflows that require universal security scanning must explicitly install these tools:

```yaml
- name: "🔒 Install Security Tools"
  shell: sh
  run: |
    unirtm run setup security
```

Or include in the main setup:

```yaml
- name: "🚀 Initialize Development Environment"
  shell: sh
  run: |
    unirtm run setup security  # Install universal security tools
    unirtm run install
    unirtm run check-env
```

### For Workflows Not Using Security Scanners

If a workflow doesn't need security scanning (e.g., documentation builds), it will fail at `unirtm run check-env` unless security tools are installed. Options:

1. **Install security tools** (recommended):

   ```yaml
   run: unirtm run setup security && unirtm run check-env
   ```

2. **Skip check-env** (not recommended):

   ```yaml
   run: unirtm run setup && unirtm run install
   # Skip check-env
   ```

---

## Adding New Security Tools

### Universal Security Scanner

If adding a new universal security scanner (applicable to all projects):

1. Add to `scripts/lib/versions.sh`:

   ```bash
   VER_NEWTOOL="1.0.0"
   VER_NEWTOOL_PROVIDER="github:org/newtool"
   ```

2. Add to `scripts/lib/langs/security.sh`:

   ```bash
   install_newtool() {
     # Installation logic
   }
   ```

3. Add to `scripts/check-env.sh` as **Critical CI-only (1, 1)**:

   ```bash
   check_tool_version "NewTool" "newtool" \
     "$(get_unirtm_tool_version newtool)" \
     "newtool --version" \
     1 1 "newtool" "NEWTOOL_FORCE_INSTALL"
   ```

### Language-Specific Security Tool

If adding a new language-specific security tool:

1. Add to the appropriate language module in `scripts/lib/langs/`

2. Add to `scripts/check-env.sh` as **Optional CI-only (0, 1)**:

   ```bash
   if has_lang_files "manifest.file" "*.ext"; then
     check_tool_version "NewTool" "newtool" \
       "latest" "newtool --version" \
       0 1 "newtool" "NEWTOOL_FORCE_INSTALL"
   fi
   ```

---

## Rationale

### Why Universal Scanners are Critical

1. **Baseline Security**: OSV-scanner and Zizmor provide security coverage that applies to all projects
2. **Compliance**: Many security policies require universal vulnerability scanning
3. **Early Detection**: Catching security issues early in CI prevents them from reaching production
4. **Zero-Tolerance Policy**: Missing universal security tools indicates a serious gap in the security pipeline

### Why Language-Specific Tools are Optional

1. **Relevance**: Only applicable when specific language files are present
2. **On-Demand Installation**: Installed automatically when needed
3. **Flexibility**: Allows projects to gradually adopt language-specific security tools
4. **Efficiency**: Doesn't block CI for languages not used in the project

---

## Migration Guide

### From Previous Configuration

If you have existing workflows that relied on the old Optional CI-only behavior for universal scanners:

**Before** (all tools were Optional CI-only):

```yaml
- name: "Check Environment"
  run: unirtm run check-env
  # Would warn but not fail if OSV-scanner missing
```

**After** (universal scanners are Critical CI-only):

```yaml
- name: "Install Security Tools"
  run: unirtm run setup security

- name: "Check Environment"
  run: unirtm run check-env
  # Will fail if OSV-scanner missing
```

---

## Testing

### Local Testing

```bash
# Test check-env without security tools (should skip)
unirtm run check-env

# Force install security tools locally
OSV_FORCE_INSTALL=1 ZIZMOR_FORCE_INSTALL=1 unirtm run check-env
```

### CI Testing

```bash
# Simulate CI environment
CI=true unirtm run check-env
# Should fail if universal security tools are missing
```

---

## References

- Implementation details in `scripts/check-env.sh`
- Security tool installation in `scripts/lib/langs/security.sh`
- Tool version definitions in `scripts/lib/versions.sh`
