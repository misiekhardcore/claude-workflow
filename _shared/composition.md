# Multi-Skill Composition — Reference

Read when authoring an orchestrator skill or composing workflows.

**Prerequisite**: `TeamCreate` requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Without it, use sequential subagents or inline.

## Skill roles

|Role|Definition|Examples|Typical model|
|-|-|-|-|
|**Orchestrator**|Leads a phase; spawns and coordinates specialists; writes the handoff artifact|`/discovery`, `/define`, `/implement`|`opus`|
|**Specialist**|Executes a bounded task; receives a seed brief; reports findings to the orchestrator|`/build`, `/review`, `/verify`, `/architecture`, `/specify`|`sonnet`|
|**Interactive primitive**|Reusable inline behavior; invoked by specialists; no team, no handoff|`/grill-me`|`sonnet`|

A primitive differs from a specialist by having no internal team and no handoff artifact. The authoring standard further splits **Orchestrator** into _research-leading_ (with research team) and _coordinator_ (sequences sub-skills; no research team), and adds **Utility** for maintenance skills (`/compound`, `/prune`, `/resolve-pr-feedback`, `/find-skills`) with no seed-brief contract.

## Composition patterns

|Pattern|Shape|When to use|
|-|-|-|
|**Linear**|A → B → C|Strict ordering; each step depends on the previous output|
|**Branch**|A → (B or C)|Mutually exclusive paths driven by a condition (scope class, flag, file type)|
|**Loop**|A → B → A (on fail)|Iterative refinement; fix cycles in `/implement`|
|**Parallel**|A → (B ∥ C) → merge|Independent work streams; requires `TeamCreate`|

Prefer linear until independence is confirmed. Parallel adds coordination overhead.

## Right-sizing the team

Scope is a cost gradient — each step up multiplies token usage:

|Scope|Heuristic|Primitive|~Cost vs single session|
|-|-|-|-|
|**Lightweight**|Single file / tightly scoped / no unknowns|Inline single agent|≈ 1×|
|**Standard**|Multi-file / typical feature / some unknowns|2–3 sequential subagents|≈ 2–4× total|
|**Deep**|Cross-module / security / breaking change / architecture-changing|All specialists, optionally `TeamCreate`|up to ≈ 7×|

> Agent teams use approximately 7x more tokens than standard sessions when teammates run in plan mode, because each teammate maintains its own context window and runs as a separate Claude instance.
> — [Anthropic, _Manage costs effectively_](https://docs.anthropic.com/en/docs/claude-code/costs)

In the table above, interpret that quote as an approximate upper bound of **~7× total token usage** versus a single standard session, **not** ~7× additional on top of the baseline.

### What loads into a teammate

Each teammate is a fresh Claude Code instance loading CLAUDE.md, MCP servers, skills, and the spawn prompt. Conversation history, files-read cache, and intermediate tool results do not carry — hence N teammates cost ≈ N × single-session baseline.

### TeamCreate decision rubric

All four criteria must hold before paying the ~7× team premium:

1. **Communication pivot** — workers need to share findings mid-task. Single-pass synthesis via subagents is cheaper.
2. **File disjointness** — non-overlapping file sets, or merge conflicts will swallow speedup.
3. **Classifiably parallel task shape** — sequential reasoning degrades 39–70% under multi-agent systems (DeepMind / MIT, _Towards a Science of Scaling Agent Systems_, arXiv:2512.08296).
4. **Expected wall-clock payoff ≥ 3×** — parallelism buys wall-clock time, not tokens. Below 3×, cost is not justified.

Rules:

- Default: inline → subagent → TeamCreate. Never pay overhead for under-a-minute work.
- Collapse adjacent roles when inputs are trivial.
- Gate optional specialists on concrete signals (diff patterns, scope class, file paths), not discretion.

### Main-thread overrun

Counter-rule to "default to single-agent": delegating prevents overrun even below the TeamCreate threshold.

**Delegate to a subagent when any of these conditions hold:**

1. **Multi-file read sweep** — task requires ≥5 independent files whose combined output saturates the lead's context before synthesis (e.g., audit all SKILL.md files, walk large dependency graph).
2. **N-way fan-out over independent items** — task processes N self-contained items, each returning only a short summary (e.g., reply-drafting per PR thread). Signal: `N × item_size > context_budget`, not N alone.
3. **Verbose I/O with thin synthesis** — work is pure retrieval/formatting (fetch, parse, stat); lead only needs the distilled result. Lead's intermediate echo adds no reasoning value.

Examples: each `/prune` lane, each `/resolve-pr-feedback` reply, `/find-skills` discovery pass.

**What to pass in the spawn prompt** — sub-agents do not inherit parent's CWD or cache:
1. `cd <abs-path> && pwd` — verify CWD before reading files.
2. Absolute paths or pre-enumerated file lists.
3. Load-bearing prior findings — no implicit context inheritance.

See `/discovery` and `/review` SKILL.md for Scope Assessment examples.

## Structured briefs

A **seed brief** is context passed from orchestrator to specialist at spawn time, replacing the specialist's own research phase.

### Research brief

|Field|Content|
|-|-|
|`tech_stack`|Languages, frameworks, key libraries|
|`module_map`|Modules, boundaries, ownership|
|`patterns`|3+ direct pattern examples from codebase|
|`prior_art`|Vault concepts or external references|
|`open_questions`|Unresolved constraints specialist must handle|

### Prior-art brief

|Field|Content|
|-|-|
|`problem_domain`|Domain area the feature touches|
|`existing_patterns`|Similar features or prior solutions in codebase|
|`constraints`|Non-negotiable constraints from discovery|

### Fix brief

|Field|Content|
|-|-|
|`failing_ac`|Failing acceptance criteria|
|`findings`|Reviewer findings as `file:line — description`|
|`prior_decisions`|Architectural decisions that must not be reversed|

## Seed-brief contract

1. Pass as structured input at spawn time, not conversationally.
2. Specialist checks for brief at startup and skips research phase if present.
3. Keep bounded — never pad with information the specialist can find itself.

**Transport format** — raw YAML in an XML tag, no inner fence:

```
<seed-brief>
preflight_verified: true
scope_class: Standard
repo: owner/repo
branch: feat/branch-name
active_issue: 42
payload:
  type: fix|research|prior-art
  # type-specific fields from tables above
</seed-brief>
```

The XML tag marks the boundary. The `payload` envelope decouples brief metadata from type-specific content. See `specialist-mode.md` for detection mechanism, validation rules, and standalone fallback.

## Hierarchical decomposition

Orchestrators may nest: `/discovery` → `/describe`, `/specify`; `/implement` → `/build`, `/review`, `/verify`.

- Maximum two levels of orchestration. Deeper nesting creates brittle context chains.
- Each level owns its own handoff boundary — do not skip levels.
- Sub-orchestrators do not inherit parent handoff artifact. Seed with brief.

## Handoff vs. seed brief

||Handoff artifact|Seed brief|
|-|-|-|
|**Stored in**|GitHub issue body (durable)|In-context at spawn (ephemeral)|
|**Crosses**|Phase boundaries|Intra-phase specialist boundaries|
|**Authoritative for**|Acceptance criteria, prior decisions, open questions|Research context, prior art, fix findings|
|**Written by**|Phase-boundary orchestrators|Research agents, review/verify specialists|

Only handoff artifacts update the issue body; seed briefs are ephemeral.

## Failure modes

|Mode|Symptom|Mitigation|
|-|-|-|
|**Context bleed**|Specialist output leaks into the next specialist's context|Pass seed briefs explicitly; do not forward full conversation history|
|**Brief inflation**|Seed briefs grow to include everything, defeating compression|Cap briefs to the fields above; omit what the specialist can find itself|
|**Over-parallelization**|Parallel specialists produce contradictory outputs|Serialize when outputs must agree (e.g., architecture before design)|
|**Missing flag**|`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is unset|Fall back to sequential; note degraded mode explicitly|
|**Handoff-brief confusion**|In-phase briefs get written to the issue body|Seed briefs are ephemeral; only handoff artifacts update the issue body|
|**Inline overrun**|Lead session bloats reading large files / verbose tool output|Delegate verbose work to a subagent; only the summary returns to context|
|**Subagent re-research**|Custom subagents start fresh and re-read files the lead loaded|Pass file paths and prior findings in the spawn prompt — no inheritance|
|**Team idle drift**|Teammates left running after the task is done keep burning tokens|Shut down explicitly; idle teammates do not auto-terminate|
|**`/batch` cross-talk**|Batched items try to coordinate via filesystem side effects|Use `TeamCreate` when coordination is required; `/batch` assumes self-contained items|

