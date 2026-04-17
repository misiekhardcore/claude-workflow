# claude-workflow

Workflow skills plugin for Claude Code — a standardized lifecycle for feature development.

```
/discovery → /define → /implement
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           /build  →   /review   →  /verify
              ▲            │            │
              └─ fix-brief ◄┴────────────┘
                            │ (both clean)
                            ▼
                   draft PR + /compound
```

## Install

This repo is its own marketplace — the plugin and marketplace manifests both live in `.claude-plugin/`, so a single `marketplace add` points Claude Code at both.

```bash
claude plugin marketplace add misiekhardcore/claude-workflow
claude plugin install claude-workflow@claude-workflow
```

Then enable it in your project or globally in Claude Code settings.

## Skills

| Skill | Description |
|-------|-------------|
| `/discovery` | Explore a problem and produce a GitHub issue with acceptance criteria |
| `/define` | Plan architecture and design; produces the implementation handoff |
| `/implement` | Full build→review→verify cycle, ends with a draft PR |
| `/build` | Code against an issue's acceptance criteria using TDD |
| `/review` | Review an implementation; correctness, standards, and conditional specialists |
| `/verify` | QA verification of every acceptance criterion |
| `/describe` | Explore and understand a problem space interactively |
| `/specify` | Turn a problem statement into testable acceptance criteria |
| `/architecture` | Decide on technical architecture — components, data flow, trade-offs |
| `/design` | Visual and UX design decisions — layouts, interaction flows |
| `/grill-me` | Relentless interviewing to stress-test a plan or design |
| `/compound` | Capture learnings into the Obsidian wiki vault |
| `/wrap-up` | End-of-session audit; harvests NOTES.md into the issue body |
| `/prune` | Audit CLAUDE.md and wiki notes for staleness |
| `/find-skills` | Discover and install skills from the ecosystem |
| `/resolve-pr-feedback` | Process PR review feedback in bulk |
| `/new-skill` | Scaffold a new skill conforming to this authoring standard |

## Workflow paths

| Task size | Path |
|-----------|------|
| Trivial fix | `/implement` directly |
| Medium feature | `/discovery` → `/implement` |
| Large feature / epic | `/discovery` → `/define` → `/implement` |

Full lifecycle walkthrough: [`docs/workflow.md`](docs/workflow.md)

## Authoring standard

This plugin ships an authoring standard for creating new skills:

- **Template**: `_templates/SKILL.template.md` — loose skeleton with placeholders
- **Convention doc**: `_templates/AUTHORING.md` — when and how to reference `_shared/` protocols
- **Scaffolder**: `/new-skill` — interactive, generates a conformant `SKILL.md`

Shared protocols live at `_shared/`:

| File | Purpose |
|------|---------|
| `handoff-artifact.md` | Five-field structure for cross-phase GitHub issue handoffs |
| `interviewing-rules.md` | One-question-at-a-time interview protocol |
| `notes-md-protocol.md` | In-phase NOTES.md memory tier |
| `compaction-protocol.md` | Context editing → delegation → /compact order |

## License

MIT
