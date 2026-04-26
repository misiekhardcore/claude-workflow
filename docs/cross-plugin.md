# Cross-plugin Coordination

Guidance for plugins that integrate with each other and share MCPs across the claude-workflow ecosystem (claude-workflow, claude-obsidian, claude-config).

## MCP scope rule

Shared MCPs live at **user scope** (in `~/.claude/`), owned and versioned by `claude-config`. Plugin-bundled MCPs only when the MCP is **plugin-specific** — tied to that plugin's function and not shared across other plugins.

**Rationale**: When two plugins ship overlapping MCP servers, Claude Code runs both with different namespace identifiers (`atlassian` vs `plugin:claude-workflow:atlassian`), wasting capacity, introducing routing confusion, and making it unclear which version is active. Centralizing shared MCPs avoids this duplication failure mode.

### Worked example: duplicate identifiers

Suppose both `claude-workflow` and `claude-obsidian` ship an `llm-context` MCP to manage context size.

**Bad** (current buggy pattern):
- `claude-workflow` installs MCP `llm-context@v1.0` bundled in `.claude-plugin/mcp/`
- `claude-obsidian` installs MCP `llm-context@v1.1` bundled in `.claude-plugin/mcp/`
- Claude Code loads **both** at startup:
  - `llm-context` (from `claude-workflow`, v1.0)
  - `plugin:claude-obsidian:llm-context` (from `claude-obsidian`, v1.1)
- Skills must branch on which identifier is live, breaking composability and doubling testing burden.

**Good** (shared user scope):
- `claude-config` owns `llm-context@v1.2` in `~/.claude/mcp/llm-context/`
- Both plugins reference it from settings (no bundled copies).
- Claude Code loads **one** MCP at startup: `llm-context` (v1.2, shared).
- All skills and plugins use the same interface.

**Decision for this plugin**: `claude-workflow` does not bundle any MCPs. It documents the optional `claude-obsidian` integration at runtime (see "Dependency declarations" below).

## Dependency declarations

`plugin.json.dependencies` is a formal field in the Anthropic plugins schema for declaring hard dependencies on other plugins. This plugin **does not populate it for the optional `claude-obsidian` integration** — it uses runtime detection instead.

### Reasoning

1. **Runtime detection keeps the integration optional.** If `claude-obsidian` were a hard dependency in `plugin.json`, Claude Code would block installation for users who don't have it, even if they never plan to use the vault-aware skills. That's too coercive.

2. **Integration is graceful degeneracy, not breakage.** Skills like `/compound` and `/prune` run correctly whether `claude-obsidian` is installed or not — they emit structured notes inline when the vault is unavailable, or delegate to `/save` when it is. No error state; no unmet requirement.

3. **Runtime detection is discoverable.** When a user runs `/compound` without `claude-obsidian`, the skill's response includes an install suggestion. That discovery path is lower friction than a hard dependency that fails at plugin load time.

### Integration pattern

Skills detect `claude-obsidian` availability by checking for its commands at runtime:
- `claude-obsidian:save` — for filing structured notes
- `claude-obsidian:wiki-query` — for overlap detection and prior-pattern lookup
- `claude-obsidian:wiki-lint` — for vault health audits

If any of these are available, the vault-aware path activates. Otherwise, the skill emits or reports inline.

**If this decision changes in the future** (e.g., the vault becomes mandatory for a new skill), add `dependencies: ["claude-obsidian"]` to `plugin.json` and document the reason in this section.

## CLAUDE.md layering

The ecosystem layers guidance across three files, each with a different scope and audience.

### `~/.claude/CLAUDE.md` — ecosystem scope (owned by claude-config)

**Lives in**: `$HOME/.claude/CLAUDE.md` (user home, not a project repo)

**Audience**: all Claude Code users and all plugins running on this machine

**Owns**:
- Cross-project conventions and standards (e.g., "always commit before tests", "max context is 50k tokens")
- Plugin installation and marketplace guidance
- Shared workflow shortcuts (e.g., "run `/wrap-up` before ending a session")
- Environment variables and global settings
- High-level multi-repo principles (repo cross-references, workspace layout)

**Does NOT own**:
- Project-specific code style or idioms
- Individual plugin implementation details (that belongs in each plugin's own CLAUDE.md)
- Local machine quirks (those belong in CLAUDE.local.md)

**Authored by**: the `claude-config` repo (user's dotfiles/settings)

### `./CLAUDE.md` — project scope (committed to the repo)

**Lives in**: the root of each repo (e.g., `claude-workflow/CLAUDE.md`, `myapp/CLAUDE.md`)

**Audience**: Claude Code and any user working on this repo

**Owns**:
- Project-specific workflow guidance and idioms (e.g., "run `/build` against the issue, never free-form")
- Code style, naming conventions, architecture rules for *this* project
- How to invoke the project's own skills, tests, or CI/CD
- Plugin configuration relevant only to this repo
- How to run the project locally (steps that apply to all contributors)

**Does NOT own**:
- User's personal local quirks (e.g., "I always edit in Vim", "my preferred test runner")
- System-wide conventions from `~/.claude/CLAUDE.md` (those are inherited; mention them here only to call out exceptions)
- Credentials or secrets (those belong in `.env` or CLAUDE.local.md, gitignored)

**Authored by**: the project maintainers, committed to git

**For monorepos and parent/child repos**: if the repo is a monorepo (e.g., `packages/*/`), create `./CLAUDE.md` at the root for monorepo-wide rules, and optionally `packages/*/CLAUDE.md` for package-specific overrides. Submodules and referenced external repos should each have their own committed CLAUDE.md; the parent does not duplicate it.

### `./CLAUDE.local.md` — personal scope (gitignored)

**Lives in**: the root of the repo, gitignored (add `CLAUDE.local.md` to `.gitignore`)

**Audience**: the individual user (not shared)

**Owns**:
- Personal machine-specific tweaks for *this* repo (e.g., "alias `npm test` to `npm run test:fast`", "use Prettier instead of the default formatter")
- Local environment variables specific to development
- Per-machine debugging toggles or performance overrides
- Personal task macros or per-repo quick commands

**Does NOT own**:
- Anything that affects the repo's collective experience (use `./CLAUDE.md` instead)
- Secrets and credentials (use `.env` or a proper secrets manager)
- Filesystem paths outside this repo (use `~/.claude/CLAUDE.local.md` if you need a per-machine global setting)

**Authored by**: the individual user, never committed

### Layering summary

| File | Scope | Inherited by | Overridden by |
|------|-------|--------------|---------------|
| `~/.claude/CLAUDE.md` | Ecosystem | All repos | `./CLAUDE.md` |
| `./CLAUDE.md` | Project (committed) | This repo | `./CLAUDE.local.md` |
| `./CLAUDE.local.md` | Personal (gitignored) | This repo only | —— |

Read order when initializing Claude Code in a repo:

1. **`~/.claude/CLAUDE.md`** (global defaults)
2. **`./CLAUDE.md`** (project overrides)
3. **`./CLAUDE.local.md`** (personal machine tweaks, if it exists)

Each layer should assume the previous one is loaded and state only what differs.

### Example: adding a new rule

**Scenario**: The `claude-workflow` project adopts a new convention: "always write acceptance criteria in the GitHub issue before calling `/build`."

- If this rule applies **across all projects** the user works on, add it to `~/.claude/CLAUDE.md` in `claude-config`.
- If it applies **only to claude-workflow**, add it to `claude-workflow/CLAUDE.md` (committed).
- If the user wants a personal exception on their machine only (e.g., "I skip this in my local development"), add it to `claude-workflow/CLAUDE.local.md` (gitignored).

### When to grep existing docs

Before adding content to any layer, grep the docs at that layer and all inherited layers to avoid duplication. Example from this repo:

```bash
grep -r "runtime detection" ~/.claude/CLAUDE.md ./CLAUDE.md ./CLAUDE.local.md 2>/dev/null
```

If the rule already exists in a parent layer, reference it instead of repeating it.

## See also

- `README.md:127` — current implicit `claude-obsidian` integration documentation
- `plugin.json` — formal plugin metadata and dependencies field
- [Anthropic plugins reference](https://docs.anthropic.com/en/docs/build-with-claude/plugins) — `plugin.json` schema
- [Anthropic MCP specification](https://modelcontextprotocol.io/) — shared MCP servers and namespacing

