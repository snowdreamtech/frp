# Release & GoReleaser

This project uses [GoReleaser](https://goreleaser.com/) to automate release builds, artifact packaging, and changelog generation.

## Configuration

The release configuration lives in `.goreleaser.yml` at the project root. It defines:

- **Build targets** — cross-compiled binaries for Linux, macOS, Windows (amd64 / arm64)
- **Archive formats** — `.tar.gz` for Unix, `.zip` for Windows
- **Checksums** — `sha256` checksums file alongside every release
- **Changelog** — auto-generated from conventional commit messages grouped by type

## Local Validation

Validate the GoReleaser config without publishing:

```bash
make release-dry-run
# or directly:
goreleaser release --snapshot --clean
```

## GitHub Actions Integration

Releases are triggered automatically when a tag matching `v*` is pushed:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The CI workflow (`.github/workflows/release.yml`) will:

1. Check out the tagged commit
2. Set up the Go toolchain
3. Run `goreleaser release --clean`
4. Publish GitHub Release with all artifacts

## Versioning Strategy

This project follows [Semantic Versioning](https://semver.org/):

| Version bump       | When                              |
| ------------------ | --------------------------------- |
| `MAJOR` (`v2.0.0`) | Breaking API changes              |
| `MINOR` (`v1.1.0`) | New features, backward-compatible |
| `PATCH` (`v1.0.1`) | Bug fixes, security patches       |

## Commit Message Convention

GoReleaser builds the changelog from [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new authentication module      → appears under "Features"
fix: resolve nil pointer in parser       → appears under "Bug Fixes"
docs: update quickstart guide            → excluded from changelog
chore: bump dependencies                 → excluded from changelog
```
