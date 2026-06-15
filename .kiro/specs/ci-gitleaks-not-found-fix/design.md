# CI Gitleaks Detection Bugfix Design

## Overview

This design addresses a bug where Gitleaks is successfully installed via `make setup` in CI but fails detection during `make check-env` verification. The root cause is that `refresh_mise_cache()` is disabled (returns empty JSON "{}") to avoid network hangs, causing `resolve_bin` to fall back to slower PATH-based lookup which fails when mise shims are not yet activated in the CI environment.

The fix ensures that after installing Gitleaks via mise, the binary resolution paths (mise shims, PATH, or direct mise metadata query) are immediately functional, allowing `check-env` to successfully locate the tool.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when mise cache is disabled and mise shims are not in PATH after tool installation
- **Property (P)**: The desired behavior - `resolve_bin` successfully locates gitleaks after installation via any of its 4 lookup layers
- **Preservation**: Existing tool detection for Node.js, Python, Ruby, Shellcheck, etc. must remain unchanged
- **refresh_mise_cache()**: Function in `.unirtm.toml` that populates `_G_MISE_LS_JSON_CACHE` with mise tool metadata (currently disabled, returns "{}")
- **resolve_bin()**: 4-layer binary resolution function: (1) venv, (2) node_modules, (3) system PATH, (4) mise which, (5) mise cache fallback
- **install_gitleaks()**: Function in `scripts/lib/langs/base.sh` that installs Gitleaks via `run_mise install gitleaks`
- **check_tool_version()**: Function in `scripts/check-env.sh` that verifies tool availability and version using `resolve_bin`

## Bug Details

### Bug Condition

The bug manifests when Gitleaks is installed via mise in CI but the subsequent verification fails to locate the binary. The `refresh_mise_cache()` function is intentionally disabled (returns "{}") to prevent network hangs, but this causes `resolve_bin` to fail when mise shims are not yet in PATH.

**Formal Specification:**

```
FUNCTION isBugCondition(input)
  INPUT: input of type ToolInstallationContext
  OUTPUT: boolean

  RETURN input.tool == "gitleaks"
         AND input.installedViaMise == true
         AND input.miseCache == "{}"
         AND input.miseShimsNotInPath == true
         AND resolve_bin("gitleaks") == null
END FUNCTION
```

### Examples

- **CI Environment**: `make setup` logs "── Setting up Gitleaks (8.30.1) ──" indicating successful installation, but `make check-env` reports "❌ Gitleaks: Not found" because `resolve_bin` cannot locate the binary
- **Local Development**: Works correctly because mise shims are typically already in PATH from shell initialization
- **Fresh CI Runner**: Fails because PATH does not include mise shims directory (`~/.local/share/mise/shims` or Windows equivalent)
- **After Manual PATH Update**: Would work if `$HOME/.local/share/mise/shims` is explicitly added to PATH before check-env runs

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**

- Other tools (Node.js, Python, Ruby, Shellcheck, Shfmt, Actionlint, etc.) must continue to be detected correctly by check-env
- Local development environment detection must remain unchanged
- The 4-layer lookup strategy in `resolve_bin` must continue to work for all tools
- Performance optimizations (caching, fast-path checks) must not be degraded

**Scope:**
All inputs that do NOT involve Gitleaks installation in CI should be completely unaffected by this fix. This includes:

- Local development tool detection
- Other mise-managed tools (checkmake, editorconfig-checker, goreleaser, etc.)
- Non-mise tools (system-installed binaries, venv tools, node_modules tools)

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Disabled Mise Cache**: `refresh_mise_cache()` is intentionally disabled (returns "{}") to avoid network hangs, but this breaks Layer 5 of `resolve_bin` which relies on mise metadata

2. **Mise Shims Not in PATH**: In CI, the mise shims directory (`~/.local/share/mise/shims`) may not be in PATH immediately after installation, causing Layer 3 (system PATH) to fail

3. **Timing Issue**: `install_gitleaks()` calls `run_mise install gitleaks` but does not ensure that the binary is immediately resolvable via PATH or mise which

4. **Missing Cache Refresh**: Unlike `install_runtime_hooks()` in `scripts/lib/langs/testing.sh` which calls `refresh_mise_cache()` after installation, `install_gitleaks()` does not refresh any resolution state

## Correctness Properties

Property 1: Bug Condition - Gitleaks Detection After Installation

_For any_ CI environment where Gitleaks is installed via `run_mise install gitleaks`, the subsequent call to `resolve_bin "gitleaks"` SHALL successfully return the binary path via mise shims, PATH, or mise which, enabling check-env to report "✅ Gitleaks: v8.30.1 (Active)".

Validates: Requirements 2.1, 2.2, 2.4

Property2: Preservation - Other Tool Detection

_For any_ tool that is NOT Gitleaks (Node.js, Python, Ruby, Shellcheck, etc.), the fixed code SHALL produce exactly the same detection behavior as the original code, preserving all existing functionality for tool resolution and version checking.

Validates: Requirements 3.1, 3.2, 3.3, 3.4

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `scripts/lib/langs/base.sh`

**Function**: `install_gitleaks()`

**Specific Changes**:

1. **Add Explicit PATH Update**: After `run_mise install gitleaks`, explicitly add mise shims directory to PATH if not already present
   - Check if `${_G_MISE_SHIMS_BASE}` is in PATH
   - If not, prepend it: `export PATH="${_G_MISE_SHIMS_BASE}:$PATH"`

2. **Add Cache Refresh Call**: After successful installation, call `refresh_mise_cache` to update metadata
   - This mirrors the pattern used in `install_runtime_hooks()` in `scripts/lib/langs/testing.sh`
   - Even though cache is disabled, this ensures any future cache-enabled code paths work

3. **Add Verification Step**: After installation, verify that `mise which gitleaks` returns a valid path
   - If it fails, log a warning but continue (graceful degradation)
   - This provides diagnostic information for debugging

4. **Alternative: Use mise exec**: If direct PATH manipulation is unreliable, use `mise exec gitleaks -- gitleaks version` to verify installation
   - This bypasses PATH entirely and uses mise's internal resolution

5. **Fallback Strategy**: If all else fails, document that CI workflows should explicitly add mise shims to PATH in the workflow YAML
   - Example: `export PATH="$HOME/.local/share/mise/shims:$PATH"`

### Implementation Strategy

The minimal fix is to add explicit PATH management after Gitleaks installation:

```bash
install_gitleaks() {
  # ... existing code ...

  local _STAT_GITL="✅ mise"
  run_mise install gitleaks || _STAT_GITL="❌ Failed"

  # FIX: Ensure mise shims are in PATH immediately after installation
  if [ "${_STAT_GITL}" = "✅ mise" ]; then
    case ":$PATH:" in
    *":${_G_MISE_SHIMS_BASE:-}:"*) ;;
    *) export PATH="${_G_MISE_SHIMS_BASE:-}:$PATH" ;;
    esac

    # Refresh cache (even if disabled, for future compatibility)
    refresh_mise_cache
  fi

  log_summary "Base" "Gitleaks" "${_STAT_GITL:-}" "$(get_version gitleaks)" "$(($(date +%s) - _T0_GITL))"
}
```

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate CI environment conditions (empty PATH, disabled mise cache) and verify that Gitleaks can be detected after installation. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:

1. **Fresh CI Environment Test**: Simulate clean CI runner with no mise shims in PATH (will fail on unfixed code)
2. **Disabled Cache Test**: Set `_G_MISE_LS_JSON_CACHE="{}"` and verify detection fails (will fail on unfixed code)
3. **PATH Verification Test**: Check if mise shims directory is in PATH after installation (will fail on unfixed code)
4. **Mise Which Test**: Verify `mise which gitleaks` returns valid path after installation (may fail on unfixed code)

**Expected Counterexamples**:

- `resolve_bin "gitleaks"` returns empty/null after successful `run_mise install gitleaks`
- Possible causes: mise shims not in PATH, mise cache disabled, mise which fails due to missing activation

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**

```
FOR ALL input WHERE isBugCondition(input) DO
  result := install_gitleaks_fixed()
  ASSERT resolve_bin("gitleaks") != null
  ASSERT check_tool_version("Gitleaks", "gitleaks", ...) == success
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**

```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT install_gitleaks_original(input) = install_gitleaks_fixed(input)
  ASSERT resolve_bin(input.tool) behavior unchanged
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:

- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for other tools (Node.js, Python, Shellcheck), then write property-based tests capturing that behavior.

**Test Cases**:

1. **Node.js Detection Preservation**: Verify Node.js detection continues to work after fix
2. **Python Detection Preservation**: Verify Python detection continues to work after fix
3. **Shellcheck Detection Preservation**: Verify Shellcheck detection continues to work after fix
4. **Local Development Preservation**: Verify local development environment detection unchanged

### Unit Tests

- Test `install_gitleaks()` in isolation with mocked `run_mise`
- Test PATH manipulation logic (adding mise shims directory)
- Test `refresh_mise_cache()` call after installation
- Test `resolve_bin "gitleaks"` after installation in various PATH configurations

### Property-Based Tests

- Generate random CI environment configurations (PATH variations, cache states)
- Verify Gitleaks detection works correctly across all configurations
- Generate random tool installation sequences and verify no regressions
- Test that all non-Gitleaks tools continue to work across many scenarios

### Integration Tests

- Test full `make setup && make check-env` flow in CI-like environment
- Test with fresh Docker container (no mise shims in PATH initially)
- Test with disabled mise cache (`_G_MISE_LS_JSON_CACHE="{}"`)
- Test that GitHub Actions workflow "Sync Dependabot Config" passes after fix
