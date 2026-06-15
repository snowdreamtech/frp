# Common Shell Functions API Reference

This document provides API documentation for the common shell functions used throughout the project, particularly those in `scripts/lib/common.sh`.

## Core Installation Functions

### `install_tool_safe()`

Safely installs a tool with binary-first detection, platform-specific binary name handling, and comprehensive error reporting.

**Signature:**

```bash
install_tool_safe BIN_NAME PROVIDER DISPLAY_NAME [VERSION_FLAG] [SKIP_FILE_CHECK] [FILE_PATTERNS] [FILE_DIR]
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `BIN_NAME` | string | Yes | - | Binary name to verify (e.g., "shfmt", "ec-linux-amd64") |
| `PROVIDER` | string | Yes | - | UniRTM provider string (e.g., "github:mvdan/sh") |
| `DISPLAY_NAME` | string | Yes | - | Human-readable name for logging |
| `VERSION_FLAG` | string | No | "--version" | Flag to check version |
| `SKIP_FILE_CHECK` | integer | No | 0 | Skip file detection (0=check, 1=skip) |
| `FILE_PATTERNS` | string | No | "" | Space-separated file patterns (e.g., "*.sh*.bash") |
| `FILE_DIR` | string | No | "" | Optional directory to search for files |

**Returns:**

- `0`: Success or skip (local development)
- `1`: Failure (CI only)

**Environment Variables:**

- `CI`: If set to "true", forces installation and fails on errors
- `DEBUG`: If set to "1", enables detailed debug logging
- `VERBOSE`: Controls verbosity level (0=minimal, 1=normal, 2=verbose)

**Examples:**

```bash
# Basic usage
install_tool_safe "shfmt" "${VER_SHFMT_PROVIDER:-}" "Shfmt"

# With custom version flag
install_tool_safe "tool" "${VER_TOOL_PROVIDER:-}" "Tool Name" "-v"

# Skip file check
install_tool_safe "tool" "${VER_TOOL_PROVIDER:-}" "Tool Name" "--version" 1

# With file patterns
install_tool_safe "shfmt" "${VER_SHFMT_PROVIDER:-}" "Shfmt" "--version" 0 "*.sh *.bash"

# With specific directory
install_tool_safe "tool" "${VER_TOOL_PROVIDER:-}" "Tool Name" "--version" 0 "*.ext" "src/"
```

**Implementation Details:**

The function follows a six-step process:

1. **Binary Detection**: Checks if binary exists using `command -v`, `unirtm which`, or filesystem search
2. **Version Verification**: Verifies binary responds to version flag
3. **Installation Decision**: Decides whether to install based on environment (CI vs local)
4. **Cleanup**: Removes non-functional binaries if found
5. **UniRTM Installation**: Installs tool using unirtm
6. **Post-Install Verification**: Verifies installation was successful

**Performance:**

- Binary verification: < 5 seconds
- Platform-specific resolution: < 3 seconds
- Total installation time varies by tool (see performance budgets)

---

### `verify_tool_atomic()`

Performs atomic verification of a tool binary with detailed status reporting.

**Signature:**

```bash
verify_tool_atomic BIN_NAME VERSION_FLAG DISPLAY_NAME
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `BIN_NAME` | string | Yes | Binary name to verify |
| `VERSION_FLAG` | string | Yes | Flag to check version |
| `DISPLAY_NAME` | string | Yes | Human-readable name for logging |

**Returns:**

- `0`: Binary exists and is functional
- `1`: Binary not found or not functional

**Examples:**

```bash
# Verify shfmt is installed and functional
if verify_tool_atomic "shfmt" "--version" "Shfmt"; then
  echo "Shfmt is ready"
else
  echo "Shfmt is not available"
fi
```

**Output:**

```
✓ Binary found: shfmt
✓ Version check passed: shfmt --version
```

---

### `verify_binary_exists()`

Checks if a binary exists in the system PATH or unirtm installation directory.

**Signature:**

```bash
verify_binary_exists BIN_NAME
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `BIN_NAME` | string | Yes | Binary name to check |

**Returns:**

- `0`: Binary exists
- `1`: Binary not found

**Examples:**

```bash
# Check if binary exists
if verify_binary_exists "shfmt"; then
  echo "shfmt is installed"
fi
```

**Resolution Strategy:**

1. Check with `command -v`
2. Check with `unirtm which`
3. Search unirtm installation directory with `find`

**Performance:**

- Completes within 5 seconds
- Results can be cached during script execution

---

## Utility Functions

### `log_info()`

Logs an informational message.

**Signature:**

```bash
log_info MESSAGE
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MESSAGE` | string | Yes | Message to log |

**Examples:**

```bash
log_info "Starting installation..."
```

**Output:**

```
ℹ Starting installation...
```

---

### `log_success()`

Logs a success message.

**Signature:**

```bash
log_success MESSAGE
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MESSAGE` | string | Yes | Message to log |

**Examples:**

```bash
log_success "Installation completed successfully"
```

**Output:**

```
✓ Installation completed successfully
```

---

### `log_warn()`

Logs a warning message.

**Signature:**

```bash
log_warn MESSAGE
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MESSAGE` | string | Yes | Message to log |

**Examples:**

```bash
log_warn "Tool not found, skipping..."
```

**Output:**

```
⚠ Tool not found, skipping...
```

---

### `log_error()`

Logs an error message.

**Signature:**

```bash
log_error MESSAGE
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MESSAGE` | string | Yes | Message to log |

**Examples:**

```bash
log_error "Installation failed"
```

**Output:**

```
❌ Installation failed
```

---

### `run_with_timeout()`

Executes a command with a timeout.

**Signature:**

```bash
run_with_timeout TIMEOUT_SECONDS COMMAND [ARGS...]
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TIMEOUT_SECONDS` | integer | Yes | Timeout in seconds |
| `COMMAND` | string | Yes | Command to execute |
| `ARGS` | string | No | Command arguments |

**Returns:**

- `0`: Command completed successfully within timeout
- `124`: Command timed out
- Other: Command exit code

**Examples:**

```bash
# Run command with 30-second timeout
if run_with_timeout 30 unirtm install shfmt; then
  echo "Installation completed"
else
  echo "Installation failed or timed out"
fi
```

---

### `guard_project_root()`

Ensures the script is running from the project root directory.

**Signature:**

```bash
guard_project_root
```

**Returns:**

- `0`: Running from project root
- `1`: Not running from project root (exits script)

**Examples:**

```bash
# At the beginning of a script
guard_project_root
```

**Behavior:**

- Checks for presence of `.git` directory or other project markers
- Exits with error if not in project root
- Prevents accidental execution from wrong directory

---

## Environment Detection Functions

### `is_ci()`

Checks if running in a CI environment.

**Signature:**

```bash
is_ci
```

**Returns:**

- `0`: Running in CI
- `1`: Not running in CI

**Detection Logic:**

Checks for common CI environment variables:

- `CI=true`
- `GITHUB_ACTIONS=true`
- `GITLAB_CI=true`
- `CIRCLECI=true`
- `TRAVIS=true`

**Examples:**

```bash
if is_ci; then
  echo "Running in CI environment"
  # Install all tools
else
  echo "Running in local development"
  # Skip optional tools
fi
```

---

### `detect_platform()`

Detects the current platform (OS and architecture).

**Signature:**

```bash
detect_platform
```

**Returns:**

Platform string (stdout):

- `linux-amd64`
- `linux-arm64`
- `darwin-amd64`
- `darwin-arm64`
- `windows-amd64`

**Examples:**

```bash
platform=$(detect_platform)
echo "Running on: $platform"
```

---

## File Detection Functions

### `has_files_matching()`

Checks if files matching a pattern exist in a directory.

**Signature:**

```bash
has_files_matching PATTERN [DIRECTORY]
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `PATTERN` | string | Yes | - | File pattern (e.g., "*.sh") |
| `DIRECTORY` | string | No | "." | Directory to search |

**Returns:**

- `0`: Matching files found
- `1`: No matching files found

**Examples:**

```bash
# Check for shell scripts in current directory
if has_files_matching "*.sh"; then
  echo "Shell scripts found"
fi

# Check for Python files in src directory
if has_files_matching "*.py" "src/"; then
  echo "Python files found in src/"
fi
```

---

## Best Practices

### Error Handling

Always check return values:

```bash
if ! install_tool_safe "tool" "$PROVIDER" "Tool Name"; then
  log_error "Failed to install tool"
  exit 1
fi
```

### Logging

Use appropriate log levels:

```bash
log_info "Starting process..."
log_success "Process completed"
log_warn "Optional step skipped"
log_error "Critical error occurred"
```

### Timeouts

Use timeouts for network operations:

```bash
# 5-minute timeout for tool installation
if ! run_with_timeout 300 unirtm install tool; then
  log_error "Installation timed out"
  exit 1
fi
```

### Environment Variables

Check environment before making decisions:

```bash
if is_ci; then
  # CI-specific behavior
  install_tool_safe "tool" "$PROVIDER" "Tool"
else
  # Local development behavior
  log_info "Skipping optional tool in local development"
fi
```

## Performance Considerations

### Binary Resolution

- Use `verify_binary_exists()` before attempting installation
- Cache results when checking multiple times
- Prefer `command -v` for simple checks

### Installation

- Use `SKIP_FILE_CHECK=1` when file patterns are not relevant
- Set appropriate timeouts based on tool size
- Consider using `UNIRTM_OFFLINE=1` when network is unavailable

### Logging Best Practices

- Use `VERBOSE=0` for minimal output in CI
- Use `DEBUG=1` only when troubleshooting
- Avoid excessive logging in tight loops

## Related Documentation

- [Tool Installation Architecture](./tool-installation.md)
- [Troubleshooting](../troubleshooting-unirtm-provenance.md)

## References

- [UniRTM Documentation](https://github.com/snowdreamtech/UniRTM)
- [POSIX Shell Scripting](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
