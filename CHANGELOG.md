# Changelog

All notable changes to **kensa-qa**. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.4.0 -- 2026-05-23

### Added

- **Marketplace manifest** (`.claude-plugin/marketplace.json`). The repo
  now doubles as a single-plugin marketplace named `rpluzhnikov`; users
  install with `/plugin marketplace add rpluzhnikov/QA_agents` then
  `/plugin install kensa-qa@rpluzhnikov`. Symlink/clone install still
  works for plugin development.
- **Auto memory checkpoint.** A `Stop` hook in `plugin.json`
  (`hooks/save-memory-stop.ps1`) blocks session stop after `/new-feature` or
  `/update-feature` until the Lead emits the sentinel line
  `memory-checkpoint: done`. The Lead runs the `/save-memory` protocol
  automatically; UX is controlled by `auto_save_learnings` in
  `.tms/memory/project.md`.
- **Per-session debug log.** A second `Stop` hook
  (`hooks/debug-log.ps1`) writes a readable digest at
  `.tms/debug/session-<id>.md` plus a transcript snapshot
  `session-<id>.jsonl`, but only when the cwd has `.tms/memory/` (i.e. it is
  a Kensa project). `/setup` adds `.tms/debug/` to the project's
  `.gitignore`.
- `INSTALL.md` -- step-by-step install, restart, smoke-test, and diagnostic
  recipe for the hooks.
- `CHANGELOG.md`.
- Top-level `.gitignore` for this repo (local Claude state, debug output if
  hooks ever run here while developing the plugin, OS junk).

### Changed

- `commands/new-feature.md` gains a Step 9 (memory checkpoint).
- `commands/update-feature.md` gains a Step 7 (memory checkpoint).
- `commands/save-memory.md` gains a Step 5 (emit sentinel) -- without it,
  the Stop hook would re-block.
- `commands/setup.md` Phase 6 now writes `.tms/debug/` into the project's
  `.gitignore`.
- `agents/lead.md` documents the memory-checkpoint contract and how the
  Stop hook enforces it.
- Plugin version bumped to `0.4.0`.

### Known limitations

- Hooks are Windows + PowerShell 5.1 only. macOS/Linux: hooks fail silently,
  rest of the plugin works as before. Bash port tracked for v0.5.
- Plugin-defined hooks in `plugin.json` depend on the Claude Code version
  supporting that field. If yours doesn't, copy the `hooks` block manually
  into your project's `.claude/settings.json` as a fallback.

## 0.3.0

- SOT-specific extraction skills (`sot-linear`, `sot-jira`, `sot-confluence`,
  `sot-notion`, `sot-figma`).
- `sequential-thinking`, `figma-use`, `kensa-cli`, `kensa-test-authoring`
  skills integrated.
- `/setup` writes MCP servers into a project `.mcp.json`.

## 0.2.0

- Memory keeper protocol for session logging and pattern promotion.

## 0.1.0

- Initial release: Lead + Worker agents, 4 slash commands, project memory
  templates.
