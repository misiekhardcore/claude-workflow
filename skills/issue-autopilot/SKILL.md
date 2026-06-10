---
name: issue-autopilot
description: Single-issue equivalent of /epic-autopilot. Chains /define → /implement → /resolve-pr-feedback → /compound → /wrap-up for one issue.
when_to_use: Use when you have a single GitHub issue and want the full lifecycle automated end-to-end with natural pause points for human review and merge.
argument-hint: <issue#>
model: opus
effort: high
allowed-tools: Agent Bash Read TaskCreate TaskUpdate
---
Orchestrate the single-issue ship pipeline. Take a GitHub issue number and drive it to a merged PR with clean local state — pausing only where human action is required (review, merge).

## Input

A single positive integer — the GitHub issue number to ship.

## Team Shape

Linear pipeline — sequential phases, no fan-out. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for spawn cost models.

## Process

### 0 — Detection

Invoke `Skill("preflight")`. Echo resolved `owner/repo`. Read `references/detection.md` at point of need to determine entry stage from issue/PR/branch state.

### 1 — Define

If issue lacks `## Implementation plan`: read `references/stage-1.md` at point of need. Invoke `Skill("define")` with seed-brief handoff (`issue: <N>`). Print pause message. **Exit.** User re-invokes after reviewing the plan.

### 2 — Implement

If plan present, branch absent, no open PR: read `references/stage-2.md` at point of need. Spawn `Agent("implement/agents/implement-runner.md")` with seed-brief (`repo`, `branch`, `issue`, `max_cycles: 3`). Print pause message. **Exit.** User re-invokes after review.

### 3 — Resolve PR feedback

If open PR with unresolved threads: read `references/stage-3.md` at point of need. Invoke `Skill("resolve-pr-feedback")` with seed-brief handoff. Apply loop-break heuristic per stage-3.md. On zero unresolved → proceed to Stage 4 in same invocation.

### 4 — Awaiting merge

If clean PR awaiting merge: read `references/stage-4.md` at point of need. Print PR status and prompt user to merge. **Exit.** Merging is human-only.

### 5 — Post-merge (compound-on-exit)

If PR merged: read `references/stage-5.md` at point of need. Invoke `Skill("compound")` (compound-on-exit pattern). Spawn `Agent("wrap-up/agents/wrap-up-runner.md")` with seed-brief (`repo`, `branch`, `worktree_path`). Print ship-complete summary. **Exit.**

## Worker I/O Contracts

|Worker|Input|Output|
|-|-|-|
|`implement-runner`|`repo`, `branch`, `issue`, `max_cycles`|PR URL, findings|
|`wrap-up-runner`|`repo`, `branch`, `worktree_path`|Removal summary|

## Rules

- Invoke `Skill("orchestrator-rules")` for CWD, delegation, no-autonomous-merge, seed-brief, and NOTES.md tracking.
- All `Agent()` spawns include a comprehensive `<seed-brief>` block with `repo`, `branch`, `issue`, and `payload`.
- `Skill()` calls to phase orchestrators include seed-brief handoff in spawn context.
- Reference reads are point-of-need — per-stage, not preloaded.
- Compound-on-exit: `Skill("compound")` on clean completion only. No invocation on abort or early exit.
- No autonomous merge. Merging is always human.
