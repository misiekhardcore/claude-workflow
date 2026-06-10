---
name: discover
description: Full discovery phase — explore a problem and produce a GitHub issue with AC.
when_to_use: Start of any new feature or vague problem. Precedes /define.
argument-hint: "[issue# | description]"
model: opus
effort: high
allowed-tools: Agent Bash Read
---
## Role & Constraints

Transform vague ideas into well-specified GitHub issues ready for architecture and implementation.

Invoke `Skill("orchestrator-rules")` — adopt CWD verification, delegation, seed-brief contract, NOTES.md progress tracking.

## Process

### 1. Ingestion

Read issue (problem statement + AC). If no issue exists, elicit a problem statement from the user.

Read `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` — adopt atomic questions, rigor, visual-first, explicit approval.

### 2. Scope decomposition

Derive work units from the problem statement. Invoke `Skill("scope-assessment")` with the work units list. No preset agent count — scope-assessment outputs N agents based on resource conflicts. Each output agent entry becomes a work group.

### 3. Per-group delegation (sequential by group)

For each group from step 2, run 3a–3c before moving to the next group.

**3a — Prior-art research**: Dispatch `Agent("discover/agents/prior-art-scout.md")` with a seed-brief containing the work unit context, repo, branch, and `cwd`. Spawn parallel sub-agents if multiple work units are disjoint. Collect findings.

**3b — Problem exploration**: Invoke `Skill("describe")` with the research brief in payload. Interactive — PPT, visualization, problem statement validation. Response in chat, not in GitHub issue.

**3c — Acceptance criteria** (complex groups only): Invoke `Skill("specify")` to derive AC from the problem statement. Response in chat, not in GitHub issue.

### 4. Review & decision

Verify all groups have a problem statement and AC. If multiple approaches exist, present to user for selection. Re-iterate until the problem is fully understood and the user explicitly approves.

### 5. Synthesize

Combine all group outputs into a cohesive GitHub issue body. Problem statement concise; AC specific and testable.

### 6. Handoff

Invoke `Skill("preflight")`. Suppress branch line: true.

Read `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` at this point (point-of-need) — do not preload.

Create the issue via `gh issue`. Structure:
- **Preamble**: What, Why, Who (from `/describe`).
- **`## Requirements`**: Acceptance criteria → Constraints → Prior decisions (optional) → Evidence (optional) → Open questions (optional).

### 7. Sign-off

Require explicit user approval.

### 8. Compound on exit

Read `${CLAUDE_PLUGIN_ROOT}/_shared/compound-on-exit.md`. Invoke `Skill("compound")` exactly once on clean completion. Then instruct user: "Start `/implement` in a fresh session."

## Worker agents

|Agent|Role|I/O contract|
|-|-|-|
|`prior-art-scout`|Scan codebase + external sources for existing patterns|`agents/prior-art-scout.md`|
|`flow-analyst`|Data-flow, security, auth analysis for high-risk domains|`agents/flow-analyst.md`|
|`adversarial-questioner`|Challenge assumptions, generate edge-case questions|`agents/adversarial-questioner.md`|

All Agent() spawns include a `<seed-brief>` with `repo`, `branch`, and `payload` per `_shared/seed-brief.md`.

## Sub-skill classification

|Skill|Contract|Invocation|
|-|-|-|
|`/describe`|Shell (interactive) — user must be present for PPT, visualization, validation|`Skill("describe")`|
|`/specify`|Shell (interactive) — user must be present for grill-me passes|`Skill("specify")`|

## Rules

- **Delegate, don't duplicate**: Sub-skills own their domain. Do not research or produce describe/specify output yourself.
- **Explicit approval**: Partial feedback ≠ approval. Require direct "Yes/Approved".
- **Persistence**: Prior-art findings persisted in Prior decisions / Evidence fields.
- **Traceability**: Every feature gets one issue; sub-issues use proper GitHub relationships.
- **Point-of-need reads**: Load `_shared/handoff-artifact.md` at step 6, `_shared/compound-on-exit.md` at step 8. Do not preload.
