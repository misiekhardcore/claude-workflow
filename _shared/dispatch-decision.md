# Dispatch Decision Reference

Condensed tables for dispatch decisions at authoring time and runtime. Full framework: `${CLAUDE_PLUGIN_ROOT}/docs/dispatch-primitives.md`.

## Role taxonomy

|Role|Runs in|User interaction|Dispatches|`context: fork`|
|-|-|-|-|-|
|**Orchestrator**|Main context|Yes|Optionally: other Orchestrators and/or Workers|Never|
|**Interaction**|Main context|Yes — only|Never|Never|
|**Worker**|Background/isolated|Task confirmations only|Optionally: other Workers|Always (Skill); implied (Agent file)|
|**Protocol**|Caller's context|N/A|Never|Never|

## `context: fork` — use when ALL hold

1. Explicit, argument-driven task (not behavioral guidelines).
2. No user deliberation during execution (task-level confirmations are fine).
3. Does not own orchestration state or user decision loops.

Never use on Orchestrators, Interactions, or Protocols.

## `agent:` selection (only with `context: fork`)

|Task type|`agent:`|
|-|-|
|Read-only, computation, pure reasoning over prompt input|`Explore` — Haiku model, no CLAUDE.md|
|Read-only: planning-phase analysis|`Plan` — no CLAUDE.md|
|Agent dispatch required, writes required, or `gh` mutations|`general-purpose`|

Always specify `agent:` explicitly — never rely on the silent `general-purpose` default.

## Worker Agent vs Worker Skill

|Use|When|
|-|-|
|Worker Skill (`context: fork`)|Task is user-invocable OR meaningful as its own skill directory|
|Worker Agent (`agents/*.md`)|Internal implementation detail, never user-invocable|

## `isolation: worktree`

Add to `Agent()` calls when spawning 2+ parallel agents with overlapping file scope. Skip when `/scope-assessment` guarantees disjoint scope.
