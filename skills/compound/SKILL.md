---
name: compound
description: Capture learnings from completed work into durable, searchable wiki notes. Invoke when the user says "it's fixed", "that worked", "working now", or explicitly via /compound — also after a non-trivial debugging session or implementation concludes successfully. When the claude-obsidian plugin is installed, filing is delegated to its /save flow; otherwise the structured note is emitted inline for the user to capture.
model: sonnet
---

You are leading the knowledge compounding phase. Your job is to capture what was just learned — the fix, the insight, the pattern — into a structured, reusable artifact that future agents and developers can discover and reuse.

### Spawn justification

See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the four-criterion `TeamCreate` rubric and primitive ladder.

- **Full-mode compounding team** (context analyst + solution extractor + overlap scanner): 3 parallel subagents + lead synthesis — comm-pivot ✗ (three independent reads with end-synthesis by lead; no mid-task coordination needed), file-disjoint ✓ (each reads a different dimension of the conversation), classifiably parallel ✓, wall-clock payoff ≥3× for independent reads. Fallback when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset: sequential subagent invocations (context analyst → solution extractor → overlap scanner → lead synthesis).

This skill extracts the learning and drafts it. **Filing is delegated** to the `claude-obsidian` plugin when available: its `/save` command handles vault placement, frontmatter, cross-links, hot-cache updates, and the operation log automatically. If `claude-obsidian` is not installed, the drafted note is emitted inline for the user to copy into whatever knowledge store they prefer.

## Input

The current conversation context — a completed debugging session, feature implementation, or fix.

## Process

### Mode Selection

Assess the complexity of what was just learned:

- **Lightweight** — simple fix, single root cause, no cross-cutting concerns. Single-pass extraction, no sub-agents.
- **Full** — multi-step debugging, non-obvious root cause, or pattern that applies broadly. Parallel sub-agents for thorough extraction.

Decision tree:
1. Is this a pattern others will hit? → Full
2. Did debugging involve multiple hypotheses or files? → Full
3. Was the fix a one-liner or config change with obvious cause AND unlikely to recur? → Lightweight
4. Is the user explicitly asking for a quick capture? → Lightweight

### Lightweight

Single-pass extraction. Work through these steps yourself:

1. Identify the problem and solution from the conversation history.
2. Check for overlap with existing knowledge:
   - If the `claude-obsidian:wiki-query` command is available, ask it for notes overlapping on module, symptoms, or root cause. Use its verdict.
   - Otherwise, skip the overlap check and note in the output that it was skipped.
3. Draft the note using the appropriate Knowledge Track (see below).
4. File the note:
   - If `claude-obsidian:save` is available → invoke `/save` with the drafted content as input. Let `claude-obsidian` place it, add frontmatter, cross-link, and update its hot cache + log.
   - Otherwise → emit the drafted note inline in the response as a fenced Markdown block the user can copy, and add a one-line suggestion: `Install claude-obsidian (claude plugin marketplace add AgriciDaniel/claude-obsidian) and run /wiki to bootstrap a vault; future /compound invocations will file automatically.`
5. **Staleness check** — if the overlap check found an existing note that the new learning contradicts or supersedes, flag it to the user for consolidation. Do not auto-edit other notes. The `wiki-lint` command (from `claude-obsidian`) is the complementary audit.

### Full

1. **Dispatch 3 parallel subagents** (one Task tool call per agent in a single message):
   - **Context analyst** — reviews the full conversation history and git diff to extract: what broke, what was tried, what worked, and why.
   - **Solution extractor** — distills the fix into a reusable pattern: root cause, solution steps, prevention guidance.
   - **Overlap scanner** — if `claude-obsidian:wiki-query` is available, asks it for existing coverage of the module, symptoms, or root cause. Reports:
     - **High overlap** (same root cause or very similar symptoms) → recommend updating the existing note. Include the target note's identifier in the report.
     - **Partial overlap** (related but distinct) → recommend creating new; include the related note's identifier for cross-linking.
     - **No overlap** → recommend creating new.
     - If `wiki-query` is not available, report `"skipped: no vault query tool available"`.

2. Wait for all three subagents to return, then synthesize their findings into a single drafted note (lead synthesis).

3. File the note:
   - If `claude-obsidian:save` is available → invoke `/save` with the drafted content and, if the overlap scanner recommended an update, pass the target note identifier so `/save` updates in place rather than creating a new note.
   - Otherwise → emit the drafted note inline, plus the overlap scanner's verdict so the user knows whether to file as new or merge into an existing note.

4. **Staleness check** — if the overlap scanner flagged a contradicting or superseded note, present the conflict to the user. Do not auto-delete. Recommend running `wiki-lint` (from `claude-obsidian`) for a broader audit if conflicts are recurrent.

## Output

### Knowledge Tracks

Choose the track that fits what was learned. Both produce a structured Markdown note — `claude-obsidian`'s `/save` will slot it into the correct vault location (concept/entity/source) and attach frontmatter based on content.

#### Bug Track
Use when the learning came from fixing a bug or unexpected behavior. Tag with `bug-fix`.

```markdown
## Problem
<!-- What went wrong — observable symptoms -->

## Symptoms
<!-- How it manifested — error messages, failing tests, user reports -->

## What Didn't Work
<!-- Approaches tried that failed — saves future debuggers time -->

## Solution
<!-- The actual fix — code changes, config changes, commands -->

## Why It Works
<!-- Root cause explanation — why the fix addresses the underlying issue -->

## Prevention
<!-- How to avoid this in the future — tests, linting rules, patterns -->
```

#### Knowledge Track
Use when the learning is a pattern, technique, or architectural insight. Tag with `pattern`, `technique`, or `architecture`.

```markdown
## Context
<!-- When this knowledge applies — project area, tech stack, situation -->

## Guidance
<!-- The insight or pattern — what to do -->

## Why
<!-- Rationale — why this approach over alternatives -->

## When to Use
<!-- Conditions that make this the right choice -->

## Examples
<!-- Concrete code examples or references -->
```

### Note shape (inline fallback)

When `claude-obsidian` is not available and the note is emitted inline, include a minimal frontmatter block so the user can drop it straight into any vault:

```markdown
---
title: "<Descriptive Title>"
tags: [<track tag>, <domain tag>, <specific tag>]
created: <YYYY-MM-DD>
---

# <Descriptive Title>

<!-- Bug Track or Knowledge Track body -->
```

When `claude-obsidian` is active, pass only the body + a suggested title to `/save`; the plugin owns the frontmatter schema.

## Rules

- Capture knowledge while it's fresh — don't defer.
- Include actual error messages and stack traces in symptoms — these are what people search for.
- Never include secrets, tokens, or credentials in notes.
- Prefer updating an existing note over creating a duplicate (the overlap scanner's job).
- Do not file directly to any filesystem path. Delegation to `/save` is the only vault-write path; the inline fallback hands responsibility to the user.
- If `claude-obsidian` is installed but `/save` invocation fails, report the error inline with the drafted note — never silently drop the capture.
