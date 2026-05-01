# Reviewer personas

Each persona is a discrete review voice. The orchestrator (`SKILL.md`) decides which to activate based on scope and gates, then dispatches them per the Spawn justification block.

Findings format (every persona):

```
- file:line | issue title | severity (P0-P3) | confidence (0.0-1.0)
```

Severity rubric:

- **P0** — defect blocks merge: data loss, auth bypass, crash on golden path, breaks acceptance criterion.
- **P1** — defect must fix before release: incorrect behavior on common path, missing AC coverage, regression risk.
- **P2** — should fix: latent bug on edge case, unclear naming, weak test, brittle pattern.
- **P3** — nit: style, micro-optimization, doc polish.

## Always-on

### Correctness

**Focus:** every acceptance criterion is satisfied; edge cases are covered; no logical errors; no leftover debug code or forgotten TODOs.

**Checks:** AC-by-AC pass/fail, off-by-one, null/empty/concurrent inputs, error paths, regression risk on adjacent code.

### Standards

**Focus:** code style, naming, patterns, test quality, adherence to project conventions.

**Checks:** matches existing idioms in the touched modules, tests cover the behavior they claim to, no dead/duplicated code introduced, public APIs follow the project's naming rules.

## Conditional

Each conditional persona has a **gate** (when it activates) and **signals** (what it looks for once active). Gates are evaluated against the prepared review package (the diff, file paths, and any linked-issue context).

### Security

**Gate:** diff contains 2+ security-related terms (`auth`, `token`, `session`, `permission`, `password`, `cookie`, `csrf`, `cors`) co-occurring in the same file, OR file paths matching `**/auth/**`, `**/security/**`, `**/middleware/**`.

**Focus:** authentication/authorization bugs, injection vulnerabilities, secret exposure, unsafe data handling, OWASP top 10 concerns.

**Signals:** unsanitized input flowing to queries/shells/HTML, secrets in logs or error messages, insecure defaults, missing authorization checks on sensitive paths, weak crypto.

### Performance

**Gate:** diff touches database queries or data access patterns — content matching `query`, `findAll`, `SELECT`, `JOIN`, `index`, OR file paths matching `**/db/**`, `**/queries/**`. Do **not** trigger on generic JS iteration (`forEach`, `map`, `filter`).

**Focus:** N+1 queries, unbounded loops, missing pagination, cache misses, unindexed lookups.

**Signals:** queries inside loops, missing `LIMIT`, full-table scans on hot paths, repeated work that could be memoized, allocations on the request critical path.

### Migration

**Gate:** file paths matching `**/migrations/**`, `**/db/**`, OR content matching `CREATE TABLE`, `ALTER TABLE`, `addColumn`, `migration`.

**Focus:** backward compatibility, rollback safety, data loss risk, migration ordering.

**Signals:** non-reversible changes, missing default for a new `NOT NULL` column, schema change without a corresponding code path for old rows, ordering hazards between migration and deploy.

### Docs consistency

**Gate:** diff touches markdown — any `**/*.md` change — OR adds/removes a skill or command (`skills/*/SKILL.md`, `commands/*.md`, `_shared/**/*.md`).

**Focus:** cross-references, stale mentions, duplication across `**/*.md`, `docs/**`, `_shared/**`.

**Signals:** broken or stale links between skill files, contradictions between a renamed/moved file and references that still point at the old name, duplicated rule blocks that should be extracted into `_shared/`, command tables and skill catalogs that drift from the actual `skills/` and `commands/` directories.

### Architecture / scope-creep

**Gate:** `scope_class == "Deep"` OR `git diff --shortstat` total > 300 lines OR diff touches > 5 distinct top-level directories.

**Focus:** premature abstraction, out-of-scope changes, speculative features.

**Signals:** new abstractions with a single caller, generalization for a hypothetical second use case, edits to files outside the issue's stated scope, refactors bundled into a feature PR without justification, configuration knobs added "just in case".

**Degraded mode:** when no linked issue is available (`gh pr view --json closingIssuesReferences` returns empty), the persona cannot evaluate "out-of-scope" against an authoritative AC list. In that case, restrict findings to **premature abstraction only** and prepend a single note to the persona's section: `_No linked issue — out-of-scope check skipped._`
