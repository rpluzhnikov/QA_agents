# Kensa QA — Manual QA Team in Your Pocket

Multi-agent Claude Code plugin for the [Kensa](https://...) test case management IDE.
Turns Claude Code into a small QA team: a Lead who scopes work and reviews,
and Workers who write checklists and test cases.

## Install

### Prerequisites

- Claude Code, logged in.
- Node.js + `npx` on PATH (the bundled `sequential-thinking` MCP installs
  itself on first run via `npx -y`).
- **Windows + PowerShell 5.1** if you want the Stop hooks (auto memory
  checkpoint, debug log). macOS / Linux: the rest of the plugin works,
  hooks silently no-op; bash port is on the v0.5 roadmap.

### 1. Add the plugin to Claude Code

Three options. Pick **A** (marketplace) for normal use — it's the cleanest
and gives you `/plugin` UI for enabling/disabling/updating. Use **B** or
**C** only if you're hacking on the plugin itself.

#### A. Marketplace (recommended)

The repo doubles as a single-plugin marketplace. Inside Claude Code:

```
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov
```

The first command registers the marketplace (Claude Code clones the repo
into its plugin cache and reads `.claude-plugin/marketplace.json`). The
second enables the plugin from it. To update later:

```
/plugin marketplace update rpluzhnikov
```

This works for any user with read access to the GitHub repo. The repo
must be **public**, or the user must have GitHub auth configured in
Claude Code with access to it.

#### B. Symlink from a local checkout

Use this when you're editing the plugin source and want edits to be live
after a restart without pushing.

```powershell
# Windows: PowerShell as admin, OR with Developer Mode enabled
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.claude\plugins\kensa-qa" `
  -Target "C:\Users\Roman\Documents\GitHub\QA_agents"
```

```bash
# macOS / Linux
ln -s /path/to/QA_agents ~/.claude/plugins/kensa-qa
```

#### C. Manual git clone into the plugins dir

```powershell
# Windows
git clone https://github.com/rpluzhnikov/QA_agents.git `
  "$env:USERPROFILE\.claude\plugins\kensa-qa"
```

```bash
# macOS / Linux
git clone https://github.com/rpluzhnikov/QA_agents.git \
  ~/.claude/plugins/kensa-qa
```

You'll `git pull` manually for updates.

### 2. Restart Claude Code

Fully restart — not just a new tab. Plugin manifest, agents, commands,
skills, and hooks all load at session start.

### 3. Verify the plugin loaded

In any project, check:

- `/help` lists `setup`, `new-feature`, `update-feature`, `save-memory`.
- Typing `@` shows `lead` and `worker` agents.
- `/hooks` shows two **Stop** entries: `kensa-qa: writing debug log` and
  `kensa-qa: checking memory checkpoint`. (Windows only — on other
  platforms this section will be empty, which is expected.)

If any of those is missing: the plugin didn't load. Most common cause is a
typo in the install path or Claude Code wasn't fully restarted. See
[INSTALL.md](INSTALL.md) §2 for deeper diagnostics.

### 4. Bootstrap a project

Open a Kensa project (new or existing) and run:

```
/setup
```

It's an interactive flow — answers about stack, test case language, sources
of truth (Linear / Jira / Confluence / Notion / Figma), style learning from
existing cases. Writes `.tms/memory/` and (if you opt in) a project
`.mcp.json` at the repo root. Restart Claude Code one more time after
`/setup` so any newly-added MCP servers connect (OAuth on first use).

### 5. First feature

```
/new-feature <ticket-id | URL | free text>
```

The Lead agent gathers context, plans scope, delegates to Workers, reviews
their checklists and cases, reports back, and auto-checkpoints memory
before the session ends.

For the full smoke-test, diagnostic recipes, and what to attach to bug
reports, see **[INSTALL.md](INSTALL.md)**.

> ⚠️ `.claude-plugin/plugin.json` follows the schema documented in the spec
> at the time of writing. Verify against current `docs.claude.com` before
> publishing to a marketplace.

## Commands

- `/setup` — bootstrap project memory (one-time)
- `/new-feature <ref>` — write test cases for a new feature
- `/update-feature <ref>` — update existing cases for a changed feature
- `/save-memory` — manually commit session learnings to project memory

## Project memory

The plugin stores conventions, glossary, and source-of-truth config in
`.tms/memory/` of the user's project. Everything is human-readable Markdown
and YAML. Edit it directly when conventions change — the plugin re-reads
on every new session.

```
<project>/.tms/memory/
├── project.md         ← what this project is, stack, testing types
├── conventions.md     ← how cases are written here
├── glossary.md        ← domain terms and translations
├── sot.yaml           ← MCP source-of-truth config
└── learned/
    ├── patterns.md    ← patterns extracted from existing cases
    ├── shared-steps.md
    └── tags.md
```

The `project.md`, `conventions.md`, and `glossary.md` files are
human-written (plugin reads only). `learned/*` is plugin-written; you
review. `sot.yaml` is written during `/setup` and edited by hand later.

## SOT integration

The plugin reads tickets and specs through MCP servers, and `/setup` now
**wires them up for you**. Tell setup which sources you use (Linear, Jira,
Confluence, Notion, Figma) and it writes the matching servers into a
project `.mcp.json` at the repo root, then asks you to restart so they
connect (remote servers use in-browser OAuth on first connect). Configure
which spaces/projects/teams to default to in `.tms/memory/sot.yaml`.

Each source has a dedicated extraction skill (`sot-linear`, `sot-jira`,
`sot-confluence`, `sot-notion`, `sot-figma`) that tells the agents where
acceptance criteria live and which MCP tools to call. If a needed MCP
isn't connected, the Lead will tell you and ask you to re-run `/setup` or
paste the content directly.

## Debug logging

Every session that runs inside a Kensa project (detected by the presence of
`.tms/memory/`) gets a debug log written by the `debug-log` Stop hook:

```
<project>/.tms/debug/
├── session-<id>.md     ← readable digest: commands invoked, files written,
│                         worker spawns, transcript pointers
└── session-<id>.jsonl  ← full transcript snapshot at last stop
```

When something misbehaves, attach both files to your issue report -- the
`.jsonl` is what's needed to debug; the `.md` makes triage fast. `/setup`
adds `.tms/debug/` to your project's `.gitignore` automatically so
transcripts (which may contain ticket text or secrets pasted into prompts)
don't get committed.

The hook never blocks the stop; on failure it exits silently and you simply
don't get a log that turn.

## Auto memory checkpoint

After every `/new-feature` and `/update-feature`, the plugin runs the
`/save-memory` protocol automatically before letting the session stop. Behaviour
is controlled by `auto_save_learnings` in `.tms/memory/project.md`:

- `true` — Lead applies saves silently and reports `Saved N items to learned/*`.
- `false` (default) — Lead presents all candidates to you in one message with
  yes/no/edit per item.

Mechanism: a `Stop` hook in `plugin.json` (`hooks/save-memory-stop.ps1`) scans
the transcript for `/new-feature` or `/update-feature` and for the sentinel
line `memory-checkpoint: done` that save-memory emits at the end. If the
sentinel is missing for the latest command, the hook blocks the stop with a
reason and Claude continues into save-memory. Once the sentinel is emitted, the
next stop proceeds normally. Current implementation is **Windows / PowerShell
only**; a bash port for macOS/Linux is on the v0.4 list.

## Bundled MCP

The plugin ships its own `sequential-thinking` MCP server (declared in
`plugin.json`, started automatically when the plugin is enabled — no
credentials needed). It powers the `sequential-thinking` reasoning skill
the Lead and Workers use for hard scope and edge-case decisions.

## Skills

~21 skills under `skills/`, auto-loaded via `skills_dir`. Highlights beyond
the QA-craft skills: `kensa-test-authoring` (byte-exact `.tms/` on-disk
format) and `kensa-cli` (drive the `kensa` CLI for queries, bulk edits, and
context bundling), `sequential-thinking` (structured reasoning), `figma-use`
(programmatic Figma access), and the five `sot-*` source extraction skills.

## Roadmap

- **v0.1** — Lead + Worker, 4 commands, project memory templates.
- **v0.2** — Memory keeper agent for session logging and pattern
  promotion.
- **v0.3** — SOT-specific extraction skills filled with concrete
  per-source guidance; `sequential-thinking` + `figma-use` + `kensa-cli` +
  `kensa-test-authoring` skills integrated; `/setup` wires MCP servers into
  `.mcp.json`.
- **v0.4 (current)** — Stop hooks for auto memory checkpoint and debug log;
  production install path documented in `INSTALL.md`.
- **v0.5** — Bash port of the hooks for macOS/Linux; exploratory testing
  mode (`/explore`).
- **v0.6** — Bulk operations (`/bulk-update`, `/audit`).

See `KENSA_QA_PLUGIN_BUILD_SPEC.md` for the full build specification.
