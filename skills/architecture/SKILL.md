---
name: architecture
description: Explore and decide on technical architecture for a feature. Use for structural decisions — components, data flow, APIs, and dependencies.
model: opus
effort: high
---
You are leading an architecture team to explore technical approaches with the user and converge on the right architecture for the feature.

## Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Research team**: 2 parallel subagents (codebase research and patterns/learnings). Model: dispatch with `model: "sonnet"`.
- **Architecture session**: analyst subagent → architect lead (grill-me) → devil's advocate subagent. Model: analyst and devil's advocate use `model: "sonnet"`; lead architect stays `opus`.

## Specialist mode

When invoked by `/define` with a `<seed-brief>` block, skip:
- codebase-research subagent dispatch
- patterns/learnings subagent dispatch

Always keep the full architecture session (grill-me + devil's advocate).

Without a seed brief, run all steps. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

A GitHub issue with problem statement and acceptance criteria (from /discovery).

## Process

1. Read the issue and understand requirements.

2. **Dispatch 2 parallel research subagents** before the architecture session:
   - **Codebase research agent** — scan relevant code: technology stack, module structure, related implementations, patterns. Output structured context brief.
   - **Patterns/learnings agent** — gather prior art from:
     1. The claude-obsidian vault (if available). Query for concepts/entities/sources relevant to the feature.
     2. Project documentation (READMEs, ADRs, `docs/**`).
     3. External documentation via Context7 or web search when local patterns are thin.

     If `claude-obsidian` is unavailable, skip step 1 and note: `Vault query skipped — claude-obsidian not installed.`

   **Gate rule**: skip external research when internal sources yield ≥3 pattern examples. Always run full research for security, payments, privacy topics, or when local patterns are thin.

3. **Run the architecture session** sequentially:
   - **Codebase analyst** subagent seeded with research brief; explores architectural constraints (module boundaries, deployment topology, integration points).
   - **Solution architect** runs interactively via /grill-me, informed by research brief and analyst findings.
   - After proposed approach is reached, dispatch **Devil's advocate** subagent to challenge it — risks, edge cases, scaling concerns. Feed back to lead session for final resolution.

4. For each major decision, present 2-3 approaches:
   - Architecture diagram (Mermaid component/sequence)
   - Trade-off table (pros, cons, complexity, risk)
   - Code structure preview (directory layout, key interfaces)
   - Recommended approach with rationale

5. Move to the next decision once resolved.

6. Define the dependency graph between sub-tasks — identify parallelizable work.

7. **Auto-deepen thin sections** — scan for vague language ("appropriate", "as needed", "standard approach"), fewer than 3 concrete decisions, or missing file references. Dispatch focused deepening agents (≤2 rounds). Ask the user first when invoked by another skill.

## Output

Architecture decisions formatted as issue comments:

- Component diagram showing overall structure
- Key interfaces and data flow
- Sub-issues with GitHub relationships if work decomposes
- Dependency graph identifying parallelizable work
- Research summary (patterns that informed decisions)

## Rules

- Never propose architecture without reading existing code first.
- Respect existing patterns unless strong reason to deviate.
- Never leave vague placeholders — every section must have concrete decisions or be explicitly marked as needing user input.
- Research agents run first; architecture team builds on findings.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
