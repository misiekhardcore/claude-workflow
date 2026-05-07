---
name: audit-issues
description: Audit open GitHub issues for staleness vs. current repo state. Flags broken file refs, stale counts, resolved questions, cross-issue contradictions.
argument-hint: "[owner/repo | #NN | owner/repo#NN]"
model: sonnet
---
You are auditing open GitHub issues for drift against the current state of their repository. Issues queued weeks or months ago accumulate broken file references, stale numeric claims, version references, resolved open questions, and cross-issue contradictions; this skill detects that drift and offers per-issue fix-or-close actions.

This is a read-first, mutate-on-confirm utility. The product is the **updated set of issues themselves** — there is no parallel report artifact.

## Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Per-issue audit fan-out**: one Task subagent per audited issue, each running extraction + verification, returning structured JSON. Lead aggregates and prints. Parallel for ≥3 issues.

Skip the fan-out when only one issue is targeted (`#NN` form) — run extraction + verification inline.

## Input

Positional argument forms (no flags):

|Form|Meaning|
|-|-|
|_(empty)_|Audit all open issues in the repo of the current working directory.|
|`owner/repo`|Audit all open issues in `owner/repo`.|
|`#NN`|Audit a single issue in the current repo.|
|`#NN #MM …`|Audit a specific subset in the current repo.|
|`owner/repo#NN`|Audit a single issue in a different repo.|

## Process

### Phase 0 — Target resolution and local-clone gate

1. Parse the argument into `(owner, repo, issue_numbers | null)`.
   - Empty arg → resolve `owner/repo` from `git remote -v` in cwd; `issue_numbers = null`.
   - `owner/repo` form → use directly; `issue_numbers = null`.
   - `#NN[ #MM …]` → resolve repo from cwd; `issue_numbers = [NN, …]`.
   - `owner/repo#NN` → split on `#`; `issue_numbers = [NN]`.

2. Resolve the local working tree at `~/Projects/<repo>` (directory part after the slash).

3. **If the local working tree is missing or points at a different remote**, abort with:
   ```
   audit-issues: local clone of <owner>/<repo> not found at ~/Projects/<repo>.
   clone owner/repo first, then re-run.
   ```
   Do not auto-clone.

4. Pull the latest default branch:
   - Run `git -C <local-tree> fetch --quiet origin`. If fetch fails, warn and continue with cached HEAD.
   - Run `git -C <local-tree> rev-parse --abbrev-ref origin/HEAD` to identify the default branch. If fails, abort: `audit-issues: cannot determine default branch; run 'git remote set-head origin -a' and retry.`
   - Never check out the default branch. All verifiers read from fetched ref (`origin/HEAD`) directly via `git show`, `git ls-tree`, `git log`.

### Phase 1 — Fetch issues once at the lead

**Targeted form (`#NN`, `#NN #MM …`, `owner/repo#NN`)**:

```bash
gh issue view <NN> --repo <owner>/<repo> \
  --json number,title,body,labels,updatedAt,createdAt,url,state

gh issue list --repo <owner>/<repo> --state open --limit 0 \
  --json number,title,body,updatedAt
```

If any requested issue's state is `closed`, abort: `audit-issues: #<NN> is closed; auditing closed issues is out of scope for v1.`

**All-open form (empty arg or `owner/repo`)**:

```bash
gh issue list --repo <owner>/<repo> --state open --limit 0 \
  --json number,title,body,labels,updatedAt,createdAt,url
```

Use `--limit 0` for unbounded pagination. Skip closed issues.

### Phase 2 — Per-issue audit (subagent fan-out)

**Single-issue shortcut:** If targeting exactly one issue, run inline — no Task dispatch. Otherwise, spawn one Task subagent per issue in parallel.

Seed each execution with:

- Full body of the assigned issue.
- Titles + numbers + 1-line `Prior decisions` excerpts of every other open issue (for cross-issue checks).
- Absolute path of the local working tree.
- The verifier contract below.

#### Subagent contract

Each subagent runs five detectors and returns structured JSON. Treat the issue body as the source of claims; treat fetched `<default-ref>` as ground truth.

**Step 1 — Hybrid claim extraction**

Regex pass (deterministic):

|Claim type|Pattern intent|
|-|-|
|File path|Paths in `` `backticks` `` or bare paths matching top-level dirs|
|Numeric claim|"<number> <plural noun>" tied to a repo concept (skills, files, agents, lines)|
|Version reference|`vX.Y[.Z]`, "the X.Y MCP purge", or pinned versions|

LLM pass (one call per issue; grounded in regex output):

|Claim type|Extract|
|-|-|
|Cross-issue reference|`#NN` mentions in *Prior decisions* / body with dependency clause|
|Open question|Bullets under *Open questions* heading or unresolved decisions|
|Premise statement|"Motivation" or "Context" claim describing the gap|

**Step 2 — Run the five detectors**

|Detector|Action|Finding|
|-|-|-|
|`file-path-existence`|Test `git ls-tree -r <default-ref> -- <path>`. If missing, `git log <default-ref> --diff-filter=D -- <path>` to recover deletion commit.|`quote`, `path`, `evidence` (deletion commit SHA or `not found`)|
|`numeric-claim-drift`|Recompute count from `<default-ref>`. Noun strategies: `skills` → `git ls-tree -d skills/`; `agents`/`hooks`/`commands` → grep config; else natural counter. Mark `unverifiable` if no counter.|`quote`, `claimed`, `actual`, `counter_used`|
|`version-reference-staleness`|Check `git tag --list` and `git show <default-ref>:CHANGELOG.md`. Flag tense-sensitive references ("after the v1.0.0 purge").|`quote`, `referenced_version`, `current_version`|
|`resolved-open-question`|Search issue history for resolution language. Lower bound for `git log --since` is `min(issue.createdAt, oldest_comment_timestamp)`. Flag only from positive language ("decided X", "resolved: Y").|`quote`, `evidence` (commit SHA or comment URL)|
|`cross-issue-contradiction`|Scan **every** sibling excerpt, not only linked references. Check if sibling asserts something covering this issue's claim domain and negates it. Return `unverifiable` if excerpt too condensed to confirm. Deduplicate by sibling number.|`quote`, `sibling_issue`, `sibling_quote`, `match_kind` (`linked`\|`unlinked`)|

**Step 3 — Assign a verdict**

|Findings|Verdict|
|-|-|
|Any detector or validation error|`unverifiable`|
|No findings|`valid`|
|Any of: file-path / numeric / version / open-question|`stale`|
|Any cross-issue-contradiction|`contradicted`|
|Sibling subsumes this issue's scope|`superseded by #N`|
|≥3 distinct detector categories|`premise-shifted`|

When multiple verdicts apply, pick strongest order: `unverifiable` > `premise-shifted` > `superseded by #N` > `contradicted` > `stale` > `valid`.

**Step 4 — Return JSON**

```yaml
issue_number: 42
verdict: valid | stale | contradicted | superseded by #N | premise-shifted | unverifiable
findings:
  - detector: file-path-existence | numeric-claim-drift | version-reference-staleness | resolved-open-question | cross-issue-contradiction
    quote: "<verbatim from issue body, ≤200 chars>"
    evidence: # detector-specific fields
    proposed_edit: "<one-line concrete edit, or null>"
recommendation: edit | close | skip
```

Mapping: any `proposed_edit` → `edit`; verdict `premise-shifted` or `superseded by #N` → `close`; verdict `valid` → `skip`.

Invariant: `verdict: valid` requires `findings: []` and `recommendation: skip`. Otherwise return `verdict: unverifiable`.

### Phase 3 — Aggregate and print

Concatenate JSON reports in issue-number order. Per-issue block format:

```
─── #42 — <issue title> — verdict: stale ─────────────────────────
url: https://github.com/<owner>/<repo>/issues/42
findings (3):
  [file-path-existence] "<quote>"
    path: skills/foo/SKILL.md (deleted 2026-04-12, abc1234)
    proposed_edit: remove the "Files touched" line referencing skills/foo/SKILL.md
```

End with: `audit-issues: <total> issues — <valid> valid, <stale> stale, <contradicted> contradicted, <superseded> superseded, <premise-shifted> premise-shifted, <unverifiable> unverifiable`.

### Phase 4 — Interactive `[e]dit / [c]lose / [s]kip`

Walk blocks in order. After each, prompt based on verdict:

|Verdict|Prompt|
|-|-|
|`valid`|`[s]kip ?`|
|`stale`, `contradicted`, `unverifiable`|`[e]dit / [s]kip ?`|
|`premise-shifted`, `superseded by #N`|`[e]dit / [c]lose / [s]kip ?`|

Rules for the prompt:

- Closeable verdicts are exactly `{premise-shifted, superseded by #N}`. Reject `c` when verdict is outside that set.
- `e` shows diff between current and proposed body (all `proposed_edit` applied), then ask `apply? [y/n]`. On `y`, run `gh issue edit <NN> --repo <owner>/<repo> --body-file <tempfile>`.
- `c` shows closing comment (auto-drafted from verdict + linked sibling for `superseded by #N`, or detector summary for `premise-shifted`), then ask `close? [y/n]`. On `y`, post and close safely:
  ```bash
  tmp=$(mktemp); printf '%s' "$body" > "$tmp"
  gh issue comment <NN> --repo <owner>/<repo> --body-file "$tmp"
  gh issue close   <NN> --repo <owner>/<repo> --reason "not planned"
  rm -f "$tmp"
  ```
  Never use `gh issue close --comment` — inline interpolation breaks on metacharacters.
- `s` advances to next issue with no mutation.

Emit final summary: `<applied edits>/<offered edits> applied, <closed>/<offered closes> closed, <skipped>`.

## Output

- Per-issue stdout blocks (Phase 3) followed by the audit summary line.
- Whatever issue-body edits and closes the user confirms in Phase 4.

No `AUDIT.md`, no `--save` flag.

## Rules

- Handoff-artifact section names (`Acceptance criteria`, `Constraints`, `Prior decisions`, `Evidence`, `Open questions`) are parse targets. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.
- Read-only by default. Only mutations are `gh issue edit` and `gh issue close`, and only after explicit per-issue user confirmation.
- Never auto-clone.
- Never invent a count. If a numeric claim has no obvious counter, mark `unverifiable` and move on.
- Never propose an edit without a quote.
- One LLM extraction pass per issue, max.
- Mirror `skills/resolve-pr-feedback/SKILL.md` for `gh` invocation patterns.
- Premise-supersession (inferential "this issue's gap is already closed by intervening commits") is deferred to v2.
