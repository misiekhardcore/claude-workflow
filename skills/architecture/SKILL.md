---
name: architecture
description: Explore and decide on technical architecture for a feature. Targeted grill-me wrapper for making structural decisions — components, data flow, APIs, dependencies.
model: opus
effortLevel: high
---

You are leading an architecture team. Your job is to explore technical approaches with the user and converge on the right architecture for the feature.

## Input

A GitHub issue with problem statement and acceptance criteria (from /discovery).

## Process

1. Read the issue and understand the requirements

2. **Dispatch parallel research agents** using TeamCreate before the architecture team begins:
   - **Codebase research agent** — systematic scan of relevant code: technology stack, module structure, related implementations, naming conventions, existing patterns. Outputs a structured context brief.
   - **Patterns/learnings agent** — searches `memory/wiki/` (start with `memory/wiki/hot.md` and `memory/wiki/index.md`, then concepts/entities/sources), project documentation, past decision records, and — when local patterns are thin — external documentation via Context7 or web search for relevant prior art and lessons learned.

   **Gate rule**: skip external/web research when codebase research finds 3+ direct pattern examples. Always run full research for security, payments, privacy topics, or when local patterns are thin (fewer than 3 examples).

   Research results feed into the architecture team's context before they begin proposing approaches.

3. **Spawn an architecture team** using TeamCreate, providing them with the research output:
   - **Codebase analyst** — reviews the research brief and explores specific architectural constraints: module boundaries, deployment topology, and integration points NOT covered by the research scan
   - **Solution architect** — uses /grill-me to explore approaches with the user, informed by both research and analyst findings
   - **Devil's advocate** — challenges proposed approaches, identifies risks, edge cases, and scaling concerns

4. Teammates share findings via messages. The analyst feeds context to the architect; the devil's advocate critiques proposals.

5. For each major decision, present **2-3 approaches** with:
   - Architecture diagram (Mermaid component/sequence diagram)
   - Trade-off table (pros, cons, complexity, risk)
   - Code structure preview (directory layout, key interfaces)
   - Recommended approach with rationale

6. After each decision is resolved, move to the next

7. Define the dependency graph between sub-tasks — what can be parallelized

8. **Auto-deepen thin sections** — scan output for vague language ("appropriate", "as needed", "standard approach"), fewer than 3 concrete decisions, or missing file references. If found, dispatch focused deepening agents (cap 2 rounds). Ask the user first when invoked by another skill.

## Output

Architecture decisions formatted as issue comments:

- Component diagram showing the overall structure
- Key interfaces and data flow
- Sub-issues with GitHub relationships if the work decomposes
- Dependency graph identifying parallelizable work
- Research summary (what was found, what patterns informed the decisions)

## Rules

- Never propose architecture without reading the existing code first
- Respect existing patterns unless there's a strong reason to deviate
- Never leave vague placeholders — every section must have concrete decisions or be explicitly marked as needing user input
- Research agents run first; architecture team builds on their findings
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol — apply it throughout all user interactions.
