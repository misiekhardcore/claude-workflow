---
name: define
description: Full definition phase — plan architecture and design for a feature. Spawns a team using /architecture and /design to make technical decisions, then updates the GitHub issue. Use after /discovery has produced an approved issue.
model: opus
effortLevel: high
---

You are leading the definition phase. Your goal is to take an approved GitHub issue and produce architecture and design decisions ready for implementation.

## Input

A GitHub issue number from /discovery (or provided by the user).

## Process

1. Read the issue to understand the problem statement and acceptance criteria.

2. **Dispatch a research team** (TeamCreate) before the definition team:
   - **Codebase research agent** — scans tech stack, modules, related implementations, naming, existing patterns. Outputs a structured brief.
   - **Patterns/learnings agent** — gathers prior art from, in order: (1) the claude-obsidian vault via `claude-obsidian:wiki-query` if available (concepts/entities/sources/meta); (2) project docs (READMEs, ADRs, `docs/**`); (3) external sources via Context7 when local patterns are thin. If `claude-obsidian` is not installed, step 1 is skipped with a note. Skip external research when internal sources yield 3+ direct pattern examples; always run full research for security/payments/privacy.

   The brief feeds both the architecture and design specialists as seed context.

3. **Spawn a definition team** using TeamCreate with specialists:
   - **Architecture specialist** — runs /architecture to explore technical approaches, seeded with research output. Pass the research brief as input — the Architecture specialist skips its own research phase when a research brief is provided. Produces component diagrams, data flow, API design, dependency graphs.
   - **Design specialist** (if the feature has visual aspects) — runs /design to explore UI/UX approaches, seeded with research output. Produces mockups, interaction flows, component hierarchies.

4. The architecture specialist goes first. Once technical decisions are approved by the user, the design specialist (if applicable) works within those constraints.

5. **Update the GitHub issue body** with decisions. The body is the handoff artifact, single source of truth — always update it in place, never post handoff state as a comment:
   - If the body already has a `## /define` section, edit it. If not, append one.
   - Record architecture decisions and design decisions (with visuals) inside that section.
   - Create sub-issues with GitHub relationships if the work decomposes.
   - Define the dependency graph — identify what can be parallelized.
   - The updated body is the sole input to `/implement` — a fresh session will read it, not this conversation. Include all five handoff fields (Acceptance criteria, Constraints, Prior decisions, Evidence, Open questions). See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.

6. Present all decisions to the user for approval. Do not proceed until sign-off.

7. After sign-off, instruct the user: "Start `/implement` in a fresh session; this one is closed." Do not call `/implement` from within `/define`.

## Rules

- **Require explicit full approval** before finalizing. Partial feedback is NOT approval.
- For complex tasks, spawn a second team to critique the plan before finalizing
- Respect existing codebase patterns unless there's a strong reason to deviate
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol — apply it throughout all user interactions.
