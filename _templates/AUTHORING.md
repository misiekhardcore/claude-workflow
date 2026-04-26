# AUTHORING.md — Skill Authoring Standard

This document defines the authoring conventions for workflow skills in this plugin. Read it when creating or editing a skill, or when `/new-skill` asks which `_shared/` files apply.

## Skill types

Every skill fills one of five authoring roles. These extend the three-role composition model in `_shared/composition.md` (orchestrator / specialist / primitive): the orchestrator role is split into two variants, and a utility type is added for maintenance skills. Choose the correct template before authoring.

| Role                              | Definition                                                                                                                                                      | Examples                                                      | Typical model                |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ---------------------------- |
| **Research-leading orchestrator** | Leads a phase; spawns a research team, then a main team of specialists; writes the handoff artifact. Used when deep reasoning happens at the orchestrator tier  | `/discovery`, `/define`                                       | `opus` + `effortLevel: high` |
| **Coordinator orchestrator**      | Sequences already-designed sub-skills in a loop (e.g. build → review → verify). Deep reasoning lives in the sub-skills, not the orchestrator — no research team | `/implement`                                                  | `sonnet`                     |
| **Specialist**                    | Executes a bounded task; receives a seed brief; reports findings to the orchestrator                                                                            | `/build`, `/review`, `/architecture`, `/specify`              | `sonnet`                     |
| **Interactive primitive**         | Reusable inline behavior; invoked by specialists; no team, no handoff                                                                                           | `/grill-me`                                                   | `sonnet`                     |
| **Utility**                       | User-invocable maintenance or post-work skill. No seed-brief contract, no phase handoff artifact, no team gating                                                | `/compound`, `/prune`, `/resolve-pr-feedback`, `/find-skills` | `sonnet` or `haiku`          |

Use the role-specific template:

- Research-leading or coordinator orchestrator → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.orchestrator.template.md` (coordinator variants omit the research-team step — see the template header note)
- Specialist or utility → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.specialist.template.md` (utility skills simply have no seed-brief input and no handoff output)
- Primitive → `${CLAUDE_PLUGIN_ROOT}/_templates/SKILL.primitive.template.md`

For generic composition theory (patterns, briefs, decomposition rules), see `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

## Composition patterns

Multi-skill workflows follow four patterns: linear, branch, loop, and parallel. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for definitions, when to use each, and the seed-brief contract that governs how orchestrators seed specialists with context. The three standard brief types (research, prior-art, fix) are defined there.

## Skill structure

Use the role-specific templates for new skills: orchestrator, specialist, or primitive. Each template is a loose skeleton — not every section is required. Use what fits.

### Frontmatter fields

| Field           | Required | Values                        | Notes                                                                                                                                                                                                                                                                |
| --------------- | -------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`          | yes      | lowercase kebab-case          | Matches the directory name under `skills/`                                                                                                                                                                                                                           |
| `description`   | yes      | 1–2 sentences, ≤150 chars     | Primary trigger mechanism — include both what it does and when to use it. Hard cap: 150 chars; move examples and use-cases into the skill body where they load on invocation only |
| `model`         | yes      | `haiku` \| `sonnet` \| `opus` | See model guide below                                                                                                                                                                                                                                                |
| `effortLevel`   | no       | `high`                        | Only for long-form research/decision-making (discovery, define, architecture, describe)                                                                                                                                                                              |
| `allowed-tools` | no       | space-separated tool names    | Pre-approves listed tools so they run without per-use permission prompts. Does **not** restrict access — every tool remains callable. Omit by default; to actually block tools, use deny rules in `.claude/settings.json` or a subagent with its own `tools:` field. |

### Model guide

| Model    | Use for                                                               |
| -------- | --------------------------------------------------------------------- |
| `haiku`  | Fast lookup, formatting, retrieval, light verification                |
| `sonnet` | Standard multi-step workflows, implementation, review                 |
| `opus`   | Deep research, architecture, high-stakes decisions with many branches |

## `_shared/` files — when and how

Shared protocols live at `${CLAUDE_PLUGIN_ROOT}/_shared/`. Reference them on-demand from the skill body; do not preload.

### Decision table

| `_shared/` file          | Reference when the skill...                                                                                                                                                             |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `handoff-artifact.md`    | Writes or reads a GitHub issue handoff block (phase-boundary skills: `/discovery`, `/define`, `/implement`, `/wrap-up`)                                                                 |
| `interviewing-rules.md`  | Interviews the user — asks questions, seeks approval, uses multi-choice forms (`/discovery`, `/define`, `/describe`, `/specify`, `/architecture`, `/design`, `/grill-me`, `/new-skill`) |
| `notes-md-protocol.md`   | Creates, updates, or resumes from `.claude/NOTES.md` (`/build`, `/wrap-up`)                                                                                                             |
| `compaction-protocol.md` | Manages in-phase context — clearing stale tool results, delegating bulk reads, using `/compact` (`/build`)                                                                              |
| `composition.md`         | Authors an orchestrator skill or designs a multi-skill workflow — patterns, briefs, decomposition rules                                                                                 |

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

## Persistent plugin data

Use `${CLAUDE_PLUGIN_DATA}` to store cached state that survives across plugin updates and sessions. This resolves to `~/.claude/plugins/data/claude-workflow/` — a directory created automatically on first use. Common uses include caching fetched data, compiled indexes, or installed dependencies.

When your hook or MCP server needs to detect updates and reinstall dependencies, use the diff-then-install pattern. This example checks if either the bundled manifest or its lockfile has changed and reinstalls `node_modules` only when needed:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "(diff -q \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package.json\" >/dev/null 2>&1 && diff -q \"${CLAUDE_PLUGIN_ROOT}/package-lock.json\" \"${CLAUDE_PLUGIN_DATA}/package-lock.json\" >/dev/null 2>&1) || (cd \"${CLAUDE_PLUGIN_DATA}\" && cp \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_ROOT}/package-lock.json\" . && npm ci) || rm -f \"${CLAUDE_PLUGIN_DATA}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package-lock.json\""
          }
        ]
      }
    ]
  }
}
```

Track the lockfile alongside `package.json`: a transitive-dependency bump may change `package-lock.json` while `package.json` stays the same, and skipping reinstall in that case leaves `${CLAUDE_PLUGIN_DATA}/node_modules` stale. Use `npm ci` (not `npm install`) so the install is deterministic against the lockfile. For other ecosystems, swap in the appropriate manifest/lockfile pair (`pnpm-lock.yaml` + `pnpm install --frozen-lockfile`, `yarn.lock` + `yarn install --immutable`, `requirements.txt`/`uv.lock`, etc.).

The `diff` chain exits nonzero when either stored copy is missing (first run) or differs from the bundled version (after an update), triggering reinstall. If installation fails, the trailing `rm` removes the stale manifests so the next session retries. Scripts can then reference the persisted `node_modules`:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/server.js"],
      "env": {
        "NODE_PATH": "${CLAUDE_PLUGIN_DATA}/node_modules"
      }
    }
  }
}
```

## Parallelism decision

When authoring an orchestrator or designing a multi-skill workflow, you must make an explicit parallelism choice. See `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for the full rubric — it defines Scope Assessment (Lightweight / Standard / Deep), TeamCreate decision criteria, and cost models for different primitives.

**Key decision points:**

- **Scope Assessment**: Classify before spawning. Lightweight runs inline; Standard/Deep trigger dispatch. See composition.md for heuristics and cost gradients.
- **Primitive choice**: Default to inline → subagent → TeamCreate. Parallel adds coordination overhead — confirm genuine communication pivot, file disjointness, classifiable parallelism, and ≥3× wall-clock payoff before paying the ~7× token premium.
- **Spawn justification**: Document your choice in the skill body. State which rubric factors apply and which don't. See existing orchestrators (`/discovery`, `/define`, `/implement`, `/review`) for the established pattern — a short "Spawn justification" block naming the cost class and required conditions.

New skills created via `/new-skill` will be guided through this decision during scaffolding.

## Naming conventions

- **Skill directory**: `skills/<name>/` — lowercase kebab-case, matches the `name` frontmatter field.
- **Entry point**: `skills/<name>/SKILL.md` — always `SKILL.md`, uppercase.
- **Bundled resources** (optional): `skills/<name>/references/`, `skills/<name>/scripts/`, `skills/<name>/assets/` — same sub-structure as the skill-creator standard.

## Length guidance

- Keep `SKILL.md` under 500 lines. If you're approaching this limit, split domain content into `references/` sub-files and link to them with clear "read when X" guidance.
- The body is loaded into context on every invocation — keep it focused on instructions, not background narrative.

### Progressive disclosure via `references/`

Use `references/` when a section is **>~40 lines**, runs only in a specific execution branch, and removing it doesn't break the default path. The trade-off: the main skill loads faster, but the reference loads only when that branch executes. See `skills/find-skills/references/`, `skills/compound/references/` for examples.

## Writing style

- Use imperative form: "Read the issue", "Spawn a team", not "You should read" or "The skill reads".
- Explain the _why_ behind non-obvious constraints. A rule without rationale becomes cargo cult.
- Avoid `ALWAYS` / `NEVER` in all-caps when a reasoned explanation works better — prefer "do X because Y" over "ALWAYS do X".
- No multi-paragraph docstrings or comment blocks. One short comment line max.

## Dogfooding this standard

The `/new-skill` scaffolder is itself written to conform to this standard. When extending this plugin, run `/new-skill` rather than copying an existing skill by hand.
