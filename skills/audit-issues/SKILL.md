---
name: audit-issues
description: Audit open GitHub issues for staleness vs. current repo state. Flags broken file refs, stale counts, resolved questions, cross-issue contradictions.
model: sonnet
---

You are auditing open GitHub issues for drift against the current state of their repository. Issues queued weeks or months ago accumulate broken file references, stale numeric claims, version references, resolved open questions, and cross-issue contradictions; this skill detects that drift and offers per-issue fix-or-close actions.

This is a read-first, mutate-on-confirm utility. The product is the **updated set of issues themselves** — there is no parallel report artifact.

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Per-issue audit fan-out**: one Task subagent per audited issue, each running extraction + the five verifiers and returning a structured JSON report; lead aggregates and prints. Comm-pivot ✗ (subagents do not need to share findings mid-task — cross-issue checks use the upfront issue-list snapshot the lead passes in), disjoint ✓ (each subagent owns one issue body + the read-only repo tree), parallel ✓ (extraction + gh/grep verification per issue is independent), payoff ≥3× (sequential ≈ 30–60s for ~15 issues; parallel ≈ one issue's wall time). Model: sonnet — issue prose extraction needs comprehension, not deep reasoning. Fallback: n/a — no flag dependency (parallel subagents do not require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

Skip the fan-out when only one issue is targeted (`#NN` form) — run extraction + verification inline.

## Input

Positional argument forms (no flags):

| Form | Meaning |
|------|---------|
| _(empty)_ | Audit all open issues in the repo of the current working directory. |
| `owner/repo` | Audit all open issues in `owner/repo`. |
| `#NN` | Audit a single issue in the current repo. |
| `#NN #MM …` | Audit a specific subset in the current repo. |
| `owner/repo#NN` | Audit a single issue in a different repo. |

Filters like `--label` and `--since` were rejected during `/define` — real triage targets a specific repo or specific issue numbers, not slices of label space. Add only when a concrete use case demands it.

## Process

### Phase 0 — Target resolution and local-clone gate

1. Parse the argument into `(owner, repo, issue_numbers | null)`.
   - Empty arg → resolve `owner/repo` from `git remote -v` in cwd; `issue_numbers = null`.
   - `owner/repo` form → use directly; `issue_numbers = null`.
   - `#NN[ #MM …]` → resolve repo from cwd; `issue_numbers = [NN, …]`.
   - `owner/repo#NN` → split on `#`; `issue_numbers = [NN]`.
2. Resolve the local working tree:
   - Default location: `~/Projects/<repo>` (the directory part after the slash).
   - Verify the directory exists and `git remote -v` inside it points at `git@github.com:<owner>/<repo>.git` (or the https equivalent).
3. **If the local working tree is missing or points at a different remote**, abort with the exact message:

   ```
   audit-issues: local clone of <owner>/<repo> not found at ~/Projects/<repo>.
   clone owner/repo first, then re-run.
   ```

   Do not auto-clone. Do not fall back to a degraded mode that audits without repo state — the verifiers depend on the working tree.
4. Pull the latest default branch:
   - Run `git -C <local-tree> fetch --quiet origin`. If fetch **fails** (no network, auth error), warn: `audit-issues: fetch failed — auditing against cached HEAD (results may be stale)` and continue.
   - If fetch **succeeds**, run `git -C <local-tree> rev-parse --abbrev-ref origin/HEAD` to identify the default branch. If rev-parse fails (no `origin/HEAD`), abort: `audit-issues: cannot determine default branch in <local-tree>; run 'git remote set-head origin -a' and retry.`

### Phase 1 — Fetch issues once at the lead

The lead runs a single `gh` call and shares the result with all subagents so cross-issue contradiction checks do not refetch.

```bash
gh issue list \
  --repo <owner>/<repo> \
  --state open \
  --limit 200 \
  --json number,title,body,labels,updatedAt,url
```

If `issue_numbers` is set, filter the result in memory rather than firing one `gh issue view` per number — keeps wall time flat and gives every subagent the same sibling-issue set for cross-issue checks.

Skip closed issues. Auditing closed issues is explicitly out of scope for v1.

### Phase 2 — Per-issue audit (subagent fan-out)

**Single-issue shortcut:** If targeting exactly one issue (`len(issue_numbers) == 1`), run the subagent contract below inline — no Task dispatch. Otherwise, spawn one Task subagent per issue in a single parallel message.

Seed each execution (inline or subagent) with:

- The full body of its assigned issue.
- The titles + numbers + 1-line `Prior decisions` excerpts of every other open issue in the repo (for cross-issue checks). Cap each excerpt to keep the brief bounded — full bodies are redundant.
- The absolute path of the local working tree.
- The verifier contract below.

#### Subagent contract

Each subagent runs five detectors against its issue body and returns a structured JSON report. Treat the issue body as the source of claims; treat the local tree (HEAD of default branch) as ground truth.

**Step 1 — Hybrid claim extraction.**

Regex pass (deterministic, runs first):

| Claim type | Pattern intent | Examples |
|------------|---------------|----------|
| File path | `` `path/like/this.ext` `` in inline code, or bare paths (no backticks) whose first segment matches a top-level directory in the local working tree (`ls -d <tree>/*/` filtered to non-hidden dirs — e.g. `skills/`, `_shared/`, `docs/`) | `` `skills/prune/SKILL.md` ``, `_shared/handoff-artifact.md` |
| Numeric claim | "<number> <plural noun>" tied to a repo concept (skills, files, agents, lines, etc.) | "11 skills", "6 detectors" |
| Version reference | `vX.Y[.Z]`, "the X.Y MCP purge", or pinned package versions | "v1.0.0", "after the v1.0.0 MCP purge" |

LLM pass (one call per issue, runs second; grounded in the regex output to reduce hallucination):

| Claim type | What the LLM extracts |
|------------|----------------------|
| Cross-issue reference | `#NN` mentions in *Prior decisions* / body, with the surrounding clause that states the dependency |
| Open question | Bullets under an *Open questions* heading, or sentences phrased as unresolved decisions |
| Premise statement | The "Motivation" or "Context" claim describing the gap the issue addresses |

The LLM extraction returns the strict JSON schema below — subagents must validate before printing.

**Step 2 — Run the five detectors.**

| Detector | Verifier action | Finding shape |
|----------|----------------|---------------|
| `file-path-existence` | For each extracted path, test `[ -e <local-tree>/<path> ]`. If missing, also `git -C <local-tree> log --diff-filter=D --name-only -- <path>` to recover the deletion commit. | `quote`, `path`, `evidence` (deletion commit SHA + date if known, else `not found`) |
| `numeric-claim-drift` | For each numeric claim, recompute the count from the working tree. Counting strategy by noun: `skills` → `ls -d <tree>/skills/*/ \| wc -l`; `agents`/`hooks`/`commands` → grep the relevant config; otherwise use the noun's nearest natural counter. If the verifier cannot pick a counter, mark the finding as `unverifiable` and skip — do not invent a number. | `quote`, `claimed`, `actual`, `counter_used` |
| `version-reference-staleness` | For each version reference, check `git -C <local-tree> tag --list` and the `CHANGELOG.md` (if present) for the current version. Flag when the issue references a version that is no longer the latest **and** the surrounding clause asserts something tense-sensitive ("after the v1.0.0 purge", "as of v1.2"). | `quote`, `referenced_version`, `current_version` |
| `resolved-open-question` | For each open-question bullet, search recent commits and the issue's own comment thread for resolution language. Use `git -C <local-tree> log --since=<issue.updatedAt> --grep=<keyword>` plus `gh issue view <NN> --json comments`. Flag only when there is a positively-phrased commit subject or comment ("decided X", "resolved: Y") — do not flag from absence of activity. | `quote`, `evidence` (commit SHA or comment URL) |
| `cross-issue-contradiction` | For each `#NN` reference, look up that sibling in the seeded 1-line excerpts — never refetch full issue bodies. Flag when the excerpt directly negates this issue's claim. If the excerpt is too condensed to confirm or deny a contradiction, return `verdict: unverifiable` for that finding rather than speculating. | `quote`, `sibling_issue`, `sibling_quote` |

**Step 3 — Assign a verdict.**

| Triggering finding(s) | Verdict |
|----------------------|---------|
| Any detector or validation error prevents reliable completion | `unverifiable` |
| No findings | `valid` |
| Any of: file-path / numeric / version / open-question | `stale` |
| Any cross-issue-contradiction | `contradicted` |
| Sibling issue claims to subsume this issue's scope | `superseded by #N` |
| ≥3 distinct detector categories firing | `premise-shifted` |

When multiple verdicts could apply, pick the strongest in this order: `unverifiable` > `premise-shifted` > `superseded by #N` > `contradicted` > `stale` > `valid`.

**Step 4 — Return JSON.**

```yaml
issue_number: 42
verdict: valid | stale | contradicted | superseded by #N | premise-shifted | unverifiable
findings:
  - detector: file-path-existence | numeric-claim-drift | version-reference-staleness | resolved-open-question | cross-issue-contradiction
    quote: "<verbatim from issue body, ≤200 chars>"
    evidence:
      # detector-specific fields from the table above
    proposed_edit: "<one-line concrete edit, or null when verdict is superseded/premise-shifted>"
recommendation: edit | close | skip
```

`recommendation` mapping: any `proposed_edit` populated → `edit`; verdict `premise-shifted` or `superseded by #N` and no fixable proposed edits → `close`; verdict `valid` → `skip`.

Subagents that fail validation must return `verdict: unverifiable` with the validation error in `findings[0].evidence` rather than inventing a partial report. The lead surfaces unverifiable issues at the end of the run; the user decides whether to retry.

Invariant check before returning: `verdict: valid` requires `findings: []` and `recommendation: skip`. Any report where `verdict: valid` but findings are non-empty or recommendation is not `skip` is itself a validation error — return `verdict: unverifiable` instead.

### Phase 3 — Aggregate and print

The lead concatenates the subagent JSON reports in issue-number order and prints a per-issue block to stdout. Block shape:

```
─── #42 — <issue title> — verdict: stale ─────────────────────────
url: https://github.com/<owner>/<repo>/issues/42
findings (3):
  [file-path-existence] "<quote>"
    path: skills/foo/SKILL.md (deleted 2026-04-12, abc1234)
    proposed_edit: remove the "Files touched" line referencing skills/foo/SKILL.md

  [numeric-claim-drift] "11 skills"
    actual: 14 (counter: ls -d skills/*/)
    proposed_edit: update "11 skills" → "14 skills"

  [resolved-open-question] "Should we add a --label filter?"
    evidence: comment https://github.com/<owner>/<repo>/issues/42#issuecomment-…
    proposed_edit: remove the question — answered "no" in the linked comment

recommendation: edit
```

End with a one-line summary: `audit-issues: <total> issues — <valid> valid, <stale> stale, <contradicted> contradicted, <superseded> superseded, <premise-shifted> premise-shifted, <unverifiable> unverifiable`.

### Phase 4 — Interactive `[e]dit / [c]lose / [s]kip`

Walk the per-issue blocks in order. After each block, prompt:

```
[e]dit / [c]lose / [s]kip ?
```

Rules for the prompt:

- `c` is offered **only** when the verdict is `premise-shifted` or `superseded by #N`. For other verdicts, present `[e]dit / [s]kip` and reject `c` if entered.
- `e` triggers an edit preview: show the diff between the current body and the proposed body (with each `proposed_edit` applied), then ask `apply? [y/n]`. On `y`, run `gh issue edit <NN> --repo <owner>/<repo> --body-file <tempfile>`. On `n`, return to the `[e]/[c]/[s]` prompt for that issue.
- `c` triggers a close preview: show the closing comment (auto-drafted from the verdict + linked sibling for `superseded by #N`, or the firing detector summary for `premise-shifted`), then ask `close? [y/n]`. On `y`, run `gh issue close <NN> --repo <owner>/<repo> --comment <body>`. On `n`, return to the prompt.
- `s` advances to the next issue with no mutation.

Emit a final per-issue summary line after the loop: `<applied edits>/<offered edits> applied, <closed>/<offered closes> closed, <skipped>` so the user can confirm the mutations match their intent.

## Output

- Per-issue stdout blocks (Phase 3) followed by the audit summary line.
- Whatever issue-body edits and closes the user confirms in Phase 4 — the durable artifact lives on GitHub, not in this skill's output.

No `AUDIT.md`, no `--save` flag. Producing a parallel report would just re-create the staleness problem one level up.

## Rules

- The handoff-artifact section names (`Acceptance criteria`, `Constraints`, `Prior decisions`, `Evidence`, `Open questions`) are the parse target for both regex and LLM extraction. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the canonical shape — issues authored before that convention may use older headings; fall back to scanning the whole body when the headings are missing.
- Read-only by default. The only mutations are `gh issue edit` and `gh issue close`, and only after explicit per-issue user confirmation.
- Never auto-clone. The local-clone gate is hard — exit with the documented message and let the user clone.
- Never invent a count. If a numeric claim has no obvious counter, mark the finding `unverifiable` and move on.
- Never propose an edit without a quote. Every finding cites a verbatim span from the issue body so the user can locate the change in the diff preview.
- One LLM extraction pass per issue, max. Repeated calls inflate token cost without improving recall — tune the schema instead.
- `gh` invocation patterns mirror `skills/resolve-pr-feedback/SKILL.md`; the audit-classify-recommend shape mirrors `skills/prune/SKILL.md`. Reuse those conventions rather than inventing new ones.
- Premise-supersession (the inferential "this issue's gap is already closed by intervening commits" detector) is deferred to v2. Do not approximate it with the v1 detectors.
