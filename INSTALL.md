# Install (no IDE)

For installing kensa-qa by hand — without the IDE integration. There is no
installer script; you either install the Claude build from the marketplace or copy
the Codex build into your project.

The shipped builds live under [`dist/claude/`](dist/claude) and
[`dist/codex/`](dist/codex) (self-contained: agents, prompts, 32 skills, hooks,
manifest all inside).

---

## Claude Code — marketplace (one-liner)

The Claude plugin bundles everything (agents, commands, skills, hooks, MCP), so the
marketplace install is complete:

```
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov
```

**Then fully restart Claude Code** (not just a new tab). Update later with
`/plugin marketplace update rpluzhnikov`.

Verify:
- `/help` lists `setup`, `new-feature`, `update-feature`, `audit`, `brainstorm`, `pull-context`, `review-spec`, `risk-assess`, `test-plan`, `analyze-cases`, `traceability`, `run-routine`, `save-memory`
- `@` shows `test-lead-agent`, `qa-engineer-agent`, `strategist`
- `/hooks` shows one **Stop** hook (memory checkpoint) — there is no PostToolUse hook (ids are allocated atomically by `kensa-cli new`)

Then run `/setup` in your project.

### Alternative: project-scoped copy (no marketplace)
Drop only the pieces into the project's `.claude/` — Claude auto-discovers them:

```powershell
$p = "C:\path\to\your-project\.claude"
Copy-Item .\dist\claude\agents   "$p\agents"   -Recurse -Force
Copy-Item .\dist\claude\commands "$p\commands" -Recurse -Force
Copy-Item .\dist\claude\skills   "$p\skills"   -Recurse -Force
```

Note: this route loads agents/commands/skills but **not** the Stop hooks or the
sequential-thinking MCP — those need `.claude/settings.json` + `.mcp.json`, which
the marketplace install wires for you. Prefer the marketplace route unless you have
a reason not to.

---

## Codex — copy the build into your project

The Codex plugin format can't bundle subagents, so the complete install is a file
copy (the layout already mirrors where Codex looks). Clone, then copy into the
project root:

```powershell
git clone https://github.com/rpluzhnikov/QA_agents.git
Copy-Item .\QA_agents\dist\codex\* C:\path\to\your-project\ -Recurse -Force
```

```bash
git clone https://github.com/rpluzhnikov/QA_agents.git
cp -R QA_agents/dist/codex/. /path/to/your-project/
```

This places `.codex/agents/*.toml` (subagents, auto-loaded), `.codex/prompts/*.md`,
`AGENTS.md` (auto-concatenated into Codex's instructions), `skills/`, and
`hooks/hooks.json`. Then run `/kensa-setup`.

**Global instead of per-project** (available in all projects): copy
`dist/codex/.codex/agents/*` into `~/.codex/agents/`, `dist/codex/.codex/prompts/*`
into `~/.codex/prompts/`, and merge `AGENTS.md` into `~/.codex/AGENTS.md`.

> Installing the Codex build via `codex plugin marketplace add` would deliver only
> the `skills/` + `hooks/` (the plugin manifest can't carry subagents), so it is
> **not** a complete install on its own. Use the copy above.

---

## `kensa-cli` on PATH

The agents drive the `kensa-cli` command-line tool directly: QA engineers **create cases** with
`kensa-cli new` (which allocates ids atomically — no counter-repair hook needed), and the
`/audit` and `/traceability` commands run `kensa-cli sync` / `doctor` / `coverage` / `gaps`.

So **`kensa-cli` must be on the system PATH** of the process that runs Claude Code / Codex. The
agents run in the host process, **not** Kensa's embedded terminal, so Kensa's terminal PATH
injection does **not** apply here — make sure `kensa-cli` resolves in a plain shell
(`kensa-cli --version`). If it's absent, case creation and the mechanical audit/traceability
checks won't work until you install it.

`kensa-cli sync` is now a **periodic safety/repair** step (run by `/audit`, or by hand after
editing a tree outside the CLI) — there is no longer an automatic PostToolUse sync hook.

---

## Building the artifacts yourself
`dist/` is generated from `shared/` + `engines/`. After changing a source, rebuild:

```powershell
.\scripts\build.ps1     # Windows
```
```bash
sh scripts/build.sh     # macOS / Linux
```
