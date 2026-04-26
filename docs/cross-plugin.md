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

## CLAUDE.md ownership in this ecosystem

| Layer | Path | Owner | Contains |
|---|---|---|---|
| Ecosystem | `~/.claude/CLAUDE.md` | `claude-config` repo | Cross-project conventions, plugin install guidance, shared shortcuts |
| Project | `./CLAUDE.md` (committed) | The project repo | Project-specific idioms, code style, how to invoke the project's skills/tests |
| Personal | `./CLAUDE.local.md` (gitignored) | Individual user | Local quirks, per-machine overrides |

Each layer assumes the previous one is loaded and states only what differs. Before adding a rule, grep existing layers — if it already exists upstream, reference it instead of duplicating.

## See also

- [`README.md`](../README.md) — `claude-obsidian` integration overview
- [`plugin.json`](../.claude-plugin/plugin.json) — plugin metadata
