# Cleanup Procedure for wrap-up

Steps 2–4 (state machine + confirmations) apply only in **standalone mode**. When `confirmed` is passed as a skill arg (or wrap-up-runner is spawned directly), skip directly to Step 5 after Step 1.

## Step 1 — Detect state

Gather via:

1. **Worktree path** — `git rev-parse --show-toplevel` or use path user provides.
2. **Branch name** — `git rev-parse --abbrev-ref HEAD`.
3. **Default branch** — `git symbolic-ref refs/remotes/origin/HEAD --short` (strips `origin/`). Fall back to `['main', 'master', 'develop']` only if symbolic-ref lookup fails; log the method used.
4. **Worktree membership** — `wt list`. Confirm worktree path appears in list.
5. **Working-tree cleanliness** — `git status --short` and `git log @{u}..HEAD --oneline` (unpushed commits not in PR).
6. **PR state** — if user provided PR number, run `gh pr view <N> --json state,headRefName` to confirm it is open and points to current branch.

## Step 2 — Apply state machine

|Condition|Outcome|
|-|-|
|Branch matches default branch|**Refuse outright.** No proceed-anyway prompt|
|Worktree path not in `wt list`|**Refuse outright.** Out-of-tree paths never managed by `/wrap-up`|
|Worktree dirty (uncommitted changes or unpushed commits not in PR)|**Show state + proceed-anyway prompt** (Step 3)|
|Worktree clean, feature branch, worktree in-tree|**Single confirmation** (Step 4)|

## Step 3 — Dirty worktree: proceed-anyway prompt

Show what is dirty (uncommitted files, unpushed commit list). Then ask:

> The worktree has unsaved state (shown above). Proceed with removal anyway?
> On yes, I will use `git branch -D` (force-delete) if unpushed commits would be lost.

Wait for explicit confirmation. Do not proceed on silence.

## Step 4 — Single confirmation (clean or dirty-with-override)

Show the exact actions that will run:

> I will:
> - `wt remove <branch>` (removes the worktree directory, its contents including `.claude/NOTES.md` if present, and the branch)
>
> Proceed?

Wait for explicit confirmation. Do not proceed on silence.

## Step 5 — Execute and report

On confirm:

1. `wt remove <branch>` (or `wt remove --force-delete <branch>` when dirty-worktree override was confirmed and commits would be lost).
2. Report what was removed: worktree path, branch name, whether NOTES.md was present.
