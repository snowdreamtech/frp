# Bugfix Requirements Document

## Introduction

Many scripts in `scripts/lib/langs/` have hardcoded provider values instead of using the centralized version variables from `.unirtm.toml`. This creates inconsistency and makes version management difficult. When versions need to be updated, developers must manually search and update multiple files instead of changing a single centralized location. This violates the Single Source of Truth (SSoT) principle and increases the risk of version drift across the codebase.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a script in `scripts/lib/langs/shell.sh` installs shfmt THEN the system uses hardcoded `local _PROVIDER="github:mvdan/sh"` instead of `${VER_SHFMT_PROVIDER}`

1.2 WHEN a script in `scripts/lib/langs/docker.sh` installs hadolint THEN the system uses hardcoded `local _PROVIDER="github:hadolint/hadolint"` instead of `${VER_HADOLINT_PROVIDER}`

1.3 WHEN a script in `scripts/lib/langs/runner.sh` installs just THEN the system uses hardcoded `local _PROVIDER="github:casey/just"` instead of `${VER_JUST_PROVIDER}`

1.4 WHEN a script in `scripts/lib/langs/lua.sh` installs stylua THEN the system uses hardcoded `local _PROVIDER="github:JohnnyMorganz/StyLua"` instead of `${VER_STYLUA_PROVIDER}`

1.5 WHEN a script in `scripts/lib/langs/shell.sh` installs shellcheck THEN the system uses hardcoded `local _PROVIDER="github:koalaman/shellcheck"` instead of `${VER_SHELLCHECK_PROVIDER}`

1.6 WHEN a script in `scripts/lib/langs/shell.sh` installs actionlint THEN the system uses hardcoded `local _PROVIDER="github:rhysd/actionlint"` instead of `${VER_ACTIONLINT_PROVIDER}`

1.7 WHEN a script in `scripts/lib/langs/runner.sh` installs task THEN the system uses hardcoded `local _PROVIDER="github:go-task/task"` instead of `${VER_TASK_PROVIDER}`

1.8 WHEN a script in `scripts/lib/langs/docker.sh` installs dockerfile-utils THEN the system uses hardcoded `local _PROVIDER="npm:dockerfile-utils"` instead of `${VER_DOCKERFILE_UTILS_PROVIDER}`

1.9 WHEN a script in `scripts/lib/langs/base.sh` installs gitleaks THEN the system uses hardcoded `local _PROVIDER="github:gitleaks/gitleaks"` instead of `${VER_GITLEAKS_PROVIDER}`

1.10 WHEN a script in `scripts/lib/langs/base.sh` installs checkmake THEN the system uses hardcoded `local _PROVIDER="github:mrtazz/checkmake"` instead of `${VER_CHECKMAKE_PROVIDER}`

1.11 WHEN a script in `scripts/lib/langs/base.sh` installs editorconfig-checker THEN the system uses hardcoded `local _PROVIDER="github:editorconfig-checker/editorconfig-checker"` instead of a centralized variable

1.12 WHEN a script in `scripts/lib/langs/base.sh` installs goreleaser THEN the system uses hardcoded `local _PROVIDER="github:goreleaser/goreleaser"` instead of `${VER_GORELEASER_PROVIDER}`

1.13 WHEN a script in `scripts/lib/langs/toml.sh` installs taplo THEN the system uses hardcoded `local _PROVIDER="npm:@taplo/cli"` instead of `${VER_TAPLO_PROVIDER}`

1.14 WHEN a script in `scripts/lib/langs/helm.sh` installs kube-linter THEN the system uses hardcoded `local _PROVIDER="github:stackrox/kube-linter"` instead of `${VER_KUBE_LINTER_PROVIDER}`

1.15 WHEN a script in `scripts/lib/langs/node.sh` installs sort-package-json THEN the system uses hardcoded `local _PROVIDER="npm:sort-package-json"` instead of `${VER_SORT_PACKAGE_JSON_PROVIDER}`

1.16 WHEN a script in `scripts/lib/langs/node.sh` installs eslint THEN the system uses hardcoded `local _PROVIDER="npm:eslint"` instead of `${VER_ESLINT_PROVIDER}`

1.17 WHEN a script in `scripts/lib/langs/node.sh` installs stylelint THEN the system uses hardcoded `local _PROVIDER="npm:stylelint"` instead of `${VER_STYLELINT_PROVIDER}`

1.18 WHEN a script in `scripts/lib/langs/node.sh` installs vitepress THEN the system uses hardcoded `local _PROVIDER="npm:vitepress"` instead of `${VER_VITEPRESS_PROVIDER}`

1.19 WHEN a script in `scripts/lib/langs/node.sh` installs prettier THEN the system uses hardcoded `local _PROVIDER="npm:prettier"` instead of `${VER_PRETTIER_PROVIDER}`

1.20 WHEN a script in `scripts/lib/langs/node.sh` installs commitlint THEN the system uses hardcoded `local _PROVIDER="npm:@commitlint/cli"` instead of `${VER_COMMITLINT_PROVIDER}`

1.21 WHEN a script in `scripts/lib/langs/node.sh` installs commitizen THEN the system uses hardcoded `local _PROVIDER="npm:commitizen"` instead of `${VER_COMMITIZEN_PROVIDER}`

1.22 WHEN a script in `scripts/lib/langs/sql.sh` installs sqlfluff THEN the system uses hardcoded `local _PROVIDER="pipx:sqlfluff"` instead of `${VER_SQLFLUFF_PROVIDER}`

1.23 WHEN a script in `scripts/lib/langs/protobuf.sh` installs buf THEN the system uses hardcoded `local _PROVIDER="github:bufbuild/buf"` instead of `${VER_BUF_PROVIDER}`

1.24 WHEN a script in `scripts/lib/langs/markdown.sh` installs markdownlint THEN the system uses hardcoded `local _PROVIDER="npm:markdownlint-cli2"` instead of `${VER_MARKDOWNLINT_PROVIDER}`

1.25 WHEN a script in `scripts/lib/langs/rego.sh` installs opa THEN the system uses hardcoded `local _PROVIDER="github:open-policy-agent/opa"` instead of `${VER_OPA_PROVIDER}`

1.26 WHEN a script in `scripts/lib/langs/swift.sh` installs swiftformat THEN the system uses hardcoded `local _PROVIDER="github:nicklockwood/SwiftFormat"` instead of a centralized variable

1.27 WHEN a script in `scripts/lib/langs/swift.sh` installs swiftlint THEN the system uses hardcoded `local _PROVIDER="github:realm/SwiftLint"` instead of `${VER_SWIFTLINT_PROVIDER}`

1.28 WHEN a script in `scripts/lib/langs/python.sh` installs ruff THEN the system uses hardcoded `local _PROVIDER="github:astral-sh/ruff"` instead of `${VER_RUFF_PROVIDER}`

1.29 WHEN a script in `scripts/lib/langs/python.sh` installs pip-audit THEN the system uses hardcoded `local _PROVIDER="pipx:pip-audit"` insteadof `${VER_PIP_AUDIT_PROVIDER}`

1.30 WHEN a script in `scripts/lib/langs/yaml.sh` installs yamllint THEN the system uses hardcoded `local _PROVIDER="pipx:yamllint"` instead of `${VER_YAMLLINT_PROVIDER}`

1.31 WHEN a script in `scripts/lib/langs/yaml.sh` installs dotenv-linter THEN the system uses hardcoded `local _PROVIDER="github:dotenv-linter/dotenv-linter"` instead of `${VER_DOTENV_LINTER_PROVIDER}`

1.32 WHEN a script in `scripts/lib/langs/openapi.sh` installs spectral THEN the system uses hardcoded `local _PROVIDER="npm:@stoplight/spectral-cli"` instead of `${VER_SPECTRAL_PROVIDER}`

1.33 WHEN a script in `scripts/lib/langs/terraform.sh` installs tflint THEN the system uses hardcoded `local _PROVIDER="github:terraform-linters/tflint"` instead of `${VER_TFLINT_PROVIDER}`

1.34 WHEN a script in `scripts/lib/langs/cpp.sh` installs clang-format THEN the system uses hardcoded `local _PROVIDER="pipx:clang-format"` instead of `${VER_CLANG_FORMAT_PROVIDER}`

1.35 WHEN a script in `scripts/lib/langs/ruby.sh` installs rubocop THEN the system uses hardcoded `local _PROVIDER="gem:rubocop"` instead ofa centralized variable

1.36 WHEN runtime installation scripts use hardcoded provider values THEN the system lacks centralized version control for runtime providers like `local _PROVIDER="node"`, `local _PROVIDER="python"`, `local _PROVIDER="go"`, `local _PROVIDER="rust"`

### Expected Behavior (Correct)

2.1 WHEN a script in `scripts/lib/langs/shell.sh` installs shfmt THEN the system SHALL use `local _PROVIDER="${VER_SHFMT_PROVIDER:-}"`

2.2 WHEN a script in `scripts/lib/langs/docker.sh` installs hadolint THEN the system SHALL use `local _PROVIDER="${VER_HADOLINT_PROVIDER:-}"`

2.3 WHEN a script in `scripts/lib/langs/runner.sh` installs just THEN the system SHALL use `local _PROVIDER="${VER_JUST_PROVIDER:-}"`

2.4 WHEN a script in `scripts/lib/langs/lua.sh` installs stylua THEN the system SHALL use `local _PROVIDER="${VER_STYLUA_PROVIDER:-}"`

2.5 WHEN a script in `scripts/lib/langs/shell.sh` installs shellcheck THEN the system SHALL use `local _PROVIDER="${VER_SHELLCHECK_PROVIDER:-}"`

2.6 WHEN a script in `scripts/lib/langs/shell.sh` installs actionlint THEN the system SHALL use `local _PROVIDER="${VER_ACTIONLINT_PROVIDER:-}"`

2.7 WHEN a script in `scripts/lib/langs/runner.sh` installs task THEN the system SHALL use `local _PROVIDER="${VER_TASK_PROVIDER:-}"`

2.8 WHEN a script in `scripts/lib/langs/docker.sh` installs dockerfile-utils THEN the system SHALL use `local _PROVIDER="${VER_DOCKERFILE_UTILS_PROVIDER:-}"`

2.9 WHEN a script in `scripts/lib/langs/base.sh` installs gitleaks THEN the system SHALL use `local _PROVIDER="${VER_GITLEAKS_PROVIDER:-}"`

2.10 WHEN a script in `scripts/lib/langs/base.sh` installs checkmake THEN the system SHALL use `local _PROVIDER="${VER_CHECKMAKE_PROVIDER:-}"`

2.11 WHEN a script in `scripts/lib/langs/base.sh` installs editorconfig-checker THEN the system SHALL use `local _PROVIDER="${VER_EDITORCONFIG_CHECKER_PROVIDER:-}"` after adding this variable to versions.sh

2.12 WHEN a script in `scripts/lib/langs/base.sh` installs goreleaser THEN the system SHALL use `local _PROVIDER="${VER_GORELEASER_PROVIDER:-}"`

2.13 WHEN a script in `scripts/lib/langs/toml.sh` installs taplo THEN the system SHALL use `local _PROVIDER="${VER_TAPLO_PROVIDER:-}"`

2.14 WHEN a script in `scripts/lib/langs/helm.sh` installs kube-linter THEN the system SHALL use `local _PROVIDER="${VER_KUBE_LINTER_PROVIDER:-}"`

2.15 WHEN a script in `scripts/lib/langs/node.sh` installs sort-package-json THEN the system SHALL use `local _PROVIDER="${VER_SORT_PACKAGE_JSON_PROVIDER:-}"`

2.16 WHEN a script in `scripts/lib/langs/node.sh` installs eslint THEN the system SHALL use `local _PROVIDER="${VER_ESLINT_PROVIDER:-}"`

2.17 WHEN a script in`scripts/lib/langs/node.sh` installs stylelint THEN the system SHALL use `local _PROVIDER="${VER_STYLELINT_PROVIDER:-}"`

2.18 WHEN a script in `scripts/lib/langs/node.sh` installs vitepress THEN the system SHALL use `local _PROVIDER="${VER_VITEPRESS_PROVIDER:-}"`

2.19 WHEN a script in `scripts/lib/langs/node.sh` installs prettier THEN the system SHALL use `local _PROVIDER="${VER_PRETTIER_PROVIDER:-}"`

2.20 WHEN a script in `scripts/lib/langs/node.sh` installs commitlint THEN the system SHALL use `local _PROVIDER="${VER_COMMITLINT_PROVIDER:-}"`

2.21 WHEN a script in `scripts/lib/langs/node.sh` installs commitizen THEN the system SHALL use `local _PROVIDER="${VER_COMMITIZEN_PROVIDER:-}"`

2.22 WHEN a script in `scripts/lib/langs/sql.sh` installs sqlfluff THEN the system SHALL use `local _PROVIDER="${VER_SQLFLUFF_PROVIDER:-}"`

2.23 WHEN a script in `scripts/lib/langs/protobuf.sh` installs buf THEN the system SHALL use `local _PROVIDER="${VER_BUF_PROVIDER:-}"`

2.24 WHEN a script in `scripts/lib/langs/markdown.sh` installs markdownlint THEN the system SHALL use `local _PROVIDER="${VER_MARKDOWNLINT_PROVIDER:-}"`

2.25 WHEN a script in `scripts/lib/langs/rego.sh` installs opa THEN the system SHALL use `local _PROVIDER="${VER_OPA_PROVIDER:-}"`

2.26 WHEN a script in `scripts/lib/langs/swift.sh` installs swiftformat THEN the system SHALL use `local _PROVIDER="${VER_SWIFTFORMAT_PROVIDER:-}"` after adding this variable to versions.sh

2.27 WHEN a script in `scripts/lib/langs/swift.sh` installs swiftlint THEN the system SHALL use `local _PROVIDER="${VER_SWIFTLINT_PROVIDER:-}"`

2.28 WHEN a script in `scripts/lib/langs/python.sh` installs ruff THEN the system SHALL use `local _PROVIDER="${VER_RUFF_PROVIDER:-}"`

2.29 WHEN a script in `scripts/lib/langs/python.sh` installs pip-audit THEN the system SHALL use `local _PROVIDER="${VER_PIP_AUDIT_PROVIDER:-}"`

2.30 WHEN a script in `scripts/lib/langs/yaml.sh` installs yamllint THEN the system SHALL use `local _PROVIDER="${VER_YAMLLINT_PROVIDER:-}"`

2.31 WHEN a script in `scripts/lib/langs/yaml.sh` installs dotenv-linter THEN the system SHALL use `local _PROVIDER="${VER_DOTENV_LINTER_PROVIDER:-}"`

2.32 WHEN a script in `scripts/lib/langs/openapi.sh` installs spectral THEN the system SHALL use `local _PROVIDER="${VER_SPECTRAL_PROVIDER:-}"`

2.33 WHEN a script in `scripts/lib/langs/terraform.sh` installs tflint THEN the system SHALL use `local _PROVIDER="${VER_TFLINT_PROVIDER:-}"`

2.34 WHEN a script in `scripts/lib/langs/cpp.sh` installs clang-format THEN the system SHALL use `local _PROVIDER="${VER_CLANG_FORMAT_PROVIDER:-}"`

2.35 WHEN a script in `scripts/lib/langs/ruby.sh` installs rubocop THEN the system SHALL use `local _PROVIDER="${VER_RUBOCOP_PROVIDER:-}"` after adding this variable to versions.sh

2.36 WHEN runtime installation scripts need provider values THEN the system SHALL reference centralized variables from versions.sh for consistency

### Unchanged Behavior (Regression Prevention)

3.1 WHEN scripts that already use centralized provider variables (like `security.sh`, `java.sh`, `kotlin.sh`, `testing.sh`) are present THEN the system SHALL CONTINUE TO use the centralized pattern `${VER_*_PROVIDER:-}`

3.2 WHEN a script uses `${VER_PIPX_PROVIDER:-pip:pipx}` with a fallback value THEN the system SHALL CONTINUE TO support the fallback pattern for backward compatibility

3.3 WHEN scripts install tools via mise THEN the system SHALL CONTINUE TO pass the provider value to `run_mise install "${_PROVIDER:-}"`

3.4 WHEN version checking logic uses `get_mise_tool_version "${_PROVIDER:-}"` THEN the system SHALL CONTINUE TO function correctly with centralized provider variables

3.5 WHEN scripts use `_log_setup "${_TITLE:-}" "${_PROVIDER:-}"` for logging THEN the system SHALL CONTINUE TO display the correct provider information

3.6 WHEN scripts check for language files using `has_lang_files` THEN the system SHALL CONTINUE TO skip installation if no relevant files are found

3.7 WHEN scripts perform version matching with `is_version_match` THEN the system SHALL CONTINUE TO work correctly with centralized provider variables

3.8 WHEN DRY_RUN mode is enabled THEN the system SHALL CONTINUE TO preview installations without executing them

3.9 WHEN scripts use `log_summary` to report installation status THEN the system SHALL CONTINUE TO display accurate status information

3.10 WHEN scripts source `versions.sh` at the beginning THEN the system SHALL CONTINUE TO have access to all centralized version variables
