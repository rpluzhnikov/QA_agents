---
name: kensa-cli
description: Drive the kensa-cli command-line tool to query, edit, and maintain QA test cases in a .tms/ project from the terminal.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (the `kensa-cli` CLI for querying, editing, and maintaining manual test cases stored in `.tms/` + `suites/`). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: implements the CTFL §6.1 test management tool category, providing metrics collection per §5.3.1 (`stats`, `coverage --by-source`) and configuration-management support per §5.4.

## Overview — when to use

Use `kensa-cli` from the embedded terminal (or any shell) when you need to read, modify, validate, or analyse test cases stored in the `.tms/` + `suites/` on-disk layout. The CLI is the fastest path for bulk changes, filtered queries, context preparation before edits, and quality maintenance tasks.

Use `kensa-cli` when you want to:
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

Do NOT call `kensa-cli` to write outside the `.tms/` format, start a server, or access remote systems (it is purely local).

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
kensa-cli list --format json > cases.json          # clean JSON on stdout
kensa-cli filter "tag=auth" --format ids           # one id per line → pipe-safe
kensa-cli filter "priority=high" --format paths    # one path per line
kensa-cli validate 2>errors.txt                    # messages go to stderr
```

---

## Write discipline — `--yes` and dry-run by default

All write commands that affect many cases (`bulk`, `rename-tag`, `bulk-apply`, `trash purge`, `duplicates --mark`) default to **dry-run** mode: they print what they would do and exit. Pass `--yes` to actually apply.

`update` (single case) and `trash restore` apply immediately (no `--yes` required).

```sh
kensa-cli bulk update --filter "status=draft" --set status=active --dry-run  # default
kensa-cli bulk update --filter "status=draft" --set status=active --yes       # applies
```

---

## Filter DSL

Used by `filter`, `bulk update/add-tag/remove-tag/move/delete`, `context bundle`, and `bulk-apply` scripts.

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

Standard fields: `id`, `title`, `priority`, `status`, `tags`, `suite`, `source_id`. Duration fields: `mtime` (last git/fs modification time), `created` (file creation time). Custom schema fields are also available.

### Examples

```sh
kensa-cli filter "tag=auth and priority=high"
kensa-cli filter "status in [draft, active]"
kensa-cli filter "title ~ login"
kensa-cli filter "mtime > 30d"                  # modified in last 30 days
kensa-cli filter "not tag=deprecated"
kensa-cli filter "suite = auth/flows and status != deprecated"
```

Duration literals: `7d` (days), `2w` (weeks), `1m` (months), `1h` (hours).

---

## Commands by category

### Read-only / filter

#### `list [suite] [--tree]`
List cases, optionally restricted to a suite path. `--tree` renders the suite hierarchy with per-suite case counts.
```sh
kensa-cli list
kensa-cli list auth/flows
kensa-cli list --tree
kensa-cli list --format ids        # one id per line
```

#### `show <id> [--field <name>] [--raw]`
Show a single case by id. `--field <name>` prints only that frontmatter field's value. `--raw` prints the raw file bytes.
```sh
kensa-cli show AUTH-001
kensa-cli show AUTH-001 --field priority
kensa-cli show AUTH-001 --raw
```

#### `filter <expr>`
Filter cases with the DSL. Outputs matching cases.
```sh
kensa-cli filter "tag=smoke and status=active" --format ids
kensa-cli filter "priority=critical" --format json
```

#### `find <query> [--limit <N>]`
Fuzzy-find cases across **title, tags, and body** — step text, expected results, notes, and
section headings — not just title/tags. Each result carries a `match_field` value
(`title|tag|step|expected|notes|section`) telling you where the query hit, so "the test about
rate limiting" now matches a step body even when the title says nothing about it. `--limit` caps
results (default 20).
```sh
kensa-cli find "login flow"
kensa-cli find "rate limiting" --format json   # match_field shows title|tag|step|expected|notes|section
kensa-cli find "payment" --limit 5
```

#### `stats`
Aggregate statistics over the project (total cases, by priority, by status, by suite).
```sh
kensa-cli stats
kensa-cli stats --format json
```

#### `validate`
Validate all cases against the project schema. Exit code 3 if violations found.
```sh
kensa-cli validate
kensa-cli validate --format json
```

#### `describe`
Emit a machine-readable JSON manifest of the CLI surface (subcommands, flags, project paths, case field definitions). Useful for agents to self-orient.
```sh
kensa-cli describe
kensa-cli describe --format json | jq '.commands[].name'
```

#### `index`
Rebuild `.tms/INDEX.md` and per-suite `_index.md` files.
```sh
kensa-cli index
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
kensa-cli new --suite auth/login --title "Log in with valid credentials" \
  --priority high --tag auth --tag smoke --source-id LIN-89 --format json
# → {"id":"AUTH-001","path":"suites/auth/login/AUTH-001.md","suite":"auth/login","status":"draft"}
kensa-cli new --suite "" --title "Smoke: homepage loads" --dry-run   # preview id+path, write nothing
```

#### `update <id> [--set FIELD=VALUE]... [--add-tag TAG]... [--remove-tag TAG]... [--dry-run]`
Update a single case. `--set` accepts `title=`, `priority=`, `status=`, or any custom schema field. Repeatable. `--dry-run` prints the planned changes without writing.
```sh
kensa-cli update AUTH-001 --set priority=high --set status=active
kensa-cli update AUTH-001 --add-tag regression --remove-tag smoke
kensa-cli update AUTH-001 --set title="New title" --dry-run
```

#### `bulk update --filter <expr> --set FIELD=VALUE [--set FIELD=VALUE]... [--dry-run] [--yes]`
Set one or more fields on all cases matching a filter. `--set` is **repeatable** — pass it
multiple times to change several fields in one pass (same as single-case `update`).
```sh
kensa-cli bulk update --filter "tag=wip" --set status=draft --yes
kensa-cli bulk update --filter "suite=auth" --set status=active --set priority=high --yes
```

#### `bulk add-tag <tag> --filter <expr> [--dry-run] [--yes]`
Add a tag to all matching cases.
```sh
kensa-cli bulk add-tag regression --filter "suite=auth" --yes
```

#### `bulk remove-tag <tag> --filter <expr> [--dry-run] [--yes]`
Remove a tag from all matching cases.
```sh
kensa-cli bulk remove-tag deprecated --filter "status=active" --yes
```

#### `bulk move --filter <expr> --to <suite> [--dry-run] [--yes]`
Move all matching cases to another suite (POSIX path relative to `suites/`).
```sh
kensa-cli bulk move --filter "tag=auth" --to auth/flows --yes
```

#### `bulk delete --filter <expr> --to-trash [--dry-run] [--yes]`
Move all matching cases to `.tms/trash/`. `--to-trash` is required (hard delete is not supported). 
```sh
kensa-cli bulk delete --filter "status=deprecated" --to-trash --yes
```

#### `rename-tag <old> <new> [--dry-run] [--yes]`
Rename a tag across the whole project.
```sh
kensa-cli rename-tag smoke regression --dry-run
kensa-cli rename-tag smoke regression --yes
```

#### `bulk-apply <script> [--dry-run] [--yes]`
Apply a declarative YAML batch script over filtered cases. Default is dry-run.
```sh
kensa-cli bulk-apply ops/set-priorities.yaml --dry-run
kensa-cli bulk-apply ops/set-priorities.yaml --yes
```

### Quality / maintenance

#### `lint`
Lint cases against built-in quality rules (missing title, empty steps, etc.).
```sh
kensa-cli lint
kensa-cli lint --format json
```

#### `duplicates [--threshold <0.0-1.0>] [--mark] [--dry-run] [--yes]`
Find cases with near-duplicate titles using Jaro-Winkler similarity. Default threshold 0.85. `--mark` adds a `dup-candidate` tag (requires `--yes` to apply).
```sh
kensa-cli duplicates
kensa-cli duplicates --threshold 0.90
kensa-cli duplicates --mark --yes
```

#### `coverage --by-tag | --by-source | --by-suite [--uncovered]`
Count cases grouped by tag, source_id, or suite. Exactly one grouping flag required.

`--by-suite --uncovered` lists **empty suites** — those with zero direct cases — which is the way
to answer "which suites have no cases". `--uncovered` combined with `--by-tag` or `--by-source`
exits 2 with a redirect to `gaps --against source` (those axes derive their keys from cases, so
"uncovered" is vacuous there — there is no case to derive an empty tag/source from).
```sh
kensa-cli coverage --by-tag
kensa-cli coverage --by-suite --format json
kensa-cli coverage --by-suite --uncovered --format json   # empty suites (zero direct cases)
```

#### `gaps --against shared-steps | --against source`
Find gaps in the test base.
- `--against shared-steps` — shared steps referenced by a case but never defined (broken `@shared:` refs).
- `--against source` — **untraced cases**: cases whose `source_id` is absent or empty (not linked
  to any requirement). Each result record is `{id, title, suite, path, status: "untraced"}`. This
  is the direct way to list untraced cases — prefer it over assembling `coverage --by-source` by hand.
```sh
kensa-cli gaps --against shared-steps
kensa-cli gaps --against source --format json   # untraced cases (absent/empty source_id)
```

#### `doctor`
Integrity report: duplicate ids, malformed files, stray files outside suites.
```sh
kensa-cli doctor
kensa-cli doctor --format json
```

#### `sync`
Recompute the project's id counters in `.tms/config.yaml` from what's on disk and rewrite the
file (byte-for-byte identical to how the Kensa IDE writes it). `sync` always recounts `next_id`;
it recounts `next_shared_step_id` / `next_plan_id` only when that key already exists in
`config.yaml` or its artifact dir (`.tms/shared-steps/` / `.tms/plans/`) is non-empty.
**Idempotent and cheap** — when already in sync it writes nothing and exits 0. Errors (exit
non-zero) only if the dir isn't a Kensa project (no `.tms/config.yaml`).
```sh
kensa-cli sync                  # recompute and rewrite config.yaml
kensa-cli sync --check          # report drift WITHOUT writing; exit 3 if out of sync, 0 if in sync
kensa-cli sync --quiet          # suppress progress on stderr
```
> When you create cases with `kensa-cli new`, the id counter is allocated atomically and never
> goes stale — you do **not** need `sync` for the create path. `sync` is a **periodic safety/repair**
> step for trees edited outside the CLI (hand-written case files, imports, merge collisions). The
> `/audit` command runs it as a preflight; run it yourself after bulk hand-edits, then `kensa-cli doctor`.

### Schema & adaptation

> **Data follows schema, never the reverse.** The agent shapes the project's
> *structure* (the schema) once, then **hands off** — the user imports their real
> export through the deterministic **Universal format** importer in the Kensa GUI.
> The two concerns are orthogonal: the agent never imports cases, and the import
> never mutates the schema. See `commands/adapt-schema.md` and the
> `schema-bootstrap-agent` for the full flow.

#### `schema show`
Print the project's current schema (system + custom fields). The starting point for
any adaptation — see what fields already exist before proposing changes.
```sh
kensa-cli schema show
kensa-cli schema show --format json
```

#### `schema preview <field-spec>`
Dry-run a schema change: show the diff, write nothing. Always preview before
`apply` so the user (and you) can see exactly what fields are added/renamed.
```sh
kensa-cli schema preview --add-field "anticipated_outcome:text"
kensa-cli schema preview --rename-field "expected=anticipated_outcome"
```

#### `schema apply <field-spec>`
Apply the schema change to `.tms/schema.yaml` (byte-parity preserved, exactly how the
Kensa GUI writes it). **Additive by default** — add fields, rename system fields; do
**not** delete or rewrite existing fields unless the user explicitly asked.
```sh
kensa-cli schema apply --add-field "anticipated_outcome:text"
kensa-cli schema apply --add-field "pre_reqs:text" --add-field "tc_ref:string"
```

#### `schema migrate`
Upgrade a v1 schema to v2 so custom fields can be defined. Run this first if
`schema show` reports a v1 schema and `apply` rejects custom-field specs.
```sh
kensa-cli schema migrate
```

#### `adapt ready`
Signal **"schema is adapted"** — writes `.tms/.cache/adapt-ready.json` (a gitignored
sentinel the Kensa GUI watches via `fs://changed`). The GUI refreshes the schema and
tells the user: *"Schema adapted — now load your full export in Universal format."*
Run this **once, last**, after the schema fits the user's sample files. It is the
agent's hand-off; it imports nothing.
```sh
kensa-cli adapt ready
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
kensa-cli changed --since main
kensa-cli changed --since HEAD~5 --format ids
```

#### `stale [--days <N>]`
List cases not modified in the last N days (git mtime, filesystem fallback). Default 90 days.
```sh
kensa-cli stale
kensa-cli stale --days 180
```

#### `blame <id>`
Show `git blame` output for a case's file.
```sh
kensa-cli blame AUTH-001
```

#### `log <id>`
Show `git log` output for a case's file.
```sh
kensa-cli log AUTH-001
```

### Trash

#### `trash list`
List the cases currently in `.tms/trash/`.
```sh
kensa-cli trash list
kensa-cli trash list --format json
```

#### `trash restore <id>`
Restore a trashed case back to `suites/` root by its case id (frontmatter id) or trash filename stem.
```sh
kensa-cli trash restore AUTH-001
```

#### `trash purge [--older-than <DURATION>] [--dry-run] [--yes]`
Permanently delete trashed cases. `--older-than` limits to files older than a duration (e.g. `30d`, `12w`). This is the only hard-delete operation.
```sh
kensa-cli trash purge --dry-run
kensa-cli trash purge --older-than 30d --yes
kensa-cli trash purge --yes      # purge all trashed cases
```

### Agent integration

#### `context show <id>`
Show editing context for a single case: frontmatter, step count, related cases (by shared tags/suite/source_id), and a snippet from `.tms/memory/conventions.md` if present.
```sh
kensa-cli context show AUTH-001
kensa-cli context show AUTH-001 --format json
```

#### `context bundle --filter <expr> [--max-tokens <N>]`
Pack matching cases under a token budget (default 8000 tokens, chars/4 heuristic). High-priority and step-heavy cases get full body; the rest are frontmatter-only. All matched cases always appear.
```sh
kensa-cli context bundle --filter "tag=auth" --format json
kensa-cli context bundle --filter "suite=payments" --max-tokens 4000
```

#### `explain <id>`
Human/agent-readable explanation of a case: structured prose summary of steps and intent.
```sh
kensa-cli explain AUTH-001
```

#### `shared-step list`
List shared-step files with their usage count.
```sh
kensa-cli shared-step list
kensa-cli shared-step list --format json
```

#### `shared-step usage <name>`
List cases that reference a specific shared step by its id (stem of the `.md` file).
```sh
kensa-cli shared-step usage LOGIN
```

#### `shared-step orphan`
List shared steps with zero references.
```sh
kensa-cli shared-step orphan
```

### Util / shell

#### `completions <shell>`
Generate a shell completion script. Shells: `bash`, `zsh`, `fish`, `powershell`.
```sh
kensa-cli completions bash > ~/.bash_completion.d/kensa-cli
kensa-cli completions powershell | Out-File $PROFILE -Append
```

#### `man`
Emit a roff man page for `kensa-cli` to stdout.
```sh
kensa-cli man > /usr/local/share/man/man1/kensa-cli.1
```

---

## Agent recipes

### Discover the project surface before editing

```sh
kensa-cli describe --format json           # machine-readable CLI manifest
kensa-cli list --tree                      # suite hierarchy + case counts
kensa-cli stats --format json              # priority / status distribution
```

### Scope changes to the right cases

```sh
# Get ids matching a condition, then update them
kensa-cli filter "tag=auth and status=draft" --format ids \
  | xargs -I{} kensa-cli update {} --set status=active

# Or use bulk (single write pass — preferred for large sets):
kensa-cli bulk update --filter "tag=auth and status=draft" --set status=active --yes
```

### Prepare context before writing case bodies

```sh
# Full context for one case
kensa-cli context show AUTH-001 --format json

# Pack a filtered set under a token budget for agent context window
kensa-cli context bundle --filter "suite=auth" --format json
```

### Validate after bulk changes

```sh
kensa-cli validate && echo "all good"
kensa-cli lint --format json | jq '.[] | select(.severity=="error")'
```

### Find scope for cleanup

```sh
kensa-cli duplicates --threshold 0.85 --format json
kensa-cli stale --days 90 --format ids
kensa-cli lint --format json
kensa-cli doctor
```

### Safe bulk rename workflow

```sh
kensa-cli bulk update --filter "tag=smoke" --set priority=medium --dry-run  # preview
kensa-cli bulk update --filter "tag=smoke" --set priority=medium --yes      # apply
kensa-cli validate                                                           # confirm
```

### Adapt the schema to a user's export (used by `/adapt-schema`)

Shape the project structure to match the user's existing TMS columns, then hand off.
**Never import the cases yourself** — the user does that via Universal format.

```sh
kensa-cli schema show --format json                       # 1. what fields exist now
# (read 1-2 of the user's sample case files to learn their columns)
kensa-cli schema migrate                                  # 2. only if schema is v1
kensa-cli schema preview --add-field "anticipated_outcome:text"   # 3. dry-run the fit
kensa-cli schema apply   --add-field "anticipated_outcome:text"   # 4. apply additively
kensa-cli schema show                                     # 5. confirm the new shape
kensa-cli adapt ready                                     # 6. hand off — import is the user's
```

### Audit workflow (used by `/audit`)

Repository-wide health check. Read-only; combine the JSON outputs into a
single report. Order matters — cheap checks first, sample-based checks last.

```sh
# 1. Scope & preflight
kensa-cli --version
kensa-cli stats --format json

# 2. Mechanical checks — collect JSON, do not abort on exit code 3 from validate
kensa-cli validate --format json
kensa-cli lint --format json
kensa-cli doctor --format json
kensa-cli duplicates --threshold 0.85 --format json
kensa-cli stale --days 90 --format json
kensa-cli shared-step orphan --format json
kensa-cli gaps --against shared-steps --format json
kensa-cli coverage --by-source --format json
kensa-cli coverage --by-tag --format json

# 3. Cross-reference (combine with .tms/memory/sot.yaml and learned/tags.md)
kensa-cli filter 'source_id != ""' --format json          # all cases with a source
kensa-cli filter 'tag:<X> and not tag:<Y>' --format ids   # required_with violations
kensa-cli filter 'status = draft and tag:tbd and mtime > 30d' --format ids

# 4. Qualitative sample
kensa-cli list --format ids                                # pick a stratified sample
kensa-cli show <ID>                                        # for each sampled case
```

See `commands/audit.md` for the full Test Lead workflow including how to bucket
findings by severity and write the `.tms/reports/audit-YYYY-MM-DD.md`
artifact. The optional fix phase reuses existing CLI primitives (`rename-tag`,
`bulk delete --to-trash`, `bulk update --set status=deprecated`) with the
dry-run-then-`--yes` discipline above.
