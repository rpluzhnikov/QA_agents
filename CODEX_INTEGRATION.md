# kensa-qa + OpenAI Codex

kensa-qa runs on OpenAI Codex two ways, and the interactive installer wires up
either (or both, alongside Claude Code):

| Mode | What it is | Codex's role |
|---|---|---|
| **B · Native Codex plugin** | The whole team re-expressed under Codex's plugin architecture | Codex runs everything (skills, subagents, hooks) |
| **C · Hybrid** | Claude Code orchestrates and delegates QA packages to Codex | Codex is a worker / second-opinion reviewer, invoked via `codex exec` |

> **History.** Earlier versions of this doc claimed "there is no MCP server / no
> native plugin for Codex — only a shell-out." That is no longer true: the Codex
> CLI now ships a native plugin system (manifest, bundled skills, hooks,
> marketplace) plus first-class subagents. Mode B uses it. Mode C keeps the
> `codex exec` shell-out, which is still the right tool for letting *Claude*
> borrow Codex as a worker.

Everything is **fail-closed**: if Codex is missing or broken, the hybrid pipeline
silently falls back to Claude's internal agents — nothing breaks.

---

## Prerequisites

1. **Codex CLI installed and on `PATH`.**
   ```bash
   npm install -g @openai/codex      # or your platform's installer
   codex --version                   # e.g. codex-cli 0.135.0
   ```
2. **Authenticated** — `codex login` (ChatGPT account, browser flow) or
   `codex login --api-key sk-...` (OpenAI API key, separate billing).

### Gotcha: the default model

The hybrid path calls `codex exec` **without** `-m`, so it inherits `model` from
`~/.codex/config.toml`. If that model isn't entitled for your auth mode, every
call returns HTTP 400 and (in hybrid mode) the Lead silently degrades to internal:

```
ERROR 400: "The 'gpt-5' model is not supported when using Codex with a ChatGPT account."
```

**ChatGPT-account logins must use `gpt-5.5`.** Edit `~/.codex/config.toml`:

```toml
model = "gpt-5.5"
model_reasoning_effort = "high"
```

(API-key logins have a different matrix — pick any model your key can access.)

---

## Mode B — native Codex plugin

Install it with the repo's installer:

```bash
./install.sh --codex          # macOS / Linux
.\install.ps1 -Codex          # Windows
```

What the installer does:

1. **Stages a Codex plugin** under `~/.codex/.kensa-marketplace/plugins/kensa-qa/`
   from the repo sources — the canonical `.codex-plugin/plugin.json`, the shared
   `skills/` (reused **verbatim** — the `SKILL.md` format is identical across
   Claude Code and Codex), and `hooks/`.
2. Registers it as a local marketplace and runs `codex plugin add kensa-qa@kensa-local`.
   Codex copies it into `~/.codex/plugins/cache/...` — so the staging dir is
   transient. Result: **31 skills + the two Stop hooks** install as a real Codex
   plugin.
3. **Places the subagents and prompts** that a plugin manifest can't bundle
   (Codex `plugin.json` supports only `skills`, `mcpServers`, `apps`, `hooks`):
   - `.codex/agents/*.toml` → `~/.codex/agents/` — the `test-lead-agent`,
     `qa-engineer-agent`, and `strategist` as Codex subagents.
   - `prompts/kensa-*.md` → `~/.codex/prompts/` — the 12 commands as `/kensa-*`
     slash prompts.

After install:
- **Trust the hooks.** Plugin-bundled hooks are not auto-trusted; review and
  enable them via `/plugins` in Codex.
- **`AGENTS.md`** (repo root) is the Codex analogue of `CLAUDE.md` — the always-on
  operating manual. The installer suggests merging it into your project's
  `AGENTS.md` (or `~/.codex/AGENTS.md`).
- **MCP** (`sequential-thinking`) is optional and not bundled (the npx invocation
  differs per OS). Add it if you want it:
  ```bash
  codex mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
  ```
  On Windows, Codex wraps npx via `cmd /c` — see your existing `[mcp_servers.*]`
  entries for the exact form.

The hooks port cleanly because Codex's Stop-hook contract matches Claude's:
stdin carries `transcript_path` / `stop_hook_active`, and a hook blocks the stop
by emitting `{"decision":"block","reason":"..."}`. One `hooks/hooks.json`
dispatches `save-memory-stop.sh` / `debug-log.sh` by default and the `.ps1`
variants via `commandWindows`.

> **Remote marketplace** (`codex plugin marketplace add rpluzhnikov/QA_agents`)
> isn't wired yet — it needs the plugin materialized in a `plugins/<name>/`
> subdirectory in the repo, which would duplicate the shared `skills/` tree. The
> installer avoids that by staging locally. Remote distribution is a v0.9 item.

---

## Mode C — hybrid (Claude delegates to Codex)

Here Claude Code runs the plugin and borrows Codex as a QA worker or reviewer.
It's opt-in **per project** and configured during `/setup`.

### Enabling it

`./install.sh --hybrid` (or `-Hybrid`) installs the Claude plugin and runs a
`codex exec` smoke test. Then, in your project, `/setup` **Phase 3.5** detects
Codex and asks how to use it:

- **worker** — the Test Lead offloads test-case packages to `codex exec`. Codex
  drafts; **Claude writes the files and runs the two-pass review.** Parallel
  packages = load distribution.
- **reviewer** — Claude's `qa-engineer-agent` writes; Codex gives an independent
  second-opinion review the Lead folds in.
- **off** — Claude only (the default).

The choice persists to `.tms/memory/codex.yaml`:

```yaml
codex_role: worker | reviewer | off
codex_review: auto | on | off
```

### How delegation runs

Before each delegation the Lead re-checks availability with the detection helper
(`hooks/codex-detect.sh` / `.ps1`), which prints `codex` or `internal` and honors
the `off` preference. It caches the verdict to `.tms/.codex-availability`
(gitignored). Detection only confirms the binary runs — a wrong default model
passes detection but fails at call time, and the Lead degrades to internal.

The Lead fills one of the templates in `codex/prompts/` and pipes it to Codex
read-only, capturing the final message:

```
codex exec --sandbox read-only --skip-git-repo-check --cd "<project>" -o "<out.md>" - < <filled prompt>
```

- `codex/prompts/codex-worker-package.md` — a self-contained QA-engineer brief.
  Because Codex has no plugin skills and no MCP in this mode, the Lead pastes the
  byte-exact authoring rules (from `kensa-test-authoring` + `conventions.md`) and
  the already-fetched SOT content into the brief. Codex returns the checklist or
  the case file contents (as `=== FILE: ===` blocks); the Lead writes them.
- `codex/prompts/codex-reviewer.md` — second-opinion review of a checklist / case
  batch against the `review-rubrics` criteria.
- `codex/prompts/codex-consult.md` — strategy second opinion, **only** when the
  user explicitly names Codex ("ask Codex", "через Codex").

**Claude stays the sole writer and reviewer** — this preserves the two-pass
review invariant and keeps Codex's sandbox read-only.

### Fail-closed triggers

A non-zero exit, empty output, a `CODEX_ERROR` line, a `400` in stderr, or
unparseable output → the Lead falls back to an internal `qa-engineer-agent` for
that package, surfacing at most one terse line ("Codex unavailable, used internal").

---

## Verifying

```bash
# 1. Detection (prints codex|internal, always exits 0):
sh hooks/codex-detect.sh .

# 2. End-to-end smoke test (exactly how the worker is invoked — no -m):
printf 'Reply with exactly the single word: PONG\n' \
  | codex exec --sandbox read-only --skip-git-repo-check --cd "$(pwd)" -
```

A healthy result prints `PONG`, shows `model: gpt-5.5` in the header, and exits
`0`. A `400` means the default model isn't entitled — fix `model` in
`config.toml`. Detection saying `codex` while the smoke test fails is the classic
"wrong model" symptom.

For Mode B: `codex plugin list` should show `kensa-qa@kensa-local installed,
enabled`, and `~/.codex/agents/` + `~/.codex/prompts/` should contain the three
TOML agents and the `kensa-*` prompts.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `codex-detect` prints `internal` | Binary not on PATH, or `codex_role: off` | Install Codex / check `.tms/memory/codex.yaml` |
| Detection says `codex` but no delegation happens | `codex exec` fails at runtime (usually model) | Run the smoke test; set `model = "gpt-5.5"` |
| `400 ... model is not supported ... ChatGPT account` | Default model not entitled | `model = "gpt-5.5"` in `~/.codex/config.toml` |
| `401` / auth errors | Token expired / no auth | `codex login` (or `--api-key`) |
| Mode B plugin installed but hooks don't fire | Plugin hooks not trusted | Review & enable via `/plugins` in Codex |
| `unknown variant ... ON_FIRST_USE` adding a marketplace | Marketplace `authentication` must be `ON_INSTALL` or `ON_USE` | Already correct in the shipped template |

---

## File map

| Path | Purpose |
|---|---|
| `.codex-plugin/plugin.json` | Native Codex plugin manifest (Mode B) |
| `codex/marketplace.template.json` | Marketplace manifest the installer stages |
| `.codex/agents/*.toml` | Codex subagents (installer → `~/.codex/agents/`) |
| `prompts/kensa-*.md` | `/kensa-*` slash prompts (installer → `~/.codex/prompts/`) |
| `AGENTS.md` | Codex operating manual (≈ CLAUDE.md) |
| `hooks/hooks.json` | Codex hook manifest (`.sh` + `commandWindows` `.ps1`) |
| `hooks/*.sh` | POSIX ports of the Stop hooks + `codex-detect.sh` |
| `codex/prompts/codex-*.md` | Hybrid worker / reviewer / consult templates (Mode C) |
| `.tms/memory/codex.yaml` | Per-project engine preference (Mode C) |
| `.tms/.codex-availability` | Detection cache (gitignored) |
