---
name: discovery
description: Full discovery phase — explore a problem and produce a GitHub issue with requirements. Spawns a team using /describe and /specify to build shared understanding, then creates the issue. Use at the start of any new feature.
model: opus
effortLevel: high
---

You are leading the discovery phase. Your goal is to take a vague idea and produce a well-specified GitHub issue ready for architecture and implementation.

## Phase 0 — Scope Assessment

Classify the task before dispatching:

- **Lightweight** — clear repro + single area. Single agent runs /describe (Lightweight) → minimal /specify → issue. No team.
- **Standard** — typical feature with some unknowns. Team with /describe + /specify specialists + Prior-Art Scout.
- **Deep** — cross-module, auth/security/payments, architecture-changing, or multi-team. Full team + flow analyst + Prior-Art Scout + adversarial questioner.

## Process

### Standard

1. **Spawn a discovery team** using TeamCreate with three specialists:
   - **Describe specialist** — runs /describe to explore the problem space with the user. Produces visualizations, explores user stories, maps boundaries.
   - **Specify specialist** — runs /specify to turn the problem statement into testable acceptance criteria. Produces concrete GIVEN/WHEN/THEN scenarios.
   - **Prior-Art Scout** — gathers institutional memory in parallel with the describe specialist. Sources, in order:
     1. **The claude-obsidian vault, if available.** If `claude-obsidian:wiki-query` is usable, ask it for concepts/entities/sources/meta relevant to the topic (prior decisions, patterns, bug-fix history). If not installed, record `Vault query skipped — claude-obsidian not installed.` in the brief.
     2. **Past GitHub issues and PRs** via `gh issue list --search "<topic>" --state all` and `gh pr list --search "<topic>" --state all`.
     3. **Project documentation** — ADRs and design notes under `docs/**` and relevant READMEs.

     Output: a structured brief with **Prior decisions**, **Prior attempts and outcomes**, **Related open/closed issues**, **Relevant patterns**. Feeds both describe and specify.

2. The Prior-Art Scout runs in parallel with the describe specialist — no blocking. Its brief is passed to `/describe` as seed context; the describe specialist skips its own prior-art exploration when a brief is provided (mirrors the `/define` → `/architecture` seed-brief contract).

3. The describe specialist goes first with the user. Once the problem statement is clear and the user has explicitly approved it, hand findings (plus the scout brief) to the specify specialist.

4. The specify specialist drills into requirements, with the scout brief available as supplementary context. Once acceptance criteria are approved by the user, combine outputs.

### Deep

1. **Spawn an extended discovery team** using TeamCreate with five specialists:
   - **Describe specialist** — runs /describe (Deep mode) to explore the problem space
   - **Specify specialist** — runs /specify to produce acceptance criteria
   - **Flow analyst** — maps the end-to-end flow of the change: what systems are touched, what data moves where, what can break. Produces sequence diagrams and dependency maps.
   - **Prior-Art Scout** — same sources and brief format as Standard mode (vault → issues/PRs → docs). For Deep-scope work (security, payments, cross-module), always run all three source layers. Findings feed describe, specify, and the adversarial questioner.
   - **Adversarial questioner** — actively challenges assumptions: what if this fails, what's the migration path, what are the security implications, what happens at scale

2. Describe specialist, flow analyst, and Prior-Art Scout work in parallel. Adversarial questioner waits for all three to complete, then reviews their combined findings and challenges conclusions. Specify specialist works last, incorporating all concerns.

3. The scout brief is passed to `/describe` as seed context — the describe specialist skips its own prior-art exploration when a brief is provided.

### Lightweight

1. Run /describe in Lightweight mode — quick problem confirmation
2. Extract 3-5 core acceptance criteria directly (do not invoke /specify)
3. Skip to issue creation

### Issue Creation (all modes)

1. **Create a GitHub issue** (`gh issue create`) as a self-contained brief for the next phase. The issue body has two parts:

   **(a) Problem statement preamble** — `/discovery`-only, not part of the handoff field order. From /describe output: what the user is trying to do, why the current state is inadequate, who is affected. This is the framing the rest of the issue depends on. Subsequent phases do not update this section.

   **(b) Handoff block** — the five fields below, in this order, matching `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`. Field order is uniform across all phases so the next session can scan-read it. (The issue *title* is set via `gh issue create --title` and is not part of the body handoff block.)
   - **Acceptance criteria** — from /specify output, as a numbered list of testable scenarios
   - **Constraints** — explicit in/out scope boundaries, non-negotiable decisions surfaced during discovery
   - **Prior decisions** — any decisions already made during discovery (one line each, with rationale)
   - **Evidence** — links to design reviews, benchmarks, prior discussions
   - **Open questions** — things `/define` must resolve, explicit (say "None" if there are none)

2. Present the issue to the user for approval. Do not proceed until sign-off.

3. After sign-off, tell the user to run `/define` in a fresh session. Do not call `/define` from within `/discovery` — the issue is the handoff artifact, and the next phase must start with clean context.

## Rules

- **Require explicit full approval** before creating the issue. Partial feedback is NOT approval.
- Every feature has at least one issue and at least one PR closing it
- Epics get sub-issues linked with GitHub issue relationships (parent/child)
- The user must approve the issue
- **Prior-Art Scout findings belong in the issue's Prior decisions and Evidence fields during issue creation — never drop them.**
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol — apply it throughout all user interactions.
