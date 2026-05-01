---
name: review
description: Review an implementation against its issue requirements. Spawns a review team — one for correctness, one for style/standards. Wraps superpowers:requesting-code-review with team-based specialist review.
model: sonnet
effortLevel: high
---

You are leading the review phase. Your goal is to thoroughly review the implementation and produce actionable findings.

## Specialist mode

When invoked by `/implement` with a `<seed-brief>` block, skip:
- repo-preflight (already run by the orchestrator; `preflight_verified: true` is in the brief)

Always keep: severity/finding-depth gates — rigor of review is not delegated to the orchestrator.

Without a seed brief, run all prompts as described below. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

A branch with commits (reviewed via `git diff main...HEAD`), and optionally a GitHub issue number whose acceptance criteria reviewers check against.

## Configuration

- **Standard reviews**: dispatch reviewers with `model: "sonnet"` to get a genuinely different analytical perspective from the implementing session.
- **Deep reviews**: dispatch reviewers with `model: "opus"` for maximum analytical depth.
- The lead agent (you) always runs on the session's current model.

## Context Isolation

Reviewers must operate with fresh context, independent of the implementing session. Before dispatching reviewers:

1. **Prepare the review package** — run `git diff main...HEAD` and capture the output. If a GitHub issue exists, run `gh issue view <number>` and capture its acceptance criteria. This package is the sole input to reviewers.
2. **Reviewer preamble** — include this in every reviewer's dispatch: "You are reviewing code you did not write. Base your review ONLY on the diff and acceptance criteria provided below. Do not reference or assume any implementation context beyond what is explicitly given to you."

## Scope Assessment

Before starting, classify the review scope:

1. **Lightweight** — small change, single file or tightly scoped fix
   - Single reviewer, quick pass. No team dispatch.
   - Focus on correctness and obvious issues only.
2. **Standard** — typical feature or multi-file change
   - 2 base reviewers + conditional specialists based on diff analysis.
3. **Deep** — security-sensitive, performance-critical, cross-cutting, or migration/breaking-change
   - All specialist reviewers active. Veto power for security/performance.

Decision tree:

1. Is the diff under ~50 lines and touches one module? → Lightweight
2. Does it touch auth/security, database migrations, public APIs, or performance-critical paths? → Deep
3. Otherwise → Standard

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`. `Fallback:` applies when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset. Model tiers: see **Configuration** section.

- **Standard**: TeamCreate with `model: "sonnet"` at ≥3 active reviewers, else 2 parallel subagents with `model: "sonnet"`. Comm-pivot ✓ (converge on disagreements), disjoint ✓, parallel ✓, payoff ≥3× at scale. Gate: ≥3 reviewers active. Fallback: sequential subagents.
- **Deep**: TeamCreate with `model: "opus"`. All four ✓ across 4 review axes; opus premium justified by criticality. Fallback: sequential subagents.

## Process

### Lightweight

1. Read the GitHub issue and its acceptance criteria.
2. Run `git diff main...HEAD` to see all changes.
3. Single-pass review: check acceptance criteria, obvious bugs, leftover debug code, forgotten TODOs.
4. Report findings.

### Standard

1. Read the GitHub issue and its acceptance criteria.

2. **Analyze the diff** to determine which conditional reviewers to activate:
   - Run `git diff main...HEAD` and scan the output for domain-specific patterns
   - **Security reviewer** — activate when the diff touches authentication or authorization code (e.g., `auth`, `token`, `session`, `permission`). Require co-occurrence of 2+ security-related terms in the same file, OR file paths matching `**/auth/**`, `**/security/**`, `**/middleware/**`.
   - **Performance reviewer** — activate when the diff touches database queries or data access patterns (e.g., `query`, `findAll`, `SELECT`, `JOIN`, `index`). Trigger on file paths matching `**/db/**`, `**/queries/**` or database-related content — NOT on generic JS iteration methods like `forEach` or `map`.
   - **Migration reviewer** — activate when the diff includes schema changes or data migrations. Trigger on file paths matching `**/migrations/**`, `**/db/**` or content matching `CREATE TABLE`, `ALTER TABLE`, `addColumn`, `migration`.

3. **Dispatch reviewers** per the Spawn justification gate (TeamCreate at ≥3 active reviewers with `model: "sonnet"`, else parallel subagents). Include the reviewer preamble from Context Isolation above in each reviewer's instructions.
   - **Correctness reviewer** (always-on) — checks that the implementation satisfies every acceptance criterion, handles edge cases, and has no logical errors.
   - **Standards reviewer** (always-on) — checks code style, naming, patterns, test quality, and adherence to project conventions.
   - **Security reviewer** (conditional) — checks for authentication/authorization bugs, injection vulnerabilities, secret exposure, and unsafe data handling.
   - **Performance reviewer** (conditional) — checks for N+1 queries, unbounded loops, missing pagination, cache misses, and unindexed lookups.
   - **Migration reviewer** (conditional) — checks for backward compatibility, rollback safety, data loss risks, and migration ordering.

4. All reviewers work in parallel. Each reviewer:
   - Runs `git diff main...HEAD` to see all changes
   - Checks for leftover debug code, forgotten TODOs, or accidental changes
   - Uses superpowers:requesting-code-review as their review framework
   - Reports findings as a structured list with **confidence scoring**:
     ```
     - file:line | issue title | severity (P0-P3) | confidence (0.0-1.0)
     ```
   - Confidence calibration:
     - 0.9+ = would bet on this being a real bug
     - 0.7–0.9 = likely an issue but needs verification
     - 0.5–0.7 = suspicious but could be intentional

5. **Merge and deduplicate findings** across all reviewers:
   - Group findings by file + line_bucket (±3 lines) + normalized title (lowercase, strip trailing punctuation, collapse whitespace)
   - When 2+ reviewers flag the same issue, boost confidence by 0.10 (clamp to 1.0)
   - Suppress findings below the confidence thresholds defined in Rules
   - Merge duplicates into a single finding, noting which reviewers flagged it
   - Suppressed findings are listed in a collapsed "Low-confidence observations" section at the end of the report

6. Reviewers discuss disagreements via messages and converge on a unified review.

7. Present findings to the implementation lead. Do **not** fix issues — only report them.

### Deep

1. Read the GitHub issue and its acceptance criteria.

2. **Spawn an extended review team** using TeamCreate with `model: "opus"` and all specialists active. Include the reviewer preamble from Context Isolation above in each reviewer's instructions.
   - **Correctness reviewer** — checks acceptance criteria, edge cases, logical errors
   - **Standards reviewer** — checks code style, naming, patterns, test quality
   - **Security reviewer** — checks for vulnerabilities: injection, auth bypass, data exposure, insecure defaults, OWASP top 10 concerns
   - **Performance/migration reviewer** — checks for N+1 queries, unnecessary allocations, breaking changes, migration safety, backward compatibility

3. All reviewers work in parallel. Each uses `git diff main...HEAD` and reports structured findings with confidence scoring (same format and calibration as Standard mode).

4. **Merge and deduplicate** — same process as Standard mode.

5. Team converges on a unified review via messages.

6. Present findings to the implementation lead. Do **not** fix issues — only report them.

## Output

A structured review report with:

- Pass/fail per acceptance criterion
- Issues found (with file:line references, severity, and confidence score)
- Which conditional reviewers were activated and why (Standard) or note that all were active (Deep)
- Recommendations

When returning findings to `/build`, package them as a **fix brief**: failing criteria + `file:line` findings + severity + confidence. No session history — `/build` already has the full context and should not re-ingest the review session.

## Rules

- Never fix issues during review — separation of concerns
- All reviewers must agree before the review is finalized
- All reviewers can block on Critical findings. In Deep mode, security and performance reviewers additionally block on High-severity findings.
- Flag any changes outside the stated scope of the issue
- Confidence below 0.60 means suppress (0.50 for P0/Critical)
- Always run the merge/dedup step — never present raw duplicates to the user
