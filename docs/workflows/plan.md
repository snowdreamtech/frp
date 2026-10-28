# speckit.plan

Invoke with `/speckit.plan` in any AI IDE.

## Purpose

Generates a **design and implementation plan** (`plan.md`) based on the approved feature specification. Covers architecture decisions, component design, API contracts, and data models.

## When to Use

- After `spec.md` has been reviewed and approved
- Before generating task breakdowns
- When architectural decisions need to be documented

## What It Produces

A `plan.md` file containing:

| Section                     | Content                                     |
| --------------------------- | ------------------------------------------- |
| **Architecture**            | System design, component diagram, data flow |
| **API design**              | Endpoints, request/response schemas         |
| **Data model**              | Database schema or data structure changes   |
| **Dependencies**            | New libraries or services required          |
| **Security considerations** | Auth, validation, threat model              |
| **Testing strategy**        | Unit / integration / E2E approach           |
| **Rollout plan**            | Feature flags, migration steps              |

## Workflow

```
Input:  spec.md (approved)
        ↓
AI reads: spec.md + project constitution + architecture rules
        ↓
AI produces: plan.md with full design artifacts
        ↓
User reviews — iterate until approved
        ↓
Proceed to: /speckit.tasks
```

## Example

```
/speckit.plan
```

The AI uses the current directory's `spec.md` as input automatically.

## Next Steps

- `/speckit.tasks` — generate implementation task list
- `/speckit.analyze` — consistency check across spec + plan
