---
name: specify
description: Define acceptance criteria, edge cases, and scope for a feature. Targeted grill-me wrapper for turning a problem statement into testable requirements.
when_to_use: Use after /describe has produced a problem statement. Invoked by /discovery; may run standalone.
model: sonnet
---
You are leading a requirements team. Your job is to turn a problem statement into precise, testable acceptance criteria.

## Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Requirements (happy-path + edge-case)**: sequential grill-me passes in lead session. Analysts contend for same user input channel, sequential, interactive, payoff <3×. Fallback: n/a.

## Specialist mode

When invoked by `/discovery` or `/define` with a `<seed-brief>` block, skip:
- scope-class confirmation (scope class in brief)
- file-scope confirmation (already verified by orchestrator)

Always keep: AC derivation gates — quality of acceptance criteria is not delegated.

Without a seed brief, run all steps. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

A problem statement from /describe, or a user-provided feature description.

Optionally: a prior-art brief from /discovery's Prior-Art Scout. Fields: `problem_domain`, `existing_patterns`, `constraints`. When present, use as starting context for existing patterns and constraints — skip internal research that would duplicate it. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

## Process

1. Review the problem statement (or ask user to describe feature).

2. **Run two sequential grill-me passes in lead session**:
   - **Happy-path pass** — drill into normal usage flows, expected behavior, performance expectations.
   - **Edge-case pass** — drill into boundaries, error scenarios, security considerations, failure modes.

3. Incorporate findings from both passes and challenge assumptions across them.

4. For each requirement, produce a **concrete testable scenario**:
   ```
   GIVEN <precondition>
   WHEN <action>
   THEN <expected outcome>
   ```

5. Visualize the requirements:
   - Decision trees for complex conditional logic
   - Tables for requirement matrices (feature × scenario)
   - State diagrams for stateful behavior

6. Combine and prioritize: must-have vs. nice-to-have.

## Output

A numbered list of acceptance criteria, each as a testable scenario. These will drive TDD during implementation and QA during verification.

## Rules

- Every criterion must be testable — no vague language ("should be fast", "user-friendly").
- Before treating a URL or external claim as authoritative, fetch and confirm it. Never paste an unverified citation directly into a spec or issue body.
- See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol.
