---
name: wrap-up
description: End-of-session assumptions audit. Surfaces assumptions, uncertain decisions, and follow-ups from the current session. Harvests ./.claude/NOTES.md and updates the active GitHub issue body so it survives session reset. Use before ending long or complex sessions.
model: sonnet
---

You are performing an end-of-session audit. Review what happened in this session and surface anything the user should know before context is lost.

## Process

1. Review the conversation history and identify:
   - **Assumptions** — decisions you made based on inference rather than explicit user instruction
   - **Uncertainties** — places where you were unsure and chose one path over alternatives
   - **Scope changes** — anything you did beyond or short of what was originally asked
   - **Follow-ups** — work that remains, was deferred, or needs human verification

   Resolve the worktree root with `git rev-parse --show-toplevel` and check for `<root>/.claude/NOTES.md`. If it exists, read it first — it is the authoritative worklog for this phase. Merge its **Decisions made this session** and **Open questions** into the audit so nothing is lost on reset. See `${CLAUDE_PLUGIN_ROOT}/_shared/notes-md-protocol.md` for the file's section shape and lifecycle rules.

2. For each item, note:
   - What the assumption/decision was
   - Why you made that choice
   - What the alternative would have been
   - Risk level (low/medium/high) if the assumption is wrong

3. **Determine the active issue.** Check the git branch name for an issue reference, or run `gh issue list --search <branch-slug>`, or ask the user directly. The audit must be tied to a specific issue — this is the handoff artifact for the next phase. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md` for the shape.

4. **Draft the body update.** Produce the audit in the Output format below. Fetch the current issue body (`gh issue view N --json body -q .body`), append or replace a `## Wrap-up — session handoff` section, and show the proposed new body to the user with: `Update issue #N body? (y/n)`. On yes, run `gh issue edit N --body-file -` with the new body. **Never auto-update** — wrong issue, leaked assumptions, or duplicate sections on replay all have real blast radius. Keep the draft visible in the terminal even if the user declines, so they can copy it manually.

## Output

Present the audit as an indented code block (four-space indent) so the user can copy it even if they decline the auto-update prompt. Print the label `paste into issue #N body — handoff artifact` (with the actual issue number substituted) on the line immediately above the block.

Example (for issue #42):

    paste into issue #42 body — handoff artifact

        ## Wrap-up — session handoff

        ### Assumptions Made
        - [assumption] — [why] — [risk if wrong]

        ### Uncertain Decisions
        - [decision] — [alternatives considered] — [why this one]

        ### Scope Notes
        - [what changed from original ask]

        ### Follow-ups
        - [what remains or needs verification]

## Rules

- Be honest about uncertainty — this is a self-audit, not a sales pitch
- Include assumptions even if you are fairly confident — the user decides what matters
- If nothing significant was assumed, say so briefly and do not pad the report
- The audit is not complete until it is written into the issue body or the user has explicitly declined
- Update the issue **body** in place — never post the audit as a comment. See `${CLAUDE_PLUGIN_ROOT}/_shared/handoff-artifact.md`.
- Never auto-update without user confirmation — show the draft and ask first
- After a successful update, leave `./.claude/NOTES.md` in place; the next session will read it on resume. Do not delete it automatically.
