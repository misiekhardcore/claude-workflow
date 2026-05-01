# NOTES.md — In-Phase Memory Tier

`.claude/NOTES.md` is the **rot-immune external memory** for in-phase state. Because in-context recall degrades as a session accumulates concepts, the model cannot trust its own memory of what it decided ten turns ago — `.claude/NOTES.md` is where that state lives durably, on disk, outside the rotting context.

This file is reference material — read it on demand when a skill creates, updates, or harvests `.claude/NOTES.md`. Do not preload.

## Where it sits in the memory hierarchy

Four tiers, no overlap:

| Tier | Where | Lifetime | Authoritative for |
|------|-------|----------|-------------------|
| `TodoWrite` | In-context | This session only | Throwaway working scratchpad |
| `.claude/NOTES.md` | Worktree-local file (gitignored) | This phase, across sessions | In-flight decisions, current task, open questions |
| GitHub issue | Remote | Cross-phase | Acceptance criteria, prior-phase decisions, handoff state |
| Durable vault (optional) | The claude-obsidian vault (git-tracked) | Durable, cross-feature | Compounded knowledge — patterns, bug-fix history, architectural insights |

`TodoWrite` and `.claude/NOTES.md` are not mirrored — they serve different roles, and manual sync invites drift. The durable vault tier only materializes when the `claude-obsidian` plugin is installed and a vault has been bootstrapped (`/wiki`); without it, the tier is absent and skills that would write to it degrade gracefully.

## NOTES.md vs the vault's recency channels

The `claude-obsidian` plugin ships its own running-memory mechanisms inside the vault. They look superficially similar to `.claude/NOTES.md` but serve a different purpose — keep the boundary sharp:

| Artifact | Scope | Lifetime | Written by | Committed? |
|---|---|---|---|---|
| `.claude/NOTES.md` | One worktree, one feature | Ends when the worktree is removed | `/build` (scratch while coding) | No (gitignored) |
| Vault hot cache | Whole repo, all work | Cross-session, curated recent context | `/save`, `/compound`, or manual vault edits | Yes |
| Session archive | One session's archive | Permanent | `/save` at session end (Karpathy-style session capture) | Yes |
| Vault log | Whole repo | Permanent, append-only | Every `/save` or `/compound` emits a line | Yes |

Rule of thumb:
- **While working** — log to `.claude/NOTES.md`. It's phase-local scratch; nothing leaves the worktree.
- **Between sessions on the same feature** — resume from `.claude/NOTES.md` (it's the authoritative in-flight state).
- **Between features** — promote durable learnings to the vault's concept notes via `/compound` (which delegates to `claude-obsidian`'s `/save` when available). That's what crosses the worktree boundary.
- **Want a quick "what have I been working on lately" cache across the repo** — that's the vault's hot cache, not NOTES.md. Hot cache is curated and committed; NOTES.md is raw and ephemeral.

`/implement` is the harvest point: at PR creation it reads NOTES.md, flows the decisions and open questions into the PR body, then deletes NOTES.md after `/compound` has run.

## Location and lifecycle

- **Path:** `<worktree-root>/.claude/NOTES.md`. Resolve the worktree root with `git rev-parse --show-toplevel` if CWD is uncertain. One per worktree, one per feature.
- **Created by `/build`** at the start of the phase, immediately after `git worktree add`, with the initial task list harvested from the issue.
- **Updated by `/build`** after each completed task, each significant decision, and before any summarization-based `/compact`.
- **Read on resume by `/build`** — before re-reading the issue.
- **Harvested by `/implement`** at PR-creation time — `## Decisions made this session` and `## Open questions` flow into the PR body's `## Notes` section.
- **Deleted by `/implement`** after `/compound` has run. If `/implement` exits abnormally between PR creation and deletion, NOTES.md persists; `/wrap-up`'s worktree removal will clean it up implicitly.
- **Left in place** by standalone `/build`, `/review`, or `/verify` runs — they do not open PRs and do not harvest. Cleanup happens when the worktree is removed (`wt remove` deletes the worktree directory and `.claude/NOTES.md` goes with it).
- **Not committed to git.** Ensure `/.claude/NOTES.md` is gitignored at the repo root before creating it; add the entry if missing.

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

Update at these points (bullet-level only — fast):

- **After each completed task** — flip the checkbox, log any decision that resulted from completing it.
- **After each significant decision** — one line, with rationale.
- **Before any summarization-based `/compact`** — write the Keep list into the file *first*, so the post-compaction summary can be diffed against an external record.
- **Before ending the session normally** — `/implement` will harvest it at PR-creation time.

Do not update for trivial moves (opening a file, running a test command). It is a checkpoint log, not a transcript.

## Resume protocol

On a fresh session in an existing worktree, `.claude/NOTES.md` exists ⇒ this is a resume:

1. Read `./.claude/NOTES.md` first.
2. Read the GitHub issue second (for cross-phase decisions and acceptance criteria).
3. Resume from **Next action on resume** — or, if that field is stale, from the first unchecked item in the Task list.
4. Before your first real action, update **Current task** and **Next action on resume** to reflect the new session.

## Rules

- **`.claude/NOTES.md` is authoritative for in-flight state.** In-context recall is rot-degraded by the time the file matters; trust the file.
- **The issue is authoritative for cross-phase state.** Acceptance criteria, locked architectural decisions, prior-phase handoff content live in the issue, not the file.
- **Deletion is `/implement`'s responsibility.** It deletes NOTES.md after `/compound` runs at PR-creation time. Standalone `/build` runs leave it in place — do not delete from within a running build phase.

## Why

Context rot makes in-context recall unreliable for long sessions, even when the window is nowhere near full. The fix is to externalize the state that the model needs to trust — onto disk, in a file the model re-reads on demand. A gitignored worktree-local worklog is the cheapest durable answer. See `${CLAUDE_PLUGIN_ROOT}/docs/context-hygiene.md` for the full rationale and `${CLAUDE_PLUGIN_ROOT}/docs/token-budgets.md` for the <1k cap alongside the other artifact budgets.
