---
name: define
description: Full definition phase for a feature. Spawns /architecture and /design to make technical decisions and updates the GitHub issue body.
when_to_use: Use after /discovery has produced an approved issue. Precedes /implement.
argument-hint: "[issue#]"
model: opus
effort: high
---
You are leading the definition phase. Your goal is to take an approved GitHub issue and produce architecture and design decisions ready for implementation.

## Input

A GitHub issue number from /discovery (or provided by the user).

## Scope Assessment

Classify the definition work. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|Single-module technical decision; clear pattern match; no visual surface; no unknowns|Lead writes 3–5 bullet architecture summary inline. Skip research team and `/architecture` specialist|
|Standard|Typical feature with some technical unknowns; may have visual surface|Research team + `/architecture`. Add `/design` when feature has visual aspects|
|Deep|Cross-module, security/payments/privacy, architecture-changing, or migration-bearing|Research team + `/architecture` + `/design` + critique team before finalizing|

Decision tree:
1. Single module, pattern exists in codebase, no visual surface, no unknowns? → Lightweight
2. Touches auth/security/payments/privacy, crosses modules, or changes architecture? → Deep
3. Otherwise → Standard

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Research team**: 2 parallel subagents (read-only, disjoint, parallel, payoff ≥3×).
- **Standard definition team**: sequential subagents (architecture → design). Strictly ordered.
- **Deep critique team**: TeamCreate (cross-axis critique, payoff ≥3× for high-risk plans). Gate: Deep scope AND security/payments/migration signal.

## Process

1. Read the issue to understand the problem statement and acceptance criteria.

2. **Dispatch 2 parallel research subagents** (Standard/Deep only — skip in Lightweight):
   - **Codebase research agent** — scans tech stack, modules, related implementations, patterns. Output structured brief.
   - **Patterns/learnings agent** — gathers prior art from: (1) claude-obsidian vault via `claude-obsidian:wiki-query` if available; (2) project docs (READMEs, ADRs, `docs/**`); (3) external sources via Context7 when local patterns are thin. Skip external research when internal sources yield ≥3 pattern examples; always run full research for security/payments/privacy. If `claude-obsidian` unavailable, skip step 1 with a note.

   Brief feeds both architecture and design specialists as seed context.

3. **Run the definition specialists** per Spawn justification:
   - **Lightweight**: lead writes architecture summary inline.
   - **Standard**: run Architecture subagent seeded with research brief, then Design subagent when feature has visual aspects.
   - **Deep**: same as Standard, then spawn critique team before user sign-off.

4. Architecture specialist goes first. Once technical decisions are approved by user, design specialist (if applicable) works within those constraints. In Deep scope, critique team runs after both and before sign-off.

5. See `${CLAUDE_PLUGIN_ROOT}/_shared/repo-preflight.md` before updating the issue body or creating sub-issues.

6. **Update the GitHub issue body** with decisions. The body is the handoff artifact, single source of truth — always update in place, never post handoff state as comment:
   - If body already has `## Implementation plan` section, edit it. If not, append one.
   - Record architecture and design decisions (with visuals) inside that section.
   - Create sub-issues with GitHub relationships if work decomposes.
   - Define dependency graph — identify what can be parallelized.
   - The updated body is the sole input to `/implement`. Mandatory fields: Acceptance criteria and Constraints. Optional fields (omit heading when empty): Prior decisions, Evidence, Open questions. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.

7. Present all decisions to the user for approval. Do not proceed until sign-off.

8. After sign-off, instruct the user: "Start `/implement` in a fresh session; this one is closed." Do not call `/implement` from within `/define`.

## Rules

- **Require explicit full approval** before finalizing. Partial feedback is NOT approval.
- Spawn primitives and gates per the Spawn justification block.
- Respect existing codebase patterns unless strong reason to deviate.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
