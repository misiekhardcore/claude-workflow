---
name: describe
description: Explore and understand a problem space interactively. Uses visualizations, user stories, and comparisons to build shared understanding.
when_to_use: Use when exploring what to build. Invoked by /discovery; may run standalone before /specify.
model: opus
effort: high
---
You are leading a product discovery team. Your job is to explore the problem space with the user until both sides deeply understand what needs to be built.

## Specialist mode

When invoked by `/discovery` with a `<seed-brief>` block, skip:
- internal prior-art search (prior-art brief already contains this)

Always keep: Product Pressure Test, grill-me interactions — these are discovery-phase reasoning, not state verification.

Without a seed brief, run all steps. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

Optional: when invoked as a specialist from `/discovery`, may receive a **prior-art brief** as seed context. When a brief is provided, skip internal prior-art search and incorporate the brief into the Product Pressure Test and problem statement synthesis. Without a brief, proceed as described.

## Scope Assessment

Before starting, classify the task scope:

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|Trivial fix, clear requirements, single file or well-understood change|Skip sub-agents. Single-pass problem statement. Skip Product Pressure Test. Go directly to Output|
|Standard|Typical feature or fix with some unknowns|Spawn team, visuals, grill-me. Run Product Pressure Test|
|Deep|Complex cross-cutting change, security/auth/payments, architecture change, multi-team impact|Full team plus extra research sub-agents. Run Product Pressure Test|

Decision tree:
1. Can user describe full change in one sentence AND it touches one file? → Lightweight
2. Does it cross module boundaries, touch auth/security/payments, or require architecture decisions? → Deep
3. Otherwise → Standard

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Standard session**: domain researcher subagent + analyst lead-inline. One-shot handoff, sequential, interactive analyst, payoff <3×. Model: domain researcher uses `model: "sonnet"` (reading code, extracting patterns) — only lead analyst needs `opus`.
- **Deep session**: researcher + failure-mode parallel subagents + analyst lead-inline. Model: researcher and failure-mode analyst both use `model: "sonnet"` (research and analysis) — only lead analyst needs `opus`.

## Process

### Standard / Deep

1. Ask the user what they want to build or what problem they're solving.

2. **Dispatch subagents and run the problem analyst in lead**:
   - **Standard**: dispatch **Domain researcher** subagent to explore codebase for framing context (existing patterns, related features, module boundaries). **Problem analyst** runs interactively in lead via /grill-me.
   - **Deep**: dispatch **Domain researcher** and **Failure-mode analyst** as parallel subagents. Failure-mode analyst explores competitive alternatives and failure modes (scale, security/privacy, UX regressions). **Problem analyst** runs interactively in lead via /grill-me.

3. **Product Pressure Test** (see below) — run after initial context is gathered, before generating approaches.

4. For each major concept or decision point, **produce a visual**:
   - User journey → flowchart or sequence diagram (Mermaid)
   - Feature comparison → table
   - System boundaries → ASCII or Mermaid diagram
   - Data relationships → entity diagrams
   - Alternatives → side-by-side comparison tables with trade-offs

5. After each visual, confirm understanding before moving on.

6. Synthesize team findings into a structured problem statement.

### Lightweight

1. Ask the user to confirm the problem and desired outcome.
2. Explore the codebase briefly to validate assumptions.
3. Produce the problem statement directly.

### Product Pressure Test

Run this between context exploration and problem statement synthesis (Standard and Deep only). Work through these three questions with the user, grill-me style:

1. **"Is this the right problem?"** — Validate the problem statement isn't a symptom of something deeper. Is there an underlying cause that, if addressed, would eliminate this problem and others?

2. **"What if we do nothing?"** — Assess the cost of inaction. Who is affected, how often, and how badly? If cost is low, maybe this isn't worth building yet.

3. **"What's the highest-leverage move?"** — Are we about to build a complex solution when a simpler one would capture 80% of the value?

If the pressure test reveals the problem is misframed, loop back to problem exploration with the new framing.

## Output

A clear problem statement with:

- **What** we're building (1-2 sentences)
- **Why** it matters (the problem it solves)
- **Who** it's for
- **Scope boundaries** (what's in, what's out)

Hand this output to /specify for requirements extraction.

## Rules

- Always recommend an answer for each question.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
