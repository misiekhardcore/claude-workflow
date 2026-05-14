---
name: epic-autopilot
description: Autonomous epic-to-PR pipeline. Chains /discovery → /define → /implement end-to-end for each sub-issue, opening draft PRs.
when_to_use: Use when you have an epic issue number or a free-text description and want the full cycle automated.
argument-hint: "[epic# | description]"
model: opus
effort: high
allowed-tools: Agent Bash Read TaskCreate TaskUpdate
---
Orchestrate the autonomous epic-to-PR pipeline. Take an epic GitHub issue (or free-text description) and produce draft sub-PRs plus a top-level epic PR, with explicit user approval at gates.

## Input

- **Positive integer** → existing GitHub epic issue number.
- **Any other string** → free-text description; `/discovery` will create the epic issue.

## Scope & Spawn

**Always Deep** — fanout orchestrator spawning sub-agents throughout.

- Per-sub-issue /define gate: sequential single-subagent per sub-issue (model: sonnet).
- Autonomous phase: parallel Task sub-agents per tier (model: opus per sub-agent).

See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for spawn rubric.

## Process [Ref: references/stages.md]

- **Stage 0**: Resume detection — read epic and sub-issue bodies; consult Resume logic table.
- **Stage 1**: Discovery gate — run /discovery if no Requirements section; wait for approval.
- **Stage 2**: Epic-level /define gate — run /define; wait for approval; check sub-issue count.
- **Stage 3**: Per-sub-issue /define gate — sequential /define per sub-issue; pause for approval after each.
- **Stage 4**: Autonomous phase — branch creation, dependency tiers (Kahn's sort with cycle-break), parallel dispatch per tier, settle sub-tasks, open epic PR.
- **Stage 5**: Exit — print summary.

Full stage details, decision trees, tier computation, and failure handling: [Ref: references/stages.md]

## Rules

See `${CLAUDE_PLUGIN_ROOT}/_shared/orchestrator-rules.md` for CWD, delegation, no-autonomous-merge, seed-brief contract.

- Require explicit user approval at each gate. Silence is not approval.
- User must not modify epic or sub-issue bodies during Stage 4. Sub-agents read at spawn time.
- Sub-issue branch/worktree: `feat/epic-<N>-sub-<M>` (M is globally unique GitHub number).
- `autonomous: true` reserved for sub-task spawns. Do not pass from other orchestrators.
- `/compound` and `/wrap-up` remain user-invoked utilities.
