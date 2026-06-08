# Agent Memory

## Multi-line Text Formatting (PRs, Issues, Commit Messages)

**Rule**: Never pass multi-line strings inline to shell commands or `git commit -m`.
Shell strips `\n` from quoted arguments, producing a single line of text.

### PRs and Issues

Use `--body-file` always:

```bash
printf '## Summary\n\nSome text here.\n' > /tmp/body.md
gh pr create --body-file /tmp/body.md
gh pr edit <num> --body-file /tmp/body.md
gh issue create --body-file /tmp/body.md
```

### Commit Messages

**Never** use `git commit -m "line1\nline2..."`. The shell strips the newlines.
Always use a message file instead:

```bash
printf 'Title line\n\nBody paragraph 1.\n\nBody paragraph 2.\n\nCo-authored-by: ...\n' > /tmp/msg.txt
git commit -F /tmp/msg.txt
# or amend:
git commit --amend -F /tmp/msg.txt
```

The standard format is:
- **Line 1**: Subject (≤50 chars, imperative mood, no period)
- **Line 2**: Blank
- **Line 3+**: Body (wrap at 72 chars), bullet points with `-`
- **Last line**: `Co-authored-by: openhands <openhands@all-hands.dev>` (when applicable)

This applies everywhere: `git commit -m`, `git commit --amend -m`, `gh pr create --body`, `gh pr edit --body`, `gh issue create --body`, etc.
