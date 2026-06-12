---
name: define
description: Lead definition phase. Resolves architecture and design technical decisions.
when_to_use: Use after /discover produces an approved issue with AC. Precedes /implement.
argument-hint: "[issue#]"
model: opus
effort: high
allowed-tools: Agent Bash Read
---
Lead definition phase. Transform an approved issue into a concrete implementation plan (architecture + design).

Adopt `Skill("orchestrator-rules")` for checkpoint, NOTES.md, and seed-brief conventions.

## Input
Issue number with acceptance criteria from /discover. Read body at entry; reference-read issue on demand throughout.

## Team Shape
Invoke `Skill("scope-assessment")` with work units (one per distinct module or sub-issue). Receive agent plan — one agent per disjoint group. No preset agent count; width matches scope.

Dispatch workers sequentially per group:
- **`Skill("architecture")`** (layer 2, sub-issue TBD) — per group with issue + AC. Response in chat.
- **`Skill("design")`** (layer 2, sub-issue TBD) — per group with arch decisions, if visual work. Response in chat.

For high-risk plans (security, payments, arch-changing scope): after architecture + design, spawn in parallel:
  - `Agent("define/agents/critique-agent.md")` with `sonnet`
  - `Agent("define/agents/critique-agent.md")` with `haiku` (second independent pass, two perspectives)
Each with seed-brief containing `issue`, `architecture_decisions`, `design_decisions`, and `scope`. Merge findings from both before presenting to user.

Each `Agent()` spawn includes a `<seed-brief>` YAML block per `_shared/seed-brief.md`. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for spawn cost models.

## Process
1. **Ingestion** — Read issue body; build work-unit list for scope-assessment.
2. **Init NOTES.md** — Create `.claude/NOTES.md` with task list, decisions log, next-action per `Skill("orchestrator-rules")`.
3. **Scope** — Invoke `Skill("scope-assessment")` with work units. Receive agent plan.
4. **Delegate** — Sequentially per group:
   - **(a)** `Skill("architecture")` with issue + AC. Response in chat.
   - **(b)** `Skill("design")` with architecture decisions (if visual work). Response in chat.
   - Checkpoint NOTES.md before each spawn; update on return.
5. **Review & Discuss** — Verify all ACs covered. Identify conflicts or gaps between architecture and design. If a gap exists, move back to **Delegate** with updated context. Present to user. Invoke `Skill("grill-me")` to challenge assumptions. Iterate until explicit approval.
6. **Critique** — If high-risk: spawn critique-agent (×2, parallel, two models). Merge findings, present, get approval.
7. **Synthesize** — Collect final decisions into a cohesive implementation plan.
8. **Handoff** — Invoke `Skill("preflight")`. Read `_shared/handoff-artifact.md`. Update issue body with `## Implementation plan` section:
   - Acceptance criteria (unchanged), Constraints, Prior decisions, Evidence, Open questions.
   - Record decisions, visuals, and sub-issues with relationships.
   - Define dependency graph for parallelization.
9. **Sign-off** — Require explicit user approval.
10. **Compound-on-exit** — Read `_shared/compound-on-exit.md`. Invoke `Skill("compound")` once on clean completion. Then instruct user: "Start `/implement` in a fresh session."

## Output
Issue body `## Implementation plan` section per `_shared/handoff-artifact.md` (five-field block).

## Rules
- **Delegate, don't duplicate**: Sub-skills own their domain work. Do not produce architecture/design output yourself.
- **Explicit approval**: Silence ≠ approval. Require direct confirmation.
- **Exploration**: Time-box codebase reading to 3–5 tool calls, then ask focused question.
