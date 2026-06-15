# Security & Compliance Guidelines

> Objective: Define rules for handling sensitive information, credentials, access control, and vulnerability management to reduce security risk and compliance exposure.

## 1. Credential & Secret Management

- All keys, tokens, passwords, and certificates **MUST NOT** appear in the repository — including commit history, comments, log files, and CI environment dumps. Use tools like **gitleaks** or **truffleHog** to scan history.
- Use environment variables or dedicated secret management systems for all secrets:
  - **GitHub**: GitHub Secrets (Actions), GitHub Environments
  - **AWS**: AWS Secrets Manager, AWS Parameter Store
  - **GCP**: GCP Secret Manager
  - **HashiCorp Vault**: for multi-cloud, self-hosted, or cross-platform requirements
  - **Azure**: Azure Key Vault
- Provide a `.env.example` listing all required variables with placeholder values and descriptions. **Never commit a real `.env`** or any equivalent secrets file:

  ```bash
  # .env.example — commit this
  DATABASE_URL=postgres://user:password@localhost:5432/mydb   # PostgreSQL connection string
  JWT_SECRET=<replace-with-random-256bit-secret>              # OpenSSL: openssl rand -hex 32
  STRIPE_SECRET_KEY=sk_live_<your-stripe-secret-key>         # From Stripe Dashboard
  ```

- Prevent accidental commits using pre-commit hooks: **git-secrets**, **gitleaks**, or **detect-secrets**. Configure as a CI hard gate that blocks the entire pipeline on any detected secret:

  ```bash
  gitleaks detect --source . --report-format json --exit-code 1
  ```

- Rotate secrets immediately upon any suspected or confirmed exposure. Revoke the old credentials before generating new ones. Document the rotation in an incident log with timestamp and actor.
- Use **short-lived credentials** wherever possible (OAuth 2.0 access tokens with short TTL, AWS STS AssumeRole, GCP Workload Identity, Kubernetes service account tokens) over long-lived static credentials.

## 2. Gitleaks Configuration Best Practices

### File Roles (MANDATORY distinction)

| File | Purpose | What it accepts |
|:---|:---|:---|
| `.gitleaks.toml` | Configuration — allowlists, rule overrides | Path regex patterns, rule definitions |
| `.gitleaksignore` | Suppress **specific findings** by fingerprint | Finding fingerprints ONLY (e.g., `abc123:file.go:42:MyRule`) |

> **Critical**: Adding directory paths (`node_modules/`, `dist/`) to `.gitleaksignore` is **invalid** and produces `WRN Invalid .gitleaksignore entry` warnings. All path exclusions MUST go in `.gitleaks.toml` under `[allowlist]`.

### Path Exclusion Decision Matrix

| Category | Example | Exclude? | Rationale |
|:---|:---|:---|:---|
| Build artifacts | `dist/`, `build/`, `out/`, `target/` | ✅ Always | Generated code, never contains credentials |
| Package caches | `node_modules/`, `.cargo/registry/` | ✅ Always | Third-party code, performance gain is large |
| Git internals | `.git/objects/`, `.git/logs/` | ✅ Always | Content hashes, not user data |
| Venv internals | `venv/bin/`, `venv/lib/` | ✅ Subdirs only | Only skip binary/lib; **root is scanned** |
| `.env` files | `.env`, `.env.local` | ❌ Never | Highest-risk files — must be detected |
| Lock files | `pnpm-lock.yaml`, `go.sum` | ❌ Never | Can contain registry URLs with embedded tokens |
| Config dirs | `.specify/`, `.ansible/`, `.github/` | ❌ Never | May contain scripts with hardcoded secrets |
| IaC state | `*.tfvars`, `*.tfstate` | ❌ Never | Frequently contain secrets and sensitive data |

### Safe Virtual Environment Exclusion Pattern

Never exclude `venv/` or `env/` entirely — a misplaced `.env` file in the root of that directory would be silently ignored. Only exclude the standard subdirectories:

```toml
# ✅ CORRECT — root of env/ is still scanned
'''(|/)(|.venv|venv|env)/(bin|lib|lib64|include|share|scripts|Lib|Scripts)/'''

# ❌ WRONG — silently hides any .env in env/
'''env/'''
```

### CI Integration

```yaml
# ✅ Use the official binary (Python-version-agnostic)
- name: Run Gitleaks
  run: |
    git config diff.renameLimit 4000   # prevent spurious git rename warnings
    ${{ env.VENV }}/bin/gitleaks detect --source . --config .gitleaks.toml
```

> **Note**: `semgrep` installed via `pip` on Python 3.12 crashes with `ModuleNotFoundError: No module named 'pkg_resources'` — its `opentelemetry` dependency requires `setuptools`, which Python 3.12 no longer bundles. Fix: add `setuptools` to `requirements-dev.txt`. **Note**: `semgrep/semgrep-action` was archived on 2024-04-09 and is no longer maintained.

## 3. Access Control & Auditing

- Apply the **Principle of Least Privilege**: grant users, services, and processes only the permissions they need to perform their specific function. Default to deny-all; explicitly allow required accesses. Review at every permission request.
- Implement **Role-Based Access Control (RBAC)** with clearly defined roles. Avoid sharing service accounts between unrelated services — each service has its own identity.
- Retain **audit logs** for all critical operations: secret access, permission changes, deployments, database schema changes, and administrative actions. Log format MUST include:

  ```json
  {
    "timestamp": "2025-01-15T10:30:00Z",
    "actor": "service-account@project.iam",
    "operation": "secrets.read",
    "resource": "projects/myapp/secrets/database-password",
    "outcome": "success",
    "requestId": "req-abc-123"
  }
  ```

- Review permissions regularly (at minimum quarterly, or after personnel changes). Revoke stale or over-broad access promptly. Maintain a permission inventory.
- Use **multi-factor authentication (MFA)** for all human accounts with access to production systems, CI/CD pipelines, or cloud consoles. Enforce MFA at the Identity Provider level (Okta, Google Workspace, Entra ID). Hardware keys (YubiKey) are preferred over TOTP for privileged accounts.
- For service-to-service communication: use **mTLS** or signed JWT assertions instead of shared secrets where possible.

## 3. Encryption & Transport Security

- All network communication MUST use **TLS 1.2+**. Prefer TLS 1.3 for new services. Redirect all HTTP traffic to HTTPS. Set `Strict-Transport-Security` (HSTS) headers with `max-age ≥ 31536000; includeSubDomains` for all user-facing services.
- Disable insecure protocol versions and cipher suites. Require forward secrecy (ECDHE) in TLS configurations. Validate TLS configurations with **SSL Labs** for public services.
- Use **mTLS** or encrypted channels for internal service-to-service communication in sensitive environments (financial, healthcare, PII-handling).
- For sensitive data at rest (backups, exports, PII fields in databases), use strong encryption:
  - Symmetric: **AES-256-GCM** (preferred), AES-256-CBC with HMAC
  - Asymmetric: RSA-4096 or ECC P-256 for key exchange
  - Document key management procedures including rotation schedule and recovery
- Never store passwords in plaintext or with weak hashing. Use adaptive algorithms with tunable cost:
  - **Argon2id**: preferred (OWASP recommended) — `m=65536, t=2, p=1` minimum
  - **bcrypt**: cost factor ≥ 12 (1 second+ on modern hardware)
  - **scrypt**: `N=32768, r=8, p=1` minimum
  - Use a unique salt per credential (most libraries handle this automatically)
- Key rotation SLA: encryption keys MUST be rotated at least annually. Credentials for critical systems (DB root, cloud admin) MUST be rotated at least every **90 days**.

## 4. Security Scanning & Dependency Hygiene

- Enable **automated dependency vulnerability scanning** in CI as a hard gate:

  ```yaml
  # GitHub Actions example
  - name: Security audit
    run: |
      npm audit --audit-level=high --production          # Node.js
      pip-audit --requirement requirements.txt           # Python
      cargo audit                                         # Rust
      govulncheck ./...                                   # Go
  ```

- Run **Static Application Security Testing (SAST)** in CI. SAST failures at HIGH or CRITICAL severity MUST block merge:
  - **CodeQL** (GitHub) — supports C/C++, Go, Java, Python, Ruby, JavaScript
  - **Semgrep** — fast, rule-based, supports all major languages
  - **Bandit** (Python), **SpotBugs** (Java), **gosec** (Go), **Brakeman** (Rails)
  Pin base images to a specific SHA digest for reproducibility: `FROM node:22-alpine@sha256:<digest>`.
- **Zero-Trust Network Egress Control (MANDATORY)**: All workflows MUST use `step-security/harden-runner` in `block` mode to prevent data exfiltration.
  - Avoid broad wildcards like `*.amazonaws.com`.
  - Use service-specific endpoints (e.g., `public.ecr.aws:443`, `registry.npmjs.org:443`).

- Generate a **Software Bill of Materials (SBOM)** in CycloneDX or SPDX format for every production release:
  - Use `trivy` or `syft` to generate SBOMs for filesystem or container images.
  - Upload SBOMs as build artifacts for transparency.

  ```bash
  # Example SBOM generation via Trivy
  trivy fs --format cyclonedx --output sbom.json .
  ```

- **GitHub Artifact Attestations (SLSA)**: Sign build artifacts and container images in CI using GitHub's built-in attestation service (Sigstore):

  ```yaml
  - name: Generate Artifact Attestation
    uses: actions/attest-build-provenance@52aa5ba130440536762391054ee55cb830c2c31e # v2.2.3
    with:
      subject-path: 'dist/my-artifact.tar.gz'
  ```

### UniRTM Toolchain Integrity

To prevent toolchain poisoning (Node.js, Go, Python, etc.):

- **Exact Pinning**: All tools in `.unirtm.toml` MUST use exact versions (e.g., `20.18.3` instead of `20`).
- **Official Registries**: Env vars like `NODEJS_ORG_MIRROR` MUST point to official sources in CI.
- **UNIRTM_LOCKED Mode**: All CI workflows MUST set `UNIRTM_LOCKED: 1` to prevent unauthorized tool updates or remote resolution at runtime.
- **UniRTM Lockfile**: A `unirtm.lock` file containing SHA-256 checksums for all platforms MUST be maintained and committed.
- **Network Isolation**: `harden-runner` remains the final defense, blocking any unauthorized connection attempted by compromised plugins.

### Dependency Governance (Final Shields Up)

- **PR Dependency Review**: All Pull Requests MUST pass the `dependency-review` check. This prevents the introduction of known vulnerabilities before they are merged.
- **Semantic Scanning**: `osv-scanner` MUST be enabled in `audit.sh` to provide deep vulnerability detection for all supported ecosystems (Go, npm, Python, etc.).
- **Artifact Signing**: All production binaries MUST be signed with `cosign` using OIDC-based keyless signing.

  | severity | Resolution Deadline |
  |----------|-------------------|
  | Critical | 7 days |
  | High | 30 days |
  | Medium | 90 days |
  | Low | Next planned maintenance |

### Security Audit Orchestration & Shift-Left

To maintain a robust security posture across all development stages, the audit pipeline MUST follow these core principles:

- **Availability-First Detection (可用性优先检测)**: Environment validations (e.g., `check-env.sh`) MUST prioritize tool presence over environment gating. If a security tool is detected locally, it MUST be reported as `✅ Active`, regardless of its Tier 3 or CI-only classification.
- **Automatic Activation (自动激活)**: Security scanners (e.g., `osv-scanner`, `zizmor`, `pip-audit`) MUST follow a "Run if installed" pattern. If a tool is available locally, `make audit` MUST automatically execute it, ensuring local validation parity with CI.
- **Non-Blocking Optionality (非阻塞可选性 / Strict CI vs Local Grace)**: Orchestration scripts MUST implement environment-aware exits (e.g., `is_ci_env`). In local environments, missing security tools MUST be reported as gracefully skipped (`⏭️ Skipped`) to eliminate developer friction. Conversely, these tools remain strictly mandated in CI, where their absence MUST trigger an immediate fatal error (`❌ Missing (Fatal)` -> `exit 1`).
- **Dynamic On-Demand Execution (动态按需执行)**: Extremely heavy analysis or security tools (like `zizmor`) MUST NOT bulk up the primary `.unirtm.toml` manifest. Instead, they should be defined as Tier 2/On-Demand tools and executed dynamically (`unirtm exec tool@ver -- cmd`) only when their specific security audit is invoked.
- **Unified Summary Reporting**: Both local and CI audit results MUST be captured in a standardized summary table (`.ci_summary.log`) to provide clear visibility into the project's security coverage and findings.

## 5. Incident Response & Disclosure

- Establish and document a **security incident response process**: who to notify (on-call engineer, CISO, legal, affected customers), how to isolate affected systems, how to investigate root cause, and how to remediate. Classify incidents:
  - **P1 (Critical)**: active exploitation, data breach, production service down
  - **P2 (High)**: potential exploitation, significant security degradation
  - **P3 (Medium)**: vulnerability identified but not yet exploited
- Define and publish a **responsible disclosure policy** (`SECURITY.md` in the repository root):

  ```markdown
  # Security Policy

  ## Reporting a Vulnerability

  Please report security vulnerabilities to: security@example.com
  We will acknowledge within 24 hours and triage within 72 hours.

  Please do not publicly disclose the vulnerability before we have
  had a chance to assess and release a fix.
  ```

- For internal vulnerabilities: fix and validate in staging, deploy to production, then disclose to affected stakeholders post-deploy.
- Conduct a **blameless post-mortem** for every P1/P2 security incident within 5 business days: root cause, timeline, impact scope, and corrective actions with owners and deadlines.
- Maintain a **security runbook** for each production service: known attack vectors, detection signals, isolation steps, and recovery procedures. Link runbooks from every dashboard alert.

## 6. Application Security Design

- **Input Validation**: Validate ALL external inputs (HTTP body, query params, path params, headers, file uploads) at the API boundary. Never trust client-supplied data:

  ```typescript
  // ✅ Validate with Zod at the API layer
  const CreateUserSchema = z.object({
    email: z.string().email().max(255),
    username: z
      .string()
      .min(3)
      .max(50)
      .regex(/^[a-zA-Z0-9_-]+$/),
    age: z.number().int().min(18).max(150),
  });

  const result = CreateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() });
  }
  ```

- **OWASP Top 10** must be addressed in every web application:
  - **A01 Broken Access Control**: enforce authorization checks on every operation — not just at the route level
  - **A02 Cryptographic Failures**: use strong algorithms (AES-256, SHA-256+), never hand-roll crypto
  - **A03 Injection**: use parameterized queries for all database access; never concatenate user input into queries
  - **A04 Insecure Design**: threat model during design phase, not after
  - **A05 Security Misconfiguration**: harden all defaults; disable debug endpoints, directory listings, and verbose error messages in production
  - **A07 Authentication Failures**: use proven auth libraries, implement MFA, use secure session management

- **Security HTTP Headers**: Set security headers on all HTTP responses using a middleware or reverse proxy:

  ```http
  Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  ```

- **Rate Limiting & Abuse Prevention**: Apply rate limiting on all authentication, signup, password-reset, and data-export endpoints. Use sliding-window algorithms with IP + user-based limits. Return `429 Too Many Requests` with a `Retry-After` header.
