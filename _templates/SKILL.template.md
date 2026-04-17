---
name: "<skill-name>"
description: "<one-to-two sentence description — the primary trigger mechanism. Include both WHAT the skill does AND WHEN to use it (contexts, trigger phrases). Be specific: 'Does X. Use when Y.' Avoid generic phrasing.>"
model: "<haiku | sonnet | opus>"
# Uncomment the next line only if this skill runs long-form multi-turn research or decision-making:
# effortLevel: high
# Uncomment the next line only if the skill should be restricted to a subset of tools; omit entirely to allow all tools:
# allowed-tools: Read, Grep, Glob, Bash
---

<!--
Author note: the frontmatter above uses YAML-valid placeholder strings and YAML comments. Replace the "<…>" strings with real values (keep the quotes, or drop them once the value is a simple identifier). Leave the commented `effortLevel` / `allowed-tools` lines commented out unless the skill needs them, then uncomment and fill in.

Optional opening statement — use for phase-boundary skills. Example: "You are leading the X phase. Your job is to..."
-->

## Input

<!-- What the skill expects — issue number, problem statement, diff, conversation context, etc. -->

## Process

<!-- Numbered steps. Be concrete: what to read first, what to spawn, what to output at each step. -->

1. <first step>

2. <second step>

## Output

<!-- What the skill produces — a file, a report, a PR, an updated issue body, etc. -->

## Rules

<!-- Non-negotiable constraints — things that must always or never happen. -->

- <rule 1>
- <rule 2>
