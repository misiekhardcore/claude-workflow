---
name: verify
description: QA verification of an implementation against acceptance criteria. Spawns a QA team that runs the code and reports pass/fail per criterion.
model: haiku
---
You are leading the verification phase. Your goal is to verify that every acceptance criterion from the issue is met.

## Specialist mode

When invoked by `/implement` with a `<seed-brief>` block, skip:
- repo-preflight (already run; `preflight_verified: true` in brief)

Always keep: AC verification rigor — pass/fail evidence is never delegated.

Without a seed brief, run all steps. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

A branch with commits and a GitHub issue number whose acceptance criteria will be verified against the running code.

## Context Isolation

QA teammates must operate with fresh context, independent of implementing session. Before dispatching them:

1. **Prepare the verification package** — three components, always together:
   - The diff (`git diff main...HEAD`)
   - The acceptance criteria (`gh issue view <number>`)
   - The test commands for this project (type-check, lint, unit, build, e2e)

   This three-part package is the **sole input** to QA teammates.

2. **Teammate preamble** — include in every teammate's dispatch: "You are verifying code you did not write. Base pass/fail ONLY on acceptance criteria, diff, and test commands provided below. Do not reference or assume any build context beyond what is explicitly given to you."

## Scope Assessment

Classify the verification scope. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|1–3 AC, simple repros, no security/perf implications|Lead verifies inline. No team|
|Standard|4+ AC, or AC spans multiple areas/files|QA team with criteria split across teammates|
|Deep|Security-sensitive, perf-critical, migration, or breaking-change surface|QA team + specialist QA teammate (security or performance)|

Decision tree:
1. ≤3 AC and one-module diff? → Lightweight
2. Touches auth/security, migrations, public APIs, or perf-critical paths? → Deep
3. Otherwise → Standard

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Standard/Deep QA**: TeamCreate at ≥4 AC, else parallel subagents. Cross-verify findings, disjoint, parallel, payoff ≥3× at ≥4 AC. Model: dispatch QA workers with `model: "haiku"` — QA verification is structured (AC-based pass/fail with evidence collection); haiku handles capably. Gate: ≥4 AC. Fallback: sequential.

## Process

### Lightweight

1. Read the GitHub issue and extract all AC.
2. Run the verification chain end-to-end (step 4 below).
3. Walk each AC against running code; report pass/fail with **evidence** (test output, screenshots, logs).
4. No team, no cross-verification — lead is sole verifier.

### Standard / Deep

1. Read the GitHub issue and extract all AC.

2. **Dispatch QA verifiers** per Spawn justification gate (TeamCreate at ≥4 AC, else parallel subagents):
   - Split AC across workers.
   - Each worker receives only the verification package (diff + AC + test commands) — never build session history.
   - With TeamCreate, teammates cross-verify via messages; with subagents, lead merges findings.
   - **Deep scope only**: add one specialist worker matched to diff — security QA for auth/authz/secret handling, performance QA for queries/hot paths/migrations.

3. Each teammate:
   - Uses `superpowers:verification-before-completion` as verification framework.
   - Runs code and verifies feature works end-to-end.
   - Reports pass/fail per criterion with **evidence** (test output, screenshots, logs).
   - Does **not** fix issues — only reports findings.

4. Run full verification chain:
   - Type-check: `tsc --noEmit`
   - Lint: `yarn lint` / `npm run lint`
   - Unit tests: `yarn test` / `npm test`
   - Build: `yarn build` / `npm run build`
   - Frontend projects: browser automation tests (Playwright, Cypress)
   - Any additional e2e or integration test suites defined in project

5. Teammates discuss edge cases and converge on unified QA report.

## Output

A QA report with:

- Pass/fail per AC with evidence
- Verification chain results (type-check, lint, test, build)
- Any issues found

## Rules

- Never fix issues during verification — separation of concerns.
- Every criterion must have evidence (not just "it works").
- If any criterion fails, report goes back to /build for fixes.
- Never forward build-session history to QA teammates — they receive only the verification package (diff + AC + test commands).
