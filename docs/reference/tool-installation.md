# Tool Installation Architecture

This document describes the tool installation architecture used in this project, focusing on the `install_tool_safe()` pattern that provides binary-first detection, platform-specific binary name handling, and comprehensive debugging capabilities.

## Overview

The project uses a unified tool installation pattern that:

- Detects existing tool binaries before attempting installation
- Handles platform-specific binary names (e.g., `ec-linux-amd64`, `ec-darwin-arm64`, `hadolint.exe`)
- Provides atomic verification steps for debugging
- Supports both CI and local development environments
- Integrates with unirtm for version management

## The Six-Step Installation Process

The `install_tool_safe()` function implements a six-step process for reliable tool installation:

### Step 1: Binary-First Detection

Before attempting installation, the function checks if the tool binary already exists in the system PATH or unirtm installation directory.

**Benefits:**

- Avoids unnecessary installations
- Faster setup in environments where tools are pre-installed
- Reduces network usage and installation time

**Implementation:**

```bash
# Check if binary exists using multiple strategies
if command -v "$BIN_NAME" >/dev/null 2>&1; then
  # Binary found in PATH
  return 0
fi

# Check unirtm installation directory
if unirtm which "$BIN_NAME" >/dev/null 2>&1; then
  # Binary found in unirtm
  return 0
fi
```

### Step 2: Version Verification

If a binary is found, verify it responds to version commands to ensure it's functional.

**Implementation:**

```bash
if "$BIN_NAME" "$VERSION_FLAG" >/dev/null 2>&1; then
  # Binary is functional
  return 0
fi
```

### Step 3: Installation Decision

Based on the environment (CI vs local development), decide whether to proceed with installation.

**Behavior:**

- **CI Environment**: Always install missing tools (fail if installation fails)
- **Local Development**: Skip installation (developer can install manually)

### Step 4: Cleanup (if needed)

If a non-functional binary is found, remove it before reinstalling.

### Step 5: UniRTM Installation

Use unirtm to install the tool with the specified version.

**Implementation:**

```bash
unirtm install "$PROVIDER"
```

### Step 6: Post-Install Verification

After installation, verify the binary is accessible and functional.

**Implementation:**

```bash
# Refresh PATH to include newly installed tools
eval "$(unirtm activate bash)"

# Verify binary exists
if ! command -v "$BIN_NAME" >/dev/null 2>&1; then
  log_error "Binary not found after installation: $BIN_NAME"
  return 1
fi

# Verify binary is functional
if ! "$BIN_NAME" "$VERSION_FLAG" >/dev/null 2>&1; then
  log_error "Binary not functional after installation: $BIN_NAME"
  return 1
fi
```

## Platform-Specific Binary Handling

Many tools provide platform-specific binaries with different names. The installation system handles these automatically.

### Naming Patterns

**Linux:**

- `ec-linux-amd64` (x86_64)
- `ec-linux-arm64` (ARM64)

**macOS:**

- `ec-darwin-amd64` (Intel)
- `ec-darwin-arm64` (Apple Silicon)

**Windows:**

- `ec-windows-amd64.exe` (x86_64)
- `hadolint.exe` (any tool with .exe extension)

### Resolution Strategy

The system uses a layered resolution strategy:

1. **UniRTM Which** (Primary): `unirtm which <tool>` - handles platform-specific binaries automatically
2. **Command -v** (Fallback 1): `command -v <tool>` - for tools in PATH
3. **UniRTM Where + Find** (Fallback 2): Search unirtm installation directory with pattern matching

**Example:**

```bash
# For editorconfig-checker on Linux x86_64
# UniRTM automatically resolves to: ec-linux-amd64

# For hadolint on Windows
# UniRTM automatically resolves to: hadolint.exe
```

### Performance Considerations

- Binary resolution completes within 5 seconds (Requirement 3.1)
- Platform-specific resolution completes within 3 seconds (Requirement 3.3)
- Results are cached during script execution to avoid repeated lookups

## Debugging and Error Handling

The installation system provides comprehensive debugging capabilities.

### Debug Mode

Enable detailed logging with the `DEBUG` environment variable:

```bash
DEBUG=1 ./scripts/setup.sh
```

**Debug output includes:**

- Each step of the installation process
- Binary resolution attempts and results
- Timing information for each phase
- Error messages with context

### Verbose Mode

Enable verbose output with the `VERBOSE` environment variable:

```bash
VERBOSE=2 ./scripts/setup.sh
```

### Atomic Verification Steps

Each verification step is atomic and reports its status:

```bash
✓ Binary found: shfmt
✓ Version check passed: shfmt --version
✓ Installation successful: shfmt
```

### Common Failure Scenarios

#### Scenario 1: Binary Not Found After Installation

```
❌ Binary not found after installation: tool-name
```

**Possible causes:**

- UniRTM installation directory not in PATH
- Platform-specific binary name not recognized
- Installation failed silently

**Solution:**

1. Check unirtm installation: `unirtm list`
2. Verify PATH includes unirtm shims: `echo $PATH`
3. Try manual installation: `unirtm install tool-name`

#### Scenario 2: Binary Not Functional

```
❌ Binary not functional after installation: tool-name
```

**Possible causes:**

- Binary is corrupted
- Missing dependencies
- Incompatible platform

**Solution:**

1. Remove and reinstall: `unirtm uninstall tool-name && unirtm install tool-name`
2. Check tool documentation for dependencies
3. Verify platform compatibility

#### Scenario 3: Platform-Specific Binary Not Found

```
❌ Could not resolve platform-specific binary: ec-*
```

**Possible causes:**

- Tool doesn't provide binaries for your platform
- UniRTM provider doesn't support platform-specific names

**Solution:**

1. Check tool's GitHub releases for your platform
2. Update unirtm provider configuration
3. Use alternative installation method

## Code Examples

### Basic Tool Installation

```bash
# Install shfmt with default settings
install_tool_safe "shfmt" "${VER_SHFMT_PROVIDER:-}" "Shfmt" "--version" 0 "*.sh *.bash" ""
```

**Parameters:**

- `BIN_NAME`: "shfmt" - binary name to verify
- `PROVIDER`: unirtm provider string (e.g., "github:mvdan/sh")
- `DISPLAY_NAME`: "Shfmt" - human-readable name for logging
- `VERSION_FLAG`: "--version" - flag to check version
- `SKIP_FILE_CHECK`: 0 - check for relevant files before installing
- `FILE_PATTERNS`: "*.sh*.bash" - file patterns to check
- `FILE_DIR`: "" - directory to search (empty = current directory)

### Platform-Specific Tool Installation

```bash
# Install editorconfig-checker (handles ec-linux-amd64, ec-darwin-arm64, etc.)
install_tool_safe "editorconfig-checker" "${VER_EDITORCONFIG_CHECKER_PROVIDER:-}" \
  "EditorConfig Checker" "--version" 0 "" ""
```

### Tool with Custom Version Flag

```bash
# Install tool with custom version flag
install_tool_safe "tool-name" "${VER_TOOL_PROVIDER:-}" "Tool Name" "-v" 0 "" ""
```

### Skip File Check

```bash
# Install tool without checking for relevant files
install_tool_safe "tool-name" "${VER_TOOL_PROVIDER:-}" "Tool Name" "--version" 1 "" ""
```

## Environment Variables

### DEBUG

Enable detailed debug logging.

**Values:**

- `0` or unset: Normal logging
- `1`: Debug logging enabled

**Example:**

```bash
DEBUG=1 ./scripts/setup.sh
```

### VERBOSE

Control verbosity level.

**Values:**

- `0`: Minimal output
- `1`: Normal output (default)
- `2`: Verbose output

**Example:**

```bash
VERBOSE=2 ./scripts/setup.sh
```

### CI

Indicates CI environment.

**Values:**

- `true`: CI environment (install all tools)
- `false` or unset: Local development (skip optional tools)

**Example:**

```bash
CI=true ./scripts/setup.sh
```

### UNIRTM_OFFLINE

Use unirtm in offline mode (no network access).

**Values:**

- `1`: Offline mode enabled
- `0` or unset: Online mode

**Example:**

```bash
UNIRTM_OFFLINE=1 ./scripts/setup.sh
```

## Performance Characteristics

Based on performance testing:

- **Total setup time**: ~5 minutes (300 seconds) for all tools
- **Binary verification**: < 5 seconds per tool
- **Platform-specific resolution**: < 3 seconds per tool
- **Cache effectiveness**: 50% speedup with warm cache

### Performance Budgets

Per-category budgets:

- Security tools: 60 seconds
- Linters: 90 seconds
- Formatters: 70 seconds
- Runtimes: 80 seconds

See `benchmarks/budgets.json` for detailed budgets.

## Migrated Tools

The following 45 tools have been migrated to the `install_tool_safe()` pattern:

**Security Tools:**

- gitleaks
- osv-scanner
- zizmor

**Linters:**

- shellcheck
- hadolint
- tflint
- actionlint
- yamllint
- markdownlint-cli2
- editorconfig-checker

**Formatters:**

- shfmt
- prettier

**And 33 more tools...**

For a complete list, see the implementation in `scripts/lib/langs/*.sh`.

## Related Documentation

- [Alpine Linux Compatibility](../alpine-compatibility.md)
- [API Documentation](./api-common.md)
- [Troubleshooting](../troubleshooting-unirtm-provenance.md)

## References

- [UniRTM Documentation](https://github.com/snowdreamtech/UniRTM)
- [Performance Testing Spec](../../.kiro/specs/performance-testing-and-docs/design.md)
