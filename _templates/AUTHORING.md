# AUTHORING.md — Skill Authoring Standard

Read when creating/editing a skill or when `/new-skill` asks which `_shared/` files apply.

## Skill types

Every skill fills one of five authoring roles. These extend the three-role composition model in `_shared/composition.md` (orchestrator / specialist / primitive): the orchestrator role is split into two variants, and a utility type is added for maintenance skills. Choose the correct template before authoring.

|Role|Definition|Examples|Typical model|
|-|-|-|-|
|**Research-leading orchestrator**|Leads a phase; spawns a research team, then a main team of specialists; writes the handoff artifact. Used when deep reasoning happens at the orchestrator tier|`/discovery`, `/define`|`opus` + `effort: high`|
|**Coordinator orchestrator**|Sequences already-designed sub-skills in a loop (e.g. build → review → verify). Deep reasoning lives in the sub-skills, not the orchestrator — no research team|`/implement`|`sonnet`|
|**Specialist**|Executes a bounded task; receives a seed brief; reports findings to the orchestrator|`/build`, `/review`, `/architecture`, `/specify`|`sonnet`|
|**Interactive primitive**|Reusable inline behavior; invoked by specialists; no team, no handoff|`/grill-me`|`sonnet`|
|**Utility**|User-invocable maintenance or post-work skill. No seed-brief contract, no phase handoff artifact, no team gating|`/compound`, `/prune`, `/resolve-pr-feedback`, `/find-skills`, `/wrap-up`|`sonnet` or `haiku`|

Use the role-specific template:

- Research-leading/coordinator orchestrator → `SKILL.orchestrator.template.md` (coordinator omits research-team step)
- Specialist/utility → `SKILL.specialist.template.md` (utility has no seed-brief input/handoff output)
- Primitive → `SKILL.primitive.template.md`

Multi-skill workflows follow four patterns (linear, branch, loop, parallel). See `composition.md`.

## Skill structure

Use the role-specific templates for new skills: orchestrator, specialist, or primitive. Each template is a loose skeleton — not every section is required. Use what fits.

### Frontmatter fields

|Field|Required|Values|Notes|
|-|-|-|-|
|`name`|yes|lowercase kebab-case|Matches the directory name under `skills/`|
|`description`|yes|1–2 sentences, ≤150 chars|Primary trigger; what it does and when. Hard cap 150 chars; move examples to skill body|
|`model`|yes|`haiku` \|`sonnet` \|`opus`|See model guide below|
|`effort`|no|`low|medium|high|xhigh|max`|Elevates model effort for long-form research/decision-making. Use `high` for opus-tier research skills (discovery, define, architecture, describe).|
|`when_to_use`|no|free text|Trigger phrases and "use before/after X" guidance. Combined cap with `description`: 1,536 chars|
|`argument-hint`|no|`[hint text]`|Hint shown after slash command (e.g. `[issue#]`, `[PR# or URL]`)|
|`user-invocable`|no|`false`|Set to `false` to hide from menu. Hide orchestrator-internal specialists|
|`disable-model-invocation`|no|`true`|Prevent Claude auto-invoke without explicit user action|
|`allowed-tools`|no|space-separated tool names|Pre-approve tools (skip prompts; doesn't restrict). Use deny rules in `.claude/settings.json` to block|

### Canonical field order

When multiple fields are present, use this order so diffs are predictable:

```
name → description → when_to_use → argument-hint → model → effort → allowed-tools → user-invocable → disable-model-invocation
```

Omit optional fields when not set — never write empty strings or `null` as values.

### Model guide

|Model|Use for|
|-|-|
|`haiku`|Fast lookup, formatting, retrieval, light verification|
|`sonnet`|Standard multi-step workflows, implementation, review|
|`opus`|Deep research, architecture, high-stakes decisions with many branches|

## `_shared/` files — when and how

Shared protocols at `_shared/`. Reference on-demand from skill body; do not preload.

|`_shared/` file|Reference when the skill...|
|-|-|
|`handoff-artifact.md`|Writes/reads GitHub issue handoff block (`/discovery`, `/define`; not `/implement` terminal phase)|
|`interviewing-rules.md`|Interviews user (`/discovery`, `/define`, `/describe`, `/specify`, `/architecture`, `/design`, `/grill-me`, `/new-skill`)|
|`notes-md-protocol.md`|Creates/updates/resumes `.claude/NOTES.md` (`/build`); harvests/deletes (`/implement`)|
|`specialist-mode.md`|Detects specialist-mode, skip-list, standalone fallback for seeded skills|
|`compaction-protocol.md`|Manages in-phase context, stale results, bulk reads, `/compact` (`/build`)|
|`composition.md`|Orchestrator skill or multi-skill workflow — patterns, briefs, decomposition|

Reference pattern: add line at relevant section end using full `${CLAUDE_PLUGIN_ROOT}` path.
```
See `${CLAUDE_PLUGIN_ROOT}/_shared/interviewing-rules.md` for questioning protocol.
```

## Persistent plugin data

Use `${CLAUDE_PLUGIN_DATA}` (`~/.claude/plugins/data/claude-workflow/`) for cached state surviving plugin updates and sessions.

Diff-then-install pattern for detecting updates:

```json
{
  "hooks": {
    "SessionStart": [{
      "type": "command",
      "command": "(diff -q \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package.json\" >/dev/null 2>&1 && diff -q \"${CLAUDE_PLUGIN_ROOT}/package-lock.json\" \"${CLAUDE_PLUGIN_DATA}/package-lock.json\" >/dev/null 2>&1) || (cd \"${CLAUDE_PLUGIN_DATA}\" && cp \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_ROOT}/package-lock.json\" . && npm ci) || rm -f \"${CLAUDE_PLUGIN_DATA}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package-lock.json\""
    }]
  }
}
```

Track lockfile alongside manifest. Use `npm ci` (not `npm install`). For other ecosystems: `pnpm-lock.yaml` + `pnpm install --frozen-lockfile`, `yarn.lock` + `yarn install --immutable`, etc.

## Parallelism decision

When authoring an orchestrator, make explicit parallelism choice per `composition.md` (Scope Assessment, TeamCreate criteria, cost models).

- **Scope Assessment** — classify before spawning. Lightweight inline; Standard/Deep trigger dispatch.
- **Primitive choice** — default: inline → subagent → TeamCreate. Confirm communication pivot, file disjointness, parallelism, ≥3× payoff before paying ~7× token premium.
- **Spawn justification** — document in skill body. State which rubric factors apply. See template below.

### Inline-overrun smell checklist

Check each smell. Presence means candidate for subagent delegation (see `composition.md` § "Main-thread overrun"):

- [ ] **File-sweep** — reads ≥5 files in loop before synthesizing.
- [ ] **Fan-out** — iterates over N independent items; N × item-size grows context linearly.
- [ ] **Thin-synthesis** — retrieval/formatting only; lead receives summary, doesn't run retrieval.
- [ ] **Verbose-tool-output** — single call returns verbose output, skill scans for small field set.

Remediation: assign smelly work to subagent with bounded prompt; return only summary. Document in `### Spawn justification` block.

### Spawn justification template

Every orchestrator/specialist dispatching team or subagents includes `### Spawn justification` block. Apply each rubric criterion explicitly.

```markdown
### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **<team/session>**: <shape — e.g. "2 parallel subagents", "TeamCreate at ≥3 splits">. Comm-pivot <✓|✗> (<why>), disjoint <✓|✗|n/a> (<why>), parallel <✓|✗> (<why>), payoff <≥3×|<3×> (<why>). Model: <choice + rationale>. Fallback: <option>.
```

**Fallback options** (when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` unset):
- `Fallback: sequential subagents` — degrade `TeamCreate` to one-at-a-time.
- `Fallback: parallel subagents or sequential` — clarifies further degradation.
- `Fallback: n/a — no flag dependency` — inline/interactive/single-subagent shapes. Use exact wording for grep.

Comm-pivot, disjoint, parallel, payoff judgments are role-specific and load-bearing — don't compress. See `skills/architecture/SKILL.md` and `skills/build/SKILL.md` for examples.

## Naming conventions

- **Skill directory**: `skills/<name>/` — lowercase kebab-case, matches the `name` frontmatter field.
- **Entry point**: `skills/<name>/SKILL.md` — always `SKILL.md`, uppercase.
- **Bundled resources** (optional): `skills/<name>/references/`, `skills/<name>/scripts/`, `skills/<name>/assets/` — same sub-structure as the skill-creator standard.

## Length guidance

- Keep `SKILL.md` <500 lines. Split domain content into `references/` sub-files with clear "read when X" guidance.
- Body loads on every invocation — focus on instructions, not narrative.

### Progressive disclosure via `references/`

Use `references/` when section is >~40 lines, runs in specific branch, and removal doesn't break default path. Main skill loads fast; reference loads only on branch. See `skills/find-skills/references/`, `skills/compound/references/`.

## Writing style

- Imperative: "Read the issue", "Spawn a team", not "You should read" or "The skill reads".
- Explain _why_ behind constraints. Rule without rationale becomes cargo cult.
- Avoid ALL-CAPS `ALWAYS`/`NEVER` — prefer "do X because Y".
- One short comment line max.

The `/new-skill` scaffolder conforms to this standard. Use it when extending this plugin.
