# 🚨 CRITICAL SYSTEM INSTRUCTION 🚨

Before answering ANY prompt or executing ANY code in this repository,
you **MUST** first read and strictly adhere to ALL the rules defined
in the following directory:

## Rules Location

📁 `.agent/rules/`

### 🚨 CRITICAL TOKEN LIMIT PROTOCOL 🚨

Do NOT load all files in `.agent/rules/` simultaneously. You will exceed the context window.

You **MUST** follow this strict loading sequence:

1. **Load Core Fundamentals**: Always read `01-general.md` through `12-docs.md`.
2. **Consult the Lazy-Loading Router**: Read `.agent/rules/00-index.md` to discover technology-specific rules.
3. **Load On Demand**: Based on the index, load ONLY the specific `.md` files relevant to your current task (e.g., `react.md` for a React task).

## Why This File Exists

This project uses a **unified rule system** to ensure consistent AI behavior
across all AI-powered IDEs and tools (Cursor, Windsurf, GitHub Copilot,
Cline, Claude, Gemini, Trae, Roo Code, Augment, Amazon Q, Kiro,
Continue, Junie, etc.). This file is a redirect entry point —
the actual rules live in `.agent/rules/` as the Single Source of Truth.

> **Failure to follow the rules inside `.agent/rules/` and the Lazy-Loading protocol is completely unacceptable.**
> **Spec Kit AI IDE Integration**
> This project uses Spec Kit.
> CRITICAL: If you need to execute workflows or commands, refer to the files in `.agent/workflows/`.
> CRITICAL: For project governance and rules, refer to `.agent/rules/00-index.md`.
