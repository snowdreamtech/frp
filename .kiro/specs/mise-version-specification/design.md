# Mise Version Specification Bugfix Design

## Overview

This bugfix addresses a critical version locking violation where ~40+ `run_mise install` calls across `scripts/lib/langs/*.sh` are missing version specifications. The bug causes mise to install the latest available version from providers instead of the pinned versions defined in `.unirtm.toml`, breaking reproducibility and environment consistency. The fix involves systematically appending `@${_VERSION:-}` to all affected `run_mise install "${_PROVIDER:-}"` calls to enforce version locking.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when `run_mise install` is called with a provider but without a version suffix
- **Property (P)**: The desired behavior - mise SHALL install the exact version specified in versions.sh
- **Preservation**: Existing fast-path checks, DRY_RUN mode, and error handling that must remain unchanged
- **run_mise**: Helper function in `scripts/lib/helpers.sh` that wraps mise installation commands
- **\_PROVIDER**: Variable containing the mise provider string (e.g., `github:hadolint/hadolint`)
- **\_VERSION**: Variable containing the version string from versions.sh (e.g., `VER_HADOLINT="2.14.0"`)
- **setup*registry*\***: Functions that dynamically register tools with mise using `mise registry set`
- **get_mise_tool_version**: Helper function that extracts version from provider string or versions.sh

## Bug Details

### Bug Condition

The bug manifests when `run_mise install "${_PROVIDER:-}"` is called without a version suffix in any of the language module installation functions. The mise tool interprets this as a request to install the latest version from the provider, ignoring the pinned version defined in `.unirtm.toml`.

**Formal Specification:**

```
FUNCTION isBugCondition(installCall)
  INPUT: installCall of type String (shell command)
  OUTPUT: boolean

  RETURN installCall MATCHES 'run_mise install "${_PROVIDER:-}"'
         AND NOT installCall CONTAINS '@${_VERSION'
         AND NOT installCall CONTAINS '@${'
         AND correspondingVersionExists(installCall,versions.sh)
END FUNCTION
```

### Examples

- **Hadolint**: `run_mise install "${_PROVIDER:-}"` where `_PROVIDER="github:hadolint/hadolint"` installs latest instead of `VER_HADOLINT="2.14.0"`
- **Shellcheck**: `run_mise install "${_PROVIDER:-}"` where `_PROVIDER="github:koalaman/shellcheck"` installs latest instead of `VER_SHELLCHECK="0.11.0"`
- **Actionlint**: `run_mise install "${_PROVIDER:-}"` where `_PROVIDER="github:rhysd/actionlint"` installs latest instead of `VER_ACTIONLINT="1.7.12"`
- **Dockerfile-utils**: `run_mise install "${_PROVIDER:-}"` where `_PROVIDER="npm:dockerfile-utils"` installs latest instead of `VER_DOCKERFILE_UTILS="0.16.3"`
- **Counter-example (correct)**: `run_mise install "${VER_GRAIN_PROVIDER:-}@${VER_GRAIN:-}"` correctly installs Grain version 0.7.2

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**

- Fast-path version checks using `is_version_match` must continue to skip reinstallation when correct version exists
- DRY_RUN mode must continue to preview installations without executing them
- Error handling with `|| _STAT="❌ Failed"` must continue to log failures and proceed
- Tools already managed in .mise.toml must continue to respect .mise.toml as source of truth
- `setup_registry_*` functions must continue to dynamically register providers before installation
- Log summary formatting and timing measurements must remain unchanged

**Scope:**
All installation calls that do NOT involve the bug condition should be completely unaffected by this fix. This includes:

- Tools that already have correct version specifications (e.g., Grain, Java)
- Tools installed via runtime-only calls (e.g., `run_mise install ruby`, `run_mise install dart`)
- Tools with version extraction via `get_mise_tool_version` (e.g., Perl, Erlang, Mojo)
- Tools installed via pipx or other package managers
- All version checking, logging, and error handling logic

## Hypothesized Root Cause

Based on the bug description and code analysis, the root causes are:

1. **Inconsistent Version Specification Pattern**: The codebase has three different patterns:
   - ✅ Correct: `run_mise install "${VER_GRAIN_PROVIDER:-}@${VER_GRAIN:-}"` (explicit version)
   - ✅ Correct: `run_mise install "perl@$(get_mise_tool_version perl)"` (version extraction)
   - ❌ Buggy: `run_mise install "${_PROVIDER:-}"` (missing version suffix)

2. **Missing Version Variable Assignment**: Many functions define `_PROVIDER` but fail to define corresponding `_VERSION` variable from versions.sh, making it impossible to append the version suffix

3. **Copy-Paste Error Propagation**: The buggy pattern was likely copied across multiple language modules without recognizing the version locking requirement

4. **Incomplete Migration**: Some modules were updated to use version specifications (Grain, Java) while others were left with the old pattern

## Correctness Properties

Property 1: Bug Condition - Version Locking Enforcement

*For any* `run_mise install` call where a provider is specified and a corresponding version exists in versions.sh, the fixed function SHALL install the exact version specified in versions.sh by appending `@${_VERSION:-}` to the provider string.

Validates: Requirements 2.1, 2.2, 2.3, 2.4

Property 2: Preservation - Existing Installation Behavior

*For any* installation call that does NOT match the bug condition (runtime-only installs, tools with version extraction, tools without defined versions), the fixed code SHALL produce exactly the same behavior as the original code, preserving all existing installation patterns and error handling.

Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**Files**: All files in `scripts/lib/langs/*.sh` with buggy `run_mise install` calls

**Pattern**: Systematic transformation of installation calls

**Specific Changes**:

1. **Add Version Variable Assignment**: For each affected function, add `_VERSION` variable assignment after `_PROVIDER`:

   ```sh
   local _PROVIDER="${VER_HADOLINT_PROVIDER:-}"
   local _VERSION="${VER_HADOLINT:-}"
   ```

2. **Update run_mise install Call**: Transform the installation call to include version suffix:

   ```sh
   # Before (buggy):
   run_mise install"${_PROVIDER:-}" || _STAT_HADO="❌ Failed"

   # After (fixed):
   run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_HADO="❌ Failed"
   ```

3. **Verify Version Variable Exists**: Ensure corresponding `VER_*` variable is defined in `.unirtm.toml`

4. **Update get_mise_tool_version Calls**: For functions using `get_mise_tool_version`, verify the provider string is passed correctly

5. **Document Version Source**: Add comments indicating version is sourced from versions.sh for clarity

### Affected Files and Functions

Based on grep analysis, the following files require fixes:

- `scripts/lib/langs/cpp.sh`: `install_clang_format()` - clang-format
- `scripts/lib/langs/docker.sh`: `install_hadolint()`, `install_dockerfile_utils()` - hadolint, dockerfile-utils
- `scripts/lib/langs/java.sh`: `install_java_lint()` - google-java-format
- `scripts/lib/langs/lua.sh`: `install_stylua()` - stylua
- `scripts/lib/langs/openapi.sh`: `install_spectral()` - spectral
- `scripts/lib/langs/ruby.sh`: `setup_registry_rubocop()` - rubocop
- `scripts/lib/langs/runner.sh`: `install_just()`, `install_task()` - just, task
- `scripts/lib/langs/security.sh`: `install_osv_scanner()`, `install_zizmor()`, `install_cargo_audit()` - osv-scanner, zizmor, cargo-audit
- `scripts/lib/langs/shell.sh`: `install_shfmt()`, `install_shellcheck()`, `install_actionlint()` - shfmt, shellcheck, actionlint
- `scripts/lib/langs/terraform.sh`: `install_tflint()` - tflint
- `scripts/lib/langs/base.sh`: `install_gitleaks()`, `install_checkmake()` - gitleaks, checkmake

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code by verifying latest versions are installed, then verify the fix works correctly by ensuring pinned versions are installed and existing behavior is preserved.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that mise installs latest versions instead of pinned versions when version suffix is missing.

**Test Plan**: Write tests that invoke affected installation functions on UNFIXED code and verify that mise attempts to install the latest version instead of the pinned version from versions.sh. This can be done by:

1. Mocking mise to capture installation commands
2. Verifying the command does NOT contain version suffix
3. Comparing installed version with versions.sh (should differ if latest is newer)

**Test Cases**:

1. **Hadolint Latest Install**: Call `install_hadolint()` on unfixed code, verify mise installs latest instead of VER_HADOLINT="2.14.0" (will fail on unfixed code)
2. **Shellcheck Latest Install**: Call `install_shellcheck()` on unfixed code, verify mise installs latest instead of VER_SHELLCHECK="0.11.0" (will fail on unfixed code)
3. **Multiple Tools**: Test 5-10 affected tools to confirm pattern is consistent (will fail on unfixed code)
4. **Version Drift Detection**: Run setup on two different dates, verify different versions are installed (will fail on unfixed code)

**Expected Counterexamples**:

- `run_mise install "github:hadolint/hadolint"` installs version 2.15.0 (latest) instead of 2.14.0 (pinned)
- `run_mise install "github:koalaman/shellcheck"` installs version 0.11.1 (latest) instead of 0.11.0 (pinned)
- Possible causes: missing `@${_VERSION:-}` suffix, missing `_VERSION` variable assignment, incorrect version variable name

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior (installs pinned version).

**Pseudocode:**

```
FOR ALL installCall WHERE isBugCondition(installCall) DO
  result := executeFixedInstall(installCall)
  ASSERT result.installedVersion = versions.sh[tool]
  ASSERT result.command CONTAINS '@${_VERSION:-}'
END FOR
```

**Test Plan**: After applying the fix, verify that:

1. All affected `run_mise install` calls include version suffix
2. Mise installs exact versions from versions.sh
3. Multiple runs produce identical versions across environments

**Test Cases**:

1. **Hadolint Pinned Install**: Call `install_hadolint()` on fixed code, verify mise installs VER_HADOLINT="2.14.0" exactly
2. **Shellcheck Pinned Install**: Call `install_shellcheck()` on fixed code, verify mise installs VER_SHELLCHECK="0.11.0" exactly
3. **All Affected Tools**: Test all ~40+ affected tools to verify version locking
4. **Reproducibility**: Runsetup on two different machines/dates, verify identical versions are installed

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**

```
FOR ALL installCall WHERE NOT isBugCondition(installCall) DO
  ASSERT fixedFunction(installCall) = originalFunction(installCall)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:

- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for non-affected installation patterns, then write property-based tests capturing that behavior.

**Test Cases**:

1. **Fast-Path Preservation**: Observe that `is_version_match` skips reinstallation on unfixed code, verify this continues after fix
2. **DRY_RUN Preservation**: Observe that DRY_RUN mode previews without executing on unfixed code, verify this continues after fix
3. **Runtime-Only Installs**: Observe that `run_mise install ruby` works on unfixed code, verify this continues after fix
4. **Version Extraction Pattern**: Observe that `run_mise install "perl@$(get_mise_tool_version perl)"` works on unfixed code, verify this continues after fix
5. **Error Handling Preservation**: Observe that installation failures are logged correctly on unfixed code, verify this continues after fix
6. **Log Format Preservation**: Observe that log_summary output format is correct on unfixed code, verify this continues after fix

### Unit Tests

- Test version variable assignment for each affected function
- Test `run_mise install` command construction with version suffix
- Test that version variables exist in versions.sh for all affected tools
- Test edge cases (empty version, missing provider, undefined variable)
- Test that non-affected installation patterns remain unchanged

### Property-Based Tests

- Generate random tool names and verify version locking is applied correctly
- Generate random version strings and verify they are appended correctly to provider strings
- Generate random combinations of DRY_RUN, fast-path, and error conditions to verify preservation
- Test that all installation calls across all language modules follow consistent patterns

### Integration Tests

- Test full setup flow with all language modules enabled
- Test that running setup twice produces identical versions
- Test that setup on different machines produces identical versions
- Test that version updates in versions.sh are reflected in installations
- Test that mise registry is correctly populated before installations
- Test that error handling and logging work correctly across all tools
