# Verdicts and Reply Logic for resolve-pr-feedback

## Phase 4 — Reply: Verdict & Reply

Each sub-agent determines a verdict and drafts reply text (code fixes were grouped by file in Phase 3).

|Verdict|Meaning|Reply|
|-|-|-|
|`fixed`|Exact implementation|"Fixed in {commit_sha}."|
|`fixed-differently`|Addressed via other approach|"Addressed differently: {explanation}. See {commit_sha}."|
|`replied`|Disagree/Clarify|"{explanation}"|
|`not-addressing`|Intentional skip|"Not addressing: {rationale}"|
|`needs-human`|Confidence too low|"Needs human review: {context}"|

### Mutation (main thread)
1. Post each drafted reply via `gh api .../replies` (safe body passing).
2. Resolve thread if verdict in {`fixed`, `fixed-differently`, `not-addressing`}.
3. **Verify**: Run `gh pr view <N> --json reviewThreads` and confirm all threads are resolved.
