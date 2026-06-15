# Quick Start

Get up and running in under 5 minutes.

## Prerequisites

- **Git** — for cloning the repository
- **Docker Desktop** — for DevContainer support (recommended)
- **VS Code** with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension

## Step 1: Use This Template

Click **"Use this template"** on GitHub, or clone directly:

```bash
git clone https://github.com/snowdreamtech/template.git my-project
cd my-project
git config core.ignorecase false  # MANDATORY for Mac/Windows
```

## Step 2: Hydrate the Project

Run the project hydration script to replace template placeholders with your project's actual identity:

```bash
bash scripts/init-project.sh
```

This will interactively prompt for:

- **Project name** (e.g., `my-awesome-app`)
- **Author name** (e.g., `John Doe`)
- **GitHub username / organization** (e.g., `myorg`)

It replaces all occurrences of `template`, `snowdreamtech`, and `snowdream` throughout the codebase and optionally re-initializes the Git repository.

## Step 3: Initialize the Environment

### Option A: AI-Assisted (Recommended)

Open your project in any supported AI IDE and run the init workflow:

```
/snowdreamtech.init
```

This triggers the AI agent to:

- Enable zero-config Node.js environment via `corepack enable`
- Install all project-local linters and formatters via `pnpm install`
- Configure platform-specific tools (Homebrew / APT / Scoop)
- Activate pre-commit hooks

### Option B: Manual

Follow the standardized sequence for a robust environment:

```bash
unirtm run init     # Step 1: Hydrate project from template
unirtm run setup    # Step 2: Install system-level tools (binaries)
unirtm run install  # Step 3: Install project dependencies & hooks
unirtm run verify   # Step 4: Run comprehensive health check
```

## Step 4: Open in DevContainer

1. Open VS Code
2. Ensure Docker Desktop is running
3. Click **"Reopen in Container"** when prompted (or use `F1` → `Dev Containers: Reopen in Container`)

The DevContainer will build an environment with all 20+ CI tools and 40+ extensions pre-installed.

## Step 5: Start Building

Your AI assistant will now follow the project rules automatically. Jump in:

```
/speckit.specify  # Describe your first feature
```

## Verify Everything Works

```bash
unirtm run lint    # Run all linters
unirtm run test    # Run tests
unirtm run build   # Build the project
```

::: tip
Run `unirtm run help` to see all available commands.
:::
