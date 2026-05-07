---
name: prune
description: Audit CLAUDE.md rules, AGENTS.md / SKILL.md authoring quality, and (optionally) the claude-obsidian vault for staleness.
when_to_use: Use monthly or after major refactors. Vault-internal health (orphans, broken links, frontmatter gaps) is delegated to claude-obsidian's wiki-lint when available.
model: haiku
---
You are auditing the project's Claude Code rules and documentation for staleness and authoring quality.

This skill has three lanes:

- **Rules lane** — audits `CLAUDE.md`, imported files, and the harness's auto-memory.
- **Authoring lane** — checks `CLAUDE.md` / `AGENTS.md` / `SKILL.md` files for structural quality issues grounded in the Augment Code empirical study.
- **Vault lane** — optional. If the `claude-obsidian` plugin is installed, delegates the vault audit to its `wiki-lint` command. If not, skipped with a one-line note.

### Spawn justification

Rubric: `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md`.

- **Three lane sub-agents (rules, authoring, vault)**: 3 parallel Task sub-agents. Independent reads, only summary returns to main; disjoint (rules/authoring/vault touch different files); parallel; payoff ≥3×. Model: `haiku` (retrieval/scan, no synthesis). Fallback: sequential.

Each sub-agent spawn prompt must begin with:
```
cd /path/to/repo && pwd  # verify CWD
```

## Process

### Dispatch

Spawn one Task sub-agent per lane. Pass working directory as absolute path. Each sub-agent must start with `cd <abs-path> && pwd`. Dispatch all three in parallel; collect output; proceed to Classification and Output.

- **Rules sub-agent** — runs Rules lane. Receives: `cwd`, global CLAUDE.md path, project CLAUDE.md path (if found), `~/.claude/projects/<project>/memory/` path.
- **Authoring sub-agent** — runs Authoring lane. Receives: `cwd`, pre-enumerated list of CLAUDE.md / AGENTS.md / SKILL.md paths.
- **Vault sub-agent** — runs Vault lane. Receives: `cwd`, whether `claude-obsidian` is installed.

### Rules lane (always)

1. **Gather all rule sources:**
   - `~/.claude/CLAUDE.md` (global)
   - Any `@imported` files referenced in CLAUDE.md
   - Project-level `CLAUDE.md` (if exists)
   - `~/.claude/projects/<project>/memory/MEMORY.md` + topic files (harness-managed auto-memory).

2. **For each rule or guidance item, assess:**
   - Does the tool/command it references still exist?
   - Does the pattern it describes still apply?
   - Has it been superseded by a newer rule?
   - Is it redundant with built-in Claude Code behavior?

3. **For each auto-memory file:**
   - Is the information still accurate?
   - Is it redundant with what's already in CLAUDE.md?

### Authoring lane (always)

**Discovery — enumerate files in scope:**
- `CLAUDE.md` files: global, project-root, subdirectories.
- `AGENTS.md` files: project-root, subdirectories. Also check `GEMINI.md` (Gemini CLI equivalent).
- `SKILL.md` files: all under `.claude/skills/` and active skill plugin directories.

For each file, run these five checks. Each finding must cite its empirical source.

**Length triage** — Count total lines. Flag if it exceeds the applicable cap:
- Global `~/.claude/CLAUDE.md`: 50 lines
- Project-root `CLAUDE.md` / `AGENTS.md`: 200 lines
- Subdirectory `CLAUDE.md` / `AGENTS.md`: 50 lines
- `SKILL.md` (any location): no cap (expected longer than agent-config files)

Configurable: user-specified caps override defaults. Citation: *project sizing guidance — progressive disclosure, 100–150 line main file + on-demand reference docs, +10–15% across benchmark metrics.*

**Unpaired "don't" detector** — Scan every line starting with `Don't`, `Avoid`, or `Never` (after stripping list markers). Look for a paired `Do`, `Always`, `Use`, or `Prefer` line within 3 lines after. List every unpaired entry with file path and line number. Citation: *Augment Code study — "pair every 'don't' with a 'do'"; warning-only underperforms paired guidance.*

**Warning-stack threshold** — Count "don't"-style lines per file:
- `> 10` → warning; cite excessive-warnings anti-pattern.
- `> 30` → error; cite study: 30+ "don't" rules doubled PR time, dropped `completeness` 20%.

Citation: *Augment Code empirical study.*

**Architecture-overview smell** — Find headings containing `Architecture`, `How it works`, `Background`, or `Overview` (case-insensitive). If section body exceeds 30 lines, flag as candidate for relocation to load-on-demand reference file. Citation: *Augment Code study — long architecture sections caused 12-doc reads, 80K token burn, `completeness` dropped 25%.*

**Decision-table candidates** — Scan for prose matching "Use X for A, use Y for B, …" with ≥3 branches. Surface as candidates for decision table conversion. Citation: *Augment Code study — decision tables added +25% on `best_practices`.*

### Vault lane (optional — claude-obsidian)

**If `claude-obsidian:wiki-lint` is available:**
- Invoke it. It handles vault-structural checks (orphans, broken wikilinks, missing frontmatter, stale claims).
- Additionally ask it to flag concept/entity/source notes whose described problem, pattern, or root cause may no longer apply given recent code changes.
- Fold returned findings into report as section titled "Vault (via wiki-lint)".

**If `claude-obsidian` is not installed:**
- Skip vault audit.
- Add single line: `Vault audit skipped — install claude-obsidian (claude plugin marketplace add AgriciDaniel/claude-obsidian) to enable.`

### Classification (main thread — after sub-agents return)

**Classify each rules-lane item:**
- **Current** — still relevant, keep as-is
- **Stale** — references things that no longer exist, recommend removal
- **Superseded** — replaced by newer rule/doc, recommend consolidation
- **Unclear** — cannot determine relevance, flag for human review

### Aggregation (main thread)

Merge the three sub-agent reports into single audit report. Do not re-read files — synthesize only from sub-agent outputs.

## Output

An audit report with:

- Total rules/docs audited
- Items by classification (current / stale / superseded / unclear) for rules lane
- **Authoring-quality findings** — grouped by file, one sub-section per check that produced findings. Each finding includes file path, line number (where applicable), specific issue, and citation.
- Vault lane's findings (or the "skipped" line) as separate section
- Specific recommendations for each non-current item
- Suggested edits (but do NOT apply without user approval)

## Rules

- Never delete rules or docs automatically — present recommendations and wait for approval.
- When in doubt, classify as "unclear" rather than "stale".
- Main thread only aggregates — do not re-read files after sub-agents return.
- Do not scan vault files directly. The vault is the `claude-obsidian` plugin's responsibility.
- Authoring-lane checks are non-destructive — list findings only; do not rewrite files.
- Omit authoring-lane check sub-sections with no findings; do not emit empty sections.
