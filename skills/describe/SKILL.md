---
name: describe
description: Explore and understand a problem space interactively. Uses visualizations and user stories to build shared understanding.
when_to_use: Use during discovery. Invoked by /discovery; can run standalone before /specify.
argument-hint: "[issue# | description]"
model: opus
effort: high
allowed-tools: Agent Bash Read
layer: 2
user-invocable: true
---
Lead product discovery. Explores problems interactively, builds shared understanding via visualizations and user stories, and hands off structured problem statements to /specify.

## Role & Constraints
Goal: Deeply understand the problem space via interactive exploration and validation. Produces a shared understanding of the problem (user stories, visualizations). Hands off via GitHub issue body under `## Requirements`.

## Specialist Mode
- **Seeded**: Skip internal prior-art search.
- **Keep**: PPT and grill-me interactions.
Invoke `Skill("specialist-mode")` at entry.

## Scope Assessment
Read `references/scope-ppt.md` for scope classification, spawn rubric, and PPT checklist.
Read `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for team sizing and composition patterns.

## I/O
- **Input**: Issue reference or problem description from user.
- **Output**: Structured problem statement (What, Why, Who, Boundaries). Handoff to `/specify`.

## Process

### Multi-area or complex problem
1. **Elicitation** — Ask user for problem/goal.
2. **Exploration** — Dispatch agents via `/grill-me` for interactive analysis.
3. **PPT** — Run Product Pressure Test (see `references/scope-ppt.md`) before synthesizing.
4. **Visualization** — Produce Mermaid/ASCII for user journeys, feature comparisons, system boundaries.
5. **Validation** — Confirm understanding of each visual.
6. **Synthesis** — Create structured problem statement.

### Narrow, single-area problem
1. Confirm problem/outcome.
2. Brief codebase validation.
3. Direct problem statement production.

## Rules
- Recommend an answer for every question.
- Read `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md`
