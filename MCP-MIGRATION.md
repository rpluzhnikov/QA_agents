# Migrating the QA_agents plugin to the Kensa MCP server

**Purpose.** A working reference for reworking the QA_agents plugin (agents,
skills, commands) so it drives Kensa through the **`kensa mcp` MCP server**
instead of shelling out to the `kensa` CLI and parsing stdout.

**Sources of truth for this doc** (all in the Kensa repo, keep this doc in
sync with them):
- `KENSA-CLI.md` §6 — the MCP server reference (transport, tool set, result shape).
- `crates/kensa-cli/src/mcp/tools.rs` — the authoritative tool registry (names,
  input schemas, CLI arm each tool wraps).
- Plugin source: `%LOCALAPPDATA%\dev.kensa.app\qa-agents-src` (the app-cache
  checkout of `github.com/kensa-ide/QA_agents`) — **transient**, do NOT edit it
  there; edit your real QA_agents working clone.

---

## 0. TL;DR — the one thing to internalize

**MCP is a *partial, agent-facing* surface, not a drop-in CLI replacement.**

- The CLI has **39 commands**. The MCP server exposes **15 tools** (12 read + 3
  guarded write) — deliberately just the agent-facing query/edit ops.
- Therefore the plugin becomes a **hybrid**: query/analysis + single/bulk field
  edits go through MCP tools; everything else (`context`, `schema apply`, `sync`,
  `duplicates`, trash, git-temporal, export/import, and the whole
  browser/mobile/http/results/blueprint tool families) **stays on the CLI**.
- The **idiom changes**: an MCP tool returns structured JSON *directly in the
  tool result*. So in migrated paths you **drop** `--format json`, `--format
  ids`, shell pipes / `xargs`, and the "stdout=data / stderr=messages" framing.
  The agent calls a tool → gets JSON → reasons → calls the next tool.
- The **writes are gated**: `create_case` / `update_case` / `bulk_update` are
  only available when the server was started with `--allow-write`. The default
  server is **read-only**. This is the single biggest decision in the migration
  (see §5) — and it matters because the plugin's most-used verb today is
  `kensa new` (a write).

If MCP does not cover an op, **keep the CLI call**. A hybrid skill is the
correct end state, not a failure.

---

## 1. What the agent gets, and how it's wired

The server is `kensa mcp` (stdio, newline-delimited JSON-RPC 2.0, protocol
`2025-06-18`). Every tool body reuses the exact `cmd::*::run` used by the CLI
against a buffered `Format::Json` context, so **a tool's result text is
byte-for-byte identical to `kensa <cmd> --format json`**. No new serializer, no
drift.

Wiring is automatic as of **v0.55.0** (GUI auto-connect) — the plugin does not
need to register anything:
- New on-disk project / QA-plugin install → `<root>/.mcp.json` gets
  `{"mcpServers":{"kensa":{"command":"kensa","args":["mcp","-C","."]}}}`.
- Claude Code trust prompt is suppressed via git-untracked
  `<root>/.claude/settings.local.json` (`enabledMcpjsonServers:["kensa"]`).
- Codex gets a `[mcp_servers.kensa]` upsert in `~/.codex/config.toml`.
- Add `"--allow-write"` to `args` to turn on the write tools.

`command:"kensa"` resolves inside Kensa's embedded terminal (PATH injection in
`pty.rs`) and anywhere `kensa` is on PATH.

**Discovery changes.** The plugin's "orient yourself" step today runs `kensa
describe`. Over MCP the client already exposes `tools/list`, so the agent sees
the tool catalog natively — you can drop `kensa describe` from migrated
discovery paths (or keep it only where you need the *CLI* manifest for CLI-only
ops).

---

## 2. Complete CLI → MCP mapping

### Bucket A — read tools (always available, even on the default read-only server)

| CLI command | MCP tool | MCP input | Notes / loss |
|-------------|----------|-----------|--------------|
| `list [suite]` | `list_cases` | `{ suite? }` | **`--tree` is NOT exposed** (it prints text even in JSON mode) — keep `kensa list --tree` on the CLI when you need the tree. |
| `show <id>` | `show_case` | `{ id }` | Returns the standard field set. **`--field <name>` and `--raw` are NOT exposed** — for a single field or raw bytes, stay on the CLI or just read the returned JSON. |
| `filter <expr>` | `filter_cases` | `{ expr }` | Full filter DSL (see kensa skill §Filter DSL). |
| `find <query>` | `find_cases` | `{ query, limit? }` | `limit` default 20; results carry `match_field`. |
| `stats` | `project_stats` | `{}` | |
| `validate` | `validate_cases` | `{}` | "violations found" is a **result, not an error** (`isError:false`). |
| `lint` | `lint_cases` | `{}` | same violations-are-a-result rule. |
| `doctor` | `doctor` | `{}` | same. |
| `coverage --by-X` | `coverage` | `{ by:"tag"\|"source"\|"suite", uncovered? }` | Tool maps `by` → the CLI's `--by-*` bool. `uncovered:true` only valid with `by:"suite"`; with tag/source → `isError:true`. |
| `gaps --against X` | `gaps` | `{ against?:"shared-steps"\|"source" }` | default `"shared-steps"`. |
| `schema show` | `schema_show` | `{}` | Emits the editable proposal JSON `{version, fields:[…]}`. |
| `shared-step list/orphan/usage` | `list_shared_steps` | `{ mode?:"list"\|"orphan"\|"usage", name? }` | default `mode:"list"`; `name` required when `mode:"usage"`. |

### Bucket B — write tools (ONLY when server started with `--allow-write`)

| CLI command | MCP tool | MCP input | Notes |
|-------------|----------|-----------|-------|
| `new --suite … --title … --tag …` | `create_case` | `{ suite, title?, priority?, status?, tags?, source_id? }` | `suite` required (empty string = `suites/` root). **Writes immediately — no dry-run.** Returns `{id, path, suite, status}`. |
| `update <id> --set … --add-tag … --remove-tag …` | `update_case` | `{ id, set?, add_tags?, remove_tags? }` | `set` is a `{field:value}` **object** (→ `--set field=value`). Covers **single-case** tag add/remove. **Writes immediately — no dry-run.** |
| `bulk update --filter … --set …` | `bulk_update` | `{ filter, set, apply? }` | `set` is a `{field:value}` object. **`apply:false`/omitted = dry-run** (returns the plan, writes nothing) — same default-safe posture as CLI `bulk update` without `--yes`. `apply:true` writes. `destructiveHint:true`. |

### Bucket C — CLI-only (NO MCP tool — leave these as shell-out calls)

These have **no** MCP surface. Any plugin path that uses them must keep calling
`kensa <cmd>`:

- **Discovery/index:** `describe` (use client `tools/list` instead), `index`, `sync`.
- **Bulk mutations beyond field-set:** `bulk add-tag`, `bulk remove-tag`,
  `bulk move`, `bulk delete --to-trash`, `rename-tag`, `bulk-apply`.
  (Single-case tag add/remove IS covered by `update_case`; *bulk* tag ops are not.)
- **Quality:** `duplicates`.
- **Schema & adaptation:** `schema preview`, `schema apply`, `schema migrate`,
  `adapt ready`. (Only `schema show` has a tool.)
- **Agent context:** `context show`, `context bundle`, `explain`. ← notable gap;
  the "prepare context before writing bodies" recipe stays CLI.
- **Git-temporal:** `changed`, `stale`, `blame`, `log`.
- **Trash:** `trash list`, `trash restore`, `trash purge`.
- **Import/Export:** `export`, `import --dry-run`.
- **Util:** `completions`, `man`.
- **Sibling tool families — entirely CLI:** `kensa browser …`, `kensa mobile …`,
  `kensa http …`, `kensa results …`, `kensa blueprint …`. The `kensa-browser`,
  `kensa-mobile`, `kensa-http`, `kensa-results`, `kensa-blueprints` skills have
  **zero** MCP surface — do not touch them in this migration.

---

## 3. Per-tool result shapes & gotchas

All results wrap the CLI's `--format json` stdout:

```json
{ "content": [ { "type": "text", "text": "<--format json stdout>" } ], "isError": false }
```

Gotchas the plugin prose must account for:

1. **Empty-string on "nothing found."** `doctor`, `lint_cases`,
   `validate_cases`, `schema_show`, `find_cases`, `list_shared_steps`, `gaps`
   can return an **empty string** (not `[]`/`{}`) on their nothing-found paths —
   byte-identical to the CLI. This is **not** an error. Any agent guidance that
   says "parse the JSON" must add: *check for empty/whitespace text before
   `JSON.parse`.*
2. **`isError` semantics.** `Err` (bad args, id not found, schema mismatch) →
   `isError:true`. "Violations found" from validate/lint/doctor →
   `isError:false` (the violations are the payload). `bulk_update` partial write
   failure → `isError:true` with plan + per-item errors folded into the text.
   Calling a write tool while `--allow-write` is off → `isError:true`
   ("write tools disabled; start server with --allow-write"). Unknown tool name
   → `isError:true`.
3. **Fresh read every call.** Each `tools/call` reloads the project from disk, so
   a long-lived server always reflects edits made by the GUI, git, or another
   terminal. No stale cache to worry about.
4. **Writes are immediate.** `create_case` and `update_case` have **no
   dry-run** — they write on call. Only `bulk_update` is dry-run-by-default
   (`apply:false`). Reflect this in any "preview first" guidance: for
   single-case ops the preview is gone; for bulk keep the dry-run→apply dance
   (`apply:false` then `apply:true`).
5. **`set` is an object, not repeated flags.** CLI `--set a=1 --set b=2` becomes
   `{"set":{"a":1,"b":2}}`. Values may be string/number/boolean.

---

## 4. Idiom shift — before / after

The plugin's recipes are written in shell-pipe style. Rewrite the covered ones
as tool-call sequences.

**Scope + update (the kensa skill's "Scope changes to the right cases"):**

```sh
# BEFORE (CLI)
kensa filter "tag=auth and status=draft" --format ids \
  | xargs -I{} kensa update {} --set status=active
```
```text
# AFTER (MCP) — needs --allow-write
1. call filter_cases { "expr": "tag=auth and status=draft" }   → JSON array of cases
2. either loop: for each case → update_case { "id": <id>, "set": { "status": "active" } }
   or one pass:  bulk_update { "filter": "tag=auth and status=draft",
                               "set": { "status": "active" }, "apply": true }
```

**Validate after changes:**
```sh
# BEFORE
kensa validate && echo ok
kensa lint --format json | jq '.[] | select(.severity=="error")'
```
```text
# AFTER (read-only server is fine)
1. validate_cases {}   → parse text (mind the empty-string case); isError:false even with violations
2. lint_cases {}       → filter records where severity=="error" in the agent, no jq
```

**Author a new case (the "preferred way to create a case"):**
```sh
# BEFORE
kensa new --suite auth/login --title "Log in" --priority high --tag auth --format json
```
```text
# AFTER — needs --allow-write
create_case { "suite":"auth/login", "title":"Log in", "priority":"high", "tags":["auth"] }
→ { "id":"AUTH-001", "path":"suites/auth/login/AUTH-001.md", ... }
then edit the returned path for the ## Steps body per kensa-test-authoring (that body
edit is a file write, NOT an MCP op — the MCP surface has no step-body editor).
```

**Audit workflow (`/audit`):** every read step (`stats`, `validate`, `lint`,
`doctor`, `coverage`, `gaps`, `shared-step orphan`, `filter`) maps to a Bucket-A
tool and works on the **read-only** server — this command is a clean, low-risk
first migration. But `duplicates`, `stale`, and `sync` in that same workflow are
**Bucket C** → keep them as CLI.

---

## 5. The `--allow-write` decision (do this first)

The plugin's authoring/maintenance agents write constantly (`new` ×39,
`update` ×8, `bulk update` ×8 across the current plugin). Over MCP those only
work if the server runs with `--allow-write`. Options:

- **A — read via MCP, write via CLI (safest, least churn).** Migrate only
  Bucket-A reads to tools; keep `new`/`update`/`bulk update` as CLI calls. The
  default read-only `.mcp.json` is enough. No trust/consent friction. Recommended
  starting point.
- **B — full MCP incl. writes.** Requires the `--allow-write` server
  (`args:[…,"--allow-write"]`). The GUI's MCP setup dialog has the opt-in toggle;
  the plugin docs should instruct the user to enable "write access" when
  installing, and the authoring agents should state they require the write tools.
- **C — per-agent split.** Read-only agents (test-lead/audit) rely on the default
  server; authoring agents (qa-engineer/automation) document that they need the
  write server. Cleanest security story, most prose to write.

Pick one and thread it consistently through the agent frontmatter/prose.

---

## 6. The edit surface — plugin files that touch the CLI

From a grep of the checkout (`shared/` + `engines/`), these reference `kensa
<verb>` and are candidates for MCP-aware rewrites. Prioritize the **core query
surface**; leave the tool-family skills alone.

**Primary (core case surface — highest value):**
- `shared/skills/kensa/SKILL.md` — the CLI reference itself. Add an MCP section
  (or a sibling `kensa-mcp` skill) that states the hybrid rule and the Bucket A/B
  mapping; keep the CLI reference for Bucket C.
- `shared/skills/kensa-test-authoring/SKILL.md` — `new`/`update` → `create_case`/
  `update_case` (write bucket); body edits stay file writes.
- `shared/skills/case-test-sync/SKILL.md`, `shared/skills/ken-traceability/…`,
  `shared/skills/testing-fundamentals/SKILL.md`, `shared/skills/task-assignment/…`,
  `shared/skills/test-monitoring-control-completion/…`.

**Engines (agents + commands):**
- `engines/claude/CLAUDE.md`
- `engines/claude/agents/`: `qa-engineer-agent.md`, `test-lead-agent.md`,
  `automation-engineer.md`, `git-operator.md`, `schema-bootstrap-agent.md`.
- `engines/claude/commands/`: `analyze-cases.md`, `audit.md`, `risk-assess.md`,
  `pull-context.md`, `new-feature.md`, `adapt-schema.md`, `brainstorm.md`,
  `run-routine.md`.
- Codex mirror under `engines/codex/` (kept in lock-step by the build).

**Leave as-is (CLI-only tool families):** `shared/skills/kensa-browser`,
`kensa-mobile`, `kensa-http`, `kensa-results`, `kensa-blueprints`, and the
`schema apply/preview`, `adapt ready`, `context`, `duplicates`, `sync`, trash,
export/import passages.

> The plugin builds `dist/{claude,codex}` from `engines/` + `shared/` via
> `scripts/`. Edit the **sources** (`shared/`, `engines/`), then rebuild — do not
> hand-edit `dist/`.

---

## 7. Suggested order of work

1. **Decide `--allow-write` posture** (§5).
2. **Add the MCP mapping to the `kensa` skill** (or split a `kensa-mcp` skill) —
   the Bucket A/B/C table + the empty-string/isError/immediate-write gotchas.
3. **Migrate the read-only commands first** (`/audit`, `/analyze-cases`,
   `risk-assess`, traceability) — no write gating, lowest risk, immediate payoff.
4. **Migrate the write paths** per your §5 choice (authoring/maintenance agents).
5. **Leave Bucket C + tool families on the CLI** and say so explicitly so agents
   don't invent MCP tools that don't exist.
6. Rebuild `dist/`, reinstall, and run the §5 manual smoke (agent lists the 12
   read tools; with `--allow-write`, the 3 write tools; a read tool returns
   structured JSON; a create/update actually writes).

---

*Generated 2026-07-13 against Kensa v0.55.0 (D209 CLI MCP server, D210 GUI
auto-connect). If the tool set changes, re-derive §2/§3 from
`crates/kensa-cli/src/mcp/tools.rs` and `KENSA-CLI.md` §6.*
