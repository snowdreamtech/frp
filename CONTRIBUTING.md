# Contributing to this Project

First off, thank you for considering contributing to the **Snowdream Tech AI IDE Template**! It's people like you that make this template such a great foundational tool.

## 🤝 How to Contribute

We welcome contributions of all kinds, including bug fixes, new AI agent rules, documentation improvements, and CI/CD enhancements.

### 1. Setting Up Your Environment

Our project uses a standardized environment targeting **Node.js 22** and **Python 3.12**.

To set up your local development environment, follow the unified sequence:

1. **Setup & Install**: `unirtm install` (Install development tools and activate git hooks)
2. **Verify**: `make verify` (Final project health check)

### 2. General Workflow

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally.
3. **Branch** from `main` to a descriptively named branch (e.g., `feat/add-new-ai-rule`, `fix/ci-memory-leak`).
4. **Develop** your feature or fix.
5. **Commit** your changes following our [Conventional Commits](https://www.conventionalcommits.org/) standards. We highly recommend using our interactive Commitizen CLI to automatically assemble your commit message format. Simply run `npm run commit` or `git commit` with a conventional message.
6. **Push** to your fork.
7. **Submit a Pull Request (PR)** against our `main` branch.

### 3. Developer Certificate of Origin (DCO)

To legally protect the repository, all commits **must** be signed off. This signifies that you have the right to submit the code you are contributing.

You can easily sign off your commits by using the `-s` or `--signoff` flag:

```bash
git commit -s -m "fix(script): resolve posix portability issue"
```

### 4. Code & Architecture Standards

Before submitting rules or code, you **MUST** read our internal architecture guides:

- [01-general.md](.agent/rules/01-general.md): Core principles and language rules.
- [02-coding-style.md](.agent/rules/02-coding-style.md): CI/CD and script fallback requirements.
- [shell.md](.agent/rules/shell.md): Strict POSIX shell portability rules.

_Any Pull Request that fails the mandatory CI workflow checks or violates the architectural standards will not be merged._

Thank you for helping us build the ultimate SSOT AI IDE Template!
