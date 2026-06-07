---
name: wrap-up
description: Clean up local state after a PR is open — remove the worktree, delete the branch, and clear NOTES.md.
when_to_use: Run when ready to discard the feature worktree after a PR is open.
model: sonnet
layer: 2
allowed-tools: Bash Read
---
Safely remove the feature worktree, delete the branch, and clear any remaining NOTES.md. In standalone mode, confirms before destructive actions and refuses when the operation would destroy protected state. In orchestrated mode, accepts `confirmed: true` from an orchestrator seed-brief and executes directly.

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
2. Read `references/procedure.md` for the step-by-step removal procedure (Steps 1–5).
3. Run Step 1 (detect state) in all cases.
4. If seed-brief has `confirmed: true`: skip to Step 5 (execute removal). If worktree is dirty in this mode, **refuse** — the orchestrator should only send `confirmed: true` when state is verified clean.
5. Otherwise (standalone mode): run Steps 2–4 (state machine + user confirmations), then Step 5.
6. Report what was removed using the Output format.

## Output

```
Removed worktree: <path>
Deleted branch: <branch>
NOTES.md removed with worktree (was present / was already absent)
```

## Rules

- Refuse outright when branch is default branch or worktree path not in `wt list`.
- Use `wt remove --force-delete` only when dirty-worktree override was explicitly confirmed (standalone mode only).
- Single confirmation covers all removals in standalone mode — do not ask separately for each artifact.
- Do not write to GitHub issue body. Use `/compound` to capture learnings into the wiki instead.
- Do not read or harvest NOTES.md — `/implement` harvests it at PR-creation time.
