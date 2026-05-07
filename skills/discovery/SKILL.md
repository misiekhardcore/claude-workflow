---
name: discovery
description: Full discovery phase — explore a problem and produce a GitHub issue with acceptance criteria. Use at the start of any new feature.
when_to_use: Use at the start of any new feature or to explore a vague problem statement. Precedes /define. For clearly-specified issues with existing AC, skip to /implement.
argument-hint: "[issue# | description]"
model: opus
effort: high
---
You are leading the discovery phase. Your goal is to take a vague idea and produce a well-specified GitHub issue ready for architecture and implementation.

## Input

A user-provided problem statement (free text), or an existing GitHub issue number to re-run discovery against.

## Scope Assessment

Classify the task:

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|Clear repro + single area|Single agent runs /describe (Lightweight) → minimal /specify → issue. No team|
|Standard|Typical feature with some unknowns|Team with /describe + /specify specialists + Prior-Art Scout|
|Deep|Cross-module, auth/security/payments, architecture-changing, or multi-team|Full team + flow analyst + Prior-Art Scout + adversarial questioner|

Decision tree:
1. Single-sentence fix with clear repro in one area? → Lightweight
2. Touches auth/security/payments, crosses modules, changes architecture, or spans multiple teams? → Deep
3. Otherwise → Standard

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Standard team**: describe lead-inline + scout parallel subagent + specify sequential subagent. Async handoff, disjoint, scout-only parallel, payoff <3×. Fallback: sequential.
- **Deep team**: TeamCreate. Adversarial questioner reacts live, disjoint, parallel, payoff ≥3×. Gate: Deep scope. Fallback: sequential.

## Process

### Standard

1. **Dispatch the Prior-Art Scout as a parallel subagent** while beginning describe flow in lead:
   - **Prior-Art Scout** gathers institutional memory from, in order:
     1. **The claude-obsidian vault** (if available) via `claude-obsidian:wiki-query` for concepts/entities/sources/meta relevant to topic.
     2. **Past GitHub issues and PRs** via `gh issue list --search "<topic>"` and `gh pr list --search "<topic>"`.
     3. **Project documentation** — ADRs, design notes under `docs/**`, relevant READMEs.

     Output: structured brief with **Prior decisions**, **Prior attempts and outcomes**, **Related open/closed issues**, **Relevant patterns**. Feeds both describe and specify.

2. **Run /describe in lead** (lead-inline) to explore problem space with user. When Prior-Art Scout brief is available, incorporate as seed context; lead skips its own prior-art exploration (mirrors `/define` → `/architecture` seed-brief contract).

3. Once problem statement is clear and user has explicitly approved it, run /specify as **sequential subagent**, passing findings and scout brief as seed context. Once AC are approved, combine outputs.

### Deep

1. **Spawn extended discovery team** using TeamCreate with up to five specialists:
   - **Describe specialist** — runs /describe (Deep mode) to explore problem space
   - **Specify specialist** — runs /specify to produce acceptance criteria
   - **Flow analyst** — maps end-to-end flow: what systems are touched, what data moves, what can break. Produces sequence diagrams and dependency maps.
   - **Prior-Art Scout** — same sources and brief format as Standard (vault → issues/PRs → docs). For Deep-scope work (security, payments, cross-module), always run all three source layers.
   - **Adversarial questioner** — actively challenges assumptions: what if this fails, what's the migration path, what are security implications, what happens at scale.

2. Describe specialist, flow analyst, and Prior-Art Scout work in parallel. Adversarial questioner waits for all three, then reviews combined findings and challenges conclusions. Specify specialist works last, incorporating all concerns.

3. Scout brief is passed to `/describe` as seed context — describe specialist skips its own prior-art exploration.

### Lightweight

1. Run /describe in Lightweight mode — quick problem confirmation.
2. Extract 3-5 core acceptance criteria directly (do not invoke /specify).
3. Skip to issue creation.

### Issue Creation (all modes)

See `${CLAUDE_PLUGIN_ROOT}/_shared/repo-preflight.md` before any `gh issue` operation.

1. **Create a GitHub issue** (`gh issue create`) as a self-contained brief for the next phase. Issue body has two parts:

   **(a) Problem statement preamble** — `/discovery`-only, not part of handoff field order. From /describe output: what user is trying to do, why current state is inadequate, who is affected. This is the framing the rest of the issue depends on. Subsequent phases do not update this section.

   **(b) Handoff block** — under `## Requirements` heading, the five fields below, in this order, matching `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`. Field order is uniform across all phases so next session can scan-read. (Issue _title_ is set via `gh issue create --title` and is not part of body handoff block.)
   - **Acceptance criteria** — from /specify output, as numbered list of testable scenarios
   - **Constraints** — explicit in/out scope boundaries, non-negotiable decisions from discovery
   - **Prior decisions** *(optional)* — decisions made during discovery (one line each, with rationale)
   - **Evidence** *(optional)* — links to design reviews, benchmarks, prior discussions
   - **Open questions** *(optional)* — things `/define` must resolve

2. Present the issue to user for approval. Do not proceed until sign-off.

3. After sign-off, tell user to run `/define` in a fresh session. Do not call `/define` from within `/discovery` — the issue is the handoff artifact, and the next phase must start with clean context.

## Rules

- **Require explicit full approval** before creating the issue. Partial feedback is NOT approval.
- Every feature has at least one issue and at least one PR closing it.
- Epics get sub-issues linked with GitHub issue relationships (parent/child).
- The user must approve the issue.
- **Prior-Art Scout findings belong in the issue's Prior decisions and Evidence fields during issue creation — never drop them.**
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
