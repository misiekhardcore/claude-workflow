# Agent Memory

## PR/Issue Description Formatting

**Rule**: Always use a separate body file for multi-line PR/issue descriptions. Never pass multi-line strings inline to shell commands.

Shell strips newlines in quoted arguments, so this produces a single-line body:
```bash
gh pr create --body '## Summary

Some text here.
```
Use `--body-file` instead:
```bash
# Create a temp file with proper newlines
printf '## Summary\n\nSome text here.\n' > /tmp/pr_body.md
gh pr create --body-file /tmp/pr_body.md
# or
gh pr edit <num> --body-file /tmp/pr_body.md
```

This applies to: `gh pr create`, `gh pr edit`, `gh issue create`, `gh issue edit`, and any other tool that accepts multi-line text input via shell arguments.
