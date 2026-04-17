---
name: implement
description: Full implementation cycle — build, review, and verify a feature until ready, then open a PR. Orchestrates /build → /review → /verify in a loop. Use after /define has produced approved architecture decisions.
model: sonnet
---

You are orchestrating the full implementation cycle. Your goal is to take a fully defined GitHub issue and produce a ready-to-merge PR.

## Input

A GitHub issue number (with architecture/design decisions from /define) and any additional resources (docs, API specs, etc.).

## Process

### Cycle: build → review → verify

1. **Run /build** — spawns implementation team, codes against the issue
2. **Run /review** — spawns review team, checks correctness and standards
3. **Run /verify** — spawns QA team, verifies every acceptance criterion

If /review or /verify report issues:
- Feed findings back to /build for fixes — pass a **fix brief** (failing criteria + reviewer findings as `file:line` + prior architectural decisions). Do not forward the review/verify session history.
- Re-run /review and /verify on the fixes
- Repeat until both pass clean

### PR creation (after cycle passes)

When /review and /verify both pass with no issues:

1. Push the branch to remote
2. Open a draft PR (`gh pr create --draft`)
3. Link to the issue:
   - `Closes #<issue>` — if this is the only/final PR for the issue
   - `Related to #<issue>` — if this is a partial implementation
4. PR description must include:
   - Summary of changes
   - **Manual testing** section with concrete repro steps someone can follow
5. Use superpowers:finishing-a-development-branch for PR finalization

### Compound (after PR is open)

6. **Run /compound** — capture learnings from the implementation cycle. If the build involved non-trivial debugging, unexpected edge cases, or architectural surprises, /compound writes them into the Obsidian vault at `memory/wiki/` (concepts/, entities/, or sources/ depending on the shape) so future `/architecture` research can find them.

## Rules

- Do not open a PR until both /review and /verify pass clean
- Maximum 3 build→review→verify cycles before escalating to the user
- Each cycle should address all findings from the previous cycle, not just some
- Keep the user informed of cycle progress (which cycle, what was found, what was fixed)
- The GitHub issue body is the handoff artifact across phases; every sub-skill reads from and updates it in place. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.
- In-phase state lives in `./.claude/NOTES.md` (read by `/build` on resume) and in the issue body (cross-phase). Do not re-issue instructions already captured in either.
