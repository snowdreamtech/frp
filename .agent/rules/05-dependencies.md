# Dependency & Release Guidelines

> Objective: Ensure dependencies are reproducible, auditable, and secure, and define a structured release process for publishing packages and APIs.

## 1. Locking & Versioning

- Lock files **MUST** be committed to version control. Never add lock files to `.gitignore`:

  | Ecosystem | Lock File |
  |-----------|----------|
  | Node.js (npm) | `package-lock.json` |
  | Node.js (pnpm) | `pnpm-lock.yaml` |
  | Node.js (yarn) | `yarn.lock` |
  | Python (pip) | `requirements.txt` with pinned versions |
  | Python (poetry) | `poetry.lock` |
  | Go | `go.sum` |
  | Rust | `Cargo.lock` |
  | Ruby | `Gemfile.lock` |
  | Java (Maven) | `pom.xml` (dependency versions) |
  | Java (Gradle) | `gradle/libs.versions.toml` |

- Prefer **exact version pinning** in production manifests. Avoid broad fuzzy strategies (`^`, `~`, `>=`) without documented rationale:

  ```json
  // ❌ Loose — allows minor/patch updates that might break things
  "express": "^4.18.0"

  // ✅ Exact — reproducible, no silent upgrades
  "express": "4.18.3"
  ```

- Pin tool and runtime versions in version manager config files committed to the repository. The project follows a **Universal Tiered Tool Strategy (UTTP)** to ensure reproducibility without local bootstrap friction:

  | Tier | Classification | Storage | Management |
  | :--- | :--- | :--- | :--- |
  | **Tier 1** | **Core/Global** | .unirtm.toml | Statically defined; local `unirtm install` default. |
  | **Tier 2** | **On-Demand** | [versions.sh](../../.unirtm.toml) | Defined as shell variables; JIT-installed by scripts. |

- **Adaptive Lock Forgiveness (ALF)**:
  - **The Problem**: Pre-compiled binaries (`github:`, `core:`) have stable hashes, but source-compiled tools (`go:`) depend on local builds, making `unirtm.lock` entries impossible to predict for all platforms.
  - **The Strategy**: To maintain a strict Security Lockdown (`UNIRTM_LOCKED=1`) without breaking source-based providers or encountering "GitHub Traffic Walls," the project implements **ALF**.
  - **Mechanism**: The `run_unirtm` wrapper in [common.sh](../../.unirtm.toml) automatically unsets the mandatory locking requirement for any tool using the `go:` prefix, allowing them to resolve via `GOPROXY` while keeping binaries strictly locked.

- **Manifest Aggregation & Locking**:
  - To ensure Tier 2 tools are cryptographically locked in `unirtm.lock` without bloating the root config, the project uses a **Manifest Aggregator** (.unirtm.toml).
  - **The Lock Ritual**: Running `make sync-lock` dynamically merges Tier 1 and Tier 2 definitions into a temporary "Full Manifest" to update the global `unirtm.lock`.
  - **CI/Audit Compliance**: All security audits and CI workflows MUST use the locked versions defined in `unirtm.lock` by activating the tiered configuration via `UNIRTM_CONFIG`.

  ```toml
  # .unirtm.toml — Standard Tier 1 config (example)
  [tools]
  node   = "20.18.3"
  pnpm   = "10.5.2"
  python = "3.12.9"
  ```

- Do not upgrade dependencies speculatively. Use automated tools (Dependabot, Renovate) with a scheduled review cadence:

  ```yaml
  # .github/dependabot.yml
  version: 2
  updates:
    - package-ecosystem: npm
      directory: "/"
      schedule: { interval: weekly }
      groups:
        dev-dependencies: { patterns: ["*"], dependency-type: development }
  ```

## 2. Dependency Sources & Integrity

- Prioritize **official registries** (npm, PyPI, crates.io, Maven Central, Go module proxy). For enterprise or air-gapped environments, use internal proxies with upstream mirroring (Nexus, Artifactory, Verdaccio).
- When downloading external resources in scripts or CI, verify downloaded artifacts with **SHA-256 checksum** before use. Prefer the project's standardized functions in `.unirtm.toml`:

  ```bash
  # Standardized download with integrity check (POSIX sh)
  . ".unirtm.toml"
  download_url "$URL" "output.tar.gz" "my-tool"
  verify_checksum "output.tar.gz" "$EXPECTED_SHA256"
  ```

- Never introduce unreviewed prebuilt binaries, native extensions, or pre-compiled wheels without verified sources and documented justification.
- Generate a **Software Bill of Materials (SBOM)** in CycloneDX or SPDX format for every production release:

  ```bash
  syft <image>           # container image SBOM
  cyclonedx-npm --output sbom.json   # Node.js project SBOM
  ```

  Attach SBOM to the release artifact or container registry metadata.
- Maintain an **allowlist of approved dependency registries** per project. Block unapproved sources:

  ```ini
  # .npmrc — restrict to official registry
  registry=https://registry.npmjs.org/
  ```

## 3. Dependency Review & Auditing

- Enable **automated vulnerability scanning** in CI — fail the pipeline on HIGH or CRITICAL severity findings:

  ```yaml
  # CI security gate
  - name: Audit dependencies
    run: |
      npm audit --audit-level=high --production   # Node.js
      pip-audit --require requirements.txt        # Python
      cargo audit                                  # Rust
      govulncheck ./...                            # Go
  ```

- CVE remediation SLA:

  | Severity | Resolution Deadline |
  |----------|-------------------|
  | **Critical** | 7 days |
  | **High** | 30 days |
  | **Medium** | 90 days |
  | **Low** | Next planned maintenance window |

- Track all **direct dependencies** and minimize transitive dependency sprawl. Before adding a new library, evaluate:
  - **Maintenance**: last commit date, open issues, bus factor (one-person project?)
  - **License**: MIT/Apache 2.0/BSD preferred. GPL/AGPL requires careful review in proprietary projects.
  - **CVE history**: more than 2 critical CVEs in the past year is a yellow flag
  - **Community adoption**: download count, GitHub stars, dependent packages
- Reject **abandoned packages** (no commits in 12+ months, no response to issues) unless actively forked and maintained internally.

## 4. Release Process

- Define a clear **release branch strategy** aligned to project size:
  - **Simple**: `main` (production-ready, tagged releases) — suitable for single-person or small projects
  - **Standard**: `main` (production) + `develop` (integration branch for feature merges)
  - **Enterprise**: `main` + `develop` + `release/x.y.z` (stabilization, QA) + `hotfix/*` (emergency production patches)
- Releases **MUST** pass CI entirely (lint, unit tests, integration tests, security scanning) and receive approval from at least one independent reviewer before tagging.
- Use **Semantic Versioning** (`MAJOR.MINOR.PATCH`) for all published packages and APIs:

  | Increment | When to Use                                        | Example           |
  | --------- | -------------------------------------------------- | ----------------- |
  | `MAJOR`   | Breaking API changes that require consumer updates | `1.5.2` → `2.0.0` |
  | `MINOR`   | Backward-compatible new features                   | `1.5.2` → `1.6.0` |
  | `PATCH`   | Backward-compatible bug fixes                      | `1.5.2` → `1.5.3` |

- Pre-release labels: use the `alpha` → `beta` → `rc` (release candidate) progression:

  ```bash
  1.2.0-alpha.1  # unstable, internal testing
  1.2.0-beta.2   # feature complete, external beta testing
  1.2.0-rc.1     # release candidate, freeze features
  1.2.0          # stable production release
  ```

- Tag every release with a signed, annotated tag:

  ```bash
  git tag -a -s v1.2.3 -m "Release v1.2.3: Add OAuth2 flow, fix token refresh race condition"
  git push origin v1.2.3
  ```

## 5. Changelog & Communication

- Maintain a `CHANGELOG.md` following the [Keep a Changelog](https://keepachangelog.com/) format. Every release MUST have a corresponding changelog entry:

  ```markdown
  ## [1.2.3] - 2025-01-15

  ### Added

  - OAuth2 login flow with Google and GitHub providers (#234)
  - Rate limiting on `/api/auth` endpoints (60 req/min per IP)

  ### Changed

  - Improved error messages for expired JWT tokens

  ### Fixed

  - Race condition in refresh token rotation (#312)

  ### Security

  - Updated `express` 4.18.2 → 4.19.2 (CVE-2024-XXXX: SSRF via open redirect)
  ```

- Automate changelog generation from Conventional Commit messages using tools like **`release-please`**, **`semantic-release`**, or **`git-cliff`**. Review and edit generated changelogs before publishing — automated tools miss context.
- For **breaking changes**, provide a dedicated **migration guide** (`docs/migrations/v2-to-v3.md`) with:
  - What changed and why
  - Side-by-side before/after code examples
  - Step-by-step migration instructions
  - Deprecation deadline for the old API version
- Announce releases through the project's designated communication channel (GitHub Releases, Slack, mailing list). Include: version number, key changes summary, upgrade instructions link, and known issues.

## 6. License Compliance & Supply Chain Security

- Track the **open-source license** of every direct dependency. Maintain a `licenses.json` or use tool-generated reports:

  ```bash
  # Node.js
  license-checker --summary --production --json > licenses.json

  # Python
  pip-licenses --format=json --output-file=licenses.json

  # Go
  go-licenses report ./... > licenses.csv
  ```

  Prohibited licenses in typical commercial software: **GPL-2.0**, **AGPL-3.0** (unless explicitly approved by legal). Always check copyleft implications when embedding libraries.

- Verify the **integrity of all tool downloads** in CI workflows using checksums or SLSA provenance:

  ```bash
  # Verify a downloaded binary with a published SHA-256 checksum
  TOOL_VERSION="1.2.3"
  curl -fsSL "https://example.com/tool-${TOOL_VERSION}-linux-amd64.tar.gz" -o tool.tar.gz

  EXPECTED_SHA="abc123def456..."
  ACTUAL_SHA=$(sha256sum tool.tar.gz | awk '{print $1}')
  [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || { echo "Checksum mismatch!"; exit 1; }
  ```

- Use **SLSA (Supply-chain Levels for Software Artifacts) provenance** for published packages and container images to provide cryptographic proof of build integrity. Target SLSA Level 2+ for production artifacts.

- Review and document the **transitive dependency tree** for any third-party library that handles: network traffic, cryptography, authentication, or file system access. These are highest-risk dependency categories.
