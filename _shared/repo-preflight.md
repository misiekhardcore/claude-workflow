# Repository Pre-flight — Shared Protocol

Used by skills that originate `gh` mutations or `git push` operations. Read this file when you reach a step that creates or edits issues, comments, PRs, or pushes code.

## Steps

1. Run `git remote -v` and `pwd` to detect the repository and working directory. Run `git branch --show-current` (or `git rev-parse --abbrev-ref HEAD`) to detect the current branch.
2. Display:
   - Detected repository (owner/repo from origin remote URL)
   - Current branch name (omit when the caller has set `Suppress branch line: true` colocated with the reference — used by worktree-spawning callers like `/implement` where the displayed branch would imply the work lands on the current branch)
   - Working directory path
3. Ask the user to confirm. Default prompt: "Does this match the repo and branch you intend to operate on?" Callers may override by setting a `Confirmation prompt:` line colocated with the reference.
4. Do not proceed with any `gh` or `git push` operation until the user explicitly confirms.

## Why

`gh` issue and PR mutations are public, persistent, and cross-repo (the `--repo` flag silently routes to a different upstream). A wrong-repo mutation has higher blast radius than a wrong-branch push. This single gate covers both surfaces.

## Orchestrator pattern

When an orchestrator (e.g. `/implement`) runs this preflight at entry, it passes `preflight_verified: true` in every seed brief it issues to specialists. Specialists skip this step when a valid seed brief is present — see `${CLAUDE_PLUGIN_ROOT}/_shared/specialist-mode.md`.
