---
name: review
description: Review an implementation against its issue requirements or a PR number/URL. Posts inline GitHub review comments in PR mode.
argument-hint: "[PR# or URL]"
model: sonnet
effort: high
---
You are leading the review phase. Your goal is to thoroughly review the implementation and produce actionable findings.

## Specialist mode

When invoked by `/implement` with a `<seed-brief>` block, skip:
- repo-preflight (already run; `preflight_verified: true` in brief)

Always keep: severity/finding-depth gates — rigor of review is not delegated to the orchestrator.

Without a seed brief, run all steps. See `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.

## Input

One of:

1. **Branch with seed brief** — invoked by `/implement`. Reviewed via `git diff main...HEAD`; AC from seed brief.
2. **Branch standalone** — no PR argument. Reviewed via `git diff main...HEAD`; if GitHub issue number supplied, AC from `gh issue view <number>`.
3. **PR argument** — a PR number or URL (e.g. `42`, `https://github.com/owner/repo/pull/42`). Reviewed via `gh pr view` and `gh pr diff`; AC from linked issue if any.

## Modes

The input determines dispatch mode. An explicit PR argument always wins over an implicit seed brief.

|Trigger|Diff source|AC source|Output|
|-|-|-|-|
|Branch + seed brief|`git diff main...HEAD`|seed brief|**Fix brief** to `/build`|
|Branch standalone|`git diff main...HEAD`|`gh issue view <n>` (if supplied)|**Findings report** to user|
|PR argument|`gh pr view <n>` + `gh pr diff <n>`|linked issue from `gh pr view --json closingIssuesReferences`|**Posted GitHub review** (inline comments + summary)|

Fix-brief path unchanged — `/implement` invocations continue to receive fix brief via seed-brief route. PR-mode runs never return a fix brief.

## Configuration

- **Standard reviews**: dispatch reviewers with `model: "sonnet"` for a genuinely different analytical perspective.
- **Deep reviews**: dispatch reviewers with `model: "opus"` for maximum analytical depth.
- The lead agent (you) always runs on the session's current model.

## Context Isolation

Reviewers must operate with fresh context, independent of the implementing session. Before dispatching reviewers:

1. **Prepare the review package** — the sole input to reviewers.
   - **Branch modes:** run `git diff main...HEAD` and capture output. If a GitHub issue exists, run `gh issue view <number>` and capture AC.
   - **PR mode:** run `gh pr view <n> --json title,body,headRefName,headRefOid,baseRefName,closingIssuesReferences,author`, `gh pr diff <n>`, and — if `closingIssuesReferences` non-empty — `gh issue view <linked>` for each linked issue. `headRefOid` is the head commit SHA the review will be anchored to. If no linked issue found, set `no_linked_issue: true` on review package.

2. **Reviewer preamble** — include in every reviewer's dispatch: "You are reviewing code you did not write. Base your review ONLY on the diff and acceptance criteria provided below. Do not reference or assume any implementation context beyond what is explicitly given to you."

## Scope Assessment

Classify the review scope:

|Scope|Criteria|Actions|
|-|-|-|
|Lightweight|Small change, single file, tightly scoped fix|Single reviewer, quick pass. No team dispatch. Focus on correctness and obvious issues|
|Standard|Typical feature or multi-file change|2 base reviewers + conditional specialists based on diff analysis|
|Deep|Security-sensitive, performance-critical, cross-cutting, migration/breaking-change|All specialist reviewers active. Veto power for security/performance|

Decision tree:
1. Diff under ~50 lines, touches one module? → Lightweight
2. Touches auth/security, database migrations, public APIs, or perf-critical paths? → Deep
3. Otherwise → Standard

The chosen class is referenced as `scope_class` by gates in `references/personas.md`.

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`. Model tiers: see **Configuration** section.

- **Standard**: TeamCreate with `model: "sonnet"` at ≥3 active personas, else 2 parallel subagents. Converge on disagreements, disjoint, parallel, payoff ≥3×. Gate: ≥3 personas active. Fallback: sequential.
- **Deep**: TeamCreate with `model: "opus"`. All four across review axes; opus premium justified by criticality. Fallback: sequential.

Always-on personas (correctness, standards) plus conditional personas whose gates fire all count toward ≥3 threshold. Conditional personas (security, performance, migration, docs consistency, architecture / scope-creep) count toward threshold.

## Personas

Reviewer personas, gates, signals, and severity rubric live in `references/personas.md`. Orchestrator decides which to activate based on scope and gates.

**Always-on:** correctness, standards.

**Conditional** (each has signal-based gate):
- security
- performance
- migration
- docs consistency
- architecture / scope-creep

Activate a conditional persona only when its gate fires against the prepared review package. Record which gates fired and why; surface in final report.

## Process

### Lightweight

1. Acquire review package per **Context Isolation**.
2. Single-pass review against AC: obvious bugs, leftover debug code, forgotten TODOs.
3. Report findings (or post them in PR mode).

### Standard

1. Acquire review package per **Context Isolation**.

2. **Analyze the diff** to determine which conditional personas activate. Evaluate every gate in `references/personas.md` against package. Note which fired and why.

3. **Dispatch reviewers** per Spawn justification gate. Include reviewer preamble from Context Isolation, plus persona prompt from `references/personas.md`.

4. All reviewers work in parallel. Each:
   - Reads prepared review package (does **not** run `git diff` again — operates on captured diff).
   - Checks for leftover debug code, forgotten TODOs, accidental changes.
   - Uses `superpowers:requesting-code-review` as review framework.
   - Reports findings as structured list with **confidence scoring**:
     ```
     - file:line | issue title | severity (P0-P3) | confidence (0.0-1.0)
     ```
   - Confidence calibration:
     - 0.9+ = would bet on this being a real bug
     - 0.7–0.9 = likely an issue but needs verification
     - 0.5–0.7 = suspicious but could be intentional

5. **Merge and deduplicate** findings across all reviewers:
   - Group by file + line_bucket (`floor(line / 3) * 3`) + normalized title (lowercase, strip trailing punctuation, collapse whitespace).
   - When 2+ reviewers flag same issue, boost confidence by 0.10 (clamp to 1.0).
   - Suppress findings below confidence thresholds (see Rules).
   - Merge duplicates into single finding, noting which reviewers flagged it.
   - Suppressed findings listed in collapsed "Low-confidence observations" section.

6. Reviewers discuss disagreements via messages and converge on unified review.

7. Emit findings:
   - **Branch + seed brief** → fix brief to `/build`.
   - **Branch standalone** → findings report to user.
   - **PR argument** → post review per **Posting findings to GitHub**.

### Deep

1. Acquire review package per **Context Isolation**.

2. **Spawn extended review team** using TeamCreate with `model: "opus"`. Activate every always-on persona plus every conditional persona — Deep mode runs all regardless of gate state, but still records why each gate would have fired (or not).

3. All reviewers work in parallel. Each reads prepared review package and reports structured findings with confidence scoring (same format as Standard).

4. **Merge and deduplicate** — same process as Standard.

5. Team converges on unified review via messages.

6. Emit findings per same dispatch rules as Standard.

## Posting findings to GitHub

This block runs only when input was a PR argument. Posts single GitHub review carrying summary body plus inline comments, with idempotency keyed on hidden fingerprint.

### 1. Fingerprint each finding

For every merged finding, compute:

```
fp = sha256(file + ":" + line_bucket + ":" + normalized_title)[:12]
```

Severity is intentionally **not** part of fingerprint: idempotency keys on location + title. Summary review body gets its own fingerprint:

```
summary_fp = sha256("summary:" + pr_number + ":" + sorted(per_finding_fps).join(","))[:12]
```

### 2. Pre-scan for existing fingerprints

Fetch every existing review comment authored by the runner on this PR, parse the markers, and skip findings whose fingerprint already appears.

```bash
me=$(gh api user --jq .login)
existing=$(gh api "repos/{owner}/{repo}/pulls/{N}/comments" --paginate \
  --jq "[.[] | select(.user.login==\"\$me\") | .body | select(test(\"<!-- review-fp: [a-f0-9]+ -->\")) | capture(\"<!-- review-fp: (?<fp>[a-f0-9]+) -->\").fp]")
```

Also fetch existing review summary bodies and skip entire post if `<!-- review-summary-fp: <summary_fp> -->` already exists:

```bash
existing_summary_fps=$(gh api "repos/{owner}/{repo}/pulls/{N}/reviews" --paginate \
  --jq "[.[] | select(.user.login==\"\$me\") | .body | select(test(\"<!-- review-summary-fp: [a-f0-9]+ -->\")) | capture(\"<!-- review-summary-fp: (?<fp>[a-f0-9]+) -->\").fp]")
```

### 3. Build the review payload

Each inline finding becomes one entry in `comments[]`. Body ends with hidden marker:

```
**[P1, conf 0.85]** Issue title

Optional one-line elaboration.

<!-- review-fp: a1b2c3d4e5f6 -->
```

Summary body lists **top 3 findings** sorted by severity descending, then confidence descending as tiebreaker. End summary with `<!-- review-summary-fp: <summary_fp> -->`.

### 4. Post atomically

Use single REST call so review is created with all comments in one transaction:

```bash
jq -n \
  --arg body "$summary_body" \
  --arg commit "$head_sha" \
  --argjson comments "$comments_json" \
  '{event: "COMMENT", commit_id: $commit, body: $body, comments: $comments}' | \
  gh api repos/{owner}/{repo}/pulls/{N}/reviews --input -
```

`commit_id` is the `headRefOid` captured in **Context Isolation** — anchoring review to SHA prevents drift if PR head advances mid-run. `event` is `"COMMENT"` (not `REQUEST_CHANGES` or `APPROVE`). Each entry in `$comments_json` carries `path`, `line`, `side`, and `body` with embedded fingerprint marker.

### 5. Report back to user

Print:

- The created review URL.
- `posted: N | skipped: M` — N is new findings, M is duplicates skipped via fingerprint.
- The top-3 ranked findings (mirror of summary body).

No fix brief returned — there is no `/build` consumer in PR mode.

## Output

A structured review report with:

- Pass/fail per acceptance criterion
- Issues found (file:line references, severity, confidence score)
- Which conditional personas were activated and why (Standard) or all were active (Deep)
- Recommendations

When returning findings to `/build` (branch + seed brief mode), package as **fix brief**: failing criteria + `file:line` findings + severity + confidence. No session history.

In **PR-argument mode**, canonical output is posted GitHub review; in-session report is short pointer (review URL, posted/skipped counts, top-3 ranked findings).

## Rules

- Never fix issues during review — separation of concerns.
- All reviewers must agree before review is finalized.
- All reviewers can block on Critical findings. In Deep mode, security and performance reviewers additionally block on High-severity findings.
- Flag any changes outside stated scope of the issue.
- Confidence below 0.60 means suppress (0.50 for P0/Critical).
- Always run merge/dedup step — never present raw duplicates to user.
- **PR mode is single-repo only.** Treat worktree's origin as target; do not accept cross-repo PR URLs.
- **PR mode is review-only.** Never push commits, never auto-fix, never approve or request-changes — `event: "COMMENT"`.
- **PR mode is idempotent.** Always pre-scan for existing fingerprints before posting; re-runs must not duplicate comments.
- **PR mode never returns a fix brief.** Fix-brief path reserved for branch + seed-brief invocation from `/implement`.
