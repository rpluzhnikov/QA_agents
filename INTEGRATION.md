# IDE integration guide

This repo ships **two self-contained plugin builds** — `dist/claude/` and
`dist/codex/` — meant to be **copied into a project** by an IDE when the user
creates or opens a project and picks an engine. There is no installer to run.

The machine-readable contract is [`engines.json`](engines.json). An IDE reads it,
offers the listed engines to the user, and copies the chosen build into the
project.

## The model

```
user creates a project in the IDE
  └─ IDE offers: [ Claude Code ] [ Codex ] [ empty ]
       ├─ Claude → copy contents of dist/claude/ → <project>/.claude/plugins/kensa-qa/
       ├─ Codex  → copy contents of dist/codex/  → <project>/
       └─ empty  → do nothing
  └─ IDE runs the engine's postInstall steps (enable / restart / run setup)
```

Everything the engine needs is **inside** the copied folder (agents, prompts,
31 skills, hooks, manifest) — nothing is fetched at install time.

## Consuming `engines.json`

For each entry in `engines[]`:

| Field | Meaning |
|---|---|
| `id` | stable engine key (`claude`, `codex`) |
| `displayName` | what to show the user |
| `summary` | one-line description for the picker |
| `source` | folder to copy **from**, relative to the repo root |
| `target` | folder to copy **into**, relative to the project root |
| `copy` | always `"contents"` — copy what's *inside* `source` into `target`, do not nest the source folder |
| `postInstall` | ordered human/automatable steps after the copy |
| `verify` | how to confirm the engine picked it up |

The IDE needs a local copy of this repo (git clone, submodule, or a pinned
release) to read `engines.json` and the `dist/` builds from.

## Per-engine activation

### Codex (most direct)
Copy `dist/codex/*` into the **project root**. The layout already mirrors where
Codex looks:
- `.codex/agents/*.toml` — project-scoped subagents, loaded automatically.
- `.codex/prompts/*.md` — custom slash prompts.
- `AGENTS.md` — concatenated into Codex's instructions automatically.
- `skills/`, `hooks/hooks.json`, `.codex-plugin/plugin.json` — at the root.

No enable step for the agents/prompts/AGENTS.md. If you want the `skills/` and
`hooks/` discovered through the **plugin** system instead of by-convention,
install the dropped folder via `codex plugin` against a local marketplace — but
for the project-scoped drop, the subagents + AGENTS.md are the primary surface.

### Claude Code
Copy `dist/claude/*` into `<project>/.claude/plugins/kensa-qa/` and enable it for
the project (or fully restart Claude Code so it discovers the folder).

> **Verify the exact activation against current Claude Code docs.** Claude Code
> has two project-scoped mechanisms: (a) a plugin folder under
> `.claude/plugins/<name>/` enabled via settings, and (b) bare project config —
> `.claude/agents/`, `.claude/commands/`, `.claude/skills/` discovered directly,
> with hooks in `.claude/settings.json` and MCP in `.mcp.json`. `dist/claude/` is
> packaged as a **plugin** (it carries `.claude-plugin/plugin.json`, which wires
> the hooks + the sequential-thinking MCP). If your IDE prefers the bare-config
> route, map the subfolders accordingly and move the hooks/MCP wiring into
> `.claude/settings.json` + `.mcp.json` yourself.

## Updating an installed project
Re-copy the engine's `source` over the same `target`. Builds are versioned
(`engines.json.version`, both `plugin.json`); a newer repo build replaces the
older dropped files. User data lives in `.tms/` and is never touched by the copy.

## Rebuilding the artifacts
If you change anything under `shared/` or `engines/`, regenerate `dist/`:

```powershell
.\scripts\build.ps1     # Windows
```
```bash
sh scripts/build.sh     # macOS / Linux
```

The build validates that each engine carries all 31 skills and a valid manifest.
