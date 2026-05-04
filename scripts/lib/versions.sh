#!/usr/bin/env sh
# shellcheck disable=SC2034
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Tool Registry - Centralized version management for dynamic registration
#
# Purpose:
#   Centralized version registry for ALL project tools.
#
# Cache Invalidation: 2026-04-01 (PATH management fix)
#
#   - Tier 1 (Core): SSoT is .mise.toml. Versions here serve as a
#     backup mirror and must stay in sync. update-tools.sh updates both.
#   - Tier 2 (On-demand): SSoT is THIS FILE. Versions are pinned here
#     and referenced by scripts/lib/langs/*.sh for dynamic registration.
#
# shellcheck disable=SC2034
# (Variables are used by sourcing scripts: lang modules and setup.sh)

# ── 🏗️ Tier 1: Core Runtimes (Mirror of .mise.toml) ──────────────────────────
# shellcheck disable=SC2034
VER_GO="1.26.2"
VER_NODE="25.9.0"
VER_PNPM="11.0.4"
VER_PNPM_PROVIDER="npm:pnpm"
VER_PYTHON="3.14.4"
VER_PIPX="1.11.0"
VER_PIPX_PROVIDER="pip"

# ── 🏗️ Tier 2: Language Runtimes (On-demand) ─────────────────────────────────
VER_KOTLIN="2.3.21-RC"
VER_RUST="1.95.0"
VER_BUN="1.3.13"
VER_DENO="2.7.14"
VER_ZIG="0.16.0"
VER_JAVA="26.0.1"
VER_DOTNET="10.0.203"
VER_RUBY="4.0.3"
VER_YARN="1.22.22"

# ── 🧪 Exotic / Domain-Specific Runtimes ─────────────────────────────────────
VER_GRAIN="0.7.2"
VER_GRAIN_PROVIDER="github:grain-lang/grain"
VER_GRAIN_REF="grain-v0.7.2"

VER_MOONBIT="0.9.0+9f1423bcb"
VER_MOONBIT_PROVIDER="github:moonbitlang/moonbit-compiler"
VER_MOONBIT_REF="v0.7.2+c12686398"

VER_KCL="0.11.2"
VER_KCL_PROVIDER="github:kcl-lang/kcl"

VER_PKL="0.31.1"
VER_PKL_PROVIDER="github:apple/pkl"

VER_BAZEL="9.1.0"
VER_BAZEL_PROVIDER="github:bazelbuild/bazel"

VER_BALLERINA="2201.13.3"
VER_BALLERINA_PROVIDER="github:ballerina-platform/ballerina-distribution"

VER_STYLUA="2.4.1"
VER_STYLUA_PROVIDER="github:JohnnyMorganz/StyLua"

VER_JUST="1.50.0"
VER_JUST_PROVIDER="github:casey/just"

VER_TASK="3.50.0"
VER_TASK_PROVIDER="github:go-task/task"

VER_TYPST="0.13.0"
VER_DUCKDB="1.5.0"
# NOTE: Lychee version removed — link checking delegated to lycheeverse/lychee-action in CI.

# Additional language runtimes requiring GitHub providers
VER_LEAN="4.29.1"
VER_LEAN_PROVIDER="github:leanprover/lean4"

VER_NIM="2.4.0"
VER_NIM_PROVIDER="github:nim-lang/Nim"

VER_RACKET="9.1"
VER_RACKET_PROVIDER="github:racket/racket"

VER_VALA="0.58.0"
VER_VALA_PROVIDER="github:GNOME/vala"

VER_APTOS="5.5.0"
VER_APTOS_PROVIDER="github:aptos-labs/aptos-core"

# ── 🔐 Tier 1: Security & Engineering (Mirror of .mise.toml) ─────────────────
VER_GITLEAKS="8.30.1"
VER_GITLEAKS_PROVIDER="github:gitleaks/gitleaks"
VER_GH_CLI="2.92.0"
VER_GH_CLI_PROVIDER="github:cli/cli"

# ── 💎 Tier 1: Core Quality & Commit Tooling (Mirror of .mise.toml) ──────────
VER_CHECKMAKE="0.3.2"
VER_CHECKMAKE_PROVIDER="github:checkmake/checkmake"
VER_EDITORCONFIG_CHECKER="3.6.1"
VER_EDITORCONFIG_CHECKER_PROVIDER="github:editorconfig-checker/editorconfig-checker"
VER_ADDLICENSE="1.2.0"
VER_ADDLICENSE_PROVIDER="github:google/addlicense"

# Git / commit workflow
VER_COMMITLINT="20.5.3"
VER_COMMITLINT_PROVIDER="npm:@commitlint/cli"
VER_COMMITLINT_CONFIG="20.5.3"
VER_COMMITLINT_CONFIG_PROVIDER="npm:@commitlint/config-conventional"
VER_COMMITIZEN="4.3.1"
VER_COMMITIZEN_PROVIDER="npm:commitizen"
VER_CZ_CONVENTIONAL_CHANGELOG="3.3.0"
VER_CZ_CONVENTIONAL_CHANGELOG_PROVIDER="npm:cz-conventional-changelog"

# Universal formatting
VER_PRETTIER="3.8.3"
VER_PRETTIER_PROVIDER="npm:prettier"

# Shell & scripting
VER_SHELLCHECK="0.11.0"
VER_SHELLCHECK_PROVIDER="github:koalaman/shellcheck"
# Use shellcheck-py for pipx fallback if needed
VER_SHELLCHECK_PY="0.11.0.1"
VER_SHELLCHECK_PY_PROVIDER="pipx:shellcheck-py"
VER_SHFMT="3.13.1"
VER_SHFMT_PROVIDER="github:mvdan/sh"
# Use shfmt-py for pipx fallback if needed
VER_SHFMT_PY="3.12.0.2"
VER_SHFMT_PY_PROVIDER="pipx:shfmt-py"
VER_YAMLLINT="1.38.0"
VER_YAMLLINT_PROVIDER="pipx:yamllint"
VER_PRE_COMMIT="4.6.0"
VER_PRE_COMMIT_PROVIDER="pipx:pre-commit"
VER_ACTIONLINT="1.7.12"
VER_ACTIONLINT_PROVIDER="github:rhysd/actionlint"
# Use actionlint-py for pipx fallback if needed
VER_ACTIONLINT_PY="1.7.12.24"
VER_ACTIONLINT_PY_PROVIDER="pipx:actionlint-py"

# ── 🎨 Language Tooling (Linters/Formatters) ─────────────────────────────────
VER_KTLINT="1.16.1"
VER_KTLINT_PROVIDER="npm:@naturalcycles/ktlint"

VER_JAVA_FORMAT="1.35.0"
VER_JAVA_FORMAT_PROVIDER="github:google/google-java-format"

VER_SWIFTFORMAT_PROVIDER="github:nicklockwood/SwiftFormat"

VER_SWIFTLINT="0.63.2"
VER_SWIFTLINT_PROVIDER="github:realm/SwiftLint"

VER_RUBOCOP_PROVIDER="gem:rubocop"

VER_STYLELINT="17.10.0"
VER_STYLELINT_PROVIDER="npm:stylelint"

VER_STYLELINT_CONFIG="40.0.0"
VER_STYLELINT_CONFIG_PROVIDER="npm:stylelint-config-standard"

VER_ASSEMBLYSCRIPT="0.28.17"
VER_ASSEMBLYSCRIPT_PROVIDER="npm:assemblyscript"

VER_OPA="1.16.1"
VER_OPA_PROVIDER="github:open-policy-agent/opa"

VER_BUF="1.69.0"
VER_BUF_PROVIDER="github:bufbuild/buf"

VER_CUE="0.16.1"
VER_CUE_PROVIDER="github:cue-lang/cue"

VER_JSONNET="0.22.0"
VER_JSONNET_PROVIDER="github:google/go-jsonnet"

VER_GOLANGCI_LINT="1.64.5"

VER_VITEPRESS="1.6.4"
VER_VITEPRESS_PROVIDER="npm:vitepress"

VER_ESLINT="10.3.0"
VER_ESLINT_PROVIDER="npm:eslint"

VER_MARKDOWNLINT="0.22.1"
VER_MARKDOWNLINT_PROVIDER="npm:markdownlint-cli2"

VER_SORT_PACKAGE_JSON="3.6.1"
VER_SORT_PACKAGE_JSON_PROVIDER="npm:sort-package-json"

VER_TAPLO="0.7.0"
VER_TAPLO_PROVIDER="npm:@taplo/cli"

VER_HADOLINT="2.14.0"
VER_HADOLINT_PROVIDER="github:hadolint/hadolint"

VER_DOCKERFILE_UTILS="0.16.3"
VER_DOCKERFILE_UTILS_PROVIDER="npm:dockerfile-utils"

VER_RUFF="0.15.12"
VER_RUFF_PROVIDER="github:astral-sh/ruff"

VER_CLANG_FORMAT="22.1.4"
VER_CLANG_FORMAT_PROVIDER="pipx:clang-format"

VER_SQLFLUFF="4.1.0"
VER_SQLFLUFF_PROVIDER="pipx:sqlfluff"

VER_DOTENV_LINTER="4.0.0"
VER_DOTENV_LINTER_PROVIDER="github:dotenv-linter/dotenv-linter"

# NOTE: VER_CHECKMAKE moved to Tier 1 section above.

# ── 🛡️ Security Scanning (CI-only by default) ─────────────────────────────────
VER_TRIVY="0.70.0"
VER_TRIVY_PROVIDER="github:aquasecurity/trivy"

VER_OSV_SCANNER="2.3.6"
VER_OSV_SCANNER_PROVIDER="github:google/osv-scanner"

VER_GOVULNCHECK="1.3.0"
VER_GOVULNCHECK_PROVIDER="go:golang.org/x/vuln/cmd/govulncheck"

# Updated 2026-04-05: Ensure latest versions are installed
VER_PIP_AUDIT="2.10.0"
VER_PIP_AUDIT_PROVIDER="pipx:pip-audit"

VER_CARGO_AUDIT="0.22.1"
VER_CARGO_AUDIT_PROVIDER="cargo:cargo-audit"

# Updated 2026-04-05: Ensure latest versions are installed
VER_ZIZMOR="1.24.1"
VER_ZIZMOR_PROVIDER="github:zizmorcore/zizmor"

# ── ☁️ DevOps & Infrastructure ────────────────────────────────────────────────
VER_HELM="3.17.1"
VER_TERRAFORM="1.11.0"
VER_TERRAGRUNT="1.0.0-rc3"
VER_TOFU="1.11.6"
VER_TOFU_PROVIDER="github:opentofu/opentofu"
VER_PULUMI="3.234.0"
VER_PULUMI_PROVIDER="github:pulumi/pulumi"
VER_KUBE_LINTER="0.8.3"
VER_KUBE_LINTER_PROVIDER="github:stackrox/kube-linter"
VER_TFLINT="0.62.0"
VER_TFLINT_PROVIDER="github:terraform-linters/tflint"
VER_ANSIBLE_LINT="26.4.0"
VER_ANSIBLE_LINT_PROVIDER="pipx:ansible-lint"
VER_SPECTRAL="6.15.1"
VER_SPECTRAL_PROVIDER="npm:@stoplight/spectral-cli"

VER_GORELEASER="2.15.4"
VER_GORELEASER_PROVIDER="github:goreleaser/goreleaser"

# ── 📖 Documentation ──────────────────────────────────────────────────────────
VER_BATS="1.13.0"
VER_BATS_PROVIDER="npm:bats"

# ── 🛠️ Mise Internal / Helpers ────────────────────────────────────────────────
VER_MISE="2026.4.15"
VER_USAGE="3.3.0"
VER_USAGE_PROVIDER="usage"
