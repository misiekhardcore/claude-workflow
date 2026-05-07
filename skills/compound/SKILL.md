---
name: compound
description: Capture learnings from completed work into durable wiki notes. Delegates to /save when claude-obsidian is available; otherwise emits inline.
model: sonnet
---
You are leading the knowledge compounding phase. Your job is to capture what was just learned — the fix, the insight, the pattern — into a structured, reusable artifact that future agents and developers can discover and reuse.

## Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Full-mode team**: 3 parallel subagents + lead synthesis. Independent reads, end-synthesis, parallel payoff ≥3×.

This skill extracts the learning and drafts it. **Filing is delegated** to the `claude-obsidian` plugin when available: its `/save` command handles vault placement, frontmatter, cross-links, and operation log automatically. If `claude-obsidian` is not installed, the drafted note is emitted inline for the user to copy into their knowledge store.

## Input

The current conversation context — a completed debugging session, feature implementation, or fix. When invoked from `/implement` end-of-flow, may also read `<worktree-root>/.claude/NOTES.md` for in-phase decisions and open questions.

## Process

### Mode Selection

Assess the complexity of what was just learned:

- **Lightweight** — simple fix, single root cause, no cross-cutting concerns. Single-pass extraction, no sub-agents.
- **Full** — multi-step debugging, non-obvious root cause, or broadly applicable pattern. Parallel sub-agents for thorough extraction.

Decision tree:
1. Is this a pattern others will hit? → Full
2. Did debugging involve multiple hypotheses or files? → Full
3. Was the fix a one-liner or config change with obvious cause AND unlikely to recur? → Lightweight
4. Is the user explicitly asking for a quick capture? → Lightweight

### Lightweight

Single-pass extraction:

1. Identify the problem and solution from conversation history.
2. Check for overlap with existing knowledge:
   - If `claude-obsidian:wiki-query` is available, ask it for notes overlapping on module, symptoms, or root cause.
   - Otherwise, skip the overlap check and note in the output.
3. Draft the note using the appropriate Knowledge Track (see below).
4. File the note:
   - If `claude-obsidian:save` is available → invoke `/save` with drafted content. Let `claude-obsidian` place it, add frontmatter, cross-link, update hot cache + log.
   - Otherwise → emit drafted note inline as fenced Markdown the user can copy. Add: `Install claude-obsidian (claude plugin marketplace add AgriciDaniel/claude-obsidian) and run /wiki to bootstrap a vault; future /compound invocations will file automatically.`
5. **Staleness check** — if overlap check found an existing note that the new learning contradicts or supersedes, flag it to the user for consolidation. Do not auto-edit other notes.

### Full

1. **Dispatch 3 parallel subagents**:
   - **Context analyst** — reviews full conversation history and git diff. Extracts: what broke, what was tried, what worked, and why.
   - **Solution extractor** — distills fix into reusable pattern: root cause, solution steps, prevention guidance.
   - **Overlap scanner** — if `claude-obsidian:wiki-query` is available, asks it for existing coverage of the module, symptoms, or root cause. Reports:
     - **High overlap** (same root cause or very similar symptoms) → recommend updating existing note. Include target note's identifier.
     - **Partial overlap** (related but distinct) → recommend creating new; include related note's identifier for cross-linking.
     - **No overlap** → recommend creating new.
     - If `wiki-query` unavailable, report `"skipped: no vault query tool available"`.

2. Wait for all three subagents, then synthesize findings into a single drafted note (lead synthesis).

3. File the note:
   - If `claude-obsidian:save` is available → invoke `/save` with drafted content. If overlap scanner recommended an update, pass target note identifier so `/save` updates in place.
   - Otherwise → emit drafted note inline, plus overlap scanner's verdict so the user knows whether to file as new or merge.

4. **Staleness check** — if overlap scanner flagged a contradicting or superseded note, present the conflict to the user. Recommend running `wiki-lint` (from `claude-obsidian`) for broader audit if conflicts are recurrent.

## Output

Choose between two knowledge tracks when filing the note. See `skills/compound/references/knowledge-tracks.md` for full templates and inline fallback shape.

**Bug Track** — use when learning came from fixing a bug. Captures problem, symptoms, what didn't work, solution, root cause, and prevention guidance.

**Knowledge Track** — use when learning is a pattern, technique, or architectural insight. Captures context, guidance, rationale, when to use, and examples.

## Rules

- Capture knowledge while it's fresh — don't defer.
- Include actual error messages and stack traces in symptoms — these are what people search for.
- Never include secrets, tokens, or credentials in notes.
- Prefer updating an existing note over creating a duplicate.
- Do not file directly to any filesystem path. Delegation to `/save` is the only vault-write path.
- If `claude-obsidian` is installed but `/save` invocation fails, report the error inline with the drafted note — never silently drop the capture.
