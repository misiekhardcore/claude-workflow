# Cross-plugin Coordination

Plugin-specific decisions for `agents-flow` and how it coexists with other plugins. For general instruction file layering, `plugin.json.dependencies`, and MCP namespacing, see Anthropic's Claude Code plugin documentation and the [MCP specification](https://modelcontextprotocol.io/).

## MCP scope

`agents-flow` bundles no MCP servers. When a plugin needs an MCP that another plugin already provides, install it once at user scope (`~/.claude/`) rather than bundling a duplicate.

Why: overlapping servers load under different identifiers (`<name>` vs `plugin:<plugin>:<name>`), forcing every consumer to branch on which is live.

**Worked example**: both `agents-flow` and `agents-memo` ship an `obsidian-vault` MCP server.

|Source|Tool identifier|
|-|-|
|User scope (`~/.claude/`)|`mcp__obsidian-vault__obsidian_get_file_contents`|
|`agents-flow` plugin|`mcp__plugin_agents-flow_obsidian-vault__obsidian_get_file_contents`|
|`agents-memo` plugin|`mcp__plugin_agents-memo_obsidian-vault__obsidian_get_file_contents`|

Both plugins boot separate server processes pointed at the same vault, doubling resource use and racing on writes. Skills written against one identifier silently no-op when only the other is installed. Installing the server once at user scope collapses all three rows to a single identifier.

## Optional `agents-memo` integration

`agents-flow` integrates with `agents-memo` via **runtime detection**, not `plugin.json.dependencies`. A hard dependency would block install for users who don't want the vault; runtime detection lets it degrade gracefully.

Skills probe for these commands; vault-aware path activates if present, otherwise fall back inline:

- `agents-memo:save` — file structured notes
- `agents-memo:wiki-query` — overlap detection and prior-pattern lookup
- `agents-memo:wiki-lint` — vault health audits

## See also

- [`README.md`](../README.md) — `agents-memo` integration overview
- [`token-budgets.md`](token-budgets.md) — instruction file placement, `@`-import syntax, per-artifact token budgets
- [`plugin.json`](../.claude-plugin/plugin.json) — plugin metadata
