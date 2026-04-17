# In-Phase Compaction Protocol — Shared

Used by `/build` (and any other long-running phase skill) to keep the working context focused on the current concept. The dominant problem this protocol addresses is **context rot** — attention dilution and stale-framing anchoring as a session accumulates unrelated tool outputs and reasoning paths — not running out of tokens.

This file is reference material — read it on demand when the skill reaches a compaction step. Do not preload.

## Tool order

1. **Context editing first.** Clear stale tool results verbatim. This is rot-immune because nothing is paraphrased.
2. **Sub-agent delegation second.** If the next bulk read can be delegated, the lead never accumulates the rot in the first place. See `${CLAUDE_PLUGIN_ROOT}/docs/context-hygiene.md` (rule 3).
3. **Summarization-based `/compact` last.** Re-summarization compresses, but it also creates a new lower-fidelity anchor the model will over-attend to. Use only when conversation bulk (not tool output) is the source of pressure.

## When to trigger

Trigger on **concept shifts**, not on a percentage:

- **The next planned action is unrelated to the last several tool results.** Stale results will distort the next decision — clear them.
- **About to start a new sub-issue or task-list item.** Natural concept boundary.
- **Just spawned a sub-agent.** The lead can drop the brief; the sub-agent's exploration is already isolated.
- **About to read a large file or search wide paths.** Delegate to a sub-agent instead — don't compact, prevent.
- **The auto-compact warning appears.** Stop immediately, run this protocol, then continue. Never let auto-compact run unattended.

A percentage threshold is not used. Rot is a function of concept-mixing, not utilization. A session at 80% on one tight concept is healthier than a session at 30% spanning four.

## Context editing — the default

If the pressure is from tool outputs that have been superseded (file reads after edits, test runs from a previous attempt, doc lookups already internalized), use [context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing) to clear them verbatim. Anthropic reports 84% token reduction in long-running workflows when context editing is used instead of summarization, and — more importantly — it doesn't introduce paraphrase artifacts.

This is the default tool. Reach for `/compact` only when it can't fix the actual pressure source.

## Summarization-based `/compact` — last resort

When you must use it (conversation bulk, not tool output), always emit a preservation note and write the Keep list to `.claude/NOTES.md` *before* compacting. Format:

```
/compact

Keep: <architectural decisions>; <current task and files in scope>;
<unresolved bugs or failing tests>; <open questions from the issue>.

Drop: <rejected alternatives>; <tool outputs already acted on>;
<API docs already internalized>; <exploration that led nowhere>.
```

**Keep** what the model can't reconstruct from the issue or `.claude/NOTES.md`. **Drop** anything large and replayable.

## Verification

After compaction, run: `Summarize where we are and what the next step is.`

Diff the summary against the Keep list **in `.claude/NOTES.md`**, not from memory — both the summary and the post-compact state draw from the same now-truncated context, so an in-context check has limited diagnostic power. If anything from the Keep list is missing, **restate it explicitly before the next tool call**. If the summary looks hollow, abort and re-read the issue + `./.claude/NOTES.md`.

## Rules

- **Compaction is a build-time responsibility.** Do not defer it to `/wrap-up` — by then it's too late.
- **Each step in the tool order is more lossy than the previous.** Reach for `/compact` only after context editing and delegation have been ruled out.

## Why

In-place summarization can silently drop architectural decisions that only matter three steps later — and the resulting summary becomes the new "early context" the model over-anchors on, recreating the rot pattern at a smaller scale. Context editing avoids both failure modes by deleting rather than paraphrasing. See `${CLAUDE_PLUGIN_ROOT}/docs/context-hygiene.md` for the full rationale.
