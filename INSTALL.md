# Installing kensa-qa

This is the production install + smoke-test guide for v0.8.0. Follow it
top-to-bottom on a fresh machine. kensa-qa runs in three modes — Claude Code,
native Codex, or hybrid (Claude delegates to Codex). See [§1B](#1b-the-installer-claude-codex-or-hybrid)
for the installer and [CODEX_INTEGRATION.md](CODEX_INTEGRATION.md) for Codex.

## 0. Prerequisites

- Claude Code installed and logged in (modes A/C) and/or the OpenAI Codex CLI
  (modes B/C)
- Node.js + `npx` available on PATH (for the optional `sequential-thinking` MCP)
- Hooks run on **both** Windows (PowerShell, `*.ps1`) and macOS/Linux (`*.sh`) as
  of v0.8.0 — the bash port shipped.
- A real Kensa project to test against (any directory; if it has no `.tms/`
  yet, `/setup` will offer to create it)

## 1. Install the plugin

For **Claude Code** you can use the classic marketplace (**1A**) or the installer
(**1B**). For **Codex** or **hybrid**, use the installer (**1B**).

### Option A: marketplace (Claude Code)

The repo is its own single-plugin marketplace (declared in
`.claude-plugin/marketplace.json`). Inside Claude Code:

```
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov
```

To update later: `/plugin marketplace update rpluzhnikov`.
To disable: `/plugin disable kensa-qa@rpluzhnikov` (kept installed, not loaded).
To remove: `/plugin uninstall kensa-qa@rpluzhnikov`.

Requires the repo to be public or your Claude Code's GitHub auth to
have access to it.

### Option B: symlink from your checkout

For editing the plugin source with live reload after restart, no push
needed:

```powershell
# from a PowerShell with administrator rights, or with Developer Mode enabled:
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.claude\plugins\kensa-qa" `
  -Target "C:\Users\Roman\Documents\GitHub\QA_agents"
```

Edits in the checkout become live in Claude Code after a restart.

### Option C: clone directly into the plugins dir

```powershell
git clone https://github.com/rpluzhnikov/QA_agents.git `
  "$env:USERPROFILE\.claude\plugins\kensa-qa"
```

You'll need to `git pull` to get updates.

### 1B. The installer (Claude, Codex, or hybrid)

Clone the repo, then run the installer for your OS. It detects which engines you
have, asks for the mode and copy-vs-symlink, and wires everything up. Re-runnable.

```powershell
# Windows
git clone https://github.com/rpluzhnikov/QA_agents.git; cd QA_agents
.\install.ps1                 # interactive menu
.\install.ps1 -Both           # or -Claude / -Codex / -Hybrid / -Marketplace ; add -Symlink for dev
```

```bash
# macOS / Linux
git clone https://github.com/rpluzhnikov/QA_agents.git && cd QA_agents
./install.sh                  # interactive menu
./install.sh --both           # or --claude / --codex / --hybrid / --marketplace ; add --symlink for dev
```

- **Claude** target: copies (or symlinks) the plugin into `~/.claude/plugins/kensa-qa`.
  Restart Claude Code afterwards.
- **Codex** target: stages a native Codex plugin and runs `codex plugin add`
  (31 skills + Stop hooks), then drops the 3 subagents into `~/.codex/agents/` and
  the `/kensa-*` prompts into `~/.codex/prompts/`. Trust the hooks via `/plugins`
  in Codex. **Codex needs a usable default model** — ChatGPT-account logins must
  set `model = "gpt-5.5"` in `~/.codex/config.toml` (see CODEX_INTEGRATION.md).
- **Hybrid** target: installs the Claude plugin and runs a `codex exec` smoke test;
  `/setup` then asks how the Test Lead should use Codex (worker / reviewer / off).

## 2. Restart Claude Code

Plugin manifest (`plugin.json`), hooks, agents, commands, and skills are
loaded at session start. **Restart Claude Code fully** -- don't just open a
new tab.

After restart, verify the plugin loaded:

- Run `/help` -- you should see `setup`, `new-feature`, `update-feature`,
  `save-memory`, `audit`, `brainstorm` in the slash command list.
- Type `@` (mention) -- `test-lead-agent`, `qa-engineer-agent`, and
  `strategist` should appear under agents.
- Run `/hooks` -- you should see two entries under **Stop**:
  - `kensa-qa: writing debug log`
  - `kensa-qa: checking memory checkpoint`

If any of the above is missing, the plugin didn't load. Common causes: typo
in the install path, Claude Code wasn't fully restarted, plugin file
permissions wrong.

## 3. Bootstrap a Kensa project

In any project directory (new or existing):

```
/setup
```

This is an interactive flow:

1. **Phase 1** -- detects existing `.tms/memory/` (if present, asks before
   overwriting).
2. **Phase 2** -- project basics (stack, language, types of testing).
3. **Phase 3** -- sources of truth (Linear / Jira / Confluence / Notion /
   Figma); writes `.mcp.json` at repo root if you opt in.
4. **Phase 4** -- if existing cases are found in `.tms/suites/`, learns your
   conventions from a sample.
5. **Phase 5** -- glossary seeding.
6. **Phase 6** -- shows a tree of what will be written, asks for explicit
   confirmation, writes files. Also appends `.tms/debug/` to your project's
   `.gitignore`.

After `/setup` finishes, restart Claude Code one more time so any MCP
servers in the freshly-written `.mcp.json` connect (OAuth happens in
browser on first connect).

## 4. Smoke test

In the same Kensa project, with the plugin loaded:

```
/new-feature LIN-42
```

(Substitute a real ticket ID or paste a free-text spec.)

Expected sequence:

1. The Test Lead echoes back what it understood and asks you to confirm a
   plan.
2. After you approve, the Test Lead spawns one or more QA Engineer subagents
   (you'll see `Task` calls in the transcript).
3. QA Engineers return checklists; the Test Lead reviews and either approves
   or sends back.
4. After checklist approval, QA Engineers write test case `.md` files under
   `.tms/suites/`.
5. The Test Lead reviews cases and reports back to you.
6. **Memory checkpoint** -- the Test Lead automatically runs `/save-memory`.
   Either silently saves (if `auto_save_learnings: true` in `project.md`)
   or shows you a yes/no/edit batch.
7. The Test Lead emits `memory-checkpoint: done` and the session is allowed
   to stop.

Check after the run:

```
.tms/suites/        <- new case files
.tms/debug/         <- one .md digest + one .jsonl snapshot per session
.tms/memory/        <- (optionally) updated learned/* files
```

## 5. If the memory-checkpoint hook misbehaves

Symptoms: session won't stop, or `memory-checkpoint: done` is logged but
hook still blocks.

Diagnostics:

1. Open `.tms/debug/session-<id>.md` -- shows commands invoked and files
   written this session.
2. Open the `.jsonl` snapshot in the same dir -- raw transcript Claude
   Code wrote.
3. Run the hook by hand to see its decision on the current transcript:

   ```powershell
   $tx = "<paste transcript_path from the digest>"
   $payload = "{`"transcript_path`":`"$($tx -replace '\\','\\')`",`"stop_hook_active`":false}"
   $out = $payload | powershell -NoProfile -ExecutionPolicy Bypass `
     -File "$env:USERPROFILE\.claude\plugins\kensa-qa\hooks\save-memory-stop.ps1"
   $out
   ```

   Non-empty output -> the hook is asking Claude to keep working.
   Empty output -> the hook is letting stop happen.

4. To turn the hook off temporarily: open `/hooks` in Claude Code and
   disable it from there.

## 6. Reporting issues / sending feedback

Attach:

- `.tms/debug/session-<id>.md` (digest)
- `.tms/debug/session-<id>.jsonl` (full transcript)
- The exact commands you ran, in order
- What you expected vs. what happened

The `.jsonl` is what I need to debug; the `.md` makes triage faster.

## Known limitations in v0.8.0

- **Hooks now run cross-platform.** PowerShell `*.ps1` on Windows, POSIX `*.sh`
  on macOS/Linux (Claude Code picks the `.ps1`; Codex's `hooks.json` dispatches
  `.sh` by default and `.ps1` via `commandWindows`). On Codex, plugin hooks must
  be trusted via `/plugins` before they fire.
- **Remote Codex marketplace not wired yet.** Codex install is via the installer
  (it stages a local marketplace). `codex plugin marketplace add rpluzhnikov/QA_agents`
  is a v0.9 item — it needs the plugin in a repo subdirectory, which would
  duplicate the shared `skills/` tree.
- **`sequential-thinking` MCP requires `npx`** and is optional on Codex (not
  bundled — add via `codex mcp add` if wanted). First invocation downloads
  `@modelcontextprotocol/server-sequential-thinking` via `npx -y`.
- **Figma write-capable MCP** (used by the `figma-use` skill) is not
  auto-wired -- `/setup` writes a commented placeholder.
