# Cross-plugin Coordination

Plugin-specific decisions for `claude-workflow` and how it coexists with other Claude Code plugins (notably `claude-obsidian`). For the general semantics of CLAUDE.md layering, `plugin.json.dependencies`, and MCP namespacing, see Anthropic's Claude Code plugin documentation and the [MCP specification](https://modelcontextprotocol.io/) — this doc only records what is specific to *this* plugin.

## MCP scope

`claude-workflow` bundles no MCP servers. When a plugin needs an MCP that another plugin (or the user's own config) already provides, install it once at user scope in `~/.claude/` rather than bundling a duplicate.

Why: when two plugins bundle overlapping servers, Claude Code loads both under different identifiers (`<name>` vs `plugin:<plugin>:<name>`), forcing every consumer to branch on which is live.

**Worked example.** Suppose both `claude-workflow` and `claude-obsidian` ship an `obsidian-vault` MCP server. Claude Code loads them as two separate clients:

| Source | Tool identifier in skill bodies |
| --- | --- |
| User scope (`~/.claude/`)    | `mcp__obsidian-vault__obsidian_get_file_contents` |
| `claude-workflow` plugin     | `mcp__plugin_claude-workflow_obsidian-vault__obsidian_get_file_contents` |
| `claude-obsidian` plugin     | `mcp__plugin_claude-obsidian_obsidian-vault__obsidian_get_file_contents` |

Both plugins boot a separate server process pointed at the same vault, doubling resource use and racing on writes. Skills written against one identifier silently no-op when only the other is installed. Permission allowlists need three entries instead of one. Installing the server once at user scope collapses all three rows back to a single identifier.

## Optional `claude-obsidian` integration

`claude-workflow` integrates with `claude-obsidian` via **runtime detection**, not via `plugin.json.dependencies`. A hard dependency would block install for users who don't want the vault; runtime detection lets the integration degrade gracefully.

Skills probe for these commands; if present, the vault-aware path activates, otherwise the skill falls back inline:

- `claude-obsidian:save` — file structured notes
- `claude-obsidian:wiki-query` — overlap detection and prior-pattern lookup
- `claude-obsidian:wiki-lint` — vault health audits

If a future skill makes the vault mandatory, declare `dependencies: ["claude-obsidian"]` in `plugin.json` and update this section.

## See also

- [`README.md`](../README.md) — `claude-obsidian` integration overview
- [`token-budgets.md`](token-budgets.md) — CLAUDE.md placement, `@`-import syntax, and per-artifact token budgets that compose with the MCP-scope rules above
- [`plugin.json`](../.claude-plugin/plugin.json) — plugin metadata
