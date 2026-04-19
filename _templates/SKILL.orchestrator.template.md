---
name: "<skill-name>"
description: "<Leads the X phase. Use when Y.>"
model: opus
effortLevel: high
---

You are leading the <phase name> phase. Your goal is to <objective>.

<!--
Research-leading vs coordinator orchestrator:
- Research-leading (e.g. /discovery, /define): keep step 2 (Dispatch a research team) — the orchestrator is where deep reasoning happens.
- Coordinator (e.g. /implement): omit step 2. Upstream phases or the sub-skills being sequenced own research; adding a research team here is redundant.
-->

## Input

<!-- What the orchestrator receives — issue number, handoff block, or problem statement. -->

## Phase 0 — Scope Assessment

Classify the task before dispatching. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the right-sizing rationale.

- **Lightweight** — <concrete heuristic: single file, trivial input, no unknowns>. Lead runs inline. No team. Skip step 2 (research) and collapse step 3 into a single pass.
- **Standard** — <concrete heuristic: typical feature, some unknowns>. Core specialists only. Optional roles stay dormant unless signals fire.
- **Deep** — <concrete heuristic: cross-module, security, architecture-changing>. Full team + critique/adversarial pass.

## Process

1. Read the input and confirm the Phase 0 classification.

2. **Dispatch a research team** (TeamCreate; Standard/Deep only — skip in Lightweight):
   - **Codebase research agent** — scans tech stack, modules, related implementations, patterns. Outputs a structured research brief.
   - **Patterns/learnings agent** — gathers prior art from the vault (via `claude-obsidian:wiki-query` if available), then project docs, then external sources when local patterns are thin.

   The brief feeds main-team specialists as seed context.

3. **Spawn the main team** (TeamCreate), seeded with research output. Team width scales with scope — include only the specialists the classification calls for:
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
- Spawn research team before the main team — never skip the seed-brief gate in Standard/Deep scope.
- Never pay coordination overhead for work a single agent completes in under a minute — Lightweight runs inline.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the five-field handoff shape.
