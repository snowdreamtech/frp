# GitHub Actions CI/CD

The template ships with a complete CI/CD pipeline powered by GitHub Actions.

## Workflows Overview

| Workflow         | Trigger            | Purpose                                   |
| ---------------- | ------------------ | ----------------------------------------- |
| `lint.yml`       | Push, PR           | Run all quality checks via pre-commit     |
| `codeql.yml`     | Push, PR, Schedule | GitHub CodeQL security analysis           |
| `goreleaser.yml` | Tag push (`v*`)    | Build and publish releases                |
| `pr-title.yml`   | PR opened/edited   | Enforce Conventional Commits on PR titles |
| `labeler.yml`    | PR opened          | Auto-label PRs based on changed files     |
| `stale.yml`      | Schedule (daily)   | Mark and close stale issues/PRs           |
| `cache.yml`      | Schedule (weekly)  | Warm dependency caches                    |

## Lint Workflow

The `lint.yml` workflow runs the full pre-commit hook suite against all changed files. It mirrors exactly what developers run locally, ensuring no surprises at CI time.

**Jobs:**

- `changes` — Path-based filtering (only run relevant jobs)
- `hygiene` — Formatting and whitespace checks
- `security` — Gitleaks secret scanning + Trivy vulnerability scanning
- `backend` — Language-specific linting (Ruff, golangci-lint, etc.)
- `infra` — Infrastructure linting (ShellCheck, Hadolint, Actionlint)
- `commitlint` — Conventional Commits format enforcement

## Release Workflow

GoReleaser automates the entire release process when a version tag is pushed:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

GoReleaser will:

1. Build binaries for all target platforms (Linux, macOS, Windows + arm64/amd64)
2. Create Docker images
3. Generate a GitHub Release with the CHANGELOG
4. Upload all artifacts

## Branch Protection

For production use, configure branch protection rules on `main`:

- ✅ Require status checks (lint, codeql)
- ✅ Require PR reviews (1–2 approvals)
- ✅ Require up-to-date branches
- ✅ Require signed commits
