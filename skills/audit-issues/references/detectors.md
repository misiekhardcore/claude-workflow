# Detectors for audit-issues

Phase 2 — Per-Issue Audit. Spawn one subagent per issue (parallel for >= 3).

## 5 Detectors (Subagent Contract)

1. **Hybrid Extraction**:
   - **Regex**: File paths, numeric claims, version refs.
   - **LLM**: Cross-issue refs, open questions, premise statements.

2. **file-path-existence**: `git ls-tree -r <ref> -- <path>`. If missing → `git log --diff-filter=D`.

3. **numeric-claim-drift**: Recompute count from `<ref>`.

4. **version-reference-staleness**: Check tags and `CHANGELOG.md`.

5. **resolved-open-question**: Search history for resolution language.

6. **cross-issue-contradiction**: Scan sibling excerpts → detect negation.

## Verdict Logic

Strongest wins: `unverifiable` > `premise-shifted` > `superseded by #N` > `contradicted` > `stale` > `valid`.

## JSON Return Schema

`issue_number`, `verdict`, `findings` (quote, evidence, proposed_edit), `recommendation` (edit|close|skip).
