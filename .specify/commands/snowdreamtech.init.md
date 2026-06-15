---
description: Initialize the project to prepare for subsequent development.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Initialize Environment**
   > **💡 Tip: DevContainer Available!**
   > This project provides a fully-configured `.devcontainer` configuration. If you use VS Code or GitHub Codespaces, you can simply open this project in a container to completely skip the environment setup below. Node.js, Python, Go, PowerShell, and all necessary linters will be pre-installed automatically.

      ```bash
      # macOS / Linux
      sh scripts/setup.sh

      # Windows (PowerShell)
      .\scripts\setup.ps1

      # Windows (CMD)
      scripts\setup.bat
      ```

      > **💡 First-Class Citizens:**
      > This template treats **Node.js, Go, and Python** as first-class citizens. The setup scripts will automatically install their runtimes and core toolchains (pnpm, golangci-lint, ruff, etc.) regardless of whether project files currently exist.
      >
      > **💡 Specify VENV (Optional):**
      > If you need to specify a custom virtual environment path (e.g., for subprojects):
      > `make VENV=.custom/.venv setup`

     **Other Backend Ecosystems (.NET / Ruby / PHP):**
     _Note: `.NET` formatters are built-in (`dotnet format`)._

     ```bash
     gem install rubocop
     composer global require friendsofphp/php-cs-fixer
     ```

     **Platform-specific binary tools (`shellcheck`, `actionlint`, `hadolint`):**

     ```bash
     # macOS — Homebrew (preferred)
     brew install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format dotenv-linter golangci-lint checkmake tflint kube-linter ktlint

     # Windows (Scoop)
     scoop install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format llvm golangci-lint checkmake tflint kube-linter ktlint dotenv-linter

     # Windows (Winget)
     winget install koalaman.shellcheck rhysd.actionlint hadolint.hadolint mvdan.sh GolangCI.golangci-lint terraform-linters.tflint
     ```

     **Binary downloads (actionlint / hadolint / gitleaks — macOS & Linux fallback):**

     > `GITHUB_PROXY` is set to `https://gh-proxy.sn0wdr1am.com/` by default to ensure reliable downloads in restricted network environments.

     ```sh
     GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"

     # actionlint (latest version, dynamically fetched)
     ACTIONLINT_VER=$(curl -sSf --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 60 \
       "${GITHUB_PROXY}https://api.github.com/repos/rhysd/actionlint/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
     OS=$(uname -s | tr '[:upper:]' '[:lower:]'); ARCH=$(uname -m)
     curl -fL --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 120 \
       "${GITHUB_PROXY}https://github.com/rhysd/actionlint/releases/download/${ACTIONLINT_VER}/actionlint_${ACTIONLINT_VER#v}_${OS}_${ARCH}.tar.gz" \
       | tar -xz -C ~/.local/bin actionlint

     # hadolint (latest version, dynamically fetched)
     HADOLINT_VER=$(curl -sSf --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 60 \
       "${GITHUB_PROXY}https://api.github.com/repos/hadolint/hadolint/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
     ARCH=$(uname -m); if [ "$ARCH" = "arm64" ]; then HA="arm64"; else HA="x86_64"; fi
     curl -fL --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 120 \
       "${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VER}/hadolint-$(uname -s)-${HA}" \
       -o ~/.local/bin/hadolint && chmod +x ~/.local/bin/hadolint

     # gitleaks (latest version, dynamically fetched)
     GITLEAKS_VER=$(curl -sSf --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 60 \
       "${GITHUB_PROXY}https://api.github.com/repos/gitleaks/gitleaks/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
     OS=$(uname -s | tr '[:upper:]' '[:lower:]'); ARCH=$(uname -m)
     if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then GA="x64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then GA="arm64"; else GA=$ARCH; fi
     if [ "$OS" = "darwin" ]; then GL="darwin"; else GL="linux"; fi
     curl -fL --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 120 \
       "${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VER}/gitleaks_${GITLEAKS_VER#v}_${GL}_${GA}.tar.gz" \
       | tar -xz -C ~/.local/bin gitleaks

     # dotenv-linter
     curl -fLsS --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 120 \
       "${GITHUB_PROXY}https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh" | sh -s -- -b ~/.local/bin

     # golangci-lint
     curl -fLsS --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 10 --max-time 120 \
       "${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh" | sh -s -- -b ~/.local/bin
     ```

     Ensure `~/.local/bin` is in your `PATH`:

     ```bash
     echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
     ```

   - Install and activate `pre-commit` hooks to enforce code quality checks before every commit:

     ```bash
     # pre-commit is installed as part of `unirtm install`
     pre-commit install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg
     ```

   - **Install Project Dependencies**:
     Finally, install all project toolchains and dependencies:

     ```bash
     unirtm install
     ```
