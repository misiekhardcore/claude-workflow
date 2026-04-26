# Knowledge Tracks — Output Templates

Choose the track that fits what was learned. Both produce a structured Markdown note — `claude-obsidian`'s `/save` will slot it into the correct vault location (concept/entity/source) and attach frontmatter based on content.

## Bug Track

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

## Knowledge Track

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

## Note Shape — Inline Fallback

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
