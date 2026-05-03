# Specialist Mode — Shared Protocol

A specialist skill runs in one of two modes depending on how it was invoked: **standalone** (invoked directly by the user) or **specialist** (invoked by an orchestrator that has already run preflights and scoped the work).

This file is reference material — read it when a skill needs to detect its invocation mode or document which prompts it skips when seeded.

## Detection

A specialist detects specialist mode by checking for a `<seed-brief>` block in its prompt at startup:

```
if "<seed-brief>" in prompt → specialist_mode = True
```

When a seed brief is present, the verified fields in it replace the specialist's own preflight checks. When no brief is present, the specialist runs in standalone mode with all prompts active.

## Seed-brief transport format

Orchestrators pass seed briefs as raw YAML inside an XML tag — no inner code fence:

```
<seed-brief>
preflight_verified: true
scope_class: Lightweight|Standard|Deep
repo: owner/repo
branch: feat/branch-name
active_issue: 42
autonomous: false  # optional — see field table below
payload:
  type: fix|research|prior-art
  # type-specific fields per _shared/composition.md
</seed-brief>
```

The XML tag marks the boundary; the YAML is parseable without a fence. The `payload` envelope decouples brief metadata from the type-specific research, fix, or prior-art content.

## Required fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `preflight_verified` | boolean | yes | Brief is rejected if `false` or missing |
| `scope_class` | string | yes | Must be `Lightweight`, `Standard`, or `Deep` |
| `repo` | string | yes | `owner/repo` — verified against `git remote -v` of the spawning worktree |
| `branch` | string | yes | `feat/<slug>` — verified against `git rev-parse --abbrev-ref HEAD` |
| `active_issue` | integer | yes | Ties the brief to its GitHub issue |
| `payload` | object | yes | `{ type: fix|research|prior-art, ... }` — type-specific fields per `_shared/composition.md` |
| `autonomous` | boolean | no | Default `false`. When `true`, suppresses `/implement`'s exhausted-exit prompt; only consumed by `/implement`. Do not set from non-autopilot orchestrators — default `false` preserves the rigor gate. |

When verification fails (wrong repo, wrong branch, missing required field), the specialist rejects the brief and falls back to standalone behavior with full prompts. Log which check failed.

## What gets skipped in specialist mode

Confirmations that verify *state* are skipped when seeded; confirmations that drive *discovery* or *rigor* stay live.

| Specialist | Skipped when seeded | Always kept |
|-----------|---------------------|-------------|
| `/build` | repo-preflight, scope-preflight, scope-class confirmation | design gate (architecture must be cross-phase verified) |
| `/review` | repo-preflight | severity/finding-depth gates |
| `/verify` | repo-preflight | AC verification rigor |
| `/describe` | internal prior-art search (declared in Input section) | Product Pressure Test, grill-me interactions |
| `/specify` | scope-class + file-scope confirmation | AC derivation gates |
| `/architecture` | codebase-research / patterns-research subagent dispatches | architecture session (grill-me + devil's advocate) |
| `/design` | design-space research subagents | interactive design session |
| `/implement` | _(none — orchestrator role; preflights run at entry)_ | exhausted-exit prompt (rigor gate — suppressed only when `autonomous: true` in seed brief) |

Each specialist documents a "Specialist mode" subsection in its own SKILL.md naming which prompts it skips.

## Standalone invocation

When no seed brief is present, the specialist runs with all prompts as documented in its SKILL.md. There is no partial-brief state — either a valid `<seed-brief>` block is present or the specialist runs standalone.

## Orchestrator responsibilities

When an orchestrator spawns a specialist, it must:

1. Run repo-preflight (see `${CLAUDE_PLUGIN_ROOT}/_shared/repo-preflight.md`) once at entry — not per specialist.
2. Run scope-preflight (see `${CLAUDE_PLUGIN_ROOT}/_shared/scope-preflight.md`) once at entry — not per specialist.
3. Pass a valid seed brief with `preflight_verified: true` to every specialist it spawns.
4. Include the verified `repo`, `branch`, and `active_issue` in every brief so specialists can sanity-check without re-running preflight.

Orchestrators that follow this contract: `/implement` → `/build`, `/review`, `/verify`; `/discovery` → `/describe`, `/specify`; `/define` → `/architecture`, `/design`, `/specify`.

## See also

- `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` — seed-brief types (research, prior-art, fix) and the full field list for each.
- `${CLAUDE_PLUGIN_ROOT}/_shared/repo-preflight.md` — the preflight protocol orchestrators run once at entry.
- `${CLAUDE_PLUGIN_ROOT}/_shared/scope-preflight.md` — the scope-preflight protocol orchestrators run once at entry.
