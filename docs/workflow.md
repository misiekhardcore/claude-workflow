# Development Workflow

A step-by-step walkthrough of the feature lifecycle in this repo: which skill runs when, what it expects as input, and what it leaves behind. The rules themselves live in `CLAUDE.md` and in each `skills/<name>/SKILL.md`; this doc stitches them into a single narrative so a newcomer doesn't have to read every `SKILL.md` to understand the flow.

## Workflow paths

Pick the lightest path that fits the task (from `CLAUDE.md`):

| Size | Path |
|---|---|
| Trivial fix | `/implement` |
| Medium feature | `/discovery` → `/implement` |
| Large feature / epic | `/discovery` → `/define` → `/implement` |

Handoff between phases uses the **GitHub issue body** as the durable artifact — see `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the five-field structure. Within a phase, `./.claude/NOTES.md` is authoritative for in-flight state — see `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md`. When context pressure mounts, follow `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` (context editing first, sub-agent delegation second, `/compact` last).

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

---

## Step 1 — `/discovery` (Opus, high effort)

- **File:** `skills/discovery/SKILL.md`
- **When:** Start of any non-trivial feature or bug. Triggered by prompts like "add X" or "fix Y".
- **Prerequisites:** A user-provided problem statement. Nothing else.
- **What it does:** Creates or updates a GitHub epic issue, then classifies scope (Lightweight / Standard / Deep) and dispatches:
  - `/describe` (`skills/describe/SKILL.md`) — a problem analyst + domain researcher interview the user and scan the codebase for existing patterns.
  - `/specify` (`skills/specify/SKILL.md`) — happy-path + edge-case analysts turn the problem statement into testable GIVEN/WHEN/THEN acceptance criteria.
  - On Deep scope, adds a flow analyst and adversarial questioner in parallel.
- **Outcome:** A live GitHub issue containing a problem statement and the five-field handoff block. **User approval is required** before moving on.
- **Hands off to:** `/define` (for large work) or `/implement` (for medium work).

### Five-field handoff block

Every issue body produced by `/discovery` contains exactly these five fields:

1. **Problem statement** — what is broken or missing and why it matters.
2. **Acceptance criteria** — a numbered list of verifiable conditions that define "done".
3. **Out of scope** — explicit exclusions to prevent scope creep.
4. **Open questions** — anything still unresolved that a downstream phase must not silently assume.
5. **References** — links to relevant code, docs, or prior issues.

### Re-run semantics

When `/discovery` runs against an existing issue it **rewrites the five-field block wholesale**. No strikethroughs, no dated sub-headings, no `<details>` folds.

- The preamble reads the full current state (issue body + all comments) before rewriting — this is the knowledge-migration step. Anything worth preserving must make it into the new block consciously.
- If the problem framing has shifted, the problem statement is rewritten. If it has not shifted, it stays byte-identical (no cosmetic rewrites).
- Acceptance criteria follow the same rule: the old list is overwritten.
- **Audit trail:** GitHub's native issue edit history holds every prior version. `/discovery` does not try to replicate it.

### Postamble reconciliation (on AC change)

AC are the contract `/implement` verifies against, so silent changes have blast radius. After rewriting AC, `/discovery` checks for downstream artifacts:

| Situation | Action |
|-----------|--------|
| A PR is already open | Post on the PR: "Acceptance criteria updated in #\<issue\>. Current AC: \<n/n\> still met, \<n\> changed, \<n\> new. Re-run /resolve-pr-feedback or /implement to reconcile." Does **not** close the PR. |
| Sub-issues exist (from a prior `/define`) | Re-derive each sub-issue's AC slice from the new parent AC. Slices that no longer map get a superseded comment + close. |
| Neither applies | Pure overwrite, nothing to reconcile. |

---

## Step 2 — `/define` (Opus, high effort) — *skip for medium features*

- **File:** `skills/define/SKILL.md`
- **When:** After `/discovery`, for epics or architecturally significant work.
- **Prerequisites:** An approved issue from `/discovery` with acceptance criteria.
- **What it does:** Spawns research agents (codebase research + patterns/learnings scan against the claude-obsidian vault via `wiki-query` when available, else skipped with a note), then dispatches:
  - `/architecture` (`skills/architecture/SKILL.md`) — codebase analyst + solution architect + devil's advocate converge on a technical approach, producing component diagrams, trade-off tables, and a sub-task dependency graph. Uses `/grill-me` (`skills/grill-me/SKILL.md`) to pin down open decisions with the user.
  - `/design` (`skills/design/SKILL.md`) — UX researcher + design proposer + a11y reviewer, only when the task has visual aspects. Produces prototypes, wireframes, and interaction flows.
- **Outcome:** The issue body is updated in place with a `## Define Outcome` section (see below), plus any sub-issues created and linked. **User approval is required** before `/implement`.
- **Hands off to:** `/implement`.

### Sub-issue inheritance

Each sub-issue receives the same five-field block inherited from the parent epic, pre-populated with the slice of acceptance criteria it covers.

### `## Define Outcome` block

`/define` writes a `## Define Outcome` section into the epic issue body containing:

- The chosen architecture / decomposition rationale.
- The sub-issue breakdown (list with links) and dependency graph.
- Any decisions made during define that downstream phases must honour.

### Re-run semantics

Re-running `/define` **replaces the `## Define Outcome` block in place**. No collapsed history.

- The preamble reads the existing block before replacing, so architecture decisions still valid are carried forward intentionally (not by accumulation).
- If a sub-issue was linked to a specific architecture decision that no longer appears in the new block, the sub-issue link becomes the only remaining reference — this forces the re-run to confront whether the sub-issue is still valid.

### Postamble reconciliation (stale sub-issues)

When `/define` re-runs and the sub-issue breakdown changes, old sub-issues are reconciled explicitly:

| Sub-issue state | Action |
|-----------------|--------|
| Still maps cleanly to a slice of the new breakdown | Keep it; update its body with the new AC slice. |
| No longer maps | Post comment: "Superseded by re-defined scope in #\<epic\>. Closing unless there's work already in flight." Then close. |
| Maps partially | Leave open; post a comment with the delta; flag in `## Define Outcome` as "needs manual review". |

---

## Step 3 — `/implement` (Sonnet)

- **File:** `skills/implement/SKILL.md`
- **When:** After `/discovery` (medium) or `/define` (large); directly for trivial fixes.
- **Prerequisites:** An approved issue with acceptance criteria (plus architecture/design if it's a large feature).
- **What it does:** Reads the issue and all comments, then orchestrates a `/build → /review → /verify` loop until both pass clean. Maximum 3 cycles before escalating to the user.
  1. **`/build`** (`skills/build/SKILL.md`, Sonnet) — creates a git worktree, initializes `./.claude/NOTES.md`, spawns an implementation team (TeamCreate only for 3+ parallelizable files), writes code test-driven, commits incrementally with semantic messages, and runs lightweight simplification scans every 2–3 tasks.
  2. **`/review`** (`skills/review/SKILL.md`, Sonnet high effort) — reviewers run in isolated context against the diff + AC only. Always-on: correctness + standards. Conditional: security / performance / migration based on diff content. Findings are merged, deduped, and confidence-scored. Reviewers report only — they do not fix.
  3. **`/verify`** (`skills/verify/SKILL.md`, Haiku) — a QA team runs the full verification chain (type-check, lint, unit tests, build, e2e) and checks every acceptance criterion with evidence. Reports pass/fail only — it does not fix.
  - If review or verify finds issues, a fix-brief (failing AC + file:line findings) is fed back to `/build`, then re-reviewed and re-verified.
- **Outcome:** A draft PR linking the issue. All acceptance criteria met, review clean, verify clean. `/compound` runs automatically before the PR is opened.
- **Follow-up:** After human review, use `/resolve-pr-feedback`.

### Preamble (read before doing anything)

Before writing any code, `/implement` fetches the issue body **and all comments**. Any comment newer than the last `## Define Outcome` update is treated as material input. If conflicting information is found, `/implement` **halts and asks** — it never silently picks one interpretation.

### Issue comments posted by `/implement`

One comment per meaningful state change. Never more.

| Checkpoint | Comment |
|-----------|---------|
| **Start** | `🤖 Starting implementation. Working from ## Define Outcome (last updated <date>). Branch: <branch>. Will post again when a draft PR is open or if the fix-cycle escalates to needs-human.` |
| **Escalation** (only if max fix-cycle iterations hit or an AC cannot be met) | `🤖 Fix-cycle escalated after N iterations. Blocking issue: <one-line>. Details: <fold with reviewer findings and failing AC>. Need guidance before continuing.` |
| **PR open** | `🤖 Draft PR opened: #<n>. AC status: <n/n met>. Review + verify clean. Ready for human review.` |
| **Consolidation** (only if `/compound` filed new wiki notes) | `🤖 Captured learnings: <note title>` (or `inline` when claude-obsidian is not installed). |

Not posted: per-commit updates, per-fix-cycle-iteration noise, internal reviewer findings (those belong in the fix-brief, not the issue thread).

### PR body wording

| Situation | PR body contains |
|-----------|-----------------|
| PR delivers the full epic | `Closes #<epic>` |
| PR delivers one sub-issue of many | `Part of #<epic>` |

---

## Step 4 — `/compound` (Sonnet)

- **File:** `skills/compound/SKILL.md`
- **When:** Automatically after a successful `/implement`. Not a separate user invocation — it is part of `/implement`'s postamble.
- **What it does:** Extracts the learning and drafts it using **Bug Track** (Problem / Symptoms / What Didn't Work / Solution / Why It Works / Prevention) or **Knowledge Track** (Context / Guidance / Why / When / Examples) format, then checks for overlap with existing knowledge via `claude-obsidian:wiki-query` when available. Filing is delegated: if `claude-obsidian:save` is available, `/save` places the note in the vault, attaches frontmatter, cross-links, updates the hot cache, and appends a log entry. If `claude-obsidian` is not installed, the drafted note is emitted inline for the user to capture into whatever knowledge store they prefer.
- **Outcome:** Either a durable vault note (when `claude-obsidian` is active) or a structured Markdown block in the response. Never auto-deletes or overwrites without flagging.

---

## Step 5 — `/resolve-pr-feedback` (Sonnet)

- **File:** `skills/resolve-pr-feedback/SKILL.md`
- **When:** After a PR receives human review comments.
- **What it does:** Fetches all review threads, triages them, spawns a fix team (one agent per disjoint file group), runs up to 2 fix-verify cycles per review round, then posts a verdict reply on every thread and resolves threads where appropriate.
- **Outcome:** PR feedback processed in bulk with verdict replies posted, and resolved threads marked resolved. Safe to re-run for subsequent review rounds.

### Verdict table

| Verdict | Reply posted? | Thread resolved? | Rationale |
|---------|--------------|-----------------|-----------|
| `fixed` | Yes — with commit SHA | Yes — auto-resolve | Acted on the request exactly as asked. |
| `fixed-differently` | Yes — with rationale + commit SHA | Yes — auto-resolve | Addressed the underlying concern; reviewer can re-open if unhappy. |
| `replied` | Yes — discussion only, no code change | No — leave open | Asking or disagreeing; reviewer owns the next move. |
| `not-addressing` | Yes — with rationale | No — leave open | Declining is a human-to-human decision; reviewer resolves it (or insists). |
| `needs-human` | Yes — escalation context | No — leave open | Could not act confidently; leaving open keeps it visible on the unresolved count. |

### Verdict tag in reply

Every reply ends with a machine-readable tag so future runs can skip already-handled threads:

```
Fixed in abc1234 — replaced the N+1 loop with a single JOIN (benchmarks in commit body).
<!-- verdict: fixed -->
```

### Idempotency and re-opened threads

`/resolve-pr-feedback` fetches the current state of each thread before acting. If it sees its own previous verdict tag and no new comments since, it skips that thread. If a reviewer unresolves a thread `/resolve-pr-feedback` previously resolved, the next run treats it as a fresh triage entry (up to the 2-cycle cap per round).

---

## Step 6 — `/wrap-up` (Sonnet) — *optional, end of session*

- **File:** `skills/wrap-up/SKILL.md`
- **When:** End of a long or complex session, or when transitioning between phases mid-work.
- **What it does:** Reads `./.claude/NOTES.md`, identifies assumptions, uncertain decisions, scope changes, and follow-ups, then drafts an update to the active issue body (never auto-applies).
- **Outcome:** An audit block the user can paste into the issue — Assumptions Made / Uncertain Decisions / Scope Notes / Follow-ups.

---

## Consistency rule: replace in place

The following three regions are always rewritten in place on re-run. None accumulate history inline.

| Region | Written by |
|--------|-----------|
| Problem statement | `/discovery` |
| Acceptance criteria | `/discovery` |
| `## Define Outcome` block | `/define` |

Each re-running phase reads the existing region before overwriting so carry-forwards are deliberate. Stale downstream artifacts (sub-issues, open PRs) get a reconciliation pass in the phase's postamble.

---

## Audit surface

No phase contract tries to be its own audit log. The canonical audit sources are:

1. **GitHub edit history** — every prior version of issue/PR bodies.
2. **Issue comments from `/implement` checkpoints** — a permanent timeline (comments are not edited, only added).
3. **The claude-obsidian vault** (optional) — when installed, any note filed via `/compound` → `/save` plus the corresponding entry in the vault log is the permanent record of "the second attempt shipped this way". Without `claude-obsidian`, this tier is absent; the `/compound` inline output serves the same purpose but relies on the user to persist it.

All three are read-only from the perspective of downstream phases.

---

## Memory hierarchy

Four tiers, no overlap:

| Tier | Location | Lifetime | Authoritative for |
|---|---|---|---|
| `TodoWrite` | In-context | This session only | Throwaway working scratchpad |
| `./.claude/NOTES.md` | Worktree-local | This phase, across sessions | In-flight decisions, current task, open questions |
| GitHub issue body | Remote | Cross-phase | Acceptance criteria, prior-phase decisions, handoff state |
| Durable vault (optional) | The claude-obsidian vault (git-tracked) | Durable, cross-feature | Compounded knowledge — bug-fix history, patterns, architectural insights (written by `/compound` via `/save` when the plugin is installed) |

---

## Maintenance — `/prune` (Haiku)

- **File:** `skills/prune/SKILL.md`
- **When:** Monthly, or after major refactors.
- **What it does:** Audits `CLAUDE.md` and auto-memory files for stale / superseded / unclear entries (semantic staleness). When `claude-obsidian` is installed, delegates the vault audit to `wiki-lint` (structural health — orphans, broken wikilinks, missing frontmatter) and folds the findings in. Without `claude-obsidian`, the vault lane is skipped with a one-line note. Never auto-deletes — produces recommendations for user approval.
