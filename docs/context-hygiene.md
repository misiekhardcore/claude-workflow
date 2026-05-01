# Context Hygiene Between Workflow Phases

Why this plugin treats phase boundaries as context resets, and what the four rules below actually do.

## The problem

The lifecycle — `/discovery` → `/define` → `/implement` (build → review → verify) → `/wrap-up` → `/compound` — is multi-phase on purpose. The problem is not that the context window fills up; even with large windows, that is rarely the binding constraint. The problem is **context rot**: the well-documented degradation in retrieval, reasoning, and instruction-following as unrelated concepts accumulate in a single session, even nominally well within the window.

Two failure modes:

1. **Within a phase** — a long `/build` session accumulates stale tool outputs (rejected approaches, replayed test runs, file reads that were superseded). The model starts anchoring on early framings instead of the current task.
2. **Between phases** — `/discovery` is interview-shaped reasoning, `/define` is architectural tradeoffs, `/implement` is code edits. Carrying one phase's context into the next dilutes attention with the wrong reasoning patterns. The model keeps re-litigating user-interview framings while it should be writing code.

The fix in both cases is the same: **keep the working context focused on the current concept**. The rules below are how.

## Guidance

Four rules. Apply them in order.

### 1. Reset between phases — phases are concept boundaries

Anthropic's harness team describes the tradeoff explicitly:

> "A reset provides a clean slate, at the cost of the handoff artifact having enough state for the next agent to pick up the work cleanly. This differs from compaction, where earlier parts of the conversation are summarized in place so the same agent can keep going on a shortened history."
> — [Harness design for long-running apps, Anthropic Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)

Phases in this workflow are not just organizational — they are **concept boundaries**. Each phase has a different reasoning shape, and carrying one shape into the next is the dominant rot vector at this workflow's scale. The GitHub issue **body** is the handoff artifact — always updated in place, never posted as a comment. End each phase by editing the issue body with the decisions and state the next phase needs, then start the next phase in a fresh session. Do not carry conversation history across `/discovery → /define`, `/define → /implement`, or `/build → /review`.

The artifact has a fixed shape (Acceptance criteria, Constraints, Prior decisions, Evidence, Open questions) defined canonically in `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`. That shape mirrors Anthropic's "structured handoff artifact" and OpenAI's [`input_type` handoff metadata](https://openai.github.io/openai-agents-python/handoffs/) — small, structured, summary-shaped, not a transcript.

### 2. Within a phase, prefer context editing over summarization, and trigger on concept shifts

Inside a phase, the dominant rot source is stale tool output: file reads that were superseded, test runs from a previous attempt, doc lookups already internalized. **Context editing** — clearing those tool results verbatim — removes the rot at its source without paraphrasing anything.

> "Context editing enabled agents to complete workflows that would otherwise fail due to context exhaustion — while reducing token consumption by 84%."
> — [Managing context on the Claude Developer Platform, Anthropic](https://www.anthropic.com/news/context-management)

Summarization-based `/compact` is a **last resort**, not the headline tool. Re-summarization forces the model to paraphrase its own reasoning, and the resulting summary becomes the new "early context" the model will over-anchor on — same rot pattern, slightly compressed. When you must use it, follow Anthropic's preservation guidance:

> "Context compaction is implemented by passing the message history to the model to summarize and compress the most critical details, preserving architectural decisions, unresolved bugs, and implementation details while discarding redundant tool outputs or messages."
> — [Effective context engineering for AI agents, Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

> "Overly aggressive compaction can result in the loss of subtle but critical context whose importance only becomes apparent later."
> — same source

Trigger compaction on **concept shifts**, not on a percentage. `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` enumerates the trigger conditions and the tool order (context editing → sub-agent delegation → summarization-based `/compact` last). The summary: never let auto-compact run unattended, always emit a preservation note when you do reach `/compact`, and write the Keep list to `.claude/NOTES.md` *before* compacting so the post-compaction state can be diffed against an external record. The model's own "summarize where we are" is a sanity check, not a verification — both the summary and the post-compact state draw from the same now-truncated context.

### 3. Delegate bulk tool output to sub-agents, not just exploration

Sub-agent isolation is **structurally rot-proof**: the lead session never sees the rotted context in the first place. This is the strongest tool in the kit and it should be used aggressively.

> "Each subagent might explore extensively, using tens of thousands of tokens or more, but returns only a condensed, distilled summary of its work (often 1,000–2,000 tokens), achieving a clear separation of concerns where the detailed search context remains isolated within sub-agents, while the lead agent focuses on synthesizing and analyzing the results."
> — [Effective context engineering for AI agents, Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

The general rule: **anything that produces bulk tool output should run in a sub-agent that returns a distilled report**. The lead session stays on synthesis, where rot hurts most. Use Glob/Grep for narrow, directed lookups, and use sub-agents for broader exploration or any task likely to generate large volumes of output.

In this workflow:

- `/review` already follows this pattern: fresh-context reviewers receive the diff, not the build history. Keep it that way.
- `/verify` is invoked with only the acceptance criteria plus the running code, never the build session history.
- `/build` should delegate to an Explore sub-agent for any of: understanding an unfamiliar area of the codebase, parsing a long log, reading API docs, grepping wide paths. Ask for a focused report bounded by what the lead actually needs to make the next decision — not a fixed word limit.
- Pass briefs, not session history. Sub-agents need objective + constraint + "what to report on" — not the conversation that led you to spawn them.

### 4. Persist end-of-phase state into the issue body before the session ends

At phase boundaries (`/discovery`, `/define`), the orchestrator edits the GitHub issue **body** in place with the handoff artifact so state survives the context reset. The captured content lives in the same scan-readable artifact as the rest of the phase state.

For `/implement`: this phase is terminal — its output is the PR, not an issue body update. End-of-phase state (assumptions, uncertainties, follow-ups, outstanding findings) flows into the PR body's `## Notes` section. `/wrap-up` is now a user-invoked cleanup utility (worktree + branch removal), not a phase-boundary skill.

## Why

Three convergent reasons, all from first-party sources:

1. **Context rot is the binding constraint, not window size.** Retrieval, reasoning, and instruction-following degrade as unrelated concepts accumulate in a single session, well before the window fills. Bigger windows let you fit more — they don't help you attend better. Compaction exists as a feature precisely because token budget is not the only failure mode.

2. **Context editing strictly dominates summarization for tool-output bulk.** Clearing stale tool results verbatim removes the rot at its source without paraphrasing anything. Summarization both compresses AND introduces a new lower-fidelity anchor for the model to over-attend to — it's a partial fix that adds its own failure mode. Anthropic's 84% token-reduction figure for context editing measures the right thing.

3. **Sub-agent isolation is empirically effective.** Anthropic quantifies it: tens of thousands of tokens of exploration compressed into a 1–2k token report, with the lead agent reasoning over the distilled results. The lead never sees the rotted context — that's why it's the strongest tool in the kit. `/review` and `/verify` already work for this reason.

A note on Opus 4.5/4.6 and "context anxiety": Anthropic reports they dropped context resets from their harness for long-running **single-concept** agents ([Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)). That is not the failure mode this doc addresses. Multi-concept session bloat across `/discovery`, `/define`, and `/implement` is a different problem and rot still applies.

## When to Use

- **Rule 1 (reset + artifact)** applies at every phase boundary, always. No exceptions.
- **Rules 2 and 3** apply within a phase whenever a concept shift occurs. See `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` for the full trigger list and the tool-order decision (context editing → sub-agent → `/compact`).
- **Rule 4** applies at every phase boundary — `/discovery` and `/define` write to the issue body; `/implement` writes to the PR body. `/wrap-up` is a cleanup utility, not a phase-boundary skill.

## Examples

### Structured handoff artifact — filled example

A worked instance of the canonical template from `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`, paste-ready into the issue body before resetting the session:

```markdown
## Implementation plan

**Acceptance criteria** (from /discovery, unchanged)
- AC1: CSV export button appears on /reports for users with `reports.read`
- AC2: Export respects current filters
- AC3: File downloads within 5s for ≤50k rows

**Constraints**
- In scope: app/reports/**, app/lib/csv.ts (new)
- Out of scope: server-side streaming, S3 upload path
- Must reuse existing filter state from ReportsContext

**Prior decisions**
- Client-side generation via Papa Parse (chose over server endpoint: no infra change needed for ≤50k rows)
- Button lives in ReportsToolbar, not inside the table (consistency with Print button)
- No progress indicator in v1 (UX confirmed acceptable at 50k)

**Evidence**
- Benchmark: 50k rows → 1.4s in Chrome (see thread with @alex, 2026-04-12)
- Design review: figma.com/... (approved)

**Open questions**
- Should empty result sets download an empty file or show a toast? (defer to /build, pick one and note it)
```

### Summarization-based `/compact` with preservation note

Use only when context editing won't address the pressure (e.g., the bulk is conversation, not tool output). Never blind:

```
/compact

Keep: issue #482 acceptance criteria; the ReportsToolbar component layout
decision (client-side Papa Parse); files currently in scope
(app/reports/ReportsToolbar.tsx, app/lib/csv.ts); the open question about
empty result sets.

Drop: the earlier exploration of server-side streaming (rejected); Papa
Parse API reading; the tsc output from the first failing compile.
```

Before issuing `/compact`, write the Keep list to `.claude/NOTES.md`. After compacting, follow up with: `Summarize where we are and what the next step is.` Diff the summary against the Keep list **in NOTES.md**, not from memory — if anything is missing, restate it before the next tool call. If the summary looks hollow, abort and re-read the issue + NOTES.md.

### Sub-agent brief (for `/review`)

Do not pass the build transcript. Pass the brief:

```
Review the diff on branch feat/csv-export against issue #482.

Criteria: AC1–AC3 in the issue body. Architectural decisions already locked
(client-side Papa Parse, button in ReportsToolbar) — do not re-litigate.

Report: correctness, standards, and any AC the diff fails to satisfy.
Bound the report to what the lead needs to decide whether to merge.
```

This matches Anthropic's sub-agent pattern: the reviewer runs in isolation, returns a distilled report, and the lead session never sees the reviewer's internal exploration.

## See Also

- `${CLAUDE_PLUGIN_ROOT}/docs/token-budgets.md` — concrete per-artifact and per-phase budgets the rules above assume; CLAUDE.md placement and `@`-import syntax.
- `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` — canonical handoff shape.
- `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md` — trigger list and tool order for in-phase context pressure.
- `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md` — NOTES.md as an external ledger the model can diff against after `/compact`.
- `${CLAUDE_PLUGIN_ROOT}/skills/compound/SKILL.md` — how learnings from a completed phase become durable wiki notes.
- `${CLAUDE_PLUGIN_ROOT}/skills/wrap-up/SKILL.md` — worktree + branch cleanup utility; invoke after the PR is merged or accepted.

## Sources

- Anthropic — [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- Anthropic — [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- Anthropic — [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- Anthropic — [Managing context on the Claude Developer Platform](https://www.anthropic.com/news/context-management)
- Anthropic — [Context editing (API docs)](https://platform.claude.com/docs/en/build-with-claude/context-editing)
- Anthropic — [Compaction (API docs)](https://platform.claude.com/docs/en/build-with-claude/compaction)
- OpenAI — [Agents SDK: Handoffs](https://openai.github.io/openai-agents-python/handoffs/)
- OpenAI — [Orchestrating Agents: Routines and Handoffs (Cookbook)](https://cookbook.openai.com/examples/orchestrating_agents)
