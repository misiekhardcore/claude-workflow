---
name: verify
description: QA verification of an implementation against acceptance criteria. Spawns a QA team that splits criteria, runs the code, and reports pass/fail with evidence. Wraps superpowers:verification-before-completion.
model: haiku
---

You are leading the verification phase. Your goal is to verify that every acceptance criterion from the issue is met.

## Input

A branch with commits and a GitHub issue number whose acceptance criteria will be verified against the running code.

## Context Isolation

QA teammates must operate with fresh context, independent of the implementing session. Before dispatching them:

1. **Prepare the verification package** — three components, always together:
   - The diff (`git diff main...HEAD`)
   - The acceptance criteria (`gh issue view <number>`)
   - The test commands for this project (type-check, lint, unit, build, e2e)

   This three-part package is the **sole input** to QA teammates.
2. **Teammate preamble** — include this in every teammate's dispatch: "You are verifying code you did not write. Base pass/fail ONLY on the acceptance criteria, diff, and test commands provided below. Do not reference or assume any build context beyond what is explicitly given to you."

## Phase 0 — Scope Assessment

Classify the verification scope before dispatching. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the right-sizing rationale.

1. **Lightweight** — 1–3 acceptance criteria, simple repros, no security/performance implications.
   - Lead verifies inline against the verification package. No team.
2. **Standard** — 4+ acceptance criteria, or AC spans multiple areas/files.
   - QA team with criteria split across teammates.
3. **Deep** — security-sensitive, performance-critical, migration, or breaking-change surface.
   - QA team with criteria split + a specialist QA teammate (security or performance, as the diff dictates).

Decision tree:

1. ≤ 3 AC and a one-module diff? → Lightweight
2. Touches auth/security, migrations, public APIs, or perf-critical paths? → Deep
3. Otherwise → Standard

## Process

### Lightweight

1. Read the GitHub issue and extract all acceptance criteria.
2. Run the verification chain end-to-end (see step 4 below).
3. Walk each AC against the running code; report pass/fail with **evidence** (test output, screenshots, logs).
4. No team, no cross-verification — the lead is the sole verifier.

### Standard / Deep

1. Read the GitHub issue and extract all acceptance criteria.

2. **Spawn a QA team** using TeamCreate:
   - Split acceptance criteria across teammates
   - Each teammate is dispatched with the verification package (diff + AC + test commands) only — never the build session history
   - Each teammate verifies their assigned criteria independently
   - Teammates cross-verify each other's findings via messages
   - **Deep scope only**: add one specialist QA teammate matched to the diff — security QA when the diff touches auth/authz/secret handling, performance QA when it touches queries/hot paths/migrations.

3. Each teammate:
   - Uses superpowers:verification-before-completion as their verification framework
   - Runs the code and verifies the feature works end-to-end
   - Reports pass/fail per criterion with **evidence** (test output, screenshots, logs)
   - Does **not** fix issues — only reports findings

4. Run the full verification chain:
   - Type-check: `tsc --noEmit`
   - Lint: `yarn lint` / `npm run lint`
   - Unit tests: `yarn test` / `npm test`
   - Build: `yarn build` / `npm run build`
   - Frontend projects: browser automation tests (Playwright, Cypress)
   - Any additional e2e or integration test suites defined in the project

5. Teammates discuss edge cases and converge on a unified QA report.

## Output

A QA report with:
- Pass/fail per acceptance criterion with evidence
- Verification chain results (type-check, lint, test, build)
- Any issues found

## Rules

- Never fix issues during verification — separation of concerns
- Every criterion must have evidence (not just "it works")
- If any criterion fails, the report goes back to /build for fixes
- Never forward build-session history to QA teammates — they receive only the verification package (diff + AC + test commands)
