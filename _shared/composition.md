# Multi-Skill Composition — Reference

Generic theory behind the applied phase shape in `docs/workflow.md`. Read when authoring an orchestrator skill or composing skills into a new workflow.

**Prerequisite**: `TeamCreate` requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in the environment. Without it, spawn sub-agents individually or fall back to sequential execution and note the degraded mode explicitly.

## Skill roles

| Role                      | Definition                                                                           | Examples                                                    | Typical model |
| ------------------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------- | ------------- |
| **Orchestrator**          | Leads a phase; spawns and coordinates specialists; writes the handoff artifact       | `/discovery`, `/define`, `/implement`                       | `opus`        |
| **Specialist**            | Executes a bounded task; receives a seed brief; reports findings to the orchestrator | `/build`, `/review`, `/verify`, `/architecture`, `/specify` | `sonnet`      |
| **Interactive primitive** | Reusable inline behavior; invoked by specialists; no team, no handoff                | `/grill-me`                                                 | `sonnet`      |

An interactive primitive is distinct from a specialist because it has no internal team and produces no handoff artifact. Collapsing it into "specialist" loses the boundary that it is a pure behavior library.

## Composition patterns

| Pattern      | Shape               | When to use                                                                   |
| ------------ | ------------------- | ----------------------------------------------------------------------------- |
| **Linear**   | A → B → C           | Strict ordering; each step depends on the previous output                     |
| **Branch**   | A → (B or C)        | Mutually exclusive paths driven by a condition (scope class, flag, file type) |
| **Loop**     | A → B → A (on fail) | Iterative refinement; fix cycles in `/implement`                              |
| **Parallel** | A → (B ∥ C) → merge | Independent work streams; requires `TeamCreate`                               |

Use the cheapest pattern that fits. Parallel adds coordination overhead — prefer linear until independence is confirmed.

## Right-sizing the team

Width (how many specialists) is a separate decision from shape (linear vs parallel). Spawn the fewest specialists the task needs. Every orchestrator starts with a **Phase 0 — Scope Assessment** block that classifies the task before dispatching:

| Scope           | Heuristic                                                            | Team shape                                                 |
| --------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Lightweight** | Single file / tightly scoped / no unknowns                           | No team — lead runs inline, or spawns a single agent       |
| **Standard**    | Multi-file / typical feature / some unknowns                         | Core specialists only (2–3); optional roles stay dormant   |
| **Deep**        | Cross-module / security / breaking change / architecture-changing    | All specialists + critique or adversarial pass             |

Rules:

- Collapse adjacent roles when inputs are trivial (e.g., `/verify` on a single AC runs inline — no team split).
- Gate optional specialists on concrete signals (diff patterns, scope class, file paths) — not on orchestrator discretion.
- Never pay coordination overhead for work a single agent completes in under a minute.

See `skills/discovery/SKILL.md` and `skills/review/SKILL.md` for canonical Phase 0 blocks. The orchestrator template at `_templates/SKILL.orchestrator.template.md` includes a Phase 0 stub.

## Structured briefs

A **seed brief** is context passed from an orchestrator to a specialist at spawn time. It replaces the specialist's own research phase when that research has already been done. Three standard forms:

### Research brief

Produced by a codebase/patterns research agent; consumed by `/architecture`, `/design`, or `/build` specialists.

| Field            | Content                                           |
| ---------------- | ------------------------------------------------- |
| `tech_stack`     | Languages, frameworks, key libraries              |
| `module_map`     | Relevant modules, boundaries, and ownership       |
| `patterns`       | 3+ direct pattern examples from the codebase      |
| `prior_art`      | Vault concepts/entities or external references    |
| `open_questions` | Unresolved constraints the specialist must handle |

### Prior-art brief

Produced by `/discovery`'s domain researcher; consumed by `/specify` (optional).

| Field               | Content                                              |
| ------------------- | ---------------------------------------------------- |
| `problem_domain`    | Domain area the feature touches                      |
| `existing_patterns` | Similar features or prior solutions in the codebase  |
| `constraints`       | Non-negotiable constraints surfaced during discovery |

### Fix brief

Produced by `/review` or `/verify`; consumed by `/build` for remediation cycles.

| Field             | Content                                           |
| ----------------- | ------------------------------------------------- |
| `failing_ac`      | Which acceptance criteria are not met             |
| `findings`        | Reviewer findings as `file:line — description`    |
| `prior_decisions` | Architectural decisions that must not be reversed |

## Seed-brief contract

When passing a seed brief to a specialist:

1. Pass as structured input at spawn time, not as a conversational message.
2. The specialist checks for the brief at startup. When one is present, it skips its own research phase and uses the brief as starting context.
3. Keep briefs bounded — never pad with information the specialist can find itself.

`skills/describe/SKILL.md` shows the entry-point pattern: the specialist immediately classifies scope before any user interaction, which lets the orchestrator route it to Lightweight / Standard / Deep without overriding internal logic:

```
(blank line — signals start of scope classification block)
Before starting, classify the task scope:
```

## Hierarchical decomposition

Orchestrators may nest: `/discovery` delegates to `/describe` and `/specify`; `/implement` delegates to `/build`, `/review`, and `/verify`. Rules:

- Maximum two levels of orchestration. Deeper nesting creates brittle context chains.
- Each level owns its own handoff boundary — do not skip levels.
- Sub-orchestrators do not inherit the parent's handoff artifact. Seed them with a brief.

## Handoff vs. seed brief

|                       | Handoff artifact                                           | Seed brief                                 |
| --------------------- | ---------------------------------------------------------- | ------------------------------------------ |
| **Stored in**         | GitHub issue body (durable)                                | In-context at spawn (ephemeral)            |
| **Crosses**           | Phase boundaries (`/discovery` → `/define` → `/implement`) | Intra-phase specialist boundaries          |
| **Authoritative for** | Acceptance criteria, prior decisions, open questions       | Research context, prior art, fix findings  |
| **Written by**        | Phase-boundary orchestrators                               | Research agents, review/verify specialists |

See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the five-field handoff structure. Seed briefs are ephemeral — only handoff artifacts update the issue body.

## Failure modes

| Mode                        | Symptom                                                       | Mitigation                                                               |
| --------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **Context bleed**           | Specialist output leaks into the next specialist's context    | Pass seed briefs explicitly; do not forward full conversation history    |
| **Brief inflation**         | Seed briefs grow to include everything, defeating compression | Cap briefs to the fields above; omit what the specialist can find itself |
| **Over-parallelization**    | Parallel specialists produce contradictory outputs            | Serialize when outputs must agree (e.g., architecture before design)     |
| **Missing flag**            | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset             | Fall back to sequential; note degraded mode explicitly                   |
| **Handoff-brief confusion** | In-phase briefs get written to the issue body                 | Seed briefs are ephemeral; only handoff artifacts update the issue body  |
