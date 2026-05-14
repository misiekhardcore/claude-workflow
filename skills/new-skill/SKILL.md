---
name: new-skill
description: Scaffold a new skill conforming to the authoring standard. Interviews the author, generates a SKILL.md, and writes it to the chosen location.
when_to_use: Use when creating a new skill for personal use, a project, or this plugin.
model: haiku
effort: low
allowed-tools: Read Write Bash
---
Interactive skill scaffolder. Help author create skill conforming to claude-workflow standard. One question at a time.

## Input

A brief statement from the author of what the skill should do, or nothing to start with question (a).

## Process

Three phases: (1) Read `${CLAUDE_PLUGIN_ROOT}/_templates/AUTHORING.md` (skill types, `_shared/` decision table, frontmatter guide); (2) Interview author with 11 questions (name, description, mis-routing, role, model, effort, argument, tools, parallelism, protocols, target) — see [Ref: references/interview-steps.md]; (3) Generate SKILL.md from template, show draft, write on explicit yes.

[Ref: references/interview-steps.md]
[Ref: ${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md]

## Output

File at target location, conforming to authoring standard. Empty skeleton for author to fill in.

## Rules

- One question at a time; no bundling.
- Explicit "yes" required before writing.
- Skeleton is sparse — no invented domain content.
- Defaults if author skips: model: sonnet, all optional fields omitted, target: personal.
- Include `when_to_use` only if mis-routing risk identified (step c).
- If target has `SKILL.md`, ask to overwrite or pick new name.
