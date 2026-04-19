---
name: implement
description: Full implementation cycle — build, review, and verify a feature until ready, then open a PR. Orchestrates /build → /review → /verify in a loop. Use after /define has produced approved architecture decisions.
model: sonnet
---

You are orchestrating the full implementation cycle. Your goal is to take a fully defined GitHub issue and produce a ready-to-merge PR.

## Input

A GitHub issue number (with architecture/design decisions from /define) and any additional resources (docs, API specs, etc.).

## Phase 0 — Scope Assessment

Classify the work before dispatching. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the right-sizing rationale.

1. **Trivial** — single-file fix, typo, docstring, rename, config tweak; AC list has 1–2 items; no logic changes.
   - Run `/build` inline (no implementation team); skip `/review` as a separate team; run a single inline AC check in place of `/verify`.
2. **Standard** — typical multi-file feature with acceptance criteria spanning one module.
   - Full build → review → verify cycle with the default team widths each sub-skill picks.
3. **Deep** — cross-module, security-sensitive, migration, or breaking change; AC list spans multiple areas.
   - Full cycle with `/review` at Deep scope and extra critique iterations allowed before escalation.

Decision tree:

1. Diff will be under ~50 lines with no logic changes? → Trivial
2. Touches auth/security, migrations, public APIs, or performance-critical paths? → Deep
3. Otherwise → Standard

## Process

**Autonomy contract**: inside a single `/implement` invocation, run build → review → verify → fix cycles back-to-back without asking the user between sub-skills. The only user-interrupt point is after the PR is opened and the cycle has either (a) passed clean, (b) exhausted 3 cycles with findings remaining, or (c) hit a blocker the sub-skill cannot resolve. Status updates during the loop are informational only — do **not** end them with a question.

### Trivial

1. Auto-run `/build` — lead codes inline in the worktree, no team spawn, TDD only for logic-heavy snippets.
2. Auto-run an inline AC self-check — walk every acceptance criterion against the diff and the running code; skip the `/review` and `/verify` team spawns.
3. Fall through to the **PR creation** block, then the **Finalize** block. No prompts in between.

### Standard / Deep — autonomous cycle: build → review → verify

1. Auto-run `/build` — spawns implementation team (or runs inline per `/build`'s own Phase 0), codes against the issue.
2. Auto-run `/review` — spawns review team; Deep scope triggers `/review`'s Deep mode (all specialists, `opus`).
3. Auto-run `/verify` — spawns QA team, verifies every acceptance criterion.
4. **Evaluate findings** (no user prompt):
   - **Clean pass** (`/review` and `/verify` both return no issues) → exit loop, fall through to **PR creation**.
   - **Findings present** and cycle count < 3 → package a **fix brief** (failing criteria + reviewer findings as `file:line` + prior architectural decisions; no review/verify session history), auto-feed it to `/build`, auto-re-run `/review` and `/verify`. Do not ask the user to confirm the next iteration.
   - **Findings present** and cycle count = 3 → exit loop with findings attached; fall through to **PR creation** and surface the remaining findings in the finalize step.

Progress reporting during the loop: emit one status line per cycle (`Cycle N/3 — /build <state>, /review <n findings>, /verify <n failures>`) so the user can follow along, but never pause for input.

### PR creation (after the loop exits — clean or exhausted)

Run these steps automatically, without asking:

1. Push the branch to remote.
2. Open a draft PR (`gh pr create --draft`).
3. Link to the issue:
   - `Closes #<issue>` — if this is the only/final PR for the issue.
   - `Related to #<issue>` — if this is a partial implementation.
4. PR description must include:
   - Summary of changes.
   - **Manual testing** section with concrete repro steps someone can follow.
   - **Outstanding findings** section when the loop exhausted 3 cycles — list each as `file:line — severity — description`.
5. Use superpowers:finishing-a-development-branch for PR finalization.

### Finalize

One deterministic finalize block follows PR creation. Branch on the loop's exit state:

- **Clean exit** (no remaining findings) → auto-run `/compound`, then auto-run `/wrap-up`. Present the PR URL and the `/wrap-up` handoff draft to the user as the final message. `/wrap-up` still asks before editing the issue body per its own contract — that prompt is the user's first interrupt point in the entire flow.
- **Exhausted exit** (3 cycles consumed, findings remain) → present the PR URL plus the outstanding findings to the user and ask a single binary question: **"Continue the implementation loop, or accept this PR and close out?"**
  - **Accept / close** → auto-run `/compound`, then auto-run `/wrap-up`.
  - **Continue** → run one more build → review → verify cycle, then return to this finalize block. Each continuation is a new escalation — log it explicitly in the PR description under **Outstanding findings** before re-entering the loop.

`/compound` drafts a structured note from the cycle's debugging, edge cases, and architectural surprises, and files it via `claude-obsidian:save` when the plugin is installed (otherwise it returns the note inline). `/wrap-up` produces the end-of-session assumptions audit and offers to patch the issue body. Both run without asking `/implement` for permission — their own contracts govern any remaining prompts.

## Output

A draft PR linking the issue (`Closes #N` or `Related to #N`) with acceptance criteria met (or with an explicit **Outstanding findings** block if the user accepted an exhausted exit), a Manual testing section with concrete repro steps, `/compound` run (filed or inline), and `/wrap-up` run (draft shown, issue body updated per the user's decision). No handoff artifact beyond the PR and issue body — this is the terminal phase.

## Rules

- **Never prompt between sub-skills.** Build → review → verify → fix cycles and the PR / `/compound` / `/wrap-up` finalize chain all run without asking. The only permitted user-interrupt is the single binary question after an **exhausted exit** (3 cycles with findings remaining).
- Do not open a PR until both /review and /verify pass clean (Standard/Deep) **or** the cycle has exhausted 3 iterations with findings attached. Trivial scope opens the PR after the inline AC self-check.
- Maximum 3 build→review→verify cycles before escalating; escalation is the one-question finalize prompt, not per-cycle approval. Trivial never cycles — if it fails the inline check, upgrade to Standard and restart.
- Each cycle must address **all** findings from the previous cycle; partial fixes do not count as a cycle.
- Emit one status line per cycle for user visibility (`Cycle N/3 — …`). Status lines are informational and must never end with a question.
- `/compound` and `/wrap-up` run automatically after PR creation on both clean and user-accepted exits. They own their own prompts; `/implement` does not wrap them in additional confirmations.
- The GitHub issue body is the handoff artifact across phases; every sub-skill reads from and updates it in place. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.
- In-phase state lives in `./.claude/NOTES.md` (read by `/build` on resume) and in the issue body (cross-phase). Do not re-issue instructions already captured in either.
