---
name: kensa
description: Drive the kensa command-line tool to query, edit, and maintain QA test cases in a .tms/ project from the terminal. Load whenever a task needs CLI access to the test base — orienting in an unfamiliar project (list/stats/find), creating or bulk-editing cases (new/update/bulk), health checks (validate/lint/duplicates/coverage/gaps/doctor), schema adaptation (schema show/preview/apply/migrate), or token-budgeted reading of related cases (context bundle). The backbone of /audit, /analyze-cases, and /traceability.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (the `kensa` CLI for querying, editing, and maintaining manual test cases stored in `.tms/` + `suites/`). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: implements the CTFL §6.1 test management tool category, providing metrics collection per §5.3.1 (`stats`, `coverage --by-source`) and configuration-management support per §5.4.

## Overview — when to use

Use `kensa` from the embedded terminal (or any shell) when you need to read, modify, validate, or analyse test cases stored in the `.tms/` + `suites/` on-disk layout. The CLI is the fastest path for bulk changes, filtered queries, context preparation before edits, and quality maintenance tasks.

Use `kensa` when you want to:
- Discover what cases exist and their current state (`list`, `filter`, `find`, `stats`)
- Create a new case with an atomically-allocated id (`new`) — the preferred way to author cases
- Read a single case's fields or raw content (`show`)
- Apply field changes to one or many cases (`update`, `bulk update`)
- Tag cases, rename tags, add/remove tags in bulk (`update`, `bulk add-tag`, `bulk remove-tag`, `rename-tag`)
- Move, delete, or duplicate cases via CLI (`bulk move`, `bulk delete`, `trash`)
- Validate cases against the project schema (`validate`)
- Inspect and **adapt the project schema** to a user's existing TMS export, then hand off (`schema show/preview/apply/migrate`, `adapt ready`)
- Run quality checks (`lint`, `duplicates`, `coverage`, `gaps`, `doctor`)
- Prepare agent editing context (`context show`, `context bundle`)
- Inspect git history per case (`blame`, `log`, `changed`, `stale`)
- Export cases with a profile, or preview a foreign import's column mapping (`export`, `import --dry-run`)

Do NOT call `kensa` to write outside the `.tms/` format, start a server, or access remote systems (it is purely local).

**Sibling tool skills.** `kensa` also fronts several **tool families** that have their own dedicated skills — load the matching one when a scope needs it: `kensa-browser` (drive Chrome over CDP), `kensa-mobile` (drive an Android/iOS device), `kensa-http` (run HTTP request collections), `kensa-results` (ingest automation reports and match them to cases), and `kensa-blueprints` (node-graph automations). This skill covers the core project/case surface.

---

## MCP surface — the hybrid rule (read via tools, write via CLI)

Kensa also ships an **MCP server** (`kensa mcp`, stdio JSON-RPC) that the Kensa GUI
auto-wires as of **v0.55.0**: a git-untracked `<root>/.mcp.json` registers
`{"mcpServers":{"kensa":{"command":"kensa","args":["mcp","-C","."]}}}`, and
`<root>/.claude/settings.local.json` pre-trusts it. **The default server is
read-only.** When the MCP client is connected you already see the Kensa tools
natively through `tools/list` — you do **not** need `kensa describe` to discover
them in migrated read paths.

Each tool body reuses the exact CLI `cmd::*::run` against a buffered JSON context,
so **a tool's result text is byte-for-byte identical to `kensa <cmd> --format json`.**

**This plugin's posture — read through MCP tools, write through the CLI:**
- **Query / analysis / health checks → call the MCP tool** and read the JSON straight
  from the tool result. In migrated paths **drop** `--format json`, `--format ids`,
  shell pipes and `xargs` — the tool hands you structured JSON directly; you reason
  over it and call the next tool.
- **Every write (`new`, `update`, `bulk …`) and everything without a tool → keep the
  `kensa <cmd>` CLI call.** The read-only default server is all the plugin needs; a
  hybrid path (some tool calls, some CLI) is the correct end state, not a failure.

### Bucket A — read tools (available on the default read-only server)

| CLI command | MCP tool | Input | Notes / loss |
|-------------|----------|-------|--------------|
| `list [suite]` | `list_cases` | `{ suite? }` | **`--tree` not exposed** — keep `kensa list --tree` on the CLI for the hierarchy. |
| `show <id>` | `show_case` | `{ id }` | **`--field`/`--raw` not exposed** — read the returned JSON, or stay on the CLI for a single field / raw bytes. |
| `filter <expr>` | `filter_cases` | `{ expr }` | full Filter DSL (below). |
| `find <query>` | `find_cases` | `{ query, limit? }` | `limit` default 20; results carry `match_field`. |
| `stats` | `project_stats` | `{}` | |
| `validate` | `validate_cases` | `{}` | violations are the **payload**, `isError:false`. |
| `lint` | `lint_cases` | `{}` | same violations-are-a-result rule. |
| `doctor` | `doctor` | `{}` | same. |
| `coverage --by-X` | `coverage` | `{ by:"tag"\|"source"\|"suite", uncovered? }` | `uncovered:true` only valid with `by:"suite"`; with tag/source → `isError:true`. |
| `gaps --against X` | `gaps` | `{ against?:"shared-steps"\|"source" }` | default `"shared-steps"`. |
| `schema show` | `schema_show` | `{}` | emits the editable proposal JSON `{version, fields:[…]}`. |
| `shared-step list/orphan/usage` | `list_shared_steps` | `{ mode?:"list"\|"orphan"\|"usage", name? }` | default `mode:"list"`; `name` required when `mode:"usage"`. |

> Write tools (`create_case` / `update_case` / `bulk_update`) exist in the server but
> require it to be started with `--allow-write`. **This plugin does not use them** — all
> writes go through the CLI, so don't invent MCP tool calls for `new`/`update`/`bulk`.

### What stays on the CLI (no MCP tool — call `kensa <cmd>`)

- **All writes:** `new`, `update`, `bulk update/add-tag/remove-tag/move/delete`,
  `rename-tag`, `bulk-apply`, `duplicates --mark`, `trash restore/purge`.
- **List/show refinements:** `list --tree`, `show --field <name>`, `show --raw`.
- **Discovery/index:** `describe` (use `tools/list`), `index`, `sync`.
- **Quality:** `duplicates`.
- **Schema & adaptation:** `schema preview`, `schema apply`, `schema migrate`, `adapt ready`.
- **Agent context:** `context show`, `context bundle`, `explain`.
- **Git-temporal:** `changed`, `stale`, `blame`, `log`.
- **Trash / import-export / util:** `trash list`, `export`, `import --dry-run`, `completions`, `man`.
- **Sibling tool families entirely:** `kensa browser/mobile/http/results/blueprint …`.

### Tool-result gotchas (check every migrated read path against these)

1. **Empty string = nothing found, not an error.** `doctor`, `lint_cases`,
   `validate_cases`, `schema_show`, `find_cases`, `list_shared_steps`, `gaps` can
   return an **empty/whitespace** text on their nothing-found path (byte-identical to
   the CLI). **Check for empty text before you `JSON.parse`.**
2. **`isError:false` even with violations.** `validate_cases` / `lint_cases` /
   `doctor` fold violations into the payload (`isError:false`) — a "clean" call and a
   "violations found" call differ only in the text. `isError:true` is reserved for bad
   args, id-not-found, schema mismatch, unknown tool, or calling a write tool on a
   read-only server.
3. **Fresh read every call.** Each `tools/call` reloads the project from disk, so the
   result always reflects edits made by the GUI, git, or another terminal — no stale
   cache to flush.
4. **Argument mapping (not repeated flags).** `coverage {by, uncovered?}` maps to the
   CLI's `--by-*`; `gaps {against?}`; `list_shared_steps {mode?, name?}`. The MCP inputs
   are objects, not flag strings.

---

## Global flags

These flags apply to every subcommand.

| Flag | Description |
|------|-------------|
| `--format table\|json\|jsonl\|ids\|paths` | Output format. Defaults to `table` on a tty, `json` when piped. `ids` prints one case id per line; `paths` prints one file path per line — both ideal for piping. |
| `--quiet` | Suppress progress/info messages on stderr. |
| `--verbose` | Print extra diagnostic info on stderr. |
| `-C <DIR>` / `--dir <DIR>` | Run as if started in `<DIR>` (overrides automatic project-root resolution). |

---

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (including empty result sets). |
| `1` | General error: I/O failure, malformed case, case id not found. |
| `2` | Invalid arguments: bad filter expression, unknown `--format`, clap parse error. |
| `3` | Validation failed: `validate` found one or more schema violations. |
| `4` | Schema/version mismatch: schema major version differs from CLI. |

---

## Environment variables

| Variable | Effect |
|----------|--------|
| `KENSA_PROJECT_ROOT` | Pre-set project root; CLI resolves from this path instead of walking up from cwd. Set automatically by the Kensa GUI in the embedded terminal. |
| `NO_COLOR` | When set (any value), disable ANSI color in table output. |

---

## stdout = data, stderr = messages

All data output is written to **stdout**. All human-readable messages (progress, counts, notes) are written to **stderr**. This means:

```sh
kensa list --format json > cases.json          # clean JSON on stdout
kensa filter "tag=auth" --format ids           # one id per line → pipe-safe
kensa filter "priority=high" --format paths    # one path per line
kensa validate 2>errors.txt                    # messages go to stderr
```

---

## Write discipline — `--yes` and dry-run by default

All write commands that affect many cases (`bulk`, `rename-tag`, `bulk-apply`, `trash purge`, `duplicates --mark`) default to **dry-run** mode: they print what they would do and exit. Pass `--yes` to actually apply.

`update` (single case) and `trash restore` apply immediately (no `--yes` required).

```sh
kensa bulk update --filter "status=draft" --set status=active --dry-run  # default
kensa bulk update --filter "status=draft" --set status=active --yes       # applies
```

---

## Filter DSL

Used by `filter`, `bulk update/add-tag/remove-tag/move/delete`, `context bundle`, `bulk-apply` op filters, and `export --filter`.

### Grammar

```
expr        := orExpr
orExpr      := andExpr ( "or" andExpr )*
andExpr     := notExpr ( "and" notExpr )*
notExpr     := "not" notExpr | atom
atom        := "(" expr ")" | comparison
comparison  := field op value
op          := = | != | ~ | !~ | > | < | >= | <= | in | not in
value       := string | bareword | number | duration | list | /regex/[i]
```

Operator precedence (lowest to highest): `or` < `and` < `not` < comparison.

### Operators

| Op | Meaning |
|----|---------|
| `=` | Exact equality (case-sensitive). |
| `!=` | Not equal. |
| `~` | Substring / regex match (string or `/regex/` literal). |
| `!~` | Not matching. |
| `>` `<` `>=` `<=` | Numeric or duration comparison. |
| `in` | Field value is one of the list: `priority in [high, critical]`. |
| `not in` | Field value is not in the list. |

### Fields available in filter expressions

The built-in fields are `id`, `title`, `tag`, `priority`, `status`, `source`, `source_id`, `suite`, `steps`, `modified`, `created` — plus any schema custom field key (and an explicit `custom.<key>` reference). Field semantics differ by type:

- **String fields** (`id`, `title`, `priority`, `status`, `source`/`source_id`, `suite`, custom): `=`, `!=`, `~`, `!~`, `in`, `not in`. Ordering ops (`>`/`<`) → error.
- **`tag`** (singular — membership over the case's tag list): `=`/`!=` test membership, `~`/`!~` substring/regex over tags, `in`/`not in` list intersection. Note the field is **`tag`, not `tags`**.
- **`steps`** (numeric — the step count): `=`, `!=`, `>`, `<`, `>=`, `<=`, `in`. `~`/`!~` → error.
- **`modified`, `created`** (date/age — require an **ordering op with a duration value**): `modified` uses the file mtime; `created` uses the `created_at` frontmatter (a case without it never matches). `=`/`!=`/`~`/`in` on these → error. The field is **`modified`, not `mtime`**.

### Examples

```sh
kensa filter "tag=auth and priority=high"
kensa filter "status in [draft, active]"
kensa filter "title ~ login"
kensa filter "modified > 30d"               # not modified in the last 30 days
kensa filter "created < 7d"                 # created within the last 7 days
kensa filter "steps >= 5"
kensa filter "not tag=deprecated"
kensa filter "suite = auth/flows and status != deprecated"
kensa filter "custom.owner = alice"
```

Duration literals: `7d` (days), `2w` (weeks), `1m` (30-day months), `1y` (365-day years), `1h` (hours).

---

## Commands by category

### Read-only / filter

#### `list [suite] [--tree]`
List cases, optionally restricted to a suite path. `--tree` renders the suite hierarchy with per-suite case counts.
```sh
kensa list
kensa list auth/flows
kensa list --tree
kensa list --format ids        # one id per line
```

#### `show <id> [--field <name>] [--raw]`
Show a single case by id. `--field <name>` prints only that frontmatter field's value. `--raw` prints the raw file bytes.
```sh
kensa show AUTH-001
kensa show AUTH-001 --field priority
kensa show AUTH-001 --raw
```

#### `filter <expr>`
Filter cases with the DSL. Outputs matching cases.
```sh
kensa filter "tag=smoke and status=active" --format ids
kensa filter "priority=critical" --format json
```

#### `find <query> [--limit <N>]`
Fuzzy-find cases across **title, tags, and body** — step text, expected results, notes, and
section headings — not just title/tags. Each result carries a `match_field` value
(`title|tag|step|expected|notes|section`) telling you where the query hit, so "the test about
rate limiting" now matches a step body even when the title says nothing about it. `--limit` caps
results (default 20).
```sh
kensa find "login flow"
kensa find "rate limiting" --format json   # match_field shows title|tag|step|expected|notes|section
kensa find "payment" --limit 5
```

#### `stats`
Aggregate statistics over the project: `total_cases`, `by_priority`, `by_status`, `by_tag`, `avg_steps`, and `missing_source_id` (count of cases with no `source_id`). Empty priority/status buckets key as `(none)`.
```sh
kensa stats
kensa stats --format json
```

#### `validate`
Validate all cases against the project schema. Exit code 3 if violations found.
```sh
kensa validate
kensa validate --format json
```

#### `describe`
Emit a machine-readable JSON manifest of the CLI surface (subcommands, flags, project paths, case field definitions). Useful for agents to self-orient.
```sh
kensa describe
kensa describe --format json | jq '.commands[].name'
```

#### `index`
Rebuild `.tms/INDEX.md` and per-suite `_index.md` files.
```sh
kensa index
```

### Write / create

#### `new --suite <PATH> [--title <T>] [--priority <P>] [--status <S>] [--tag <T>]... [--source-id <SID>] [--dry-run]`
**The preferred way to create a case.** Atomically allocates the next id (reconciles the counter
on disk exactly like `sync`, then formats it per the project's `id_format` — numeric `001` or
prefixed `AUTH-007`) and writes a valid draft case: frontmatter `{id, title, status: "draft"}`
plus any flags you pass. Because allocation is atomic, **concurrent `new` calls never collide** —
no manual id picking, no `next_id` bump, no id-range carving when multiple agents author in
parallel. Returns the record `{id, path, suite, status}` (use `--format json` and read `path`).

- `--suite ""` targets the `suites/` root; nested suites like `--suite auth/checkout` are fine.
  `..`, absolute paths, and backslash suites are rejected.
- `--tag` is repeatable. `--priority` / `--status` / `--source-id` set those frontmatter fields.
- `--dry-run` prints the would-be `{id, path}` and writes nothing.

`new` creates the case shell; author the `## Steps` body (and `preconditions`, `custom`, `## Notes`)
by editing the returned `path` per the `kensa-test-authoring` skill.
```sh
kensa new --suite auth/login --title "Log in with valid credentials" \
  --priority high --tag auth --tag smoke --source-id LIN-89 --format json
# → {"id":"AUTH-001","path":"suites/auth/login/AUTH-001.md","suite":"auth/login","status":"draft"}
kensa new --suite "" --title "Smoke: homepage loads" --dry-run   # preview id+path, write nothing
```

#### `update <id> [--set FIELD=VALUE]... [--add-tag TAG]... [--remove-tag TAG]... [--dry-run]`
Update a single case. `--set` accepts `title=`, `priority=`, `status=`, or any custom schema field. Repeatable. `--dry-run` prints the planned changes without writing.
```sh
kensa update AUTH-001 --set priority=high --set status=active
kensa update AUTH-001 --add-tag regression --remove-tag smoke
kensa update AUTH-001 --set title="New title" --dry-run
```

#### `bulk update --filter <expr> --set FIELD=VALUE [--set FIELD=VALUE]... [--dry-run] [--yes]`
Set one or more fields on all cases matching a filter. `--set` is **repeatable** — pass it
multiple times to change several fields in one pass (same as single-case `update`).
```sh
kensa bulk update --filter "tag=wip" --set status=draft --yes
kensa bulk update --filter "suite=auth" --set status=active --set priority=high --yes
```

#### `bulk add-tag <tag> --filter <expr> [--dry-run] [--yes]`
Add a tag to all matching cases.
```sh
kensa bulk add-tag regression --filter "suite=auth" --yes
```

#### `bulk remove-tag <tag> --filter <expr> [--dry-run] [--yes]`
Remove a tag from all matching cases.
```sh
kensa bulk remove-tag deprecated --filter "status=active" --yes
```

#### `bulk move --filter <expr> --to <suite> [--dry-run] [--yes]`
Move all matching cases to another suite (POSIX path relative to `suites/`).
```sh
kensa bulk move --filter "tag=auth" --to auth/flows --yes
```

#### `bulk delete --filter <expr> --to-trash [--dry-run] [--yes]`
Move all matching cases to `.tms/trash/`. `--to-trash` is required (hard delete is not supported). 
```sh
kensa bulk delete --filter "status=deprecated" --to-trash --yes
```

#### `rename-tag <old> <new> [--dry-run] [--yes]`
Rename a tag across the whole project.
```sh
kensa rename-tag smoke regression --dry-run
kensa rename-tag smoke regression --yes
```

#### `bulk-apply <script> [--dry-run] [--yes]`
Apply a declarative YAML batch script over filtered cases. Default is dry-run.
```sh
kensa bulk-apply ops/set-priorities.yaml --dry-run
kensa bulk-apply ops/set-priorities.yaml --yes
```

### Quality / maintenance

#### `lint`
Lint cases against built-in quality rules (missing title, empty steps, etc.).
```sh
kensa lint
kensa lint --format json
```

#### `duplicates [--threshold <0.0-1.0>] [--mark] [--dry-run] [--yes]`
Find cases with near-duplicate titles using Jaro-Winkler similarity. Default threshold 0.85. `--mark` adds a `dup-candidate` tag (requires `--yes` to apply).
```sh
kensa duplicates
kensa duplicates --threshold 0.90
kensa duplicates --mark --yes
```

#### `coverage --by-tag | --by-source | --by-suite [--uncovered]`
Count cases grouped by tag, source_id, or suite. Exactly one grouping flag required.

`--by-suite --uncovered` lists **empty suites** — those with zero direct cases — which is the way
to answer "which suites have no cases". `--uncovered` combined with `--by-tag` or `--by-source`
exits 2 with a redirect to `gaps --against source` (those axes derive their keys from cases, so
"uncovered" is vacuous there — there is no case to derive an empty tag/source from).
```sh
kensa coverage --by-tag
kensa coverage --by-suite --format json
kensa coverage --by-suite --uncovered --format json   # empty suites (zero direct cases)
```

#### `gaps --against shared-steps | --against source`
Find gaps in the test base.
- `--against shared-steps` — shared steps referenced by a case but never defined (broken `@shared:` refs).
- `--against source` — **untraced cases**: cases whose `source_id` is absent or empty (not linked
  to any requirement). Each result record is `{id, title, suite, path, status: "untraced"}`. This
  is the direct way to list untraced cases — prefer it over assembling `coverage --by-source` by hand.
```sh
kensa gaps --against shared-steps
kensa gaps --against source --format json   # untraced cases (absent/empty source_id)
```

#### `doctor`
Integrity report: duplicate ids, malformed files, stray files outside suites.
```sh
kensa doctor
kensa doctor --format json
```

#### `sync`
Recompute the project's id counters in `.tms/config.yaml` from what's on disk and rewrite the
file (byte-for-byte identical to how the Kensa IDE writes it). `sync` always recounts `next_id`;
it recounts `next_shared_step_id` / `next_plan_id` only when that key already exists in
`config.yaml` or its artifact dir (`.tms/shared-steps/` / `.tms/plans/`) is non-empty.
**Idempotent and cheap** — when already in sync it writes nothing and exits 0. Errors (exit
non-zero) only if the dir isn't a Kensa project (no `.tms/config.yaml`).
```sh
kensa sync                  # recompute and rewrite config.yaml
kensa sync --check          # report drift WITHOUT writing; exit 3 if out of sync, 0 if in sync
kensa sync --quiet          # suppress progress on stderr
```
> When you create cases with `kensa new`, the id counter is allocated atomically and never
> goes stale — you do **not** need `sync` for the create path. `sync` is a **periodic safety/repair**
> step for trees edited outside the CLI (hand-written case files, imports, merge collisions). The
> `/audit` command runs it as a preflight; run it yourself after bulk hand-edits, then `kensa doctor`.

### Schema & adaptation

> **Data follows schema, never the reverse.** The agent shapes the project's
> *structure* (the schema) once, then **hands off** — the user imports their real
> export through the deterministic **Universal format** importer in the Kensa GUI.
> The two concerns are orthogonal: the agent never imports cases, and the import
> never mutates the schema. See the `/adapt-schema` command and the
> `schema-bootstrap-agent` for the full flow.

> **The schema interface is proposal-based.** You do not pass `--add-field` flags.
> You dump the current schema as an editable JSON **proposal** (`{version, fields:[…]}`),
> edit that object (add/rename entries in `fields[]`), and feed it back through
> `schema apply --from`. The round-trip is: `schema show --format json` → edit →
> `schema preview --from` → `schema apply --from`.

#### `schema show`
Print the project's current schema. Default (`table`) renders a fields table
(`key`, `name`, `type`, `required`, `options`, `order`, `system`). **`--format json`
emits the editable *proposal* shape** that round-trips straight back into
`schema apply --from -`. No `schema.yaml` yet → exit 0 with a note. This is the
starting point for any adaptation — dump it, then edit the JSON.
```sh
kensa schema show
kensa schema show --format json > proposal.json     # dump the editable proposal
```

#### `schema preview --from <PATH> --sample <CASE.md>`
Dry-run a proposal: render a **sample case** under the draft schema and **write
nothing**. Prints each draft field with the sample's value (system fields from
top-level frontmatter; others from the `custom:` map; absent → `(no value)`) — a
"does this shape fit the data?" confirmation step. Always preview before `apply`.
Invalid proposal → exit 3.
```sh
kensa schema preview --from proposal.json --sample suites/auth/AUTH-1.md
```

#### `schema apply --from <PATH|->`
Apply a JSON schema proposal (`{version, fields:[…]}`, or a bare-array shape) to
`.tms/schema.yaml`. Validates + builds the canonical schema, **backs up** any existing
`schema.yaml` to `schema.yaml.bak-<ms>`, then atomically writes the new schema
(byte-parity with the Kensa GUI). `-` reads the proposal from **stdin**. Keep it
**additive** — add fields, rename system fields; do **not** delete or rewrite existing
fields unless the user explicitly asked. Invalid JSON / unknown type / duplicate keys
→ exit 3; I/O error → exit 1.
```sh
kensa schema apply --from proposal.json
cat proposal.json | kensa schema apply --from -     # or stream it from stdin
```

#### `schema migrate`
Version-stamp migration: compare `schema.yaml`'s version to the CLI's current schema
version and apply registered migrations. The migration registry is **currently empty**,
so this is usually a no-op ("already up to date"). A schema **newer** than the CLI
supports → exit 3 (a read-only refusal — it never downgrades). No `schema.yaml` → exit 0.
Note: this does **not** add custom-field capability — custom fields are defined by
editing the proposal's `fields[]` and running `schema apply`.
```sh
kensa schema migrate
```

#### `adapt ready [--message <TEXT>]`
Signal **"schema is adapted"** — writes `.tms/.cache/adapt-ready.json` (a gitignored
sentinel `{ts, schema:true, message?}` the Kensa GUI watches via `fs://changed`). The
GUI refreshes the schema and tells the user: *"Schema adapted — now load your full
export in Universal format."* `--message` stores an optional display message. Run this
**once, last**, after the schema fits the user's sample files. It is the agent's
hand-off; it imports nothing. I/O error → exit 1.
```sh
kensa adapt ready
kensa adapt ready --message "schema adapted from TestRail export"
```

> **Contract for the agent.** Adapt the schema *additively* and then run `adapt
> ready`. Do **not** import cases, and do **not** delete/rewrite existing fields
> unless asked. The import step is the user's, deterministic, and reversible — the
> Universal importer parses any CSV / JSON / YAML / XML into the current schema
> (synonym-mapping known fields, dropping the rest into `frontmatter.custom.<key>`),
> and **never mutates the schema**. Export mirrors it (Export → "Current schema").

### Git-temporal

#### `changed --since <git-ref>`
List cases changed since a git ref (e.g. `HEAD`, branch name, commit sha).
```sh
kensa changed --since main
kensa changed --since HEAD~5 --format ids
```

#### `stale [--days <N>]`
List cases not modified in the last N days (git mtime, filesystem fallback). Default 90 days.
```sh
kensa stale
kensa stale --days 180
```

#### `blame <id>`
Show `git blame` output for a case's file.
```sh
kensa blame AUTH-001
```

#### `log <id>`
Show `git log` output for a case's file.
```sh
kensa log AUTH-001
```

### Trash

#### `trash list`
List the cases currently in `.tms/trash/`.
```sh
kensa trash list
kensa trash list --format json
```

#### `trash restore <id>`
Restore a trashed case back to `suites/` root by its case id (frontmatter id) or trash filename stem.
```sh
kensa trash restore AUTH-001
```

#### `trash purge [--older-than <DURATION>] [--dry-run] [--yes]`
Permanently delete trashed cases. `--older-than` limits to files older than a duration (e.g. `30d`, `12w`). This is the only hard-delete operation.
```sh
kensa trash purge --dry-run
kensa trash purge --older-than 30d --yes
kensa trash purge --yes      # purge all trashed cases
```

### Agent integration

#### `context show <id>`
Show editing context for a single case: frontmatter, step count, related cases (by shared tags/suite/source_id), and a snippet from `.tms/memory/conventions.md` if present.
```sh
kensa context show AUTH-001
kensa context show AUTH-001 --format json
```

#### `context bundle --filter <expr> [--max-tokens <N>]`
Pack matching cases under a token budget (default 8000 tokens, chars/4 heuristic). High-priority and step-heavy cases get full body; the rest are frontmatter-only. All matched cases always appear.
```sh
kensa context bundle --filter "tag=auth" --format json
kensa context bundle --filter "suite=payments" --max-tokens 4000
```

#### `explain <id>`
Human/agent-readable explanation of a case: structured prose summary of steps and intent.
```sh
kensa explain AUTH-001
```

#### `shared-step list`
List shared-step files with their usage count.
```sh
kensa shared-step list
kensa shared-step list --format json
```

#### `shared-step usage <name>`
List cases that reference a specific shared step by its id (stem of the `.md` file).
```sh
kensa shared-step usage LOGIN
```

#### `shared-step orphan`
List shared steps with zero references.
```sh
kensa shared-step orphan
```

### Import / Export

> The CLI's `export`/`import` are **deterministic, profile-driven, and deliberately
> narrow** — for the full range of TMS formats use the Kensa GUI export/import wizards.
> The CLI covers the scriptable slice.

#### `export --profile <PATH> [--filter <EXPR>] [--out <PATH>]`
Profile-driven deterministic export. `--profile` (required) is an export-profile JSON
(`{format, fieldMap?, static?}`). **Supported formats: `universal-csv`, `testrail-csv`**
— any other (`qase-json`, `allure-json`, …) → exit 3 ("use the GUI export wizard").
`fieldMap` maps a foreign column → a kensa key (builtins `id`/`title`/`priority`/`status`/
`tags`/`suite`/`source_id`, or a custom field); `static` maps a foreign column → a literal
(wins over `fieldMap`). Column order is deterministic (fieldMap keys, then static-only
keys). `--filter` selects cases (Kensa DSL); `--out` is the output path (`-`, the default,
writes to stdout). Invalid/malformed profile JSON → exit 3.
```sh
kensa export --profile .tms/tools/export-profiles/testrail.json --filter "tag=smoke" --out out.csv
kensa export --profile universal.json                  # → CSV on stdout
```

#### `import --from <PATH> --dry-run [--sample <N>] [--profile <PATH>]`
Tolerant import — **mapping report only**. This slice supports `--dry-run` **only**
(omitting it → exit 2, "full import is not yet supported; use the GUI importer"). It
classifies the foreign CSV's columns against the built-in keys (`id`/`title`/`priority`/
`status`/`tags`/`source_id`/`suite`/`preconditions`) + schema custom keys and reports the
mapping quality **without writing**. `--sample <N>` (default 40) is the row count for the
report; `--profile` applies a profile's `fieldMap` before checking known keys. Table
output: `N mapped clean, M with leftovers`; JSON: `{sample_rows, columns_total,
mapped_clean, leftovers, leftover_columns}`. Never fails on unknown columns (exit 0); bad
`--profile` JSON → exit 2.
```sh
kensa import --from testrail-export.csv --dry-run --format json
kensa import --from export.csv --dry-run --profile map.json --sample 100
```

> **Import is the user's job, not the agent's.** For the schema-adaptation flow the
> agent shapes the *schema* (see "Schema & adaptation") and the user loads their real
> export through the GUI's deterministic **Universal-format** importer. `import
> --dry-run` is a diagnostic — a way to *preview* how well a foreign CSV's columns line
> up before the user imports — not a write path.

### Util / shell

#### `completions <shell>`
Generate a shell completion script. Shells: `bash`, `zsh`, `fish`, `powershell`.
```sh
kensa completions bash > ~/.bash_completion.d/kensa
kensa completions powershell | Out-File $PROFILE -Append
```

#### `man`
Emit a roff man page for `kensa` to stdout.
```sh
kensa man > /usr/local/share/man/man1/kensa.1
```

---

## Agent recipes

### Discover the project surface before editing

When the MCP client is connected the tool catalog is already visible via `tools/list`
(no `kensa describe` needed). Orient with tool calls; drop to the CLI only for `--tree`.

```text
project_stats {}                       # priority / status distribution (MCP)
list_cases {}                          # flat case list (MCP)
kensa list --tree                      # suite hierarchy + counts — CLI (--tree not exposed)
```

### Scope changes to the right cases

Reads go through the tool; the write stays on the CLI (this plugin does not use the
write tools). Call `filter_cases`, reason over the returned JSON, then apply with `kensa`.

```text
1. filter_cases { "expr": "tag=auth and status=draft" }   → JSON array of matching cases (MCP)
2. apply the change on the CLI:
   kensa bulk update --filter "tag=auth and status=draft" --set status=active --yes   # single write pass
   # or, per id from step 1:  kensa update <id> --set status=active
```

### Prepare context before writing case bodies

```sh
# Full context for one case
kensa context show AUTH-001 --format json

# Pack a filtered set under a token budget for agent context window
kensa context bundle --filter "suite=auth" --format json
```

### Validate after bulk changes

```text
1. validate_cases {}   → parse the text (mind the empty-string = clean case); isError:false even with violations (MCP)
2. lint_cases {}       → filter records where severity=="error" in the agent, no jq (MCP)
```

### Find scope for cleanup

```text
lint_cases {}                                  # quality-rule violations (MCP)
doctor {}                                       # integrity report (MCP)
kensa duplicates --threshold 0.85 --format json # near-duplicate titles — CLI (no tool)
kensa stale --days 90 --format ids              # git-temporal — CLI (no tool)
```

### Safe bulk rename workflow

```sh
kensa bulk update --filter "tag=smoke" --set priority=medium --dry-run  # preview
kensa bulk update --filter "tag=smoke" --set priority=medium --yes      # apply
kensa validate                                                           # confirm
```

### Adapt the schema to a user's export (used by `/adapt-schema`)

Shape the project structure to match the user's existing TMS columns, then hand off.
**Never import the cases yourself** — the user does that via Universal format.

```sh
kensa schema show --format json > proposal.json       # 1. dump the editable proposal
# (read 1-2 of the user's sample case files to learn their columns, then edit
#  proposal.json: add/rename entries in fields[] to match — additive only)
kensa schema preview --from proposal.json --sample suites/auth/AUTH-1.md   # 2. dry-run the fit
kensa schema apply   --from proposal.json             # 3. apply (backs up schema.yaml first)
kensa schema show                                     # 4. confirm the new shape
kensa adapt ready                                     # 5. hand off — import is the user's
```

### Audit workflow (used by `/audit`)

Repository-wide health check. Read-only — every mechanical check maps to a Bucket-A
tool and runs on the **default read-only server**. `duplicates`, `stale`, and `sync`
have no tool → keep them on the CLI. Order matters — cheap checks first, sample last.
Remember the gotchas: violations come back `isError:false`; guard against empty text
before parsing.

```text
# 1. Scope & preflight
kensa --version                     # CLI (no tool)
kensa sync                          # CLI preflight — recompute id counters
project_stats {}                    # MCP

# 2. Mechanical checks (MCP) — a validate/lint/doctor with violations is NOT an error
validate_cases {}
lint_cases {}
doctor {}
list_shared_steps { "mode": "orphan" }
gaps { "against": "shared-steps" }
coverage { "by": "source" }
coverage { "by": "tag" }

#    …plus the two CLI-only checks:
kensa duplicates --threshold 0.85 --format json
kensa stale --days 90 --format json

# 3. Cross-reference (combine with .tms/memory/sot.yaml and .tms/memory/learned/tags.md)
filter_cases { "expr": "source_id != \"\"" }                        # all cases with a source
filter_cases { "expr": "tag=<X> and not tag=<Y>" }                 # required_with violations
filter_cases { "expr": "status = draft and tag=tbd and modified > 30d" }

# 4. Qualitative sample
list_cases {}                       # pick a stratified sample from the returned JSON
show_case { "id": "<ID>" }          # for each sampled case
```

See the `/audit` command for the full Test Lead workflow including how to bucket
findings by severity and write the `.tms/reports/audit-YYYY-MM-DD.md`
artifact. The optional fix phase reuses existing CLI primitives (`rename-tag`,
`bulk delete --to-trash`, `bulk update --set status=deprecated`) with the
dry-run-then-`--yes` discipline above.
