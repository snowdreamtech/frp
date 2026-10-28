# Linting Tools

This template uses a comprehensive set of linters and formatters, all enforced via pre-commit hooks and CI.

## Pre-commit Hooks

All hooks are defined in `.pre-commit-config.yaml`. Install once:

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

## Tool Reference

### Code Quality

| Tool                        | Language / Type         | What it checks               |
| --------------------------- | ----------------------- | ---------------------------- |
| `prettier`                  | JS/TS/CSS/JSON/YAML/MD  | Formatting                   |
| `eslint`                    | JavaScript / TypeScript | Code quality, best practices |
| `ruff`                      | Python                  | Linting + formatting         |
| `gofmt` / `goimports`       | Go                      | Formatting, imports          |
| `rustfmt`                   | Rust                    | Formatting                   |
| `rubocop`                   | Ruby                    | Linting + formatting         |
| `google-java-format`        | Java                    | Formatting                   |
| `ktlint`                    | Kotlin                  | Formatting                   |
| `swiftformat` / `swiftlint` | Swift                   | Formatting + linting         |
| `dotnet format`             | C# / .NET               | Formatting                   |
| `dartfmt`                   | Dart                    | Formatting                   |
| `PSScriptAnalyzer`          | PowerShell              | Linting                      |
| `shellcheck`                | Shell scripts           | Correctness, portability     |

### Markdown & Docs

| Tool                | What it checks                |
| ------------------- | ----------------------------- |
| `markdownlint-cli2` | Markdown style and structure  |
| `prettier`          | Markdown formatting           |
| `lychee`            | Broken links in docs          |
| `spectral`          | OpenAPI/AsyncAPI spec linting |

### Security

| Tool          | What it checks                           |
| ------------- | ---------------------------------------- |
| `gitleaks`    | Secrets and credentials in code          |
| `trivy`       | Container and dependency vulnerabilities |
| `cargo audit` | Rust dependency vulnerabilities          |
| `pip-audit`   | Python dependency vulnerabilities        |
| `npm audit`   | Node.js dependency vulnerabilities       |
| `govulncheck` | Go dependency vulnerabilities            |

### Formatting & Structure

| Tool                | What it checks                               |
| ------------------- | -------------------------------------------- |
| `sort-package-json` | `package.json` key ordering                  |
| `dotenv-linter`     | `.env` file formatting                       |
| `commitlint`        | Commit message format (Conventional Commits) |
| `actionlint`        | GitHub Actions workflow syntax               |

## Running Manually

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run a specific hook
pre-commit run prettier --all-files
pre-commit run markdownlint-cli2 --all-files
pre-commit run shellcheck --all-files

# Run commitlint
echo "feat: my feature" | commitlint
```

## CI Integration

All linters run in the `lint` job of `.github/workflows/lint.yml`. Failures block merging.
