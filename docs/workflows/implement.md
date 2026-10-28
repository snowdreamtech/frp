# speckit.implement

Invoke with `/speckit.implement` in any AI IDE.

## Purpose

Executes the implementation plan by **processing all tasks** defined in `tasks.md` sequentially, making atomic commits after each completed task.

## When to Use

- After `tasks.md` is reviewed and ready
- When you want the AI to drive implementation systematically
- For complex features where you want structured, tracked progress

## What It Does

1. Reads `tasks.md` to get the ordered task list
2. Processes tasks one at a time in dependency order
3. For each task:

- Implements the changes
- Runs the relevant pre-commit checks
- Makes an atomic commit with a descriptive message
- Marks the task as complete in `tasks.md`

1. Reports progress after each task

## Workflow

```
Input:  tasks.md (reviewed and approved)
        ↓
For each task (in order):
  1. Implement changes
  2. Run linters and tests
  3. git commit (atomic)
  4. Mark task ✅ in tasks.md
        ↓
All tasks complete → implementation done
```

## Commit Convention

Each task produces one or more commits following Conventional Commits:

```bash
feat(auth): add users table migration
feat(auth): implement JWT token generation
feat(auth): add login endpoint with email/password
test(auth): add unit tests for token validation
```

## Pausing and Resuming

If the AI stops or you need to interrupt:

```
/speckit.implement
# AI reads tasks.md, finds the last completed task, and continues from there
```

## Next Steps

After all tasks are complete:

- Review the changes with `git log --oneline`
- Run the full test suite
- Open a Pull Request
