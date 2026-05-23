# Installing kensa-qa

This is the production install + smoke-test guide for v0.4.0. Follow it
top-to-bottom on a fresh machine.

## 0. Prerequisites

- Claude Code installed and logged in
- Node.js + `npx` available on PATH (for the bundled `sequential-thinking` MCP)
- Windows 11 + Windows PowerShell 5.1 (already present)
  - macOS / Linux: the memory-checkpoint and debug-log hooks are PowerShell
    only in v0.4.0; the rest of the plugin works without them.
- A real Kensa project to test against (any directory; if it has no `.tms/`
  yet, `/setup` will offer to create it)

## 1. Install the plugin

Three options. Use **A** for normal use, **B** while developing the plugin
itself, **C** if A isn't available in your Claude Code version.

### Option A: marketplace (recommended)

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

## 2. Restart Claude Code

Plugin manifest (`plugin.json`), hooks, agents, commands, and skills are
loaded at session start. **Restart Claude Code fully** -- don't just open a
new tab.

After restart, verify the plugin loaded:

- Run `/help` -- you should see `setup`, `new-feature`, `update-feature`,
  `save-memory` in the slash command list.
- Type `@` (mention) -- `lead` and `worker` should appear under agents.
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

1. Lead echoes back what it understood and asks you to confirm a plan.
2. After you approve, Lead spawns one or more Worker subagents (you'll see
   `Task` calls in the transcript).
3. Workers return checklists; Lead reviews and either approves or
   sends back.
4. After checklist approval, Workers write test case `.md` files under
   `.tms/suites/`.
5. Lead reviews cases and reports back to you.
6. **Memory checkpoint** -- Lead automatically runs `/save-memory`. Either
   silently saves (if `auto_save_learnings: true` in `project.md`) or shows
   you a yes/no/edit batch.
7. Lead emits `memory-checkpoint: done` and the session is allowed to stop.

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

## Known limitations in v0.4.0

- **Hooks are Windows-only.** They invoke `powershell.exe` directly. On
  macOS/Linux they silently fail and the plugin still works, but
  auto-checkpoint and debug-log are inactive. Bash port is tracked for v0.5.
- **`sequential-thinking` MCP requires `npx`.** First invocation downloads
  `@modelcontextprotocol/server-sequential-thinking` via `npx -y`. If `npx`
  isn't in PATH the MCP won't start; the rest of the plugin still works.
- **Figma write-capable MCP** (used by the `figma-use` skill) is not
  auto-wired -- `/setup` writes a commented placeholder.
