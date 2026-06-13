# Scripts Version Centralization Bugfix Design

## Overview

This bugfix addresses the inconsistent use of hardcoded provider values across 20+ shell scripts in `scripts/lib/langs/`. Currently, 36 instances use hardcoded strings like `local _PROVIDER="github:hadolint/hadolint"` instead of referencing centralized variables from `.unirtm.toml` (e.g., `${VER_HADOLINT_PROVIDER:-}`). This violates the Single Source of Truth (SSoT) principle and makes version management error-prone. The fix systematically replaces all hardcoded provider values with centralized variable references, ensuring consistency and maintainability.

## Glossary

- **Bug_Condition (C)**: A script contains a hardcoded `_PROVIDER` assignment instead of referencing a centralized variable from `versions.sh`
- **Property (P)**: The script uses `local _PROVIDER="${VER_*_PROVIDER:-}"` pattern to reference centralized provider values
- **Preservation**: Existing functionality (version checking, installation, logging, DRY_RUN mode) must remain unchanged
- **versions.sh**: The centralized registry at `.unirtm.toml` that defines all tool versions and provider strings
- **Provider String**: The mise backend identifier (e.g., `github:hadolint/hadolint`, `npm:prettier`, `pipx:sqlfluff`)
- **SSoT (Single Source of Truth)**: The principle that each piece of data should have exactly one authoritative source
- **install\_\* functions**: Shell functions in `scripts/lib/langs/*.sh` that install specific tools via mise
- **get_mise_tool_version**: Helper function that retrieves the required version for a provider from mise configuration
- **run_mise install**: Helper function that executes mise installation with the specified provider

## Bug Details

### Bug Condition

The bug manifests when a script in `scripts/lib/langs/` defines a `_PROVIDER` variable with a hardcoded string value instead of referencing the corresponding centralized variable from `.unirtm.toml`. This creates version management inconsistency and violates the SSoT principle.

**Formal Specification:**

```
FUNCTION isBugCondition(scriptLine)
  INPUT: scriptLine of type String (a line from a shell script)
  OUTPUT: boolean

  RETURN scriptLine MATCHES 'local _PROVIDER="[^$]+"'
         AND scriptLine NOT CONTAINS '${'
         AND correspondingCentralizedVariableExists(extractProvider(scriptLine))
         AND scriptLine IN fileSet('scripts/lib/langs/*.sh')
END FUNCTION
```

### Examples

- **shell.sh - shfmt**: Uses `local _PROVIDER="github:mvdan/sh"` instead of `${VER_SHFMT_PROVIDER:-}`
- **docker.sh - hadolint**: Uses `local _PROVIDER="github:hadolint/hadolint"` instead of `${VER_HADOLINT_PROVIDER:-}`
- **node.sh - prettier**: Uses `local _PROVIDER="npm:prettier"` instead of `${VER_PRETTIER_PROVIDER:-}`
- **python.sh - ruff**: Uses `local _PROVIDER="github:astral-sh/ruff"` instead of `${VER_RUFF_PROVIDER:-}`
- **base.sh - editorconfig-checker**: Uses `local _PROVIDER="github:editorconfig-checker/editorconfig-checker"` but `VER_EDITORCONFIG_CHECKER_PROVIDER` doesn't exist yet in versions.sh

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**

- Scripts that already use centralized provider variables (e.g., `security.sh`, `java.sh`, `kotlin.sh`) must continue to work exactly as before
- Version checking logic using `get_mise_tool_version "${_PROVIDER:-}"` must continue to function correctly
- Installation logic using `run_mise install "${_PROVIDER:-}"` must continue to work
- Logging with `_log_setup "${_TITLE:-}" "${_PROVIDER:-}"` must display correct provider information
- DRY_RUN mode preview functionality must remain unchanged
- Fast-path version matching with `is_version_match` must continue to work
- Language file detection with `has_lang_files` must continue to skip installations when no relevant files exist
- Status reporting with `log_summary` must display accurate information
- The `:-` fallback pattern in variable expansion must be preserved for robustness

**Scope:**
All inputs that do NOT involve the 36 identified hardcoded `_PROVIDER` assignments should be completely unaffected by this fix. This includes:

- Scripts that already use centralized variables correctly
- All other script logic (version checking, installation, logging, error handling)
- The structure and content of `versions.sh` itself (except for adding 3 missing variables)
- The behavior of helper functions in `.unirtm.toml`

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Incremental Development Pattern**: Scripts were created at different times, and the centralization pattern was adopted later. Earlier scripts retained hardcoded values while newer scripts (like `security.sh`, `java.sh`) adopted the centralized pattern from the start.

2. **Copy-Paste Propagation**: Developers copied existing functions as templates and didn't update the hardcoded `_PROVIDER` values to use centralized variables.

3. **Incomplete Migration**: A partial migration to centralized variables was started but not completed across all scripts. Some files (like `security.sh`) were updated while others (like `shell.sh`, `docker.sh`) were missed.

4. **Missing Variables in versions.sh**: Three tools lack centralized provider variables:
   - `VER_EDITORCONFIG_CHECKER_PROVIDER` (used by base.sh)
   - `VER_SWIFTFORMAT_PROVIDER` (used by swift.sh)
   - `VER_RUBOCOP_PROVIDER` (used by ruby.sh)

## Correctness Properties

Property 1: Bug Condition - Provider Centralization

_For any_ script line that contains a hardcoded `_PROVIDER` assignment where a corresponding centralized variable exists in `versions.sh`, the fixed script SHALL use `local _PROVIDER="${VER_*_PROVIDER:-}"` instead of the hardcoded string value.

Validates: Requirements 2.1-2.36

Property 2: Preservation - Existing Functionality

_For any_ script logic that does NOT involve `_PROVIDER` variable assignment, the fixed scripts SHALL produce exactly the same behavior as the original scripts, preserving all version checking, installation, logging, and error handling functionality.

Validates: Requirements 3.1-3.10

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct, we need to systematically replace hardcoded provider values with centralized variable references across all affected scripts.

#### Phase 1: Add Missing Variables to versions.sh

**File**: `.unirtm.toml`

**Specific Changes**:

1. Add `VER_EDITORCONFIG_CHECKER_PROVIDER="github:editorconfig-checker/editorconfig-checker"` in the appropriate section
2. Add `VER_SWIFTFORMAT_PROVIDER="github:nicklockwood/SwiftFormat"` in the language tooling section
3. Add `VER_RUBOCOP_PROVIDER="gem:rubocop"` in the language tooling section

#### Phase 2: Replace Hardcoded Providers in Shell Scripts

For each of the 36 instances identified in bugfix.md, replace the hardcoded `_PROVIDER` assignment with a centralized variable reference:

**Pattern to Replace:**

```bash
local _PROVIDER="hardcoded-value"
```

**Replacement Pattern:**

```bash
local _PROVIDER="${VER_TOOL_PROVIDER:-}"
```

**Files to Modify:**

1. `scripts/lib/langs/shell.sh` - 3 instances (shfmt, shellcheck, actionlint)
2. `scripts/lib/langs/docker.sh` - 2 instances (hadolint, dockerfile-utils)
3. `scripts/lib/langs/runner.sh` - 2 instances (just, task)
4. `scripts/lib/langs/lua.sh` - 1 instance (stylua)
5. `scripts/lib/langs/base.sh` - 4 instances (gitleaks, checkmake, editorconfig-checker, goreleaser)
6. `scripts/lib/langs/toml.sh` - 1 instance (taplo)
7. `scripts/lib/langs/helm.sh` - 1 instance (kube-linter)
8. `scripts/lib/langs/node.sh` - 7 instances (sort-package-json, eslint, stylelint, vitepress, prettier, commitlint, commitizen)
9. `scripts/lib/langs/sql.sh` - 1 instance (sqlfluff)
10. `scripts/lib/langs/protobuf.sh` - 1 instance (buf)
11. `scripts/lib/langs/markdown.sh` - 1 instance (markdownlint)
12. `scripts/lib/langs/rego.sh` - 1 instance (opa)
13. `scripts/lib/langs/swift.sh` - 2 instances (swiftformat, swiftlint)
14. `scripts/lib/langs/python.sh` - 2 instances (ruff, pip-audit)
15. `scripts/lib/langs/yaml.sh` - 2 instances (yamllint, dotenv-linter)
16. `scripts/lib/langs/openapi.sh` - 1 instance (spectral)
17. `scripts/lib/langs/terraform.sh` - 1 instance (tflint)
18. `scripts/lib/langs/cpp.sh` - 1 instance (clang-format)
19. `scripts/lib/langs/ruby.sh` - 1 instance (rubocop)

#### Phase 3: Handle Runtime Provider Centralization (Optional)

**File**: Various runtime installation scripts

**Consideration**: Runtime providers like `local _PROVIDER="node"`, `local _PROVIDER="python"`, `local _PROVIDER="go"` could also be centralized, but this is lower priority since they rarely change and are simple strings without version-specific backends.

**Decision**: Address in requirements 2.36 if time permits, otherwise defer to future enhancement.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, verify that hardcoded values exist in the unfixed code (exploratory), then verify the fix correctly references centralized variables and preserves all existing functionality.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that hardcoded provider values exist and identify all instances across the codebase.

**Test Plan**: Use grep/ripgrep to search for hardcoded `_PROVIDER` assignments in `scripts/lib/langs/*.sh` files. Run these searches on the UNFIXED code to catalog all instances and verify they match the 36 instances documented in bugfix.md.

**Test Cases**:

1. **Hardcoded GitHub Providers**: Search for `local _PROVIDER="github:` in all lang scripts (will find ~20 instances on unfixed code)
2. **Hardcoded NPM Providers**: Search for `local _PROVIDER="npm:` in all lang scripts (will find ~10 instances on unfixed code)
3. **Hardcoded Pipx Providers**: Search for `local _PROVIDER="pipx:` in all lang scripts (will find ~5 instances on unfixed code)
4. **Hardcoded Gem Providers**: Search for `local _PROVIDER="gem:` in ruby.sh (will find 1 instance on unfixed code)

**Expected Counterexamples**:

- 36 instances of hardcoded `_PROVIDER` assignments across 20+ scripts
- Possible causes: incremental development, copy-paste propagation, incomplete migration
- Missing centralized variables: `VER_EDITORCONFIG_CHECKER_PROVIDER`, `VER_SWIFTFORMAT_PROVIDER`, `VER_RUBOCOP_PROVIDER`

### Fix Checking

**Goal**: Verify that for all scripts where the bug condition holds, the fixed scripts correctly reference centralized provider variables from versions.sh.

**Pseudocode:**

```
FOR ALL scriptFile IN 'scripts/lib/langs/*.sh' DO
  FOR ALL line IN scriptFile WHERE isBugCondition(line) DO
    toolName := extractToolName(line)
    centralizedVar := getCentralizedVariable(toolName)
    ASSERT line CONTAINS "${" + centralizedVar + ":-}"
    ASSERT centralizedVar EXISTS IN '.unirtm.toml'
  END FOR
END FOR
```

**Test Plan**: After implementing the fix, search for any remaining hardcoded `_PROVIDER` assignments and verify that all 36 instances now use centralized variables. Verify that the 3 missing variables have been added to versions.sh.

**Test Cases**:

1. **No Hardcoded Providers Remain**: Search for `local _PROVIDER="[^$]` should return zero results in lang scripts
2. **All Centralized Variables Exist**: Verify all referenced `VER_*_PROVIDER` variables are defined in versions.sh
3. **Correct Variable Names**: Verify variable names follow the naming convention (VER_TOOLNAME_PROVIDER)
4. **Fallback Pattern Preserved**: Verify all references use `${VAR:-}` pattern for robustness

### Preservation Checking

**Goal**: Verify that for all script functionality that does NOT involve `_PROVIDER` assignment, the fixed scripts produce the same behavior as the original scripts.

**Pseudocode:**

```
FOR ALL scriptFile IN 'scripts/lib/langs/*.sh' DO
  FOR ALL functionality IN [version_checking, installation, logging, dry_run, error_handling] DO
    ASSERT behavior_fixed(functionality) = behavior_original(functionality)
  END FOR
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:

- It generates many test scenarios automatically across different tool installations
- It catches edge cases that manual unit tests might miss (missing tools, version mismatches, network failures)
- It provides strong guarantees that behavior is unchanged for all non-provider-assignment logic

**Test Plan**: Run existing installation scripts on UNFIXED code first to observe baseline behavior, then run the same scripts on FIXED code to verify identical behavior.

**Test Cases**:

1. **Version Checking Preservation**: Verify `get_mise_tool_version "${_PROVIDER:-}"` works identically with centralized variables
2. **Installation Preservation**: Verify `run_mise install "${_PROVIDER:-}"` executes correctly with centralized variables
3. **Logging Preservation**: Verify `_log_setup` and `log_summary` display correct provider information
4. **DRY_RUN Preservation**: Verify preview mode works identically with centralized variables
5. **Fast-Path Preservation**: Verify `is_version_match` logic continues to skip unnecessary installations
6. **Error Handling Preservation**: Verify failure scenarios (missing tools, network errors) behave identically

### Unit Tests

- Test that each modified script correctly references its centralized provider variable
- Test that missing variables (editorconfig-checker, swiftformat, rubocop) are added to versions.sh
- Test that no hardcoded provider strings remain in any lang script
- Test that variable naming follows the convention (VER_TOOLNAME_PROVIDER)
- Test that the `:-` fallback pattern is preserved in all variable references

### Property-Based Tests

- Generate random tool installation scenarios and verify provider values resolve correctly from versions.sh
- Generate random combinations of installed/missing tools and verify version checking works identically
- Test that DRY_RUN mode produces identical preview output with centralized variables
- Test that error scenarios (missing versions.sh, undefined variables) are handled gracefully

### Integration Tests

- Run full setup.sh script with centralized variables and verify all tools install correctly
- Test that version updates in versions.sh propagate correctly to all scripts
- Test that scripts continue to work when versions.sh is sourced at different points
- Test cross-platform behavior (Linux, macOS, Windows) with centralized variables
- Verify that existing scripts using centralized variables (security.sh, java.sh, kotlin.sh) continue to work without modification
