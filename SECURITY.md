# Security Policy

## Supported Versions

Currently, the **Snowdream Tech AI IDE Template** is updated on a rolling basis. Our security fixes are applied exclusively to the latest `main` branch.

| Version | Supported          |
| ------- | ------------------ |
| `main`  | :white_check_mark: |
| Older   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability within this template (e.g., in the GitHub Actions configurations, exposed secret handling, or container dependencies), please report it to us privately via **email** or through the **GitHub Security Advisory** private reporting mechanism.

**Security Contact**: [snowdreamtech@qq.com](mailto:snowdreamtech@qq.com)

### Severity Classification

We categorize vulnerabilities into three severity levels:

| Severity | Description                                                                         |
| -------- | ----------------------------------------------------------------------------------- |
| **P1**   | Critical — active exploit possible; data loss or full system compromise at risk     |
| **P2**   | High — significant impact; exploitable under specific conditions                    |
| **P3**   | Medium/Low — limited impact; hardening recommendation or minor information exposure |

### Response SLA

| Severity | Acknowledgement | Severity Assessment | Patch Target |
| -------- | --------------- | ------------------- | ------------ |
| **P1**   | ≤ 24 hours      | ≤ 48 hours          | ≤ 7 days     |
| **P2**   | ≤ 24 hours      | ≤ 72 hours          | ≤ 30 days    |
| **P3**   | ≤ 24 hours      | ≤ 7 days            | Next release |

### Disclosure Process

1. Reporter submits vulnerability details privately (email or GitHub Security Advisory).
2. We acknowledge receipt within **24 hours**.
3. We assess severity and assign a classification (P1/P2/P3) within the SLA window.
4. We develop and validate a fix in a private branch.
5. We coordinate disclosure timing with the reporter.
6. We publicly release the fix and publish a security advisory.
7. We conduct a **blameless post-mortem** for P1/P2 incidents to prevent recurrence.

Thank you for helping to keep our project safe.
