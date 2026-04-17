---
name: compound
description: Capture learnings from completed work into durable, searchable wiki notes. Invoke when the user says "it's fixed", "that worked", "working now", or explicitly via /compound — also after a non-trivial debugging session or implementation concludes successfully. Turns ephemeral knowledge into reusable artifacts in the Obsidian vault at memory/wiki/.
model: sonnet
---

You are leading the knowledge compounding phase. Your job is to capture what was just learned — the fix, the insight, the pattern — into a durable artifact that future agents and developers can discover and reuse.

The target is the Obsidian vault at `memory/wiki/`, powered by the `claude-obsidian` plugin (Karpathy's LLM Wiki pattern). The vault's schema is in `memory/WIKI.md` and vault-scoped instructions are in `memory/CLAUDE.md`. If the `claude-obsidian` plugin is enabled, prefer its `/save` flow — it handles frontmatter, cross-links, and the operation log automatically. This skill describes the same workflow for the direct-file case and adds dedupe/discoverability checks on top.

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

1. Ensure `memory/wiki/concepts/` exists — create it if missing. (The `/wiki` command scaffolds the full vault if anything else is missing.)
2. Identify the problem and solution from the conversation history.
3. Search `memory/wiki/` for existing notes with overlapping content (same module, component, or symptoms). Start with `memory/wiki/index.md` and `memory/wiki/hot.md`; grep `memory/wiki/concepts/`, `memory/wiki/entities/`, and `memory/wiki/sources/` for related material.
   - **High overlap** (same root cause or very similar symptoms) → update the existing note instead of creating a new one. Bump `updated:` in the frontmatter.
   - **Partial overlap** (related but distinct) → create a new note, add the related note to the `related:` list and a wikilink in "See Also".
   - **No overlap** → create a new note.
4. Write the wiki note (see Knowledge Tracks and Output Format below).
5. Append a one-line entry to `memory/wiki/log.md` describing what was filed.
6. Verify discoverability: check whether `CLAUDE.md` or project-level instructions point at `memory/wiki/`. If not, suggest adding a line like: `Check memory/wiki/ (start with hot.md, then index.md) for known issues and patterns before debugging.` Do not modify CLAUDE.md automatically — present the suggestion to the user.
7. **Staleness check** — scan `memory/wiki/` for notes the new learning contradicts or supersedes. If conflict exists, flag it for consolidation (do not auto-delete — present the conflict to the user). `wiki-lint` can help.

### Full

1. Ensure `memory/wiki/concepts/` exists — create it if missing.

2. **Spawn a compounding team** using TeamCreate with three specialists:
   - **Context analyst** — reviews the full conversation history and git diff to extract: what broke, what was tried, what worked, and why.
   - **Solution extractor** — distills the fix into a reusable pattern: root cause, solution steps, prevention guidance.
   - **Overlap scanner** — searches `memory/wiki/` (concepts/entities/sources + index + hot cache) and project docs for existing coverage. Reports whether to create new or update existing:
     - **High overlap** (same root cause or very similar symptoms) → update the existing note with new findings.
     - **Partial overlap** (related but distinct) → create new note, add a wikilink to the related note in `related:` and "See Also".
     - **No overlap** → create new note.

3. Teammates share findings via messages. The overlap scanner's verdict determines whether we create or update.

4. Synthesize team findings into a wiki note.

5. Append an entry to `memory/wiki/log.md`.

6. Verify discoverability: check whether `CLAUDE.md` or project-level instructions point at `memory/wiki/`. If not, suggest adding a line like: `Check memory/wiki/ (start with hot.md, then index.md) for known issues and patterns before debugging.` Do not modify CLAUDE.md automatically — present the suggestion to the user.

7. **Staleness check** — scan `memory/wiki/` for notes the new learning contradicts or supersedes. If the new note contradicts or replaces an existing one, flag it for consolidation (do not auto-delete — present the conflict to the user). `wiki-lint` is the plugin's complementary audit.

## Output

### Knowledge Tracks

Choose the track that fits what was learned. Both end up under `memory/wiki/concepts/` — they differ in frontmatter tags and body shape.

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

### Output Format

Create (or update) a Markdown file under `memory/wiki/concepts/` with this frontmatter shape (matches the vault schema in `memory/WIKI.md`):

```markdown
---
type: concept
title: "<Descriptive Title>"
complexity: basic | intermediate | advanced
domain: <module or area — e.g. workflow, auth, payments>
aliases:
  - "<alternate phrasing>"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
tags:
  - <track tag — bug-fix | pattern | technique | architecture>
  - <domain tag>
  - <specific tag>
status: draft | mature | deprecated
related:
  - "[[<related wiki note title>]]"
  - "[[concepts/_index]]"
sources:
  - "<url or internal ref>"
---

# <Descriptive Title>

<!-- Knowledge track content here (Bug Track or Knowledge Track) -->

## See Also

- `[[<related note>]]`
- `<path/to/skill>` when relevant
```

File naming: `memory/wiki/concepts/<Descriptive Title>.md` (Title Case with spaces, matching the existing vault convention — e.g. `Compounding Knowledge.md`). Do not kebab-case; Obsidian wikilinks match the file title.

## Rules

- Capture knowledge while it's fresh — don't defer.
- Prefer updating existing notes over creating duplicates.
- Keep notes concise — future readers want answers, not narratives.
- Include actual error messages and stack traces in symptoms — these are what people search for.
- Never include secrets, tokens, or credentials in wiki notes.
- Always add at least one wikilink in `related:` and one in "See Also" so the graph stays connected — orphans are surfaced by `wiki-lint`.
- If the `claude-obsidian` plugin is active and a `/save` invocation would produce the same artifact, prefer `/save` — the plugin's schema, index, and log updates stay in sync automatically.
