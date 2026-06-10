---
name: resolve-pr-feedback
description: Process PR review feedback in bulk — triage, fix in parallel, and reply with verdicts.
when_to_use: PR has review comments or given thread URL.
argument-hint: "[thread-URL]"
model: sonnet
effort: high
allowed-tools: Agent Bash Read
---
Process PR feedback end-to-end: Triage → Fix (parallel) → Reply → Compound.

Adopt `Skill("orchestrator-rules")` — use NOTES.md as progress ledger, checkpoint before every spawn,
seed-brief every agent, and no autonomous merge. Read `${CLAUDE_PLUGIN_ROOT}/_shared/seed-brief.md`
for seed-brief format and `${CLAUDE_PLUGIN_ROOT}/_shared/composition.md` for parallel-dispatch cost model.

## Input

- No argument: walk all unresolved threads on the current branch's PR via `gh pr view`.
- Thread URL: extract `owner/repo/number` and filter to matching `databaseId`.

## Worker Agent Inventory

### fix-agent
**File**: `agents/fix-agent.md`
**Role**: Reads one file-group of review threads, applies fixes, verifies, emits verdicts.
**Spawn**: `Agent("skills/resolve-pr-feedback/agents/fix-agent.md")` — one per disjoint file group, in parallel.
**I/O (seed-brief passed in spawn prompt)**:
```yaml
<seed-brief>
repo: <owner/repo>
branch: <branch-name>
payload:
  task: "fix-review-threads"
  cwd: <absolute-worktree-path>
  pr_number: <N>
  threads:
    - id: <thread-id>
      file: <path>
      line: <N>
      comment: "<comment text>"
      category: <category>
</seed-brief>
```
**Output** (YAML block printed to stdout):
```yaml
threads:
  - id: <thread-id>
    verdict: fixed | already-handled | needs-human
    file: <path>
    line: <N>
    commit: <sha or null>
    note: <reason if needs-human>
```

### reply-agent
**File**: `agents/reply-agent.md`
**Role**: Drafts a reply comment for one thread given the fix verdict. Spawned after all fix-agents complete.
**Spawn**: `Agent("skills/resolve-pr-feedback/agents/reply-agent.md")` — one per thread, parallel.
**I/O (seed-brief passed in spawn prompt)**:
```yaml
<seed-brief>
repo: <owner/repo>
branch: <branch-name>
payload:
  task: "draft-reply"
  thread_id: <thread-id>
  thread_comment: "<comment text>"
  verdict: fixed | already-handled | needs-human
  commit_sha: <sha-or-null>
  note: "<reason if needs-human>"
</seed-brief>
```
**Output** (YAML block):
```yaml
thread_id: <thread-id>
reply: |
  <draft reply text>
```

## Process

### Phase 1 — Fetch
1. Resolve PR owner/repo/number from URL or `gh pr view`.
2. Fetch threads via GraphQL (`isResolved` state), filter bots/approvals/CI.
3. If URL arg provided, match `databaseId`.

### Phase 2 — Triage
1. Classify each thread:
   - **Status**: `new` | `already-handled` (check diff).
   - **Category**: `error-handling` | `validation` | `type-safety` | `naming` | `performance` | `testing` | `security` | `docs` | `style` | `architecture`.
2. Group by category → present triage summary to user; allow override.
3. Map threads to files for conflict avoidance (no two agents on same file).

### Phase 3 — Fix (Parallel)
1. Group threads by file; build seed-brief per group.
2. Checkpoint NOTES.md; spawn fix-agents in parallel.
3. Each fix-agent reads context → applies fix → verifies → commits → reports verdict.
4. After all fix-agents return: run full test suite for regression check.
5. Update NOTES.md with verdicts.

### Phase 4 — Reply
1. Read `references/verdicts.md` for verdict/reply mapping and mutation rules.
2. For each thread, spawn reply-agent with seed-brief (verdict + commit info).
3. Collect all draft replies; post them via `gh api .../replies`.
4. Resolve threads where verdict in `{fixed, fixed-differently, not-addressing}`.
5. Verify: `gh pr view <N> --json reviewThreads` — confirm all resolved.

### Phase 5 — Compound
After all phases complete cleanly: invoke `Skill("compound")` to capture session
learnings. See `${CLAUDE_PLUGIN_ROOT}/_shared/compound-on-exit.md` — exactly once,
clean completion only.

## Output
Summary: total threads → counts per verdict → commits created → threads needing human attention.

## Rules
- Additive only — no force-push or history rewrite.
- Read full thread, not just last comment.
- Flag fixes outside PR scope.
- Each logical fix as separate commit referencing thread.
- Checkpoint NOTES.md before every `Agent()` spawn (see orchestrator-rules § Progress tracking).
- No `context: fork` — worker agents run as `Agent()` in isolated background sessions.
