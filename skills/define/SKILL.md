---
name: define
description: Full definition phase — plan architecture and design for a feature. Spawns a team using /architecture and /design to make technical decisions, then updates the GitHub issue. Use after /discovery has produced an approved issue.
model: opus
effortLevel: high
---

You are leading the definition phase. Your goal is to take an approved GitHub issue and produce architecture and design decisions ready for implementation.

## Input

A GitHub issue number from /discovery (or provided by the user).

## Scope Assessment

Classify the definition work before dispatching. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the right-sizing rationale.

1. **Lightweight** — single-module technical decision with a clear pattern match already in the codebase; no visual surface; no architectural unknowns.
   - Lead writes an inline architecture summary (3–5 bullets) directly to the issue body. Skip research team and skip `/architecture` as a separate specialist.
2. **Standard** — typical feature with some technical unknowns; may have a visual surface.
   - Research team (both agents) + `/architecture` specialist. Add `/design` when the feature has visual aspects.
3. **Deep** — cross-module, security/payments/privacy, architecture-changing, or migration-bearing.
   - Research team + `/architecture` + `/design` (when applicable) + a second team to critique the plan before finalizing.

Decision tree:

1. Single module, pattern already exists in the codebase, no visual surface, no unknowns? → Lightweight
2. Touches auth/security/payments/privacy, crosses modules, or changes architecture? → Deep
3. Otherwise → Standard

### Spawn justification

See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the four-criterion `TeamCreate` rubric and primitive ladder.

- **Research team** (codebase + patterns/learnings): 2 parallel subagents — comm-pivot ✗ (read-only research, no mid-task coordination needed), file-disjoint ✓, classifiably parallel ✓, wall-clock payoff ≥3× for two independent reads. Fallback when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset: sequential subagent invocations (codebase agent → patterns agent).
- **Standard definition team** (architecture → design): sequential subagent invocations — comm-pivot ✗ (design follows architecture, strictly ordered), sequential reasoning required, no parallel speedup. Fallback when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset: same — sequential subagents do not require the experimental flag.
- **Deep critique team**: TeamCreate — comm-pivot ✓ (adversarial reviewers coordinate critique findings across migration, security, and rollout axes), classifiably parallel ✓, wall-clock payoff ≥3× for high-risk plans. Gated on Deep scope AND a security/payments/migration signal in the issue. Fallback when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset: sequential subagent invocations (critic runs after architecture and design complete).

## Process

1. Read the issue to understand the problem statement and acceptance criteria.

2. **Dispatch 2 parallel research subagents** (one Task tool call per agent in a single message; Standard/Deep only — skip in Lightweight):
   - **Codebase research agent** — scans tech stack, modules, related implementations, naming, existing patterns. Outputs a structured brief.
   - **Patterns/learnings agent** — gathers prior art from, in order: (1) the claude-obsidian vault via `claude-obsidian:wiki-query` if available (concepts/entities/sources/meta); (2) project docs (READMEs, ADRs, `docs/**`); (3) external sources via Context7 when local patterns are thin. If `claude-obsidian` is not installed, step 1 is skipped with a note. Skip external research when internal sources yield 3+ direct pattern examples; always run full research for security/payments/privacy.

   The brief feeds both the architecture and design specialists as seed context.

3. **Run the definition specialists sequentially** — shape depends on scope:
   - **Lightweight**: lead writes the architecture summary inline against the research already in the issue. No team.
   - **Standard**: run the **Architecture specialist** as a sequential subagent seeded with the research brief (skips its own research phase). Then run the **Design specialist** as a sequential subagent seeded with the research brief when the feature has visual aspects. Each is a Task tool call with the prior output as seed brief.
   - **Deep**: same specialists as Standard, then spawn a **TeamCreate critique team** to critique the plan before finalizing (adversarial review, migration safety, rollout risks) — gated on Deep scope AND a security/payments/migration signal in the issue.

4. The architecture specialist goes first. Once technical decisions are approved by the user, the design specialist (if applicable) works within those constraints. In Deep scope, the critique team runs after both and before user sign-off.

5. **Update the GitHub issue body** with decisions. The body is the handoff artifact, single source of truth — always update it in place, never post handoff state as a comment:
   - If the body already has a `## Implementation plan` section, edit it. If not, append one.
   - Record architecture decisions and design decisions (with visuals) inside that section.
   - Create sub-issues with GitHub relationships if the work decomposes.
   - Define the dependency graph — identify what can be parallelized.
   - The updated body is the sole input to `/implement` — a fresh session will read it, not this conversation. Mandatory fields: Acceptance criteria and Constraints. Optional fields (omit heading when empty, no "None" placeholders): Prior decisions, Evidence, Open questions. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.

6. Present all decisions to the user for approval. Do not proceed until sign-off.

7. After sign-off, instruct the user: "Start `/implement` in a fresh session; this one is closed." Do not call `/implement` from within `/define`.

## Rules

- **Require explicit full approval** before finalizing. Partial feedback is NOT approval.
- Deep scope spawns a TeamCreate critique team before finalizing only when a security/payments/migration signal is present; Standard uses sequential subagents; Lightweight skips both.
- Respect existing codebase patterns unless there's a strong reason to deviate
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol — apply it throughout all user interactions.
