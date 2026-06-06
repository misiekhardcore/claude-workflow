# Issue-Autopilot: Stage 2 — Implement

## Stage 2 — Implement

**Entry condition**: Issue has `## Implementation plan`, branch `feat/issue-<N>` does not exist, no open PR.

1. Run `/implement <N>` from current directory. Invoke `Skill("specialist-mode")` § Autonomous Implement Invocation with overrides:
   - `branch`: `feat/issue-<N>`
   - `active_issue`: `<N>`
   - `payload.prior_art`: `"Issue #<N> ## Implementation plan (architecture and design decisions from /define)"`
   - `payload.open_questions`: open questions from the plan, or empty

2. `/implement` creates the worktree internally via `/build`, runs the full build → review → verify cycle, and opens a draft PR (`autonomous: true` suppresses its exit prompt).

3. After `/implement` exits, print:

   > Draft PR opened. Invite human review, then re-invoke `/issue-autopilot <N>`.

4. **Exit.**
