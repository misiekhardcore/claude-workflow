---
name: implement
description: Full implementation cycle — build, review, and verify a feature from a GitHub issue, then open a PR.
argument-hint: "[issue#]"
model: sonnet
---
You are orchestrating the full implementation cycle. Your goal is to take a fully defined GitHub issue and produce a ready-to-merge PR.

## Input

A GitHub issue number (with architecture/design decisions from /define) and any additional resources (docs, API specs, etc.).

## Scope Assessment

Classify the work. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|Single-file fix, typo, docstring, rename, config tweak; AC list 1–2 items; no logic changes|Run `/build` inline (no team); skip `/review` team; run inline AC check in place of `/verify`|
|Standard|Typical multi-file feature, AC spanning one module|Full build → review → verify cycle with default team widths|
|Deep|Cross-module, security-sensitive, migration, breaking change; AC spans multiple areas|Full cycle with `/review` at Deep scope and extra critique iterations before escalation|

Decision tree:
1. Diff under ~50 lines with no logic changes? → Lightweight
2. Touches auth/security, migrations, public APIs, or performance-critical paths? → Deep
3. Otherwise → Standard

**Design gate** (Standard / Deep only):

Inspect the GitHub issue body for a `## Implementation plan` section containing architecture/design decisions from `/define`. If absent:
- **Pause** and prompt: _"No architecture/design decisions recorded on this issue. Run `/define` first, or confirm this is a trivial enough change to skip the gate."_
- If user confirms trivial (typo, single-line fix), downgrade to **Lightweight** and proceed.
- Otherwise, wait for user to run `/define`.

Skip this gate for **Lightweight** scope.

## Pre-flight

Run `${CLAUDE_PLUGIN_ROOT}/_shared/repo-preflight.md` once at entry. Suppress branch line: true.

Run `${CLAUDE_PLUGIN_ROOT}/_shared/scope-preflight.md` if file list is 3+ files. Pass `preflight_verified: true` in every seed brief issued to specialists.

## Process

**Autonomy contract**: inside a single `/implement` invocation, run build → review → verify → fix cycles back-to-back without asking the user between sub-skills. Only user-interrupt point is after the PR is opened and the cycle has either (a) passed clean, (b) exhausted 3 cycles with findings, or (c) hit a blocker. Status updates during the loop are informational only — do **not** end them with a question.

**Seed-brief handling**: when invoked by an orchestrator (e.g. `/epic-autopilot`) with a `<seed-brief>` block, read the `autonomous` field at startup — default `false` when absent. This flag affects only the Finalize block. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

### Lightweight

1. Auto-run `/build` — lead codes inline in worktree, no team spawn, TDD for logic-heavy snippets only.
2. Auto-run inline AC self-check — walk every AC against diff and running code; skip `/review` and `/verify` team spawns.
3. Fall through to **PR creation** block, then **Finalize** block. No prompts in between.

### Standard / Deep — autonomous cycle: build → review → verify

Construct a seed brief for each specialist at spawn time:

```
<seed-brief>
preflight_verified: true
scope_class: <Lightweight|Standard|Deep>
repo: <owner/repo>
branch: <feat/slug>
active_issue: <N>
autonomous: <true|false>
payload:
  type: <fix|research>
  # type-specific fields per _shared/composition.md
</seed-brief>
```

1. Auto-run `/build` — spawns implementation team (or runs inline per `/build`'s own Scope Assessment), codes against issue. Pass seed brief with `type: research` and architectural context.
2. Auto-run `/review` — spawns review team; Deep scope triggers Deep mode (all specialists, `opus`). Pass seed brief with `type: research` (diff + AC).
3. Auto-run `/verify` — spawns QA team, verifies every AC. Pass seed brief with `type: research` (diff + AC + test commands).
4. **Evaluate findings** (no user prompt):
   - **Clean pass** (`/review` and `/verify` both return no issues) → exit loop, fall through to **PR creation**.
   - **Findings present** and cycle count < 3 → package a **fix brief** (failing criteria + reviewer findings as `file:line` + prior architectural decisions). Write to `./.claude/NOTES.md` and follow `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` — context editing first, sub-agent delegation second, `/compact` last resort. Resume from fix brief in NOTES.md, auto-feed to `/build`, auto-re-run `/review` and `/verify`. Do not ask user to confirm next iteration.
   - **Findings present** and cycle count = 3 → exit loop with findings; fall through to **PR creation** and surface remaining findings in finalize step.

Progress reporting: emit one status line per cycle (`Cycle N/3 — /build <state>, /review <n findings>, /verify <n failures>`) for user visibility, but never pause for input.

### PR creation (after loop exits — clean or exhausted)

Run these steps automatically, without asking:

**All git and `gh` commands must run from within the worktree root** (`cd <worktree-root>` before the first command if CWD is not already there).

1. Read `<worktree-root>/.claude/NOTES.md` if it exists. Harvest `## Decisions made this session` and `## Open questions` — these flow into the PR body's `## Notes` section.
2. Push the branch to remote.
3. Resolve PR base: Run `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`. If it returns `origin/<base>`, strip `origin/` and use `<base>`. If no upstream (fresh feature branch), default to repo's default branch (typically `main`). Stacked-branch orchestrators (e.g. `/epic-autopilot`) pre-set upstream so sub-PR targets correct parent branch.
4. Open a draft PR (`gh pr create --draft --base <resolved-base>`) with body shape below. Link to issue:
   - `Closes #<issue>` — if this is the only/final PR for the issue.
   - `Related to #<issue>` — if this is a partial implementation.

**PR body shape:**

```markdown
## Summary
<1-2 sentences: what was implemented, why, ACs satisfied>

## Testing notes
<repro steps, env setup, expected behavior — concrete enough that a reviewer can verify locally>

## Notes
<free-form prose, with bullet lists where natural; absorbs assumptions, uncertainties, follow-ups, outstanding findings from NOTES.md harvest and any exhausted-exit findings>
```

`## Notes` is omitted entirely when there is nothing to note.

5. Run `/compound` — autonomous, reads cycle context and remaining NOTES.md content, files durable learnings to wiki via `claude-obsidian:save` when installed (otherwise returns note inline).
6. Delete `<worktree-root>/.claude/NOTES.md`.
7. Exit with PR URL and any outstanding findings.

### Finalize

One deterministic finalize block follows PR creation. Branch on loop's exit state:

- **Clean exit** (no remaining findings) → present PR URL to user. `/compound` has already run autonomously.
- **Exhausted exit** (3 cycles consumed, findings remain):
  - If `autonomous: true` → skip prompt; execute Accept/close unconditionally; emit one status line: `autonomous accept: 3 cycles, <N> findings flowed into PR body ## Notes`. Done.
  - If `autonomous: false` (default) → present PR URL plus outstanding findings and ask single binary question: **"Continue the implementation loop, or accept this PR and close out?"**
    - **Accept / close** → Done.
    - **Continue** → run one more build → review → verify cycle, then return to finalize block. Each continuation is a new escalation — log it explicitly in PR description under `## Notes` before re-entering loop.

## Output

A draft PR linking the issue (`Closes #N` or `Related to #N`) with ACs met (or with explicit outstanding findings block in `## Notes` if user accepted exhausted exit), a Testing notes section with concrete repro steps, and `/compound` run (filed or inline). No handoff artifact beyond the PR — this is the terminal phase.

## Rules

- **Never prompt between sub-skills.** Build → review → verify → fix cycles and PR / `/compound` finalize chain all run without asking. Only permitted user-interrupt is the single binary question after **exhausted exit** (3 cycles with findings) — suppressed when `autonomous: true` is set in seed brief.
- Run repo-preflight once at entry; pass `preflight_verified: true` to every specialist via seed brief.
- Do not open a PR until both /review and /verify pass clean (Standard/Deep) **or** cycle has exhausted 3 iterations with findings. Lightweight opens PR after inline AC self-check.
- Maximum 3 build→review→verify cycles before escalating; escalation is the one-question finalize prompt. Lightweight never cycles — if it fails inline check, upgrade to Standard and restart.
- Each cycle must address **all** findings from previous cycle; partial fixes do not count.
- Emit one status line per cycle for user visibility. Status lines are informational and must never end with a question.
- `/compound` runs automatically after PR creation. It owns its own prompts; `/implement` does not wrap it.
- Do not call `/wrap-up`. It is a user-invoked utility.
- In-phase state lives in `./.claude/NOTES.md` (read by `/build` on resume) and in issue body (cross-phase). See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.
- Issue body after `/implement` contains only `## Requirements` (from `/discovery`) and `## Implementation plan` (from `/define`). Do not write a `## Session handoff` block.
