# Handoff Artifact — Shared Template

Used by phase-boundary skills (`/discovery`, `/define`, `/implement`, `/wrap-up`) to hand off state to the next phase. The GitHub issue body is the artifact. Each phase updates the body in place with the five fields below, then the user resets and starts the next phase in a fresh session.

This file is reference material — read it on demand when the skill reaches a handoff step. Do not preload.

## The five fields

Every handoff artifact contains:

1. **Acceptance criteria** — testable scenarios, unchanged from `/discovery`. One line each. **Mandatory.**
2. **Constraints** — files in scope, files out of scope, non-negotiable decisions from `/define`. **Mandatory.**
3. **Prior decisions** — "we chose X over Y because Z" entries. One line each. Include links to the conversation or code that produced the decision. *(Optional — omit heading when empty.)*
4. **Evidence** — links to commits, PRs, benchmark output, design reviews, or approvals that justify each decision. *(Optional — omit heading when empty.)*
5. **Open questions** — things the next phase must resolve. Explicit — no "obvious, will figure out later". *(Optional — omit heading when empty.)*

## Shape

Always update the **issue body** in place. If a section for the current phase (e.g. `## Solution` for `/define`) does not exist in the body, append it; if it does, edit it. Comments are for discussion, not for handoff state — scan-reading a thread of comments is exactly the rot pattern this protocol avoids.

Fields appear in this order: Acceptance criteria, Constraints, Prior decisions, Evidence, Open questions. Omit optional fields entirely when empty — a missing heading means zero items, not an unwritten section. Never write placeholder text ("None", "No open questions", etc.).

```markdown
## Handoff: /<prev> → /<next>

**Acceptance criteria** (from /discovery, unchanged)
- AC1: ...
- AC2: ...

**Constraints**
- In scope: <paths>
- Out of scope: <paths>
- Must reuse: <existing module/util>

**Prior decisions** (optional)
- <one-line decision> (why: <rationale>)

**Evidence** (optional)
- <link to commit | PR | benchmark | design review>

**Open questions** (optional)
- <question the next phase must resolve>
```

## Precedence

Two persistent stores, no overlap:

- **The issue body is authoritative for cross-phase state** — acceptance criteria, locked architectural decisions, the handoff fields above.
- **`.claude/NOTES.md` is authoritative for in-flight state within a phase** — current task, intra-phase decisions not yet promoted, working open questions. See `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md`.

When a phase ends, intra-phase state from `.claude/NOTES.md` that the next phase needs is **promoted** into the issue body (typically by `/wrap-up`). Until promotion, the issue does not know about it. After promotion, the issue body is the source of truth for that item.

## Rules

- **Update the body, not a comment.** Every phase edits the issue body in place — append a new section if one does not exist for the current phase, edit the existing section if it does. Comments are for discussion only.
- **Reset after updating.** Once the body is updated, tell the user to start the next phase in a fresh session. Do not call the next skill from within the current one.
- **For cross-phase state, the issue body wins.** If in-context recall disagrees with the body, trust the body.
- **Never include secrets.** Evidence links should point to internal systems, not pasted API keys, credentials, or internal hostnames in log dumps.
- **Never drop prior decisions to save space.** If the list is long, that's the workflow working — not a bug.
- **Mandatory fields:** Acceptance criteria and Constraints — include on every handoff. **Optional fields:** Prior decisions, Evidence, and Open questions — omit the heading entirely when empty. Never write placeholder text ("None", "No open questions", etc.).

## Final-pass checklist

Before submitting the handoff artifact (issue update), every orchestrator must verify:

- **Style match** — scan 2 recent examples in the same repository (prior issue bodies, `.claude/NOTES.md`, or adjacent `_shared/` files); flag any drift in heading levels, bullet formatting, or tone. Correct before updating the body.
- **No duplication** — grep the repo and issue body for any heading, rule, or decision you added; if already present elsewhere, link to the existing item instead of duplicating it.
- **No unrelated files** — run `git diff --name-only <base>..HEAD` and verify every file is in scope for the current issue. Flag outliers explicitly; do not silently include them.
- **No untracked expected files** — run `git status --short`. If `.claude/`, `docs/`, or other expected directories have untracked files, surface them to the user before proceeding.

## Why this shape

The five fields map to Anthropic's "structured handoff artifact" and OpenAI's `input_type` handoff metadata pattern. Summarization in place loses detail that the next phase needs; a body-update-in-place with this exact shape preserves the surviving content exactly and keeps the handoff scan-readable in a single fetch. See `${CLAUDE_PLUGIN_ROOT}/docs/context-hygiene.md` for the full rationale.
