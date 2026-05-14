# Detectors for audit-issues

Phase 2 — Per-Issue Audit. Spawn one subagent per issue (parallel for >= 3).

## Hybrid Extraction (Setup)

Extract data via:
- **Regex**: File paths, numeric claims, version refs.
- **LLM**: Cross-issue refs, open questions, premise statements.

## 5 Detectors (Subagent Contract)

1. **file-path-existence**: `git ls-tree -r <ref> -- <path>`. If missing → `git log --diff-filter=D`.

2. **numeric-claim-drift**: Recompute count from `<ref>`.

3. **version-reference-staleness**: Check tags and `CHANGELOG.md`.

4. **resolved-open-question**: Search history for resolution language.

5. **cross-issue-contradiction**: Scan sibling excerpts → detect negation.

## Verdict Logic

Strongest wins: `unverifiable` > `premise-shifted` > `superseded by #N` > `contradicted` > `stale` > `valid`.

## JSON Return Schema

`issue_number`, `verdict`, `findings` (quote, evidence, proposed_edit), `recommendation` (edit|close|skip).
