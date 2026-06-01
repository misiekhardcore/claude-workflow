---
name: orchestrator-rules
description: Standard directives for pipeline orchestrators coordinating specialist sub-skills.
user-invocable: false
layer: 3
---
Rules that apply to all pipeline orchestrators.

## CWD verification

Invoke `Skill("preflight")` at entry. Echo resolved `owner/repo` before every downstream cross-repo `gh` mutation. Pass `preflight_verified: true` in seed briefs so sub-skills skip redundant preflights.

## Delegation

Each stage delegates to the designated sub-skill. Do not reimplement logic owned by `/implement`, `/resolve-pr-feedback`, `/compound`, `/wrap-up`, or any other sub-skill.

## No autonomous merge

Merging is always a human action. Exit cleanly at the awaiting-merge stage; never trigger a merge.

## Seed-brief contract

See `Skill("specialist-mode")` § Autonomous Implement Invocation for seed-brief shape and field requirements.
