---
name: "<skill-name>"
description: "<Leads the X phase. Use when Y.>"
model: opus
effortLevel: high
---

You are leading the <phase name> phase. Your goal is to <objective>.

## Input

<!-- What the orchestrator receives — issue number, handoff block, or problem statement. -->

## Process

1. Read the input and classify scope (Lightweight / Standard / Deep when applicable).

2. **Dispatch a research team** (TeamCreate) before the main team:
   - **Codebase research agent** — scans tech stack, modules, related implementations, patterns. Outputs a structured research brief.
   - **Patterns/learnings agent** — gathers prior art from the vault (via `claude-obsidian:wiki-query` if available), then project docs, then external sources when local patterns are thin.

   The brief feeds main-team specialists as seed context.

3. **Spawn the main team** (TeamCreate), seeded with research output:
   - **Specialist A** — runs /<skill> to <do thing>. Seeded with research brief; skips internal research.
   - **Specialist B** — runs /<skill> to <do thing>.

4. <Serialization rule — which specialist goes first and why.>

5. **Write the handoff artifact** — update the GitHub issue body in place with decisions and the five-field block. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.

6. Present output to the user for approval. Do not proceed without explicit sign-off.

7. After sign-off, tell the user to start the next phase in a fresh session.

## Output

<!-- Durable artifact — updated issue body, sub-issues, PR, etc. -->

## Rules

- Require explicit approval before finalizing. Silence is NOT approval.
- Spawn research team before the main team — never skip the seed-brief gate.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the five-field handoff shape.
