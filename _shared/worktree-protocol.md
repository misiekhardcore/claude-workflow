# Worktree Protocol — Shared Reference

Standard commands for creating and managing feature worktrees.

## Create

```bash
git checkout <base-branch> && git pull
git worktree add .worktrees/<branch> -b <branch>
cd .worktrees/<branch>
git branch --set-upstream-to=origin/<base-branch>
```

`<base-branch>` is `main` for top-level features, or a parent branch for dependent sub-features.

## Verify

```bash
git worktree list
git rev-parse --abbrev-ref HEAD   # must equal <branch>
```

## Remove

Handled by `/wrap-up`. Do not remove manually unless instructed.
