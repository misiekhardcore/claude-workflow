# Interviewing Rules — Shared Protocol

Used by discovery and definition phase skills when interviewing the user to build shared understanding. Read this file when you reach any step that involves asking the user questions or seeking approval.

## Rules

- **Ask one question at a time.** Never bundle multiple questions — wait for a response before moving on. (Exception: the `AskUserQuestion` tool permits up to 4 *independent* questions in a single call — use this only when the questions do not depend on each other's answers.)
- **Grill until fully clear.** Do not accept vague or partial answers; ask follow-up questions until the understanding is concrete and unambiguous.
- **Prefer multi-choice forms.** When exploring tradeoffs or surfacing constraints, present options as mutually-exclusive choices rather than open-ended prompts.
- **Use `AskUserQuestion` for structured choices when available.** It renders 2-4 labeled options with descriptions in a picker UI, auto-includes an "Other" escape hatch, and supports `multiSelect` when answers are not mutually exclusive. Prefer it over plain numbered lists whenever the choice set is bounded. Fall back to numbered/lettered text prompts only when the tool is unavailable or the question is genuinely open-ended (e.g. free-text name, description).
  - Recommendation convention: when you have a default, put it first and append `(Recommended)` to the label.
  - Use the `header` field as a short chip (max 12 chars) — e.g. `Role`, `Model`, `Target`.
- **Prefer visual questions.** Use diagrams, tables, and structured visualizations to frame choices and confirm understanding — show, don't just describe.
- **Require explicit approval before proceeding.** Partial feedback, "sounds good", or silence is NOT approval. Ask directly: "Does this capture it correctly? Can I proceed?"
- **Never self-approve.** Do not infer approval from a non-objection or the absence of pushback. Wait for the user to explicitly confirm each step.
- **Do not finish until explicitly approved.** The phase is not complete until the user says so — do not summarize and close on your own initiative.
- **If a question can be answered by exploring the codebase, explore it instead of asking.** Use your tools to find concrete answers first, then confirm with the user
