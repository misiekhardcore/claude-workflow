# AUTHORING.md — Skill Authoring Standard

Directives for creating/editing skills. Ensures consistency, token efficiency, and predictability.

## Skill Roles
All skills map to one of these five roles (extending the [Ref: composition] model). Use the corresponding template.

|Role|Definition|Example|Model|Template|
|-|-|-|-|-|
|**Research-Lead Orch**|Leads phase → research → specialists → handoff.|`/discovery`, `/define`|`opus`|`SKILL.orchestrator`|
|**Coordinator Orch**|Sequences sub-skills in loop (Build → Review → Verify).|`/implement`|`sonnet`|`SKILL.orchestrator`|
|**Specialist**|Bounded task → seed-brief → report findings.|`/build`, `/review`|`sonnet`|`SKILL.specialist`|
|**Interactive Primitive**|Inline behavior; no team or handoff.|`/grill-me`|`sonnet`|`SKILL.primitive`|
|**Utility**|Maintenance/post-work. No seed-brief or handoff.|`/compound`, `/prune`|`sonnet`/`haiku`|`SKILL.specialist`|

## Structure & Density
**Goal**: Maximize info-density. Replace narrative with constraints.

### Frontmatter
Order: `name` → `description` → `scope` → `when_to_use` → `argument-hint` → `model` → `effort` → `allowed-tools` → `user-invocable` → `disable-model-invocation`.
- `description`: <= 150 chars. Trigger-focused.
- `model`: `haiku` (fast/retrieval), `sonnet` (standard/impl), `opus` (deep research/arch).

#### Required: `scope:`
Declares what the skill is allowed to operate on. Allowed values:

| Value | Operates on |
|-|-|
| `plugin-authoring` | The plugin's own SKILL/template/`_shared` files. |
| `user-codebase` | The user's project files. |
| `cross-plugin` | Files in other installed plugins. |
| `mixed` | Multiple lanes. **Requires** a `## Scope` section in the SKILL.md body enumerating scope per lane. Non-`mixed` skills do not need the body section. |

- **Don't** omit `scope:` — without it, contributors mis-route checks across plugin boundaries (see claude-obsidian#105).
- **Do** set `scope:` on every SKILL.md and a first-line hint on every `_shared/*.md`.

#### Optional frontmatter fields

| Field | Values | When to use |
|-|-|-|
| `when_to_use` | short routing hint | All skills. Primary dispatch signal for the harness. |
| `argument-hint` | `"[arg]"` string | Skills that accept a positional argument from the user. |
| `effort` | `low` / `high` | `high` for deep research/decision-making; `low` for maintenance/utility. Omit for standard. |
| `allowed-tools` | space-separated tool names | Pre-approves a narrow tool surface (skips permission prompts). Does **not** restrict access — the agent can still call other tools if unlocked at runtime. `Agent` is a valid tool name and must be listed for all orchestrating skills. |
| `user-invocable` | `false` | Hides the skill from the slash-command menu. Use for orchestrator-internal specialists. |
| `disable-model-invocation` | `true` | Skips the model call entirely — the skill is treated as a pure pipeline step that only sequences sub-skills. Only use for skills with no model-driven logic (no reasoning, no user interaction, no branching decisions). |

#### tools vs allowed-tools (agent frontmatter)

`allowed-tools` (skill frontmatter) and `tools` / `disallowedTools` (agent frontmatter) are distinct:

- **`allowed-tools`** — skill-level hint, pre-approves tools to skip permission prompts. Does not block access.
- **`tools`** — agent-level allowlist; only listed tools may be called (hard restriction).
- **`disallowedTools`** — agent-level blocklist; listed tools are always blocked, regardless of `tools`.

Agents (in `agents/`) use `tools` + `disallowedTools` for security isolation. Skills use `allowed-tools` for UX (fewer prompts).

#### Plugin security restrictions

Agents dispatched inside a plugin context run with constrained tool access by default. Declaring `tools:` in the agent frontmatter is the authoritative way to enforce least-privilege. `Skill` is a valid tool name for agents that need to invoke sub-skills (e.g. `prune-lane` invoking `claude-obsidian:wiki-lint`).

#### context and agent frontmatter

`context: fork` isolates an agent's context from the parent session. It is intentionally **not** used on claude-workflow orchestrating skills (`/define`, `/implement`, `/epic-autopilot`) because they need to sequence sub-skills with shared in-session state. Use `context: fork` only when the sub-task is fully self-contained and should not see parent context.

### Body Layout
1. **Role & Constraints**: Imperative directives. No "You are a...".
2. **Specialist Mode**: [Ref: specialist-mode] seed-brief skip-list.
3. **I/O**: Input → Output. No paragraphs.
4. **Scope Assessment**: Table based on complexity → Action.
5. **Spawn Justification**: [Ref: composition] rubric (Pivot, Disjoint, Parallel, Payoff).
6. **Process**: Step-by-step imperative flow.
7. **Rules**: Hard constraints + [Ref: interviewing-rules].

## `_shared/` Integration
Do not preload. Reference on-demand via `${CLAUDE_PLUGIN_ROOT}/_shared/<file>.md`.
- `handoff-artifact.md`: Issue body state.
- `interviewing-rules.md`: User interaction.
- `notes-md-protocol.md`: `.claude/NOTES.md` state.
- `specialist-mode.md`: Seed-brief logic.
- `compaction-protocol.md`: In-phase context management.
- `composition.md`: Team/sub-agent cost and shape.

`[Ref: name]` is shorthand for `${CLAUDE_PLUGIN_ROOT}/_shared/name.md`. Skills use it for compact inline references in space-constrained skill bodies.

`_shared/*.md` files have no frontmatter. Declare scope as a first-line comment hint:
```
<!-- scope: plugin-authoring -->
# interviewing-rules.md
```

## Compaction Checklist
Before declaring any compaction (density pass, context-hygiene trim) complete:
- All gates and numeric thresholds preserved verbatim (no approximation).
- All spawn rubrics, dispatch contracts, and payload specs intact.
- All `[Ref:]` cross-references present — none silently removed.
- All verdict/mutation/resolution steps accounted for.
- Output format spec and section headings unchanged.

## Implementation Rigor
- **Parallelism**: Default: inline → subagent → `TeamCreate`. Justify >= 3× payoff.
- **Overrun Prevention**: Delegate to sub-agent if:
  - >= 5 files read in loop (File-sweep).
  - N × item_size > budget (Fan-out).
  - Retrieval-only/Formatting (Thin-synthesis).
  - Verbose tool output → small field set (Verbose-I/O).
- **Naming**: `skills/<name>/SKILL.md` (lowercase kebab-case for dir, uppercase for file).

## Writing Style
- **Imperative**: "Read issue", not "You should read".
- **Surgical**: One short comment line max.
- **Dense**: No filler, no preamble, no "The skill does X".
- **Rational**: Pair every "Don't" with a "Do" (Augment Code study).
