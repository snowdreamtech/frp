# Supported AI IDEs

This template provides unified rules and workflow support for **50+ AI-powered IDEs and coding assistants**. All AI IDEs read from the same `.agent/rules/` source of truth.

## First-Class Support

These AI IDEs have dedicated configuration directories with symlinks or redirects to `.agent/rules/`:

| AI IDE                 | Config Location                   | Notes                          |
| ---------------------- | --------------------------------- | ------------------------------ |
| **Cursor**             | `.cursor/rules/`                  | Symlinked from `.agent/rules/` |
| **Windsurf**           | `.windsurfrules`                  | Redirect file                  |
| **GitHub Copilot**     | `.github/copilot-instructions.md` | Redirect file                  |
| **Claude (claude.ai)** | `CLAUDE.md`                       | Redirect to `.agent/rules/`    |
| **Gemini**             | `GEMINI.md`                       | Redirect to `.agent/rules/`    |
| **Continue**           | `.continue/config.json`           | References `.agent/rules/`     |
| **Cline**              | `.clinerules`                     | Redirect file                  |
| **Amazon Q**           | `.amazonq/rules/`                 | Symlinked from `.agent/rules/` |
| **Kiro**               | `.kiro/rules/`                    | Symlinked from `.agent/rules/` |
| **Junie**              | `.junie/guidelines.md`            | Redirect file                  |
| **Roo Code**           | `.roo/rules/`                     | Symlinked from `.agent/rules/` |
| **Augment**            | `.augment/rules/`                 | Symlinked from `.agent/rules/` |
| **Trae**               | `.trae/rules/`                    | Symlinked from `.agent/rules/` |

## How It Works

Each AI IDE looks for instructions in a specific location. This template places a redirect or symlink at each of those locations, pointing back to `.agent/rules/` as the single source of truth:

```
.cursor/rules/ ──────────────┐
.windsurfrules ──────────────┤
CLAUDE.md ───────────────────┤──→ .agent/rules/  (Single Source of Truth)
.github/copilot-instructions ┤
.amazonq/rules/ ─────────────┘
... (all others)
```

## Adding a New AI IDE

1. Find where the AI IDE reads its instructions (usually documented in the IDE's docs)
2. Create a redirect file or symlink at that location pointing to `.agent/rules/`
3. Test that the IDE correctly picks up the rules

## Workflow Support

All AI IDEs can also invoke SpecKit workflows. Workflows are defined in `.agent/workflows/` and aliased in each IDE's workflow directory.
