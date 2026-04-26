# Cross-plugin Coordination

Plugin-specific decisions for the `claude-workflow` + `claude-obsidian` + `claude-config` ecosystem. For the general semantics of CLAUDE.md layering, `plugin.json.dependencies`, and MCP namespacing, see Anthropic's Claude Code plugin documentation and the [MCP specification](https://modelcontextprotocol.io/) — this doc only records what is specific to *this* ecosystem.

## MCP scope

Shared MCP servers live at user scope in `~/.claude/`, owned by `claude-config`. Plugins bundle MCPs only when the MCP is plugin-specific.

Why: when two plugins bundle overlapping servers, Claude Code loads both under different identifiers (`<name>` vs `plugin:<plugin>:<name>`), forcing every consumer to branch on which is live. Centralising shared MCPs in `claude-config` eliminates the duplicate.

`claude-workflow` bundles no MCPs.

## Optional `claude-obsidian` integration

`claude-workflow` integrates with `claude-obsidian` via **runtime detection**, not via `plugin.json.dependencies`. A hard dependency would block install for users who don't want the vault; runtime detection lets the integration degrade gracefully.

Skills probe for these commands; if present, the vault-aware path activates, otherwise the skill falls back inline:

- `claude-obsidian:save` — file structured notes
- `claude-obsidian:wiki-query` — overlap detection and prior-pattern lookup
- `claude-obsidian:wiki-lint` — vault health audits

If a future skill makes the vault mandatory, declare `dependencies: ["claude-obsidian"]` in `plugin.json` and update this section.

## CLAUDE.md ownership

`~/.claude/CLAUDE.md` is sourced from the [`claude-config`](https://github.com/misiekhardcore/claude-config) repo, not authored ad-hoc per machine. For the semantics of project (`./CLAUDE.md`) vs personal (`./CLAUDE.local.md`) scopes and load order, see Claude Code's memory documentation.

## See also

- [`README.md`](../README.md) — `claude-obsidian` integration overview
- [`plugin.json`](../.claude-plugin/plugin.json) — plugin metadata
