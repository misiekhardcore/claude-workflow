# Audit Checks for prune

## Authoring Lane Checks

Read each file in `files`. Run 5 checks:

1. **Length Triage**: Flag if exceeds cap (Global: 50, Project: 200, Subdir: 50, Shared: 100, `.claude/` files use Subdir: 50).
2. **Unpaired "Don't"**: Scan for `Don't`/`Avoid`/`Never` without a paired `Do`/`Always`/`Prefer` within 3 lines.
3. **Warning-Stack**: Flag if `Don't` lines > 10 (warning) or > 30 (error).
4. **Architecture Smell**: Headings like `Architecture`/`Overview` exceeding 30 lines → recommend relocation to reference file.
5. **Decision-Table**: Prose matching "Use X for A, use Y for B" (≥ 3 branches) → recommend table conversion.

## Dead-state Lane Classes

Always audits global `~/.claude/`. Flags:

- `~/.claude/projects/<encoded>/` dirs whose encoded CWD does not resolve to any directory on disk.
- `.jsonl` transcripts inside those flagged directories.
- `~/.claude/agents/*.md` files not referenced by any installed skill, `settings*.json`, or recent transcript.
- `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` dirs whose version is not the currently installed one.
- `~/.claude/scheduled_tasks.json` entries pointing at a CWD that no longer exists.
- `~/.claude/plans/*-agent-<hex>.md` files (sub-agent spawn artifacts). Always candidates.

Regular plans (`~/.claude/plans/*.md` without `-agent-` suffix) are listed informational-only with `mtime`, size, and first H1/first-line snippet. `suggested-action: keep`.
