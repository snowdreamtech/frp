# unirtm Supply Chain Security Analysis

## Overview

This document analyzes the supply chain risks associated with unirtm's default registry and provides mitigation strategies.

## Risk Analysis

### 1. Implicit Registry Redirection

**Risk**: unirtm's built-in registry can silently redirect tool installations to different backends.

**Example**:

```toml
# You specify:
"github:checkmake/checkmake" = "v0.3.2"

# But unirtm's registry maps 'checkmake' to:
aqua:mrtazz/checkmake
```

**Impact**:

- Different maintainer (`mrtazz` vs `checkmake` organization)
- Additional layer (aqua registry) increases attack surface
- Potential for supply chain attacks if registry is comprounirtmd

### 2. Affected Tools in This Project

Based on unirtm registry inspection, the following tools have registry mappings:

```bash
checkmake                     aqua:mrtazz/checkmake
gitleaks                      aqua:gitleaks/gitleaks
hadolint                      aqua:hadolint/hadolint
```

## Mitigation Strategies

### ✅ Already Implemented

1. **Explicit Backend Specification**: All tools in `.unirtm.toml` use explicit backends:
   - `github:owner/repo` for GitHub releases
   - `npm:package` for npm packages
   - `pipx:package` for Python packages

2. **Tool Spec Mapping**: In `scripts/lib/lint-wrapper.sh`, we explicitly map tool names to full specs:

   ```bash
   checkmake)
     _UNIRTM_TOOL_SPEC="github:checkmake/checkmake"
     _LINTER_BIN="checkmake"
     ;;
   ```

3. **Version Pinning**: All tools are pinned to specific versions in `.unirtm.toml`

### 🔒 Additional Recommendations

#### 1. Disable unirtm Registry (Future)

When unirtm supports it, consider disabling the default registry:

```toml
[settings]
disable_default_registry = true  # Not yet supported
```

#### 2. Audit Tool Sources

Regularly verify that installed tools match expected sources:

```bash
# Check what unirtm actually installed
unirtm list

# Verify binary checksums against official releases
unirtm exec -- <tool> --version
```

#### 3. Use unirtm.lock for Reproducibility

The `unirtm.lock` file ensures consistent installations across environments:

```bash
# Verify lock file matches configuration
unirtm install --frozen
```

#### 4. Monitor unirtm Registry Changes

Watch for changes in unirtm's registry that might affect your tools:

```bash
# Check current registry mappings
unirtm registry | grep -E "(checkmake|gitleaks|hadolint)"
```

## Verification Steps

### Before Deployment

1. **Verify Tool Sources**:

   ```bash
   unirtm list | grep -v "npm:" | grep -v "pipx:"
   ```

2. **Check for Unexpected Backends**:

   ```bash
   unirtm list | grep "aqua:"
   ```

   Should only show tools you explicitly configured with aqua backend.

3. **Validate Binary Integrity**:

   ```bash
   # For GitHub releases, verify against official checksums
   unirtm where github:checkmake/checkmake
   sha256sum $(unirtm where github:checkmake/checkmake)/bin/checkmake
   ```

### During CI/CD

Our CI workflows already implement:

- ✅ Locked unirtm versions (`UNIRTM_LOCKED=1`)
- ✅ Explicit tool specs in lint-wrapper.sh
- ✅ Version pinning in .unirtm.toml
- ✅ unirtm.lock committed to repository

## Related Security Measures

1. **Dependabot**: Monitors unirtm tool versions
2. **Trivy**: Scans for vulnerabilities in binaries
3. **SBOM Generation**: Documents all tool dependencies
4. **Signed Commits**: Ensures code integrity

## References

- [unirtm Registry Documentation](https://github.com/snowdreamtech/UniRTMregistry.html)
- [unirtm Security Policy](https://github.com/jdx/unirtm/blob/main/SECURITY.md)
- [unirtm Paranoid Mode](https://github.com/snowdreamtech/UniRTMparanoid)
- [SLSA Framework](https://slsa.dev/)

## Action Items

- [ ] Monitor unirtm for registry disable feature
- [ ] Set up automated alerts for registry changes
- [ ] Document tool source verification in CI
- [ ] Consider contributing to unirtm for better registry transparency

---

**Last Updated**: 2026-04-16
**Reviewed By**: Security Team
**Next Review**: 2026-07-16
