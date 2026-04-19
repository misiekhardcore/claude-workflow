---
name: "<skill-name>"
description: "<Does X. Invoked inline by specialists when Y.>"
model: "<haiku | sonnet>"
# Uncomment only to pre-approve a narrow tool surface (skips permission prompts; does not restrict access):
# allowed-tools: Read Grep Glob Bash
---

<!-- Primitives are reusable inline behaviors — no team, no handoff artifact. Keep under 50 lines. -->

## Input

<!-- What the primitive receives — a question, a prompt, or a bounded context. -->

## Process

<!-- Primitives are short. 2–4 steps max. -->

1. <Step 1>

2. <Step 2>

## Output

<!-- What the primitive returns to the caller — always a structured, bounded response. -->

## Rules

- No team, no handoff. This skill is called inline and returns results to the caller.
- <Rule 2>
