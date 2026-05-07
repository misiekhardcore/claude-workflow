# Context Hygiene Between Workflow Phases

Why this plugin treats phase boundaries as context resets, and the four rules that enable it.

## The problem

Multi-phase workflow — `/discovery` → `/define` → `/implement` (build → review → verify) → `/wrap-up` → `/compound` — accumulates context in two failure modes:

1. **Within a phase**: stale tool outputs (rejected approaches, superseded reads, replayed tests) cause early framings to over-anchor.
2. **Between phases**: interview-shaped reasoning (`/discovery`) dilutes attention when you need architecture reasoning (`/define`) or code-editing focus (`/implement`).

The fix: **keep working context focused on the current concept**. The rules below implement this.

## Four rules (in order)

### 1. Reset between phases — phases are concept boundaries

Each phase has a different reasoning shape. The GitHub **issue body** is the handoff artifact — always updated in place, never posted as comments. End each phase by editing the issue with the decisions and state the next phase needs, then start the next phase in a fresh session.

Reference: Anthropic's [Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps):
> "A reset provides a clean slate, at the cost of the handoff artifact having enough state for the next agent to pick up the work cleanly."

The artifact has a fixed shape (Problem statement, Acceptance criteria, Out of scope, Open questions, References) defined in `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.

### 2. Within a phase, prefer context editing over summarization; trigger on concept shifts

Inside a phase, stale tool output is the dominant rot source. **Context editing** — clearing tool results verbatim — removes rot at its source without paraphrasing.

Reference: Anthropic's [Managing context on the Claude Developer Platform](https://www.anthropic.com/news/context-management):
> "Context editing enabled agents to complete workflows that would otherwise fail due to context exhaustion — while reducing token consumption by 84%."

Summarization-based `/compact` is a **last resort**. From Anthropic's [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):
> "Preserve architectural decisions, unresolved bugs, and implementation details while discarding redundant tool outputs."

Trigger compaction on **concept shifts**, not percentages. See `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` for the full trigger list and tool order (context editing → sub-agent → `/compact` last).

### 3. Delegate bulk tool output to sub-agents, not just exploration

Sub-agent isolation is **structurally rot-proof** — the lead session never sees the rotted context.

Reference: Anthropic's [Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):
> "Each subagent might explore extensively, using tens of thousands of tokens, but returns only a condensed distilled summary (1,000–2,000 tokens), achieving clear separation of concerns where detailed search context remains isolated."

**Rule**: anything producing bulk tool output should run in a sub-agent that returns a distilled report. Use Glob/Grep for narrow lookups; use sub-agents for broader exploration or anything likely to generate large output volumes.

Delegate on these smells (from `_templates/AUTHORING.md`):
- **File-sweep**: reading ≥5 files in a loop before synthesis.
- **Fan-out**: iterating over N independent items with similar processing per item.
- **Thin-synthesis**: retrieval/formatting only; the lead's role is receiving a summary.
- **Verbose-tool-output**: a single tool call returns verbose output; only a small set of fields is used.

In this workflow:
- `/review` receives the diff, not the build history.
- `/verify` gets only the acceptance criteria plus running code, never the build session.
- `/build` should delegate to an Explore sub-agent for understanding unfamiliar code, parsing long logs, reading API docs, or grepping wide paths. Ask for a focused report bounded by what the lead needs.
- Pass briefs, not session history. Sub-agents need objective + constraint + "what to report" — not the conversation that led you to spawn them.

### 4. Persist end-of-phase state into the issue body before the session ends

At phase boundaries (`/discovery`, `/define`), the orchestrator edits the GitHub **issue body** with the handoff artifact so state survives the context reset.

For `/implement`: this phase is terminal — output is the PR, not an issue-body update. End-of-phase state (assumptions, uncertainties, follow-ups) flows into the PR body's `## Notes` section. `/wrap-up` is now a cleanup utility (worktree + branch removal), not a phase-boundary skill.

## Why these rules work

From first-party sources:

1. **Context rot is the binding constraint, not window size.** Retrieval, reasoning, and instruction-following degrade as unrelated concepts accumulate, well before the window fills. Bigger windows don't help you attend better.

2. **Context editing strictly dominates summarization for tool-output bulk.** Clearing stale results removes rot without paraphrasing. Summarization both compresses AND introduces a new lower-fidelity anchor — partial fix with its own failure mode. Anthropic's 84% token-reduction figure measures the right thing.

3. **Sub-agent isolation is empirically effective.** Tens of thousands of tokens of exploration → 1–2k token report. The lead reasons over the distilled results and never sees the rotted context.

Note: Opus 4.5/4.6 dropped context resets for single-concept long-running agents ([Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)). Multi-concept session bloat across `/discovery`, `/define`, `/implement` is a different problem — rot still applies.

## When to use

- **Rule 1** (reset + artifact): every phase boundary, always.
- **Rules 2 and 3**: within a phase, whenever a concept shift occurs. See `_shared/compaction-protocol.md` for trigger list and tool order.
- **Rule 4**: every phase boundary. `/discover` and `/define` write to issue body; `/implement` writes to PR body. `/wrap-up` is cleanup, not phase-boundary.

## Examples

### Structured handoff artifact (filled)

Before resetting, paste this into the issue body:

```markdown
## Implementation plan

**Acceptance criteria** (unchanged)
- AC1: CSV export button appears on /reports for users with `reports.read`
- AC2: Export respects current filters
- AC3: File downloads within 5s for ≤50k rows

**Constraints**
- In scope: app/reports/**, app/lib/csv.ts (new)
- Out of scope: server-side streaming, S3 upload
- Reuse existing filter state from ReportsContext

**Prior decisions**
- Client-side via Papa Parse (no infra change for ≤50k)
- Button in ReportsToolbar, not inside table
- No progress indicator in v1

**Evidence**
- Benchmark: 50k rows → 1.4s in Chrome (thread, 2026-04-12)
- Design review: figma.com/... (approved)

**Open questions**
- Empty result sets: empty file or toast? (defer to /build)
```

### Summarization-based `/compact` with preservation note

Use only when context editing won't address pressure. Never blind:

```
/compact

Keep: issue #482 acceptance criteria; ReportsToolbar client-side Papa Parse
decision; files in scope (app/reports/ReportsToolbar.tsx, app/lib/csv.ts);
open question on empty result sets.

Drop: earlier exploration of server-side streaming (rejected); Papa Parse API
reading; tsc output from first failing compile.
```

Before issuing `/compact`, write the Keep list to `.claude/NOTES.md`. After compacting: `Summarize where we are and what the next step is.` Diff the summary against `.claude/NOTES.md`. If anything is missing, restate it before the next tool call.

### Sub-agent brief (for `/review`)

Do not pass the build transcript:

```
Review the diff on branch feat/csv-export against issue #482.

Criteria: AC1–AC3 in the issue body. Architectural decisions already locked
(client-side Papa Parse, button in ReportsToolbar) — do not re-litigate.

Report: correctness, standards, and any AC the diff fails to satisfy. Bound
the report to what the lead needs to decide whether to merge.
```

## See Also

- `${CLAUDE_PLUGIN_ROOT}/docs/token-budgets.md` — per-artifact and per-phase budgets, CLAUDE.md placement, `@`-import syntax.
- `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` — canonical handoff shape.
- `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` — trigger list and tool order for in-phase context pressure.
- `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md` — NOTES.md as external ledger.
- `${CLAUDE_PLUGIN_ROOT}/docs/workflow.md` — phase-by-phase walkthrough.

## Sources

- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Managing context on the Claude Developer Platform](https://www.anthropic.com/news/context-management)
- [Context editing (API docs)](https://platform.claude.com/docs/en/build-with-claude/context-editing)
- [Compaction (API docs)](https://platform.claude.com/docs/en/build-with-claude/compaction)
