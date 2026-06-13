# Mise Tools PATH Management Fix - Bugfix Design

## Overview

This bugfix addresses a systemic architectural defect affecting all 20+ tools installed via mise. The root cause is a disabled `refresh_mise_cache()` function combined with the absence of unified PATH management after tool installation. This causes `resolve_bin` to fail in finding newly installed tools, particularly in CI environments where mise shims directories may not be in the PATH.

The fix implements a comprehensive Hybrid Approach (Solution 3 from root cause analysis) that:

1. Adds unified PATH management in `run_mise` after successful installations
2. Re-enables `refresh_mise_cache()` with timeout protection
3. Automatically persists PATH to GITHUB_PATH in CI environments
4. Removes the temporary Gitleaks-specific workaround

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when `run_mise install` completes but mise shims are not in PATH
- **Property (P)**: The desired behavior - mise shims directory is automatically added to PATH after installation
- **Preservation**: Existing tool resolution behavior that must remain unchanged by the fix
- **run_mise**: The function in `.unirtm.toml` that wraps all mise command executions
- **refresh_mise_cache()**: The function in `.unirtm.toml` that caches `mise ls --json` output for performance
- **resolve_bin**: The function in `scripts/lib/bin-resolver.sh` that resolves tool binary paths across multiple layers
- **\_G_MISE_SHIMS_BASE**: Global variable containing the path to mise shims directory (OS-specific)
- **GITHUB_PATH**: Environment variable in GitHub Actions for persisting PATH modifications across steps

## Bug Details

### Bug Condition

The bug manifests when a tool is installed via `run_mise install` but the mise shims directory is not in the current session's PATH. The `run_mise` function successfully installs the tool, but does not ensure that `_G_MISE_SHIMS_BASE` is added to PATH, and `refresh_mise_cache()` returns empty JSON instead of actual tool metadata.

**Formal Specification:**

```
FUNCTION isBugCondition(context)
  INPUT: context of type ExecutionContext
  OUTPUT: boolean

  RETURN context.command == "run_mise install"
         AND context.exitCode == 0
         AND (_G_MISE_SHIMS_BASE NOT IN context.PATH
              OR refresh_mise_cache() returns "{}")
         AND resolve_bin(context.toolName) fails
END FUNCTION
```

### Examples

- **Example 1**: In CI, `run_mise install gitleaks` succeeds, but `resolve_bin gitleaks` fails because `$HOME/.local/share/mise/shims` is not in PATH
- **Example 2**: After `run_mise install shellcheck`, `get_version
- Non-install mise commands (`mise list`, `mise use`, etc.) must not modify PATH
- Existing `resolve_bin` fallback layers (venv, node_modules, system PATH, mise which) must remain functional
- Local development with shell configurations that already include mise activation must work unchanged

**Scope:**
All inputs that do NOT involve `run_mise install` should be completely unaffected by this fix. This includes:

- Direct tool invocations (when tools are already in PATH)
- `resolve_bin` calls for tools not managed by mise
- Shell sessions where mise is already activated via `.bashrc`/`.zshrc`
- Windows environments using PowerShell or CMD wrappers

## Hypothesized Root Cause

Based on the root cause analysis document, the most likely issues are:

1. **Disabled Cache Function**: `refresh_mise_cache()` was disabled due to `mise ls --json` hanging on proxy/network issues, causing the mise cache fallback layer in `resolve_bin` to fail

2. **Missing PATH Management**: `run_mise` does not add mise shims to PATH after successful installations, relying on bootstrap-time PATH setup which doesn't persist across CI steps

3. **No CI Persistence**: The `persist_mise_to_github_path()` function exists but is not automatically called after tool installations

4. **No Timeout Protection**: The original `refresh_mise_cache()` implementation had no timeout, causing indefinite hangs in restricted network environments

## Correctness Properties

Property 1: Bug Condition - Automatic PATH Management

_For any_ execution where `run_mise install <tool>` completes successfully (exit code 0), the fixed function SHALL automatically add `_G_MISE_SHIMS_BASE` to the current session's PATH if not already present, ensuring that `resolve_bin <tool>` can immediately locate the newly installed tool. (Validates: Requirements 2.1, 2.4, 2.5)

Property 2: Bug Condition - Cache Refresh with Timeout

_For any_ execution where `refresh_mise_cache()` is called, the fixed function SHALL execute `mise ls --json` with a 5-second timeout protection, returning valid tool metadata on success or empty JSON `{}` on timeout/failure, ensuring the system never hangs indefinitely. (Validates: Requirements 2.2, 2.6)

Property 3: Bug Condition - CI PATH Persistence

_For any_ execution where `run_mise install <tool>` completes successfully in a CI environment (GITHUB_PATH is set), the fixed function SHALL automatically persist `_G_MISE_SHIMS_BASE` to GITHUB_PATH, ensuring subsequent workflow steps can resolve the tool. (Validates: Requirements 2.3)

Property 4: Preservation - Non-Install Commands

_For any_ execution where `run_mise` is called with non-install commands (e.g., `run_mise list`, `run_mise use`), the fixed function SHALL produce exactly the same behavior as the original function, preserving all existing functionality for non-installation operations. (Validates: Requirements 3.3)

Property 5: Preservation - Existing Tool Resolution

_For any_ tool that is already in PATH from sources other than mise (system packages, manual installs, other version managers), the fixed `resolve_bin` function SHALL continue to locate and use those tools correctly, preserving multi-source tool resolution. (Validates: Requirements 3.1, 3.2, 3.6)

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `.unirtm.toml`

**Function**: `run_mise`

**Specific Changes**:

1. **Add PATH Management After Install**: After successful `run_mise install`, check if `_G_MISE_SHIMS_BASE` is in PATH, and add it if missing
   - Use idempotent case statement pattern to avoid duplicates
   - Only trigger on `install` or `i` commands with exit code 0

2. **Add CI PATH Persistence**: After adding to session PATH, check if `GITHUB_PATH` is set and persist the shims directory
   - Use existing `persist_mise_to_github_path()` function if available
   - Otherwise, directly append to `$GITHUB_PATH` file

3. **Re-enable Cache Refresh**: Keep the existing `refresh_mise_cache` call but ensure it has timeout protection

**Function**: `refresh_mise_cache`

**Specific Changes**: 4. **Add Timeout Protection**: Wrap `mise ls --json` with `timeout 5s` or `run_with_timeout_robust 5`

- Use `MISE_OFFLINE=1` to prevent network calls
- Fallback to empty JSON `{}` on timeout or error

1. **Remove Disabled State**: Replace the current disabled implementation with the timeout-protected version

**File**: `scripts/lib/langs/base.sh`

**Function**: `install_gitleaks`

**Specific Changes**: 6. **Remove Temporary Workaround**: Delete the manual PATH management code added as a temporary fix

- Remove the case statement that adds mise shims to PATH
- Remove the CI persistence logic
- Keep only the core `run_mise install` call

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate tool installation in various environments (local, CI, different shells) and assert that the tool can be resolved immediately after installation. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:

1. **Fresh CI Environment Test**: Simulate `run_mise install gitleaks` in a clean CI environment (will fail on unfixed code - resolve_bin returns empty)
2. **Local Development Test**: Simulate `run_mise install shellcheck` in local dev without mise activation (will fail on unfixed code - tool not in PATH)
3. **Multi-Step CI Test**: Simulate installing a tool in one GitHub Actions step and using it in the next (will fail on unfixed code - PATH not persisted)
4. **Cache Hang Test**: Simulate `refresh_mise_cache()` with network issues (will hang indefinitely on unfixed code)

**Expected Counterexamples**:

- `resolve_bin` fails to find newly installed tools
- `get_version` returns "-" for installed tools
- CI workflows fail with "command not found" errors in subsequent steps
- Setup scripts hang indefinitely during cache refresh

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**

```
FOR ALL context WHERE isBugCondition(context) DO
  result := run_mise_fixed("install", context.tool)
  ASSERT result.exitCode == 0
  ASSERT _G_MISE_SHIMS_BASE IN result.PATH
  ASSERT resolve_bin(context.tool) succeeds
  IF is_ci_env THEN
    ASSERT _G_MISE_SHIMS_BASE persisted to GITHUB_PATH
  END IF
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**

```
FOR ALL context WHERE NOT isBugCondition(context) DO
  ASSERT run_mise_original(context.command, context.args) = run_mise_fixed(context.command, context.args)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:

- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for non-install commands and existing tool resolution, then write property-based tests capturing that behavior.

**Test Cases**:

1. **Non-Install Commands Preservation**: Verify `run_mise list`, `run_mise use`, `run_mise which` continue to work identically
2. **System Tool Resolution Preservation**: Verify tools installed via apt/brew/choco continue to be found by `resolve_bin`
3. **Venv/Node Modules Preservation**: Verify tools in `.venv/bin` and `node_modules/.bin` continue to be prioritized
4. **Shell Activation Preservation**: Verify local development with mise already activated in shell continues to work

### Unit Tests

- Test `run_mise install` adds mise shims to PATH when missing
- Test `run_mise install` does not duplicate PATH entries when shims already present
- Test `run_mise install` persists to GITHUB_PATH in CI environments
- Test `refresh_mise_cache()` completes within 5 seconds
- Test `refresh_mise_cache()` returns empty JSON on timeout
- Test `resolve_bin` finds tools after `run_mise install`

### Property-Based Tests

- Generate random tool names and verify PATH management works for all
- Generate random CI/local environment configurations and verify correct behavior
- Generate random sequences of mise commands and verify preservation of non-install commands
- Test that all existing tool resolution layers continue to work across many scenarios

### Integration Tests

- Test full `make setup && make check-env` flow in Docker container
- Test GitHub Actions workflow with multiple steps installing and using tools
- Test Windows/macOS/Linux compatibility for PATH management
- Test that removing Gitleaks workaround doesn't break Gitleaks installation
- **Test GitHub Actions cache hit scenario**: Verify tools are detected when restored from cache
- **Test local pre-installed tools**: Verify system-installed tools (via apt/brew) are used when version matches
- **Test concurrent tool installation**: Verify PATH management is idempotent when installing 20+ tools
- **Test version upgrade scenario**: Verify new version is installed and used when .mise.toml is updated
- **Test network-restricted environment**: Verify MISE_OFFLINE mode and timeout protection work correctly
- **Test CI multi-step workflow**: Verify PATH persists across GitHub Actions steps via GITHUB_PATH
