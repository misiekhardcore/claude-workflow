# Specialist Mode — Shared Protocol

A specialist runs in two modes: **standalone** (user-invoked) or **specialist** (orchestrator-invoked after preflights). Read when detecting invocation mode or documenting skipped prompts when seeded.

## Detection

Specialist detects specialist mode by checking for `<seed-brief>` block in prompt at startup:

```
if "<seed-brief>" in prompt → specialist_mode = True
```

When brief is present, verified fields replace specialist's preflight checks. When absent, specialist runs standalone with all prompts active.

## Seed-brief transport format

Orchestrators pass briefs as raw YAML in XML tag, no inner fence:

```
<seed-brief>
preflight_verified: true
scope_class: Lightweight|Standard|Deep
repo: owner/repo
branch: feat/branch-name
active_issue: 42
autonomous: false  # optional
payload:
  type: fix|research|prior-art
  # type-specific fields per composition.md
</seed-brief>
```

XML tag marks boundary. `payload` envelope decouples brief metadata from type-specific content.

## Required fields

|Field|Type|Required|Notes|
|-|-|-|-|
|`preflight_verified`|boolean|yes|Brief is rejected if `false` or missing|
|`scope_class`|string|yes|Must be `Lightweight`, `Standard`, or `Deep`|
|`repo`|string|yes|`owner/repo` — verified against `git remote -v` of the spawning worktree|
|`branch`|string|yes|`feat/<slug>` — verified against `git rev-parse --abbrev-ref HEAD`|
|`active_issue`|integer|yes|Ties the brief to its GitHub issue|
|`payload`|object|yes|`{ type: fix|research|prior-art, ... }` — type-specific fields per `_shared/composition.md`|
|`autonomous`|boolean|no|Default `false`. When `true`, suppresses `/implement`'s exhausted-exit prompt; only consumed by `/implement`. Do not set from non-autopilot orchestrators — default `false` preserves the rigor gate.|

Verification failure (wrong repo/branch, missing field) → specialist rejects brief, falls back to standalone with full prompts. Log which check failed.

## What gets skipped in specialist mode

Confirmations that verify *state* are skipped when seeded; confirmations that drive *discovery* or *rigor* stay live.

|Specialist|Skipped when seeded|Always kept|
|-|-|-|
|`/build`|repo-preflight, scope-preflight, scope-class confirmation|design gate (architecture must be cross-phase verified)|
|`/review`|repo-preflight|severity/finding-depth gates|
|`/verify`|repo-preflight|AC verification rigor|
|`/describe`|internal prior-art search (declared in Input section)|Product Pressure Test, grill-me interactions|
|`/specify`|scope-class + file-scope confirmation|AC derivation gates|
|`/architecture`|codebase-research / patterns-research subagent dispatches|architecture session (grill-me + devil's advocate)|
|`/design`|design-space research subagents|interactive design session|
|`/implement`|_(orchestrator; preflights at entry)_|exhausted-exit prompt (rigor gate; suppressed only when `autonomous: true`)|

Each specialist documents a "Specialist mode" subsection in its SKILL.md naming skipped prompts.

## Standalone invocation

No seed brief present → specialist runs with all documented prompts. No partial-brief state — either valid `<seed-brief>` block exists or specialist runs standalone.

## Orchestrator responsibilities

When spawning a specialist:

1. Run repo-preflight once at entry, not per specialist.
2. Run scope-preflight once at entry, not per specialist.
3. Pass valid seed brief with `preflight_verified: true` to every specialist.
4. Include verified `repo`, `branch`, `active_issue` in every brief for sanity-checking.

Established patterns: `/implement` → `/build`, `/review`, `/verify`; `/discovery` → `/describe`, `/specify`; `/define` → `/architecture`, `/design`, `/specify`.
