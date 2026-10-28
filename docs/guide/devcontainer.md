# DevContainer

A fully pre-configured development environment that eliminates "works on my machine" issues.

## What's Included

The DevContainer provides:

- **20+ CI/CD tools** pre-installed: `actionlint`, `hadolint`, `golangci-lint`, `gitleaks`, `shellcheck`, `trivy`, and more
- **40+ VS Code extensions** auto-installed: language servers, formatters, AI assistants, Docker, Git tools
- **All language runtimes**: Go, Python, Node.js, with version management
- **Pre-commit hooks** pre-configured and ready to run

## Two Operating Modes

### Mode 1: Single Container (Default)

Lightweight, fast startup. A single Docker container with everything you need.

```json
// .devcontainer/devcontainer.json (default)
{
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  }
}
```

### Mode 2: Docker Compose (Multi-service)

Includes additional backend services for full-stack development.

**Available services:**

- **PostgreSQL** — Relational database
- **Redis** — Cache and message broker

To enable Docker Compose mode:

1. Open `.devcontainer/devcontainer.json`
2. Comment out the `build` section
3. Uncomment the `dockerComposeFile` section:

```json
{
  "dockerComposeFile": "docker-compose.yaml",
  "service": "app",
  "workspaceFolder": "/workspace"
}
```

1. Rebuild the container (`F1` → `Dev Containers: Rebuild Container`)

## Usage

### Local Development

1. Open VS Code with Docker Desktop running
2. Click **"Reopen in Container"** in the notification that appears
3. Or: `F1` → `Dev Containers: Reopen in Container`

### Remote SSH Development

1. Connect to your remote server via `Remote - SSH`
2. Open the project folder
3. `F1` → `Dev Containers: Reopen in Container`

VS Code builds and runs the container on the **remote server's Docker engine** — all compute stays remote.

## Customization

### Custom Base Image

Modify the `FROM` line in `.devcontainer/Dockerfile`:

```dockerfile
# Default
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Custom enterprise image
FROM your-registry.example.com/your-base-image:latest
```

Ensure your image has a `vscode` user, or adjust `remoteUser` in `devcontainer.json`.

### Adding Extensions

Add extensions to `devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": ["existing.extensions", "your.new-extension"]
    }
  }
}
```

### Post-Create Commands

The DevContainer runs `unirtm run install` after creation to install project dependencies automatically.
