# Development Workflow

Step-by-step walkthrough of the feature lifecycle: which skill runs when, what it expects, and what it leaves behind. For the underlying composition model — composition patterns, skill roles, brief contracts — see `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

## Workflow paths

|Size|Path|
|-|-|
|Trivial fix|`/implement`|
|Medium feature|`/discovery` → `/implement`|
|Large feature / epic|`/discovery` → `/define` → `/implement`|

Handoff between phases uses the **GitHub issue body** as the durable artifact (five-field structure in `_shared/handoff-artifact.md`). Within a phase, `./.claude/NOTES.md` is authoritative for in-flight state (`_shared/notes-md-protocol.md`). On context pressure, follow `_shared/compaction-protocol.md` (context editing → sub-agent delegation → `/compact` last).

## Quick visual

```
/discovery ──► (issue w/ AC + handoff) ──► /define ──► (issue w/ arch+design) ──► /implement
                                                                                       │
                                                                        ┌──────────────┼──────────────┐
                                                                        ▼              ▼              ▼
                                                                     /build  ──►   /review    ─►  /verify
                                                                        ▲              │              │
                                                                        └── fix-brief ◄┴──────────────┘
                                                                                       │ (both clean)
                                                                                       ▼
                                                                              draft PR + /compound
                                                                                       │
                                                                              [human reviews PR]
                                                                                       │
                                                                              /resolve-pr-feedback
```

## Step 1 — `/discovery` (Opus, high effort)

**When**: Start of any non-trivial feature or bug.
**Input**: User-provided problem statement.
**What it does**: Creates or updates a GitHub epic issue, classifies scope (Lightweight/Standard/Deep), and dispatches:
  - `/describe` — problem analyst + domain researcher interview the user and scan for patterns.
  - `/specify` — happy-path + edge-case analysts turn the problem into testable GIVEN/WHEN/THEN AC.
  - On Deep scope, adds a flow analyst and adversarial questioner in parallel.
**Output**: Live GitHub issue with problem statement and five-field handoff block. **User approval required**.
**Hands off to**: `/define` (large) or `/implement` (medium).

### Five-field handoff block

Every issue from `/discovery` contains:
1. **Problem statement** — what is broken or missing.
2. **Acceptance criteria** — verifiable conditions that define "done".
3. **Out of scope** — explicit exclusions.
4. **Open questions** — anything still unresolved.
5. **References** — links to relevant code, docs, prior issues.

### Re-run semantics

`/discovery` **rewrites the five-field block wholesale** — no strikethroughs, no folds. The preamble reads the full current state (issue body + comments) before rewriting (knowledge-migration). If the problem framing shifted, the problem statement is rewritten. If not, it stays byte-identical. Acceptance criteria follow the same rule.

**Audit trail**: GitHub's native edit history holds every prior version.

### Postamble reconciliation (on AC change)

AC are the `/implement` verification contract, so silent changes have blast radius.

|Situation|Action|
|-|-|
|PR already open|Post: "Acceptance criteria updated in #<issue>. Current AC: <n/n met>, <n> changed, <n> new. Re-run /resolve-pr-feedback or /implement to reconcile." Does NOT close PR.|
|Sub-issues exist (from prior `/define`)|Re-derive each sub-issue's AC slice. Slices that no longer map get a superseded comment + close.|
|Neither|Pure overwrite.|

## Step 2 — `/define` (Opus, high effort) — _skip for medium features_

**When**: After `/discovery`, for epics or architecturally significant work.
**Input**: Approved issue with acceptance criteria.
**What it does**: Spawns research agents, then dispatches:
  - `/architecture` — codebase analyst + solution architect + devil's advocate converge on a technical approach. Produces component diagrams, trade-off tables, and sub-task dependency graph. Uses `/grill-me` to pin down open decisions.
  - `/design` — UX researcher + design proposer + a11y reviewer (only when the task has visual aspects). Produces prototypes, wireframes, interaction flows.
**Output**: Issue body updated in place with `## Implementation plan` section plus any sub-issues created and linked. **User approval required**.
**Hands off to**: `/implement`.

### Sub-issue inheritance

Each sub-issue receives the same five-field block from the parent epic, pre-populated with the AC slice it covers.

### `## Implementation plan` block

`/define` writes:
- The chosen architecture / decomposition rationale.
- Sub-issue breakdown (list with links) and dependency graph.
- Decisions the next phase must honour.

### Re-run semantics

**Replaces the `## Implementation plan` block in place** — no collapsed history. The preamble reads the existing block before replacing so valid architecture decisions are carried forward intentionally. If a sub-issue no longer maps to a specific decision, the sub-issue link becomes the only remaining reference — forcing the re-run to confront whether the sub-issue is still valid.

### Postamble reconciliation (stale sub-issues)

|Sub-issue state|Action|
|-|-|
|Still maps to a slice|Keep it; update its body with the new AC slice.|
|No longer maps|Post comment: "Superseded by re-defined scope. Closing unless work is in flight." Then close.|
|Maps partially|Leave open; post a comment with the delta; flag in `## Implementation plan` as "needs manual review".|

## Step 3 — `/implement` (Sonnet)

**When**: After `/discovery` (medium) or `/define` (large); directly for trivial fixes.
**Input**: Approved issue with acceptance criteria (plus architecture/design if large).
**What it does**: Reads the issue and all comments, then orchestrates a `/build → /review → /verify` loop until both pass clean. Maximum 3 cycles before escalating.
  1. **`/build`** (Sonnet) — creates a git worktree, initializes `./.claude/NOTES.md`, spawns an implementation team (TeamCreate only for 3+ parallelizable files), writes code test-driven, commits incrementally, runs lightweight simplification scans every 2–3 tasks.
  2. **`/review`** (Sonnet high effort) — reviewers run in isolated context against diff + AC only. Always-on: correctness + standards. Conditional: security / performance / migration. Findings merged, deduped, confidence-scored. Reviewers report only — they do not fix.
  3. **`/verify`** (Haiku) — QA team runs full verification chain (type-check, lint, unit tests, build, e2e) and checks every AC with evidence. Reports pass/fail only.
  - If review or verify finds issues, a fix-brief (failing AC + file:line findings) feeds back to `/build`.
**Output**: Draft PR linking the issue. All AC met, review clean, verify clean. `/compound` runs automatically before PR is opened.
**Follow-up**: After human review, use `/resolve-pr-feedback`.

### Preamble (read before any work)

Before writing any code, `/implement` fetches the issue body **and all comments**. Any comment newer than the last `## Implementation plan` update is material input. On conflicting information, `/implement` **halts and asks** — never silently picks one interpretation.

### Issue comments from `/implement`

One comment per meaningful state change:

|Checkpoint|Comment|
|-|-|
|**Start**|`Starting implementation. Working from ## Implementation plan (last updated <date>). Branch: <branch>. Will post again when a draft PR is open or if the fix-cycle escalates.`|
|**Escalation**|`Fix-cycle escalated after N iterations. Blocking issue: <one-line>. Details: <findings + failing AC>. Need guidance.`|
|**PR open**|`Draft PR opened: #<n>. AC status: <n/n met>. Review + verify clean. Ready for human review.`|
|**Consolidation**|`Captured learnings: <note title>` (or `inline` when claude-obsidian is not installed).|

Not posted: per-commit updates, per-iteration noise, internal reviewer findings (those belong in the fix-brief).

### PR body wording

|Situation|PR body contains|
|-|-|
|PR delivers the full epic|`Closes #<epic>`|
|PR delivers one sub-issue|`Part of #<epic>`|

Fixed three-section template: **Summary** / **Testing notes** / **Notes**. Before pushing, `/implement` reads `./.claude/NOTES.md` and harvests `## Decisions made this session` and `## Open questions` into the `## Notes` section, then deletes NOTES.md after `/compound` runs. The `## Notes` section is omitted when there is nothing to record.

## Step 4 — `/compound` (Sonnet)

**When**: Automatically after successful `/implement`. Not a separate user invocation.
**What it does**: Extracts learning and drafts using **Bug Track** (Problem / Symptoms / What Didn't Work / Solution / Why It Works / Prevention) or **Knowledge Track** (Context / Guidance / Why / When / Examples) format. Checks overlap with existing knowledge via `claude-obsidian:wiki-query` when available. Filing is delegated: if `claude-obsidian:save` is available, `/save` places the note in the vault, attaches frontmatter, cross-links, updates the hot cache. If not, the drafted note is emitted inline.
**Output**: Either a durable vault note (when `claude-obsidian` is active) or a structured Markdown block. Never auto-deletes or overwrites without flagging.

## Step 5 — `/resolve-pr-feedback` (Sonnet)

**When**: After a PR receives human review comments.
**What it does**: Fetches all review threads, triages them, spawns a fix team (one agent per disjoint file group), runs up to 2 fix-verify cycles per review round, posts verdict replies on every thread.
**Output**: PR feedback processed in bulk with verdict replies and resolved threads marked resolved. Safe to re-run for subsequent review rounds.

### Verdict table

|Verdict|Reply|Resolved|Rationale|
|-|-|-|-|
|`fixed`|Yes — with SHA|Yes — auto|Acted exactly as asked.|
|`fixed-differently`|Yes — with rationale + SHA|Yes — auto|Addressed underlying concern.|
|`replied`|Yes — discussion only|No|Asking or disagreeing; reviewer owns next move.|
|`not-addressing`|Yes — with rationale|No|Declining is human-to-human; reviewer resolves.|
|`needs-human`|Yes — escalation context|No|Could not act confidently; keeps it visible.|

### Verdict tag in reply

Every reply ends with a machine-readable tag for idempotency:

```
Fixed in abc1234 — replaced the N+1 loop with a single JOIN.
<!-- verdict: fixed -->
```

### Idempotency and re-opened threads

`/resolve-pr-feedback` fetches current state before acting. If it sees its previous verdict tag and no new comments since, it skips that thread. If a reviewer unresolves a thread, the next run treats it fresh (up to 2-cycle cap).

## Step 6 — `/wrap-up` (Sonnet) — _optional, after PR is open_

**When**: After draft PR is open and feature worktree is no longer needed.
**What it does**: Removes feature worktree, deletes branch, clears `./.claude/NOTES.md`. Refuses on default branch or out-of-tree paths. On dirty worktree, surfaces unpushed/uncommitted state and requires explicit proceed-anyway confirmation. **Not** an audit utility — assumptions and follow-ups are harvested into PR body by `/implement`.
**Output**: Worktree directory gone, branch deleted, NOTES.md removed.

## Consistency rule: replace in place

Three regions are always rewritten in place on re-run:

|Region|Written by|
|-|-|
|Problem statement|`/discovery`|
|Acceptance criteria|`/discovery`|
|`## Implementation plan` block|`/define`|

Each re-running phase reads the existing region before overwriting so carry-forwards are deliberate. Stale downstream artifacts get a reconciliation pass in the phase's postamble.

## Audit surface

No phase tries to be its own audit log. Canonical sources:

1. **GitHub edit history** — every prior version of issue/PR bodies.
2. **Issue comments from `/implement` checkpoints** — permanent timeline (never edited, only added).
3. **The claude-obsidian vault** (optional) — notes filed via `/compound` → `/save` plus log entry. Without `claude-obsidian`, the `/compound` inline output serves the same purpose if the user persists it.

All three are read-only from downstream phases.

## Memory hierarchy

Four tiers, no overlap:

|Tier|Location|Lifetime|Authoritative for|
|-|-|-|-|
|Scratchpad|In-context|This session only|Throwaway working scratchpad|
|`./.claude/NOTES.md`|Worktree-local|This phase, across sessions|In-flight decisions, current task, open questions|
|GitHub issue body|Remote|Cross-phase|Acceptance criteria, prior-phase decisions, handoff state|
|Durable vault|claude-obsidian vault (git-tracked)|Durable, cross-feature|Compounded knowledge — bug-fix history, patterns, architectural insights|

## Maintenance — `/prune` (Haiku, dispatches to Task sub-agents)

**When**: Monthly or after major refactors.
**What it does**: Spawns three parallel Task sub-agents (rules, authoring, vault lanes), collects reports, synthesizes findings. Rules lane audits CLAUDE.md and auto-memory for stale/superseded/unclear entries. Authoring lane scans SKILL.md/AGENTS.md/CLAUDE.md for structural issues. When `claude-obsidian` is installed, vault lane delegates to `wiki-lint` and probes for semantic staleness. Without it, vault lane is skipped. Never auto-deletes — produces recommendations for user approval.

## Maintenance — `/audit-issues` (Sonnet)

**When**: Periodically or after a refactor.
**What it does**: Audits open GitHub issues against current working tree. Runs five drift detectors (file-path-existence, numeric-claim-drift, version-reference-staleness, resolved-open-question, cross-issue-contradiction) and assigns verdicts. Offers per-issue interactive `[e]dit / [c]lose / [s]kip` actions. Requires a local clone at `~/Projects/<repo>`.
**Output**: Issue bodies edited or closed where the user approved; a stdout summary.

## Autonomous variant — `/epic-autopilot` (Opus, high effort)

**When**: Large epics where you want the full `/discovery → /define → /implement` chain to run end-to-end with minimal supervision.
**What it does**: Five-stage orchestrator with explicit human gates after `/discovery`, after epic-level `/define`, after each per-sub-issue `/define`. Once all sub-issues are gated, the autonomous phase opens the epic branch, computes a Kahn topological sort of the dependency graph, dispatches `/implement` per tier as parallel Task subagents, opens draft sub-PRs plus epic PR. Suppresses `/implement`'s exhausted-exit prompt via `autonomous: true` flag. Resumable from any stage via markers in epic issue body.
**Output**: Draft epic PR targeting `main` and one draft sub-PR per sub-issue (`Part of #<epic>`), with merge-order advisory in epic PR body.
