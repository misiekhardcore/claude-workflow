# Interviewing Rules — Shared Protocol

Used when interviewing the user to build shared understanding. Read at steps involving user questions or approval.

## Rules

- **Ask one question at a time** (exception: `AskUserQuestion` permits up to 4 independent questions).
- **Grill until fully clear.** Don't accept vague or partial answers.
- **Prefer multi-choice forms.** Present options as mutually-exclusive choices, not open-ended.
- **Use `AskUserQuestion` for structured choices.** Renders 2-4 labeled options with picker UI. Fall back to text prompts only for open-ended questions (free-text name, description).
  - Recommendation convention: put default first, append `(Recommended)` to label.
  - Use `header` as short chip (max 12 chars): `Role`, `Model`, `Target`.
- **Prefer visual questions.** Use diagrams, tables, visualizations to frame choices and confirm understanding.
- **Require explicit approval.** Partial feedback or silence is NOT approval. Ask directly.
- **Never self-approve.** Don't infer approval from non-objection or absence of pushback.
- **Don't finish until explicitly approved.** Phase is incomplete until user confirms.
- **If the codebase can answer it, explore instead of asking.** Find concrete answers first, then confirm with user.
