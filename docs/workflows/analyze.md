# speckit.analyze

Invoke with `/speckit.analyze` in any AI IDE.

## Purpose

Performs a **non-destructive cross-artifact consistency and quality analysis** across `spec.md`, `plan.md`, and `tasks.md`. Identifies gaps, contradictions, and missing details without modifying any file.

## When to Use

- After generating any of the SpecKit artifacts
- Before starting implementation to catch issues early
- As a quality gate before opening a PR
- When you suspect spec/plan/tasks have drifted from each other

## What It Checks

| Check                   | Description                                         |
| ----------------------- | --------------------------------------------------- |
| **Completeness**        | All spec requirements addressed in plan and tasks   |
| **Consistency**         | No contradictions between spec, plan, and tasks     |
| **Coverage**            | All plan components have corresponding tasks        |
| **Dependency order**    | Tasks are correctly sequenced                       |
| **Acceptance criteria** | Each task's criteria align with spec's requirements |
| **Security**            | Security requirements from spec reflected in plan   |
| **Testing**             | Test tasks exist for all functional tasks           |

## Output Format

The analysis produces a structured report:

```
## Analysis Report

### ✅ Passing
- Spec requirements fully covered in plan
- All tasks have acceptance criteria

### ⚠️ Warnings
- Task 003 references UserProfile but spec doesn't define it
- Security section in plan doesn't address rate limiting from spec

### ❌ Gaps
- No tasks for error handling described in spec §3.2
- Missing E2E test tasks for login flow
```

## Non-Destructive

This workflow **never modifies** any file — it only reads and reports. Use it freely at any point in the workflow.

## Next Steps

After reviewing the analysis:

- Update `spec.md` to resolve gaps → re-run `/speckit.plan`
- Update `plan.md` for design issues → re-run `/speckit.tasks`
- Update `tasks.md` directly for minor task gaps
