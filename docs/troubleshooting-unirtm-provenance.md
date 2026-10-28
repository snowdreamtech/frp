# Troubleshooting UniRTM Provenance Verification Issues

## Problem

When running `make sync-lock` or `unirtm lock`, you may encounter an error like:

```
unirtm ERROR github:astral-sh/ruff@0.15.9 has no provenance verification on macos-x64,
but github:astral-sh/ruff@0.15.8 had github-attestations. This could indicate a supply
chain attack. Verify the release is authentic before proceeding.
```

This error occurs even when the GitHub release page clearly shows that attestations ARE present.

## Root Cause

The issue is caused by stale cached metadata in unirtm's cache directory. When unirtm checks for provenance verification:

1. It caches the verification status of previous versions (e.g., ruff 0.15.8 had attestations)
2. When a new version is released (e.g., ruff 0.15.9), unirtm may fail to fetch fresh attestation data
3. The cached metadata becomes outdated, causing false positives for supply chain attacks

## Solution

Clear the unirtm cache before synchronizing the lockfile. This has been implemented in `scripts/sync-lock.sh`:

```sh
# Clear unirtm cache to avoid stale provenance verification data
log_debug "Clearing unirtm cache to refresh provenance verification data..."
unirtm cache clear >/dev/null 2>&1 || true
```

The cache clear operation:

- Runs silently (`>/dev/null 2>&1`)
- Never fails the script (`|| true`)
- Ensures fresh provenance verification data is fetched

## Manual Verification

To manually verify that attestations exist for a release:

1. Visit the GitHub release page (e.g., <https://github.com/astral-sh/ruff/releases/tag/0.15.9>)
2. Look for the "Verifying GitHub Artifact Attestations" section
3. Verify using GitHub CLI:

```sh
gh attestation verify <file-path> --repo astral-sh/ruff
```

## Prevention

The fix is now automated in the CI/CD pipeline:

- The "🔄 Sync Dependabot Config" workflow runs `make sync-lock`
- `scripts/sync-lock.sh` automatically clears the cache before locking
- This prevents stale provenance verification errors

## Related Issues

- Ruff 0.15.9 provenance verification error
- GitHub Attestations: <https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations>
- UniRTM cache documentation: <https://github.com/snowdreamtech/UniRTMcli/cache.html>

## References

- [GitHub Artifact Attestations Documentation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds)
- [Ruff 0.15.9 Release](https://github.com/astral-sh/ruff/releases/tag/0.15.9)
- [UniRTM Cache Clear Discussion](https://github.com/jdx/unirtm/discussions/7267)
