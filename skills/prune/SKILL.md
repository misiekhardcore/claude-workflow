---
name: prune
description: Audit CLAUDE.md rules, memory files, and (optionally) the claude-obsidian vault for staleness. Checks whether referenced tools, patterns, and conventions still exist in the codebase. Use monthly or after major refactors. Vault-internal health (orphans, broken links, frontmatter gaps) is delegated to claude-obsidian's wiki-lint when available.
model: haiku
---

You are auditing the project's Claude Code rules and documentation for staleness.

This skill has two lanes:

- **Rules lane** — always runs. Audits `CLAUDE.md`, imported files, and the harness's auto-memory.
- **Vault lane** — optional. If the `claude-obsidian` plugin is installed, delegates the vault audit to its `wiki-lint` command and folds the findings in. If not, the vault lane is skipped with a one-line note.

## Process

### Rules lane (always)

1. **Gather all rule sources:**
   - `~/.claude/CLAUDE.md` (global)
   - Any `@imported` files referenced in CLAUDE.md
   - Project-level `CLAUDE.md` (if exists in cwd)
   - `~/.claude/projects/<project>/memory/MEMORY.md` + topic files — Claude Code's built-in auto memory (per-user, harness-managed). Group these together when reporting; do not propose edits inside `MEMORY.md` itself unless it is clearly stale, since the harness rewrites it.

2. **For each rule or guidance item, assess:**
   - Does the tool/command it references still exist? (e.g., if a rule references `yarn lint`, does the project still use yarn?)
   - Does the pattern it describes still apply? (e.g., if a rule says "use X pattern for Y", does Y still exist in the codebase?)
   - Has it been superseded by a newer rule or convention?
   - Is it redundant with built-in Claude Code behavior?

3. **For each auto-memory file:**
   - Is the information still accurate? (check against current state)
   - Is it redundant with what's already in CLAUDE.md or the codebase?

### Vault lane (optional — claude-obsidian)

4. **If `claude-obsidian:wiki-lint` is available:**
   - Invoke it. It handles vault-structural checks (orphans, broken wikilinks, missing frontmatter fields, stale claims) — don't duplicate that work here.
   - Additionally ask it (or use `claude-obsidian:wiki-query`) to flag concept/entity/source notes whose described problem, pattern, or root cause may no longer apply given recent code changes. That semantic check is the piece unique to `/prune`.
   - Fold the returned findings into the audit report as a separate section titled "Vault (via wiki-lint)".

5. **If `claude-obsidian` is not installed:**
   - Skip step 4.
   - Add a single line to the report: `Vault audit skipped — install claude-obsidian (claude plugin marketplace add AgriciDaniel/claude-obsidian) to enable.`

### Classification

6. **Classify each item:**
   - **Current** — still relevant, keep as-is
   - **Stale** — references things that no longer exist, recommend removal
   - **Superseded** — replaced by a newer rule/doc, recommend consolidation
   - **Unclear** — cannot determine relevance, flag for human review

## Output

An audit report with:

- Total rules/docs audited
- Items by classification (current / stale / superseded / unclear) for the rules lane
- The vault lane's findings (or the "skipped" line) as a separate section
- Specific recommendations for each non-current item
- Suggested edits (but do NOT apply them without user approval)

## Rules

- Never delete rules or docs automatically — present recommendations and wait for approval.
- When in doubt, classify as "unclear" rather than "stale".
- Check the actual codebase, not just the rule text — a rule might reference an outdated name but the intent is still valid.
- Do not scan vault files directly. The vault's structure is the `claude-obsidian` plugin's responsibility; this skill calls into it rather than walking paths.
