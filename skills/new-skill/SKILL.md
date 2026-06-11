---
name: new-skill
description: Scaffold a new skill conforming to the authoring standard. Interviews the author, generates a SKILL.md, and writes it to the chosen location.
when_to_use: Creating or extending a skill in any context — plugin, project, or personal config.
model: haiku
effort: low
allowed-tools: Read Write Bash
---

Maintenance Orchestrator that interviews the author to produce a conformant SKILL.md. Runs entirely in main context; never uses `context: fork`. One question at a time.

## Protocol skills

Adopt `Skill("interviewing-rules")` — one question at a time, structured choice with `(Recommended)` first, explicit approval required, max 4 `AskUserQuestion` options.

## Process

1. **Adopt protocol** — Read `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` and operate by its conventions throughout every user-facing step.

2. **Name** — Plain prompt: "What's the skill called?" Must be lowercase kebab-case, matches directory name under `skills/`.

3. **Description** — Plain prompt: "In one or two sentences: what does it do, and when should it trigger?" Frame as "Does X. Use when Y."

4. **Derive role from purpose** — From the description, assess which role fits. Present the likely role with rationale. AskUserQuestion `header: "Role"`: "Does `<role>` match your intent?"

   |Role|Runs in|User interaction|Dispatches|`context: fork`|
   |-|-|-|-|-|
   |**Orchestrator**|Main context|Yes|Optionally: Orchestrators and/or Workers|Never|
   |**Worker**|Isolated|Task confirmations|Optionally: other Workers|Always|
   |**Interaction**|Main context|Yes — exclusively|Never|Never|
   |**Protocol**|Caller's context|N/A|Never|Never|

   Options: **Yes (Recommended)**, **No, let me choose**. If No, show table and let them pick.

   **Role follow-ups:**
   - **Orchestrator** — AskUserQuestion `header: "Orchestrator type"`: "Research-leading (deep reasoning, `opus`, `effort: high`) or Coordinator (sequences sub-skills, `sonnet`)?"
   - **Worker** — Plain prompt: "What input does it expect and what does it produce?" Note seed-brief contract.
   - **Interaction** — "Does it need a research sub-agent?" If yes, split: autonomous research agent + interactive skill.
   - **Protocol** — Plain prompt: "Which behavioral convention does it encode?"

5. **Model** — AskUserQuestion `header: "Model"`: "Which model?" Options: **sonnet** (Recommended), haiku, opus. Pre-filled per role default.

6. **Effort** — AskUserQuestion `header: "Effort"`: "Long-form multi-turn research or decisions?" Options: **Standard** (Recommended; omit field), **High** (`effort: high`).

7. **Argument hint** — Plain prompt: "Accepts a positional argument? Enter hint text (e.g. `[issue#]`) or 'no' to skip."

8. **Allowed tools** — AskUserQuestion `header: "Tools"`: "Tool surface?" Options: **All tools** (Recommended; omit field), **Restricted** (specify list).

9. **Parallelism** — AskUserQuestion `header: "Parallelism"`: "Spawns sub-agents?" Options: **No** (Recommended), **Yes**. If Yes, document spawn justification per `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

10. **Shared protocols** — AskUserQuestion `header: "Protocols"`, `multiSelect: true`: "Which shared protocols?" Options: Handoff artifact, Interviewing rules, NOTES.md protocol, Compaction protocol, Composition.

11. **Read AUTHORING.md** — Read `${CLAUDE_PLUGIN_ROOT}/_templates/AUTHORING.md` at point of need for frontmatter guide and template structure.

12. **Build frontmatter** — Compile from answers. Rules:
    - `name`, `description`: from steps 2–3.
    - `when_to_use`: include only if description is ambiguous (ask "Could another skill be invoked instead?").
    - `model`, `effort`, `argument-hint`, `allowed-tools`: from steps 5–8 (omit optional fields when not set).
    - `user-invocable: false` for Protocol and internal Worker skills. Omit (default `true`) otherwise.
    - No `layer:`, no `context: fork`, no `agent:`.

13. **Build body** — Minimal skeleton. Sections: `## Input`, `## Process`, `## Output`, `## Rules`. Orchestrator body must be ≤150 lines total. Workers: reference seed-brief contract. Any `Agent()` spawn must include a seed-brief per `${CLAUDE_PLUGIN_ROOT}/_shared/seed-brief.md`.

14. **Show draft & confirm** — Fenced code block. AskUserQuestion `header: "Write?"`: "Write to `<target-path>`?" Options: **Yes**, **No, revise**.

15. **Write** — Create directory if needed, write file. If target exists, ask before overwriting.

## Output

Single SKILL.md at target path, shown for approval before writing.

## Rules

- One question at a time. Require explicit yes before writing.
- All reference-file reads are point-of-need (step 11, step 13), not unconditional at top.
- Defaults (if skipped): `model: sonnet`; `effort`, `argument-hint`, `allowed-tools`, `user-invocable`: omit; target: personal.
- Generated frontmatter: no `layer:`, no `context: fork`, no `agent:`.
- Generated `Agent()` calls must include a seed-brief.
- If target `SKILL.md` exists, ask before overwriting.
