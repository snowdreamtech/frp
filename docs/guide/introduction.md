# Introduction

**Snowdream Tech AI IDE Template** is an enterprise-grade, foundational repository template designed for modern software teams who use AI-powered coding assistants.

## The Problem

As AI coding assistants proliferate — Cursor, Windsurf, GitHub Copilot, Cline, and 50+ others — every tool has its own configuration format, rules directory, and behavioral customization mechanism. Without a unified system, teams face:

- **Inconsistency**: Different AI assistants follow different rules, producing inconsistent results.
- **Maintenance overhead**: Updating a rule requires modifying dozens of per-IDE configuration files.
- **Knowledge silos**: Each team member's preferred AI tool gets different instructions.

## The Solution: Single Source of Truth

This template establishes `.agent/rules/` as the **Single Source of Truth (SSoT)** for all AI behavioral rules. Every supported IDE's configuration directory points back to this canonical location.

```text
.agent/rules/          ← The Brain (you edit here)
    ├── 01-general.md
    ├── 02-coding-style.md
    └── ...

.cursor/rules/         ← Mirror
.cline/rules/          ← Mirror
.windsurf/rules/       ← Mirror
.aide/rules/           ← Mirror
... (50+ more)         ← Mirrors
```

## Core Design Principles

### 1. Centralized, Not Distributed

Rules are written once in `.agent/rules/` and propagated everywhere. No more hunting through 50 directories when you need to update a coding convention.

### 2. Language-Agnostic Intelligence

The rule system detects what languages and frameworks a project uses, then loads the appropriate specialized rules. Go rules for Go projects, React rules for React projects — automatically.

### 3. Full Lifecycle Management

Beyond just rules, the template includes the **SpecKit** workflow suite — a set of AI workflows covering the entire feature development lifecycle from specification through deployment.

### 4. Shift-Left Quality

Quality is enforced at every stage:

- **Pre-commit hooks**: 40+ standardized checks run locally to catch issues early.
- **Unified CI Pipeline**: Modernized GitHub Actions (`unirtm run lint`, `unirtm run audit`, `unirtm run test`) ensure 100% environment parity.
- **Standardized Runtimes**: Consistent use of Node.js 22 and Python 3.12 across all stages.
- **DevContainer**: Reproducible environment ensures 100% setup reliability.

## Technology Stack

| Layer            | Technology                     |
| ---------------- | ------------------------------ |
| Rule System      | Markdown (`.agent/rules/`)     |
| Workflows        | Markdown (`.agent/workflows/`) |
| Quality Gates    | pre-commit + GitHub Actions    |
| Container        | Docker + DevContainer          |
| Release          | GoReleaser                     |
| Language Support | 80+ languages and frameworks   |
| AI IDE Support   | 50+ tools                      |

## Who Is This For?

- **Individual developers** who switch between AI tools and want consistent behavior.
- **Teams** that need to standardize AI assistant behavior across members.
- **Organizations** adopting AI-assisted development at scale.
- **Open source maintainers** who want contributors' AI tools to follow project conventions.
