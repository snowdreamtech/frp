# CI PATH Cache Security Analysis

## Overview

The CI PATH cache mechanism (`.ci_path_cache`) is used to persist tool installation paths across CI workflow steps. This document analyzes the security implications and mitigation measures.

## What is Stored

The `.ci_path_cache` file contains **only directory paths**, for example:

```
/home/runner/.local/share/unirtm/shims
/home/runner/.local/share/unirtm/installs/osv-scanner/2.3.5/bin
/home/runner/.local/share/unirtm/installs/zizmor/1.23.1/bin
```

## Security Assessment

### ✅ Low Risk - Current Implementation is Safe

**Why it's safe:**

1. **No Credentials** - Only stores directory paths, no API keys, tokens, or passwords
2. **No Environment Variables** - Does not store `$SECRET_*`, `$TOKEN_*`, or other sensitive env vars
3. **Temporary File** - CI workspace is cleaned up after build completion
4. **Ignored by Git** - Added to `.gitignore` to prevent accidental commits
5. **Restrictive Permissions** - File created with `chmod 600` (owner read/write only)

### ⚠️ Potential Information Disclosure

While not a critical security risk, the cache file may reveal:

- **Usernames** - e.g., `/home/runner/` (CI runner user)
- **Tool Versions** - e.g., `/osv-scanner/2.3.5/` (installed versions)
- **Directory Structure** - CI workspace layout

**Impact:** Low - This information is typically visible in CI logs anyway.

## Security Measures Implemented

### 1. Input Validation

```sh
# Reject paths containing command injection characters
case "${_path_to_add:-}" in
*\$* | *\`* | *\;* | *\|* | *\&*)
  log_warn "Security: Rejected suspicious path"
  return 1
  ;;
esac
```

Prevents injection of:

- Command substitution: `$(cmd)`, `` `cmd` ``
- Command chaining: `;`, `|`, `&`
- Variable expansion: `$VAR`

### 2. File Permissions

```sh
# Set restrictive permissions on creation
chmod 600 "${_ci_path_file:-}"  # Owner read/write only
```

Prevents other users/processes from reading the cache file.

### 3. Git Ignore

```gitignore
# .gitignore
.ci_path_cache
```

Prevents accidental commit to version control.

### 4. Workspace Isolation

Each CI platform stores the cache in its workspace directory:

| Platform         | Cache Location                                    |
| ---------------- | ------------------------------------------------- |
| GitHub Actions   | `$GITHUB_PATH` (native mechanism)                 |
| GitLab CI        | `$CI_PROJECT_DIR/.ci_path_cache`                 |
| Forgejo/Gitea    | `$CI_PROJECT_DIR/.ci_path_cache`                 |
| Drone/Woodpecker | `$DRONE_WORKSPACE/.ci_path_cache`                |
| CircleCI         | `$CIRCLE_WORKING_DIRECTORY/.ci_path_cache`       |
| Travis CI        | `$TRAVIS_BUILD_DIR/.ci_path_cache`               |
| Azure Pipelines  | `$BUILD_SOURCESDIRECTORY/.ci_path_cache`         |
| Jenkins          | `$WORKSPACE/.ci_path_cache`                      |

All these directories are:

- Isolated per build
- Cleaned up after build completion
- Not shared between different projects/builds

## Comparison with Native Mechanisms

### GitHub Actions `$GITHUB_PATH`

GitHub Actions provides a native `$GITHUB_PATH` file for PATH persistence:

```yaml
- name: Add to PATH
  run: echo "/path/to/bin" >> $GITHUB_PATH
```

**Our implementation:**

- Uses `$GITHUB_PATH` directly on GitHub Actions (no custom file)
- Provides equivalent functionality for other CI platforms
- Same security model as GitHub's native mechanism

## Best Practices

### ✅ DO

- Use the cache for tool installation paths only
- Let the CI platform clean up the workspace
- Review CI logs for unexpected path disclosures

### ❌ DON'T

- Store credentials, tokens, or secrets in the cache
- Manually persist the cache across builds
- Share the cache file between different projects
- Commit `.ci_path_cache` to version control

## Threat Model

### Threats Mitigated

1. **Command Injection** - Input validation prevents malicious paths
2. **Unauthorized Access** - File permissions restrict access
3. **Accidental Commit** - `.gitignore` prevents version control leaks

### Threats NOT Mitigated (Out of Scope)

1. **CI Log Disclosure** - Paths may appear in public CI logs
2. **Workspace Comprounirtm** - If attacker has workspace access, they can read the file
3. **CI Platform Vulnerabilities** - Relies on CI platform's workspace isolation

These are acceptable risks because:

- CI logs typically show tool paths anyway
- Workspace comprounirtm implies broader security breach
- CI platform security is the platform's responsibility

## Compliance

### GDPR / Privacy

- **No Personal Data** - Only stores system paths
- **No User Tracking** - No analytics or telemetry

### Security Standards

- **Principle of Least Privilege** - File permissions restrict access
- **Defense in Depth** - Multiple layers (validation, permissions, gitignore)
- **Fail Secure** - Validation failures reject the operation

## Monitoring & Auditing

### Detection

If you suspect the cache file is being misused:

```sh
# Check file permissions
ls -la .ci_path_cache

# Inspect contents
cat .ci_path_cache

# Verify no secrets
grep -E '(password|token|key|secret)' .ci_path_cache
```

### Expected Output

```
-rw------- 1 runner runner 245 Apr 5 12:34 .ci_path_cache
/home/runner/.local/share/unirtm/shims
/home/runner/.local/share/unirtm/installs/osv-scanner/2.3.5/bin
```

### Red Flags

- File contains `password`, `token`, `key`, or `secret`
- File permissions are too permissive (e.g., `644`, `777`)
- File exists in version control (should be gitignored)

## Conclusion

The CI PATH cache mechanism is **secure by design** for its intended purpose:

- ✅ Stores only non-sensitive directory paths
- ✅ Implements input validation and access controls
- ✅ Follows CI platform best practices
- ✅ Provides equivalent security to native mechanisms

The risk of information disclosure is **low** and **acceptable** given that:

- The disclosed information (paths) is typically visible in CI logs
- The file is temporary and workspace-isolated
- Multiple security layers prevent misuse

## References

- [GitHub Actions: Adding a system path](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-system-path)
- [OWASP: Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)
