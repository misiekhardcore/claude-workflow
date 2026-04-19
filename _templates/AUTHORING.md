# AUTHORING.md — Skill Authoring Standard

This document defines the authoring conventions for workflow skills in this plugin. Read it when creating or editing a skill, or when `/new-skill` asks which `_shared/` files apply.

## Skill types

Every skill fills one of three roles. Choose the correct template before authoring.

| Role | Definition | Examples | Typical model |
|------|-----------|---------|---------------|
| **Orchestrator** | Leads a phase; spawns and coordinates specialists; writes the handoff artifact | `/discovery`, `/define`, `/implement` | `opus` |
| **Specialist** | Executes a bounded task; receives a seed brief; reports findings to the orchestrator | `/build`, `/review`, `/architecture`, `/specify` | `sonnet` |
| **Interactive primitive** | Reusable inline behavior; invoked by specialists; no team, no handoff | `/grill-me` | `sonnet` |

Use the role-specific template:
- Orchestrator → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.orchestrator.template.md`
- Specialist → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.specialist.template.md`
- Primitive → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.primitive.template.md`

For generic composition theory (patterns, briefs, decomposition rules), see `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

## Composition patterns

Multi-skill workflows follow four patterns: linear, branch, loop, and parallel. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for definitions, when to use each, and the seed-brief contract that governs how orchestrators seed specialists with context. The three standard brief types (research, prior-art, fix) are defined there.

## Skill structure

Use the role-specific templates for new skills: orchestrator, specialist, or primitive. Each template is a loose skeleton — not every section is required. Use what fits.

### Frontmatter fields

| Field | Required | Values | Notes |
|-------|----------|--------|-------|
| `name` | yes | lowercase kebab-case | Matches the directory name under `skills/` |
| `description` | yes | 1–2 sentences | Primary trigger mechanism — include both what it does and when to use it |
| `model` | yes | `haiku` \| `sonnet` \| `opus` | See model guide below |
| `effortLevel` | no | `high` | Only for long-form research/decision-making (discovery, define, architecture, describe) |
| `allowed-tools` | no | comma-separated tool names | Restrict the skill to a subset of tools. Omit to allow all tools. |

### Model guide

| Model | Use for |
|-------|---------|
| `haiku` | Fast lookup, formatting, retrieval, light verification |
| `sonnet` | Standard multi-step workflows, implementation, review |
| `opus` | Deep research, architecture, high-stakes decisions with many branches |

## `_shared/` files — when and how

Shared protocols live at `${CLAUDE_PLUGIN_ROOT}/_shared/`. Reference them on-demand from the skill body; do not preload.

### Decision table

| `_shared/` file | Reference when the skill... |
|---|---|
| `handoff-artifact.md` | Writes or reads a GitHub issue handoff block (phase-boundary skills: `/discovery`, `/define`, `/implement`, `/wrap-up`) |
| `interviewing-rules.md` | Interviews the user — asks questions, seeks approval, uses multi-choice forms (`/discovery`, `/define`, `/describe`, `/specify`, `/architecture`, `/design`, `/grill-me`, `/new-skill`) |
| `notes-md-protocol.md` | Creates, updates, or resumes from `.claude/NOTES.md` (`/build`, `/wrap-up`) |
| `compaction-protocol.md` | Manages in-phase context — clearing stale tool results, delegating bulk reads, using `/compact` (`/build`) |
| `composition.md` | Authors an orchestrator skill or designs a multi-skill workflow — patterns, briefs, decomposition rules |

### Reference pattern

Add a reference line at the end of the relevant section in the skill body. Use the full `${CLAUDE_PLUGIN_ROOT}` path:

```markdown
See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for the questioning protocol — apply it throughout all user interactions.
```

```markdown
See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the five-field handoff shape.
```

```markdown
See `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md`.
```

```markdown
See `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md`. Context editing first, sub-agents second, `/compact` last.
```

## Naming conventions

- **Skill directory**: `skills/<name>/` — lowercase kebab-case, matches the `name` frontmatter field.
- **Entry point**: `skills/<name>/SKILL.md` — always `SKILL.md`, uppercase.
- **Bundled resources** (optional): `skills/<name>/references/`, `skills/<name>/scripts/`, `skills/<name>/assets/` — same sub-structure as the skill-creator standard.

## Length guidance

- Keep `SKILL.md` under 500 lines. If you're approaching this limit, split domain content into `references/` sub-files and link to them with clear "read when X" guidance.
- The body is loaded into context on every invocation — keep it focused on instructions, not background narrative.

## Writing style

- Use imperative form: "Read the issue", "Spawn a team", not "You should read" or "The skill reads".
- Explain the *why* behind non-obvious constraints. A rule without rationale becomes cargo cult.
- Avoid `ALWAYS` / `NEVER` in all-caps when a reasoned explanation works better — prefer "do X because Y" over "ALWAYS do X".
- No multi-paragraph docstrings or comment blocks. One short comment line max.

## Dogfooding this standard

The `/new-skill` scaffolder is itself written to conform to this standard. When extending this plugin, run `/new-skill` rather than copying an existing skill by hand.
