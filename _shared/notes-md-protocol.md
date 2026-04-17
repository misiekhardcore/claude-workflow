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
| Obsidian vault | `memory/wiki/` (git-tracked) | Durable, cross-feature | Compounded knowledge — patterns, bug-fix history, architectural insights |

`TodoWrite` and `.claude/NOTES.md` are not mirrored — they serve different roles, and manual sync invites drift.

## NOTES.md vs the vault's recency channels

The `claude-obsidian` plugin ships its own running-memory mechanisms inside the vault. They look superficially similar to `.claude/NOTES.md` but serve a different purpose — keep the boundary sharp:

| Artifact | Scope | Lifetime | Written by | Committed? |
|---|---|---|---|---|
| `.claude/NOTES.md` | One worktree, one feature | Ends when the worktree is removed | `/build` (scratch while coding) | No (gitignored) |
| `memory/wiki/hot.md` | Whole repo, all work | Cross-session, curated recent context | `/save`, `/compound`, or manual edits | Yes |
| `memory/wiki/meta/<session>.md` | One session's archive | Permanent | `/save` at session end (Karpathy-style session capture) | Yes |
| `memory/wiki/log.md` | Whole repo | Permanent, append-only | Every `/save` or `/compound` emits a line | Yes |

Rule of thumb:
- **While working** — log to `.claude/NOTES.md`. It's phase-local scratch; nothing leaves the worktree.
- **Between sessions on the same feature** — resume from `.claude/NOTES.md` (it's the authoritative in-flight state).
- **Between features** — promote durable learnings to `memory/wiki/concepts/` via `/compound` (or the plugin's `/save`). That's what crosses the worktree boundary.
- **Want a quick "what have I been working on lately" cache across the repo** — that's `memory/wiki/hot.md`, not NOTES.md. Hot cache is curated and committed; NOTES.md is raw and ephemeral.

`/wrap-up` is the bridge: it harvests NOTES.md at clean exit and drafts a GitHub-issue comment, and it's the natural trigger point to ask whether anything in NOTES.md deserves promotion to the vault.

## Location and lifecycle

- **Path:** `<worktree-root>/.claude/NOTES.md`. Resolve the worktree root with `git rev-parse --show-toplevel` if CWD is uncertain. One per worktree, one per feature.
- **Created by `/build`** at the start of the phase, immediately after `git worktree add`, with the initial task list harvested from the issue.
- **Updated by `/build`** after each completed task, each significant decision, and before any summarization-based `/compact`.
- **Read on resume by `/build`** — before re-reading the issue.
- **Harvested by `/wrap-up`** into a GitHub issue comment on clean exit.
- **Left in place** after the phase ends. Cleanup happens when the worktree is removed (`wt remove` deletes the worktree directory and `.claude/NOTES.md` goes with it). Do not delete it from within a running phase.
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
- **Before ending the session normally** — `/wrap-up` will harvest it.

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
- **Never delete it automatically.** The owning session may archive it on clean exit; do not remove it from within a running phase.

## Why

Context rot makes in-context recall unreliable for long sessions, even when the window is nowhere near full. The fix is to externalize the state that the model needs to trust — onto disk, in a file the model re-reads on demand. A gitignored worktree-local worklog is the cheapest durable answer. See `memory/wiki/concepts/Context Hygiene Between Workflow Phases.md` for the full rationale.
