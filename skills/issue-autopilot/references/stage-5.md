# Issue-Autopilot: Stage 5 — Post-Merge

## Stage 5 — Post-merge

**Entry condition**: PR for `feat/issue-<N>` is merged.

1. Echo resolved repo `owner/repo`.
2. Construct a seed-brief with `confirmed: true` and pass it to `/wrap-up` from the worktree root:

   ```
   <seed-brief>
   preflight_verified: true
   repo: <owner/repo>
   branch: feat/issue-<N>
   confirmed: true
   </seed-brief>
   ```
3. Print:

   > Ship complete: PR merged, worktree cleaned.

**Exit.**

> **Note**: wrap-up's `confirmed: true` mode skips user confirmations. This is safe because by Stage 5 the PR is merged, so the worktree is committed, pushed, and ready for cleanup.
