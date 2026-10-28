# speckit.specify

Invoke with `/speckit.specify` in any AI IDE.

## Purpose

Creates or updates a **feature specification** (`spec.md`) from a natural language feature description. This is the first step in the SpecKit workflow.

## When to Use

- Starting work on a new feature, story, or change request
- When requirements need to be formally documented before planning begins
- When a vague feature idea needs to be transformed into a structured spec

## What It Produces

A `spec.md` file containing:

| Section                 | Content                                          |
| ----------------------- | ------------------------------------------------ |
| **Goal**                | Clear statement of what the feature accomplishes |
| **User stories**        | Who, what, why in standard format                |
| **Acceptance criteria** | Testable, unambiguous success conditions         |
| **Out of scope**        | Explicit exclusions to prevent scope creep       |
| **Open questions**      | Unresolved decisions that need answers           |

## Workflow

```
User provides: feature description (natural language)
        ↓
AI reads: existing spec.md (if any), project constitution
        ↓
AI produces: structured spec.md with all required sections
        ↓
User reviews and iterates (use /speckit.clarify for ambiguities)
```

## Example

```
/speckit.specify

Add user authentication with email/password login,
JWT session tokens, and a "remember me" option.
```

## Next Steps

After spec is approved:

- `/speckit.plan` — generate the design and architecture plan
- `/speckit.clarify` — resolve ambiguous requirements
