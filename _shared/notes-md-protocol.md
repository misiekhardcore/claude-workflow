# NOTES.md — In-Phase Memory Tier

`.claude/NOTES.md` is rot-immune external memory for in-phase state. Read on-demand when creating, updating, or harvesting; do not preload.

## Where it sits in the memory hierarchy

Four tiers:

|Tier|Where|Lifetime|Authoritative for|
|-|-|-|-|
|`TodoWrite`|In-context|This session|Throwaway scratchpad|
|`.claude/NOTES.md`|Worktree-local, gitignored|This phase, across sessions|In-flight decisions, task progress, current task, open questions|
|GitHub issue|Remote|Cross-phase|Acceptance criteria, prior-phase decisions, handoff state|
|Durable vault|claude-obsidian vault (git-tracked)|Durable, cross-feature|Patterns, bug-fix history, architectural insights|

Do not mirror `TodoWrite` and `.claude/NOTES.md` — they serve different roles. The vault tier materializes when `claude-obsidian` is installed; without it, skills that would write degrade gracefully.

## NOTES.md vs the vault's recency channels

|Artifact|Scope|Lifetime|Committed?|
|-|-|-|-|
|`.claude/NOTES.md`|One worktree, one feature|Ends when worktree removed|No (gitignored)|
|Vault hot cache|Whole repo, all work|Cross-session, curated|Yes|
|Session archive|One session|Permanent|Yes|
|Vault log|Whole repo|Permanent, append-only|Yes|

- **While working** — log to `.claude/NOTES.md` (phase-local scratch).
- **Between sessions on same feature** — resume from `.claude/NOTES.md` (authoritative in-flight state).
- **Between features** — promote durable learnings to vault via `/compound`. That crosses the worktree boundary.
- **For recent context across repo** — use vault's hot cache (curated, committed), not NOTES.md (raw, ephemeral).

`/implement` is the harvest point: at PR creation it reads NOTES.md, flows the decisions and open questions into the PR body, then deletes NOTES.md after `/compound` has run.

## Location and lifecycle

- **Path:** `<worktree-root>/.claude/NOTES.md`.
- **Created by the agent that starts the phase** — either an orchestrator (L1) or a standalone skill (L2 like `/build`). The creator owns the file.
- **Updated by the owning agent** after each completed task, significant decision, returned sub-agent result, or before spawning a sub-agent (checkpoint).
- **NOT managed by spawned sub-agents** — when an L2 skill is called by an orchestrator, it receives a NOTES.md slice via seed-brief `progress:` field but does **not** write to NOTES.md (the orchestrator owns it). Spawned skills use `TodoWrite` for their ephemeral scratchpad.
- **Read on resume** — before re-reading the issue, reconstruct state from NOTES.md.
- **Harvested by `/implement`** at PR-creation time. `## Decisions made this session` and `## Open questions` flow into PR body's `## Notes` section.
- **Deleted by `/implement`** after `/compound` runs. If `/implement` exits abnormally, NOTES.md persists; `/wrap-up` cleans it up with worktree removal.
- **Left in place** by standalone skills — cleanup happens when worktree is removed.
- **Not committed to git.** Ensure `/.claude/NOTES.md` is gitignored; add entry if missing.

## Required sections

`.claude/NOTES.md` is a bullet list, not prose. Keep the whole file readable in one screen — it should cost <1k tokens to re-read.

```markdown
# NOTES — feat/<feature-slug>

## Current task
- <the one thing you are working on right now>

## Task list
- [x] <done task>
- [ ] <pending or in-progress task — first unchecked item is the current one>
- [!] <blocked task — with reason>

## Decisions made this session
- <one-line decision> (why: <rationale>)
- ...

## Open questions
- <question that needs the user or next phase to resolve>

## Next action on resume
- <exact command or file to open if the session dies>
```

## Update cadence

Update at these points (bullet-level only):

- **After each completed task** — flip checkbox, log any decision.
- **After each significant decision** — one line with rationale.
- **Before any `/compact`** — write Keep list first, so post-compaction summary can be diffed against external record.
- **Before ending session normally** — `/implement` harvests at PR-creation time.

Don't update for trivial moves (opening file, running test). Checkpoint log, not transcript.

## Resume protocol

When `.claude/NOTES.md` exists in worktree, it's a resume:

1. Read `./.claude/NOTES.md` first.
2. Read the GitHub issue second (cross-phase decisions and acceptance criteria).
3. Resume from **Next action on resume**, or from first unchecked item in Task list if stale.
4. Update **Current task** and **Next action on resume** before first real action.

## Standalone skill pattern

A standalone L2 skill (e.g. `/build` invoked directly by the user, not by an orchestrator) uses NOTES.md as a lightweight progress tracker:

1. **Create** — On entry, create NOTES.md with `## Task list`, `## Decisions made this session`, and `## Next action on resume`.
2. **Update** — Flip checkboxes as tasks complete, log decisions, update `## Current task` and `## Next action on resume` at each natural breakpoint.
3. **Leave** — On exit, leave NOTES.md in place for `/implement` to harvest. Do not delete.

No checkpoint-before-spawn is needed — standalone skills do not spawn sub-agents. The pattern is create → update → leave.

## Orchestrator checkpoint pattern

Orchestrators use NOTES.md as the progress ledger for multi-step pipelines that delegate to sub-agents. The pattern:

1. **Create** — On entry (after preflight), create NOTES.md with the full task list derived from work units.
2. **Checkpoint before sub-agent spawn** — Write `## Current task` (what the sub-agent will do) and `## Next action on resume` (how to reconstruct if session dies) before every `Skill()` or `Agent()` call. This ensures crash-safe resume.
3. **Update after sub-agent returns** — Flip checkboxes, log results and decisions from the agent's findings report.
4. **Wrap-up** — On clean exit, leave NOTES.md in place for `/implement` to harvest. On abnormal exit, NOTES.md serves as the resume point.

### Seed-brief slice

When spawning a sub-agent, include a relevant slice of NOTES.md in the seed-brief payload so the agent arrives with progress context:

```
<seed-brief>
...
payload:
  type: research
  progress: |
    ## Task list (relevant)
    - [x] Scope assessment → 3 work units
    - [ ] Build specialist (current)
    - [ ] Review specialist

    ## Decisions made this session
    - Split auth into own work unit (why: security isolation)
  open_questions: ""
</seed-brief>
```

Slice rules:
- Include only the subset of `## Task list` relevant to the spawned agent's scope.
- Include `## Decisions made this session` in full (decisions are global to the phase).
- Omit `## Current task` (the agent will set its own).
- Cap at 15 lines — the brief is not a state dump.

## Rules

- **NOTES.md is authoritative for in-flight state.** Trust the file; in-context recall is rot-degraded.
- **Issue is authoritative for cross-phase state.** Acceptance criteria, locked decisions, prior-phase handoff live in issue, not file.
- **The agent that creates NOTES.md owns it.** Standalone L2 skills own their own NOTES.md. Orchestrators own the NOTES.md their sub-agents receive slices of.
- **Spawned sub-agents do not write to NOTES.md.** They receive context via the seed-brief `progress:` field and use `TodoWrite` for ephemeral state.
- **Deletion is `/implement`'s responsibility.** It deletes after `/compound` runs. Standalone skills leave in place.
- **Orchestrator checkpoints before every sub-agent spawn.** If the session dies mid-spawn, NOTES.md must contain enough state to reconstruct.
