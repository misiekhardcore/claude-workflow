---
name: wrap-up
description: Clean up local state after a PR is open — remove the worktree, delete the branch, and clear NOTES.md.
when_to_use: Run when ready to discard the feature worktree after a PR is open.
model: sonnet
user-invocable: true
layer: 2
allowed-tools: Bash Read
---
Safely remove the feature worktree, delete the branch, and clear any remaining NOTES.md. In standalone mode, confirms before destructive actions and refuses when the operation would destroy protected state. In orchestrated mode, accepts `confirmed: true` from an orchestrator seed-brief and executes directly. Cleans up local state: removes worktree, deletes branch, clears NOTES.md. Expects PR to be in a terminal state. Refuses destructive actions on dirty state in standalone mode.

## Input

- Current worktree path and branch.
- Optional: seed-brief from orchestrator with `confirmed: true`. When present, skip user confirmations and proceed directly to removal.

  ```
  <seed-brief>
  preflight_verified: true
  repo: owner/repo
  branch: feat/my-branch
  confirmed: true
  </seed-brief>
  ```

  Read `${CLAUDE_PLUGIN_ROOT}/_shared/seed-brief.md` for the full seed-brief format.

- Optional: PR number (used to verify unpushed-commit safety in standalone mode).

## Process

1. Check for seed-brief with `confirmed: true`.
2. Invoke `Skill("worktree")` — adopt worktree lifecycle protocol.
3. Invoke `Skill("notes-md")` — adopt NOTES.md lifecycle protocol.
4. Read `references/procedure.md` for the step-by-step removal procedure.
5. Run step 1 (detect state) in all cases.
6. If seed-brief has `confirmed: true`: skip to step 5 (execute removal). If worktree is dirty in this mode, **refuse**.
7. Otherwise (standalone mode): run steps 2–4 (state machine + user confirmations), then step 5.
8. Report what was removed.

## Output

```
Removed worktree: <path>
Deleted branch: <branch>
NOTES.md removed with worktree (was present / was already absent)
```

## Rules

- Refuse outright when branch is default branch or worktree path not in `wt list`.
- Single confirmation covers all removals in standalone mode — do not ask separately for each artifact.
- Do not write to GitHub issue body. Use `/compound` to capture learnings into the wiki instead.
- Do not read or harvest NOTES.md — `/implement` harvests it at PR-creation time.
