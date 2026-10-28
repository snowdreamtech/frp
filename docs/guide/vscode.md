# VS Code Setup

The template includes a pre-configured VS Code workspace optimized for AI-assisted development.

## Extensions (Auto-installed via DevContainer)

Over 40 extensions are auto-installed when you open the project in a DevContainer, including:

- **AI Assistants**: GitHub Copilot, Cline, Roo Code, Windsurf
- **Languages**: Go, Python, TypeScript, Rust, Java, C/C++, Swift
- **Infrastructure**: Docker, Kubernetes, Terraform, Ansible
- **Quality**: ESLint, Prettier, ShellCheck, markdownlint

## Tasks (`tasks.json`)

Access via `Terminal` → `Run Task`:

| Task                 | Command         |
| -------------------- | --------------- |
| `🔧 make: lint`      | `unirtm run lint`     |
| `🔧 make: format`    | `make format`   |
| `🔧 make: test`      | `unirtm run test`     |
| `🔧 make: build`     | `unirtm run build`    |
| `🔧 make: setup`     | `unirtm run setup`    |
| `🌐 web: dev server` | `npm run dev`   |
| `🏗️ web: build`      | `npm run build` |

## Launch Configurations (`launch.json`)

Debug profiles available via `Run and Debug` (`F5`):

| Profile                     | Description                        |
| --------------------------- | ---------------------------------- |
| `Go: Launch Current File`   | Debug the current Go file          |
| `Go: Launch Package`        | Debug `main.go` in the project     |
| `Python: Current File`      | Debug current Python script        |
| `Python: Module`            | Debug a Python module              |
| `Node.js: Launch`           | Debug Node.js application          |
| `Edge: Debug React/Vue App` | Debug frontend app in Edge browser |
| `React: Vite Dev Server`    | Debug Vite dev server              |
