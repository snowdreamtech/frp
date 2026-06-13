# ADR 0002: Single Source of Truth (SSoT) Symlink and Redirect Pattern

## Status

Accepted

## Context

This template must provide behavioral rules and configurations to over 50 different AI-powered IDEs
and tools (Cursor, Windsurf, GitHub Copilot, Cline, Roo Code, Gemini, Claude Code, etc.).

Each IDE follows its own convention for locating rule files. For example:

- Cursor reads rules from `.cursorrules` or `.cursor/rules/`
- Cline reads from `.cline/`
- VS Code-based extensions read from `.github/copilot-instructions.md`
- SpecKit-compatible tools read from `.agent/rules/`

A naive approach would maintain a separate, full copy of all rules for each IDE — resulting in
dozens of diverged copies that drift apart over time and no longer encode the intended behavior.

## Decision

We adopt a **Single Source of Truth (SSoT) Symlink and Redirect Pattern**:

1. **The Canonical Location**: All AI behavioral rules, workflow definitions, and quality configurations
   reside exclusively in `.agent/rules/` (the "Brain"). This is the only directory that should ever be
   edited directly.

2. **Thin Adapter Files**: For every IDE or tool that requires a specific file path or format, we create
   a thin adapter — either a **symbolic link** (on POSIX-compliant systems) or a **redirect file** (a
   plain text file containing a path or `@import`-style pointer to the canonical source).

3. **Propagation at Init Time**: The `scripts/init-project.sh` script is responsible for creating and
   maintaining all symlinks/redirect files when a project is initialized. This ensures that any new IDE
   adopters can be supported by updating a single script rather than copying rules.

4. **Git Strategy**: Symlinks are committed to Git as-is (Git supports symbolic links natively). Redirect
   stub files are also committed. The canonical `.agent/rules/` directory is the single file that must be
   kept up to date.

## Consequences

### Positive

- **Zero Drift**: There is only one authoritative copy of each rule. Updating `.agent/rules/01-general.md`
  instantly propagates to every IDE that points to it, with no manual synchronization step.
- **Scalability**: Adding support for a new AI IDE costs only a single new symlink or stub file — not a
  full copy of the entire rule set.
- **Auditability**: A security or compliance review only needs to inspect one directory, not dozens.

### Negative

- **Symlink Fragility on Windows**: Native Windows environments do not support POSIX symlinks without
  Developer Mode or admin rights. For Windows, the adapter must use a redirect file or a copy-on-init
  strategy. This is an accepted trade-off given that the majority of development occurs on POSIX systems.
- **Init Dependency**: The symlink graph is only valid after `unirtm run setup` or `scripts/init-project.sh`
  has been run. A freshly cloned repository before initialization may have broken symlinks for any IDE
  that relies on them.

## Alternatives Considered

### Option A: Full Copies per IDE

Maintain a complete copy of all rule files under every IDE-specific directory
(e.g., `.cursor/rules/*.md`, `.cline/rules/*.md`, etc.).

- **Reason rejected:** Any update to a rule requires N synchronized edits across N directories.
  In practice this leads to immediate drift and divergence of IDE behavior.

### Option B: Build-time Generation

Use a script to generate all per-IDE rule files from a template during a build step, and commit the
generated files.

- **Reason rejected:** Commits generated files into the repository, inflating history and creating
  noise in pull requests. It also requires developers to remember to re-run the build step after
  every rule change, which is error-prone.

### Option C: Central Config Server

Host all rules on a remote server and have each IDE extension pull from it at runtime.

- **Reason rejected:** Adds an external network dependency for a local development tool. Offline
  development becomes impossible. Introduces a latency penalty and a single point of failure.
