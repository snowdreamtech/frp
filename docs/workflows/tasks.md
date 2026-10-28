# speckit.tasks

Invoke with `/speckit.tasks` in any AI IDE.

## Purpose

Generates an actionable, **dependency-ordered task list** (`tasks.md`) for implementing the feature described in `spec.md` and designed in `plan.md`.

## When to Use

- After both `spec.md` and `plan.md` are approved
- When you need a structured, step-by-step implementation roadmap
- Before starting the implementation phase

## What It Produces

A `tasks.md` file with:

- Tasks organized in **dependency order** (prerequisites come first)
- Each task has a clear, actionable description
- Tasks are sized for atomic commits (1 task ≈ 1–3 commits)
- Tasks include acceptance criteria aligned with the spec
- Estimated complexity (S / M / L / XL)

## Task Structure

```markdown
## Task 001: Set up database schema

**Priority**: P0 (blocking)
**Complexity**: S
**Depends on**: none

### Description

Create the `users` table with columns: id, email, password_hash, created_at, updated_at.

### Acceptance Criteria

- [ ] Migration file created and reversible
- [ ] Table visible in local dev database
- [ ] Indexes on email for fast lookup
```

## Workflow

```
Input:  spec.md + plan.md (both approved)
        ↓
AI reads: all artifacts + project rules
        ↓
AI produces: tasks.md ordered by dependency
        ↓
User reviews task list
        ↓
Proceed to: /speckit.implement
```

## Next Steps

- `/speckit.implement` — execute the task list
- `/speckit.analyze` — consistency check across all artifacts
- `/speckit.taskstoissues` — convert tasks to GitHub Issues
