---
name: build
description: Build a feature from a GitHub issue. Creates a git worktree, spawns a build team, and codes against the issue's acceptance criteria using TDD. Use after /define has produced approved architecture decisions.
model: sonnet
---

You are leading the build phase. Your goal is to take a fully specified GitHub issue and produce working code.

## Input

A GitHub issue number (with architecture/design decisions from /define) and any additional resources.

## Process

1. Read the issue, all comments, and linked sub-issues to understand the full scope.

2. **Create a git worktree** for the feature (`git worktree add`). Worktrees keep the main workspace clean and let teammates operate in isolation.

   Before creating `./.claude/NOTES.md`, verify `/.claude/NOTES.md` is listed in the repo root `.gitignore`; add it there if missing. Then create `./.claude/NOTES.md` with the initial task list harvested from the issue. This is the living worklog for the phase — it survives unexpected session close and is the resume point if this session dies before `/wrap-up`. See `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md`.

   **On resume in an existing worktree**, read `./.claude/NOTES.md` *before* re-reading the issue — it has the latest in-flight state. Resume from its **Next action on resume** field.

3. **Spawn an implementation team** using TeamCreate:
   - Assign each teammate a separate sub-issue or file group to avoid conflicts
   - Teammates communicate peer-to-peer, share discoveries, and flag potential conflicts
   - The lead coordinates via the shared task list and merges results

4. Each teammate follows **test-driven development (TDD)** for logic-heavy code:
   - Write a failing test first — derive test cases from the acceptance criteria
   - Implement until the test passes — minimal code to satisfy the test
   - Refactor — clean up while tests stay green
   - Skip TDD for pure boilerplate/wiring

5. **Verify before marking done** — run `superpowers:verification-before-completion` after each task. Mandatory, no user approval needed; fix any gaps before committing.

6. **Simplify as you go** — after every 2-3 task completions from the task list, do a quick consolidation scan:
   - Review files you just touched for obvious duplication, dead code, or consolidation opportunities
   - This is NOT a full refactor — just a fast scan for low-hanging improvements
   - If found, create a micro-task to consolidate before proceeding to the next implementation task
   - Keep it lightweight: "scan for obvious duplication in files you just touched"

7. **Keep context focused.** Trigger on **concept shifts**, not on a percentage:
   - Stale tool results in context after the work has moved on → clear them with **context editing** (verbatim — the default tool).
   - About to read a large file or grep wide paths → delegate to a sub-agent that returns a focused report (the lead never accumulates the bulk).
   - About to start a new sub-issue, or just spawned a sub-agent → natural reset point.
   - If summarization-based `/compact` is unavoidable: flush the working set into `./.claude/NOTES.md` first, emit a `Keep: / Drop:` note, run `/compact`, then diff the post-compaction summary against the Keep list **in `.claude/NOTES.md`** before the next tool call.

   See `${CLAUDE_PLUGIN_ROOT}/_shared/compaction-protocol.md`. Context editing first, sub-agents second, `/compact` last.

8. Commit changes incrementally using semantic commit messages (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`). Update `./.claude/NOTES.md` after each completed task — it is the resume point if the session dies unexpectedly.

## Output

A feature branch in a worktree with all acceptance criteria implemented, tests passing, and clean incremental commits. Ready for /review.

## Rules

- Use superpowers:test-driven-development for the TDD workflow
- Use `git worktree add` / `git worktree remove` for worktree management. [worktrunk](https://github.com/max-sixty/worktrunk)'s `wt` wrapper is an optional convenience when installed; the skill assumes only the stock `git worktree` commands.
- Use TeamCreate for team coordination
- Do not ask the user whether to use teams — just use them
- Do not open a PR — that happens after /implement completes the full cycle
- Always run the 5-question verification check before marking a task done
- Consolidation scans are lightweight — spend seconds, not minutes
- Context hygiene is a build-time responsibility, not a wrap-up afterthought — trigger on concept shifts, not percentages, and never let auto-compact run unattended
- `./.claude/NOTES.md` is authoritative for in-flight state; if your recall disagrees with the file, trust the file
