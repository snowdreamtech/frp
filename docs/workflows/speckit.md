# SpecKit Workflows

SpecKit is a suite of AI-powered workflows that manage the **entire feature development lifecycle** — from a natural language description to a fully implemented and analyzed feature.

## The Feature Lifecycle

```
Natural Language Idea
        ↓
  /speckit.specify    ← Create feature specification
        ↓
  /speckit.clarify    ← Resolve ambiguities (optional)
        ↓
  /speckit.plan       ← Generate implementation plan
        ↓
  /speckit.tasks      ← Break into actionable task list
        ↓
  /speckit.implement  ← Execute tasks one by one
        ↓
  /speckit.analyze    ← Verify cross-artifact consistency
```

## Available Workflows

### `/speckit.specify`

**Purpose**: Transform a natural language feature description into a structured specification document (`spec.md`).

**Output**: A comprehensive `spec.md` covering user stories, acceptance criteria, and technical requirements.

**Usage**:

```
/speckit.specify

I want to add user authentication with email and password login,
with JWT tokens and refresh token rotation.
```

---

### `/speckit.clarify`

**Purpose**: Identify underspecified areas in the current feature spec. Asks up to 5 targeted clarification questions and encodes answers back into the spec.

**When to use**: After `/speckit.specify` when the spec has ambiguous areas before planning.

---

### `/speckit.plan`

**Purpose**: Execute implementation planning based on the spec. Generates design artifacts including architecture diagrams, API contracts, and database schemas.

**Output**: A `plan.md` with the technical approach, proposed file changes, and dependencies.

---

### `/speckit.tasks`

**Purpose**: Generate an actionable, dependency-ordered task list from the available design artifacts.

**Output**: A `tasks.md` with numbered, granular tasks including file paths, acceptance criteria, and implementation notes.

---

### `/speckit.implement`

**Purpose**: Execute the implementation plan by processing all tasks defined in `tasks.md` sequentially. Each task is implemented and committed atomically.

**Key behavior**: Implements one task → commits → proceeds to next task. Never batches.

---

### `/speckit.analyze`

**Purpose**: Perform a non-destructive cross-artifact consistency and quality analysis across `spec.md`, `plan.md`, and `tasks.md` after task generation.

**Checks for**: Gaps, contradictions, missing requirements, and alignment issues between artifacts.

---

### `/speckit.checklist`

**Purpose**: Generate a custom implementation checklist for the current feature based on the spec.

---

### `/speckit.taskstoissues`

**Purpose**: Convert tasks from `tasks.md` into actionable, dependency-ordered GitHub Issues.

---

### `/snowdreamtech.init`

**Purpose**: Initialize the development environment for this project. Installs all required tools, configures pre-commit hooks, and sets up language-specific linters.

## Running Workflows

Workflows are available in all supported AI IDEs via the slash command syntax. The exact invocation depends on the IDE:

| IDE      | Syntax                |
| -------- | --------------------- |
| Cursor   | `/speckit.specify`    |
| Windsurf | `/speckit.specify`    |
| Cline    | `/speckit.specify`    |
| Claude   | `@[/speckit.specify]` |
| Gemini   | `/speckit.specify`    |

## Customizing Workflows

Workflow definitions live in `.agent/workflows/`. Each file is a Markdown document with `---description---` frontmatter and step-by-step instructions.

To create a custom workflow:

1. Add a new `.md` file to `.agent/workflows/`
2. Follow the existing format with YAML frontmatter
3. The workflow automatically becomes available in all supported IDEs
