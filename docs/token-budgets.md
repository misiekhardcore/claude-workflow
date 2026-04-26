# Token Budgets

User-facing budgets and CLAUDE.md placement rules that the rest of this plugin assumes. Read this once when setting up the workflow on a new project; revisit when the model starts misbehaving in long sessions.

The companion doc [`context-hygiene.md`](context-hygiene.md) explains *why* the workflow resets between phases; this doc gives the concrete numbers and placement rules that make those resets cheap.

## The threshold

Context rot — degradation of retrieval, reasoning, and instruction-following — kicks in well before the window fills. Anthropic's guidance: treat the rot threshold as roughly **12% of the window** (~120k of a 1M-token model), not the window itself ([Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)). Every budget below is sized so a phase finishes under that threshold with margin.

## Per-artifact budgets

The lifecycle moves state between three artifact tiers. Each has a hard cap that other skills assume:

| Artifact | Cap | Why this number |
| --- | --- | --- |
| `.claude/NOTES.md` (per session) | **<1k tokens** | Re-read on every resume and before every `/compact`; must fit in one screen ([`_shared/notes-md-protocol.md`](../_shared/notes-md-protocol.md)) |
| GitHub issue body (handoff artifact) | **<2k tokens** | Loaded fully at the start of every phase; the five-field shape in [`_shared/handoff-artifact.md`](../_shared/handoff-artifact.md) targets this |
| Seed brief to a sub-agent | **<500 tokens** | A brief is objective + constraint + report contract — not session history. Sub-agents return 1–2k token reports, not the briefs they received |
| Sub-agent report back to lead | 1–2k tokens | Quoted from Anthropic's reference figure for the isolation pattern; enforced by asking for a "focused report bounded by what the lead needs to decide" |

If any artifact crosses its cap, the cause is almost always content that belongs in another tier: a long decision log in NOTES.md belongs in the issue body; a seed brief restating the conversation belongs in the issue body, not the brief.

## Per-phase budgets

The full session context — system prompt + CLAUDE.md + prior turns + tool output — at handoff:

| Phase boundary | Target context size | Verification |
| --- | --- | --- |
| End of `/discovery` | **<15k tokens** | `/context` after the issue body is written, before resetting |
| End of `/define` | **<15k tokens** | Same — define ends with the implementation plan written into the issue |
| End of `/implement` (build → review → verify) | **<20k tokens** | `/context` after the draft PR is opened |

These are *targets*, not enforced caps. They exist to make it obvious when a phase is dragging context that should have been delegated or reset. Crossing 30k near a phase boundary is the signal to bring forward the next reset and harvest into the issue body.

### Verification with `/context`

Run `/context` at the start and end of each phase:

```
/context
```

Compare the system + tools + messages totals against the targets above. The relevant deltas:

- **System + CLAUDE.md jumps between sessions** → a CLAUDE.md edit grew the per-turn cost. Trim or move content out (see CLAUDE.md placement below).
- **Messages line growing toward 30k inside a phase** → run context editing or delegate the next bulk lookup to a sub-agent ([`_shared/compaction-protocol.md`](../_shared/compaction-protocol.md)).
- **End-of-phase total over target** → harvest into the issue body now, do not carry conversation across the boundary.

## CLAUDE.md placement

CLAUDE.md is loaded verbatim every turn. Where the file lives determines who pays for it.

| Path | Loaded by | Lifetime | Use for |
| --- | --- | --- | --- |
| `~/.claude/CLAUDE.md` | Every session, every project | User-global | Tone, formatting, global rules, memory-system pointers |
| `./CLAUDE.md` | Every session in this repo | Project, committed to git | Tech stack, build commands, project invariants, directory map |
| `./CLAUDE.local.md` | Every session in this repo, only on this machine | Personal, **gitignored** | Local overrides, personal scratch rules, machine-specific paths |
| `./<subdir>/CLAUDE.md` | Sessions whose CWD enters that subdir | Subsystem | Subsystem quirks that don't apply to the whole repo |

All files in the current path stack are loaded *additively* — global + project + subdir all pay tokens on every turn. Don't duplicate rules across levels.

**Sizing targets** (from Anthropic's [costs guidance](https://code.claude.com/docs/en/costs) and the wiki concept note `claude-md-sizing`):

| Scope | Recommended | Hard cap |
| --- | --- | --- |
| Global `~/.claude/CLAUDE.md` | <50 lines | 100 lines |
| Project `./CLAUDE.md` | <200 lines | 300 lines |
| Subdirectory `./sub/CLAUDE.md` | <50 lines | 100 lines |

Move out anything not used in the majority of sessions: long rule blocks (>50 lines) into a dedicated `REFERENCE.md` read on demand; workflow-specific instructions (PR review, migration steps) into skills that load only when invoked.

## `@`-imports

CLAUDE.md supports `@path/to/file` to inline another markdown file at load time. Imports recurse up to **5 hops** ([Memory docs](https://code.claude.com/docs/en/memory)).

```markdown
# CLAUDE.md

Tone and global rules go here directly.

For the full lifecycle walkthrough — only relevant when working in this repo:
@docs/workflow.md

Personal overrides (gitignored, optional):
@CLAUDE.local.md
```

The cost of an `@`-import is identical to inlining the same content — imports are a *organization* tool, not a deferral mechanism. If a doc is only useful sometimes, link it (`See [docs/X.md](...) when ...`) rather than `@`-importing it.

## Avoid skill-invocation duplication

Each `/skill` invocation loads the full skill body verbatim into context. Invoking the same skill multiple times duplicates that body — the model already has the content from the first invocation, and the second copy adds rot without adding information. Documented as upstream [anthropics/claude-code#11065](https://github.com/anthropics/claude-code/issues/11065).

**Rule:** invoke each skill **once per task**. Downstream turns reference its outputs — the issue body, NOTES.md, the diff, the previous tool result — not a re-invocation.

**Anti-pattern:**

```
/discovery   # writes issue #482
/define      # writes the implementation plan into #482

# later in the same session, after some confusion:
/discovery   # re-loads the entire skill body to "re-check the spec"
```

The fix: read the issue body or NOTES.md instead. The skill body has nothing to add on a re-read — the artifacts it produced are what carry the state.

This is a different failure from `/compact` over-aggression: `/compact` paraphrases reasoning, while skill duplication just inflates the context with identical text. Both raise the rot floor; only one is trivially avoidable.

## When to read this doc

- Setting up a new project: pick CLAUDE.md placement and trim the template.
- The model starts confusing phases or re-litigating decisions: check the per-phase totals with `/context`.
- A skill author asks "where should this rule live": placement table above answers it.
- Reviewing a PR that grows CLAUDE.md by >20 lines: justify against the sizing targets.

## See also

- [`context-hygiene.md`](context-hygiene.md) — *why* phases reset and how the four hygiene rules interact.
- [`cross-plugin.md`](cross-plugin.md) — MCP-server sizing (each server adds tool-name overhead even when schemas defer).
- [`_shared/notes-md-protocol.md`](../_shared/notes-md-protocol.md) — `.claude/NOTES.md` shape and update cadence.
- [`_shared/handoff-artifact.md`](../_shared/handoff-artifact.md) — five-field issue-body structure.
- [`_shared/composition.md`](../_shared/composition.md) — sub-agent vs `TeamCreate` cost rubric.

## Sources

- Anthropic — [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- Anthropic — [Claude Code costs](https://code.claude.com/docs/en/costs) — CLAUDE.md "under 200 lines" guidance
- Anthropic — [Memory](https://code.claude.com/docs/en/memory) — `@`-import syntax and recursion limit
- Anthropic — [Managing context on the Claude Developer Platform](https://www.anthropic.com/news/context-management) — 84% context-editing reduction figure
- anthropics/claude-code#11065 — skill-invocation duplication bug report
