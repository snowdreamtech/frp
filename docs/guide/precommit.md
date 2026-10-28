# Pre-commit Hooks

The template enforces code quality locally using [pre-commit](https://pre-commit.com/) with 40+ hooks that mirror the CI pipeline.

## Installation

Pre-commit is installed automatically when you run:

```bash
unirtm run setup
```

Or manually:

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

## Hook Categories

### Formatting

`prettier`, `gofmt`, `shfmt`, `ruff-format`, `clang-format`, `taplo`, `editorconfig-checker`

### Linting

`eslint`, `stylelint`, `ruff`, `yamllint`, `markdownlint-cli2`, `shellcheck`, `hadolint`, `actionlint`, `golangci-lint`, `checkmake`, `sqlfluff`, `tflint`, `kube-linter`, `ktlint`, `spectral`

### Security

`gitleaks` (secret detection)

### Other Languages

`rubocop` (Ruby), `psscriptanalyzer` (PowerShell), `swiftformat` / `swiftlint` (Swift), `dart format` (Dart), `dotnet-format` (.NET)

### Git Hygiene

`commitlint`, `trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflict`, `check-added-large-files`

## Running Manually

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run a specific hook
pre-commit run shellcheck --all-files

# Update all hooks to latest versions
pre-commit autoupdate
```
