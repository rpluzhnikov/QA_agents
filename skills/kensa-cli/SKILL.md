---
name: kensa-cli
description: Drive the kensa CLI to query, edit, and maintain QA test cases in a .tms/ project from the terminal.
---

## Overview — when to use

Use `kensa-cli` from the embedded terminal (or any shell) when you need to read, modify, validate, or analyse test cases stored in the `.tms/` + `suites/` on-disk layout. The CLI is the fastest path for bulk changes, filtered queries, context preparation before edits, and quality maintenance tasks.

Use `kensa-cli` when you want to:
- Discover what cases exist and their current state (`list`, `filter`, `find`, `stats`)
- Read a single case's fields or raw content (`show`)
- Apply field changes to one or many cases (`update`, `bulk update`)
- Tag cases, rename tags, add/remove tags in bulk (`update`, `bulk add-tag`, `bulk remove-tag`, `rename-tag`)
- Move, delete, or duplicate cases via CLI (`bulk move`, `bulk delete`, `trash`)
- Validate cases against the project schema (`validate`)
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
kensa filter "tag=auth and priority=high"
kensa filter "status in [draft, active]"
kensa filter "title ~ login"
kensa filter "mtime > 30d"                  # modified in last 30 days
kensa filter "not tag=deprecated"
kensa filter "suite = auth/flows and status != deprecated"
```

Duration literals: `7d` (days), `2w` (weeks), `1m` (months), `1h` (hours).

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
Fuzzy-find cases by title or tags. `--limit` caps results (default 20).
```sh
kensa find "login flow"
kensa find "payment" --limit 5
```

#### `stats`
Aggregate statistics over the project (total cases, by priority, by status, by suite).
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

### Write / bulk

#### `update <id> [--set FIELD=VALUE]... [--add-tag TAG]... [--remove-tag TAG]... [--dry-run]`
Update a single case. `--set` accepts `title=`, `priority=`, `status=`, or any custom schema field. Repeatable. `--dry-run` prints the planned changes without writing.
```sh
kensa update AUTH-001 --set priority=high --set status=active
kensa update AUTH-001 --add-tag regression --remove-tag smoke
kensa update AUTH-001 --set title="New title" --dry-run
```

#### `bulk update --filter <expr> --set FIELD=VALUE [--dry-run] [--yes]`
Set fields on all cases matching a filter.
```sh
kensa bulk update --filter "tag=wip" --set status=draft --yes
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

#### `coverage --by-tag | --by-source | --by-suite`
Count cases grouped by tag, source_id, or suite. Exactly one grouping flag required.
```sh
kensa coverage --by-tag
kensa coverage --by-suite --format json
```

#### `gaps [--against shared-steps]`
Find unreferenced shared steps. Only `--against shared-steps` is supported.
```sh
kensa gaps --against shared-steps
```

#### `doctor`
Integrity report: duplicate ids, malformed files, stray files outside suites.
```sh
kensa doctor
kensa doctor --format json
```

#### `schema migrate`
Migrate the project schema to the current version.
```sh
kensa schema migrate
```

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

### Util / shell

#### `completions <shell>`
Generate a shell completion script. Shells: `bash`, `zsh`, `fish`, `powershell`.
```sh
kensa completions bash > ~/.bash_completion.d/kensa
kensa completions powershell | Out-File $PROFILE -Append
```

#### `man`
Emit a roff man page for `kensa-cli` to stdout.
```sh
kensa man > /usr/local/share/man/man1/kensa.1
```

---

## Agent recipes

### Discover the project surface before editing

```sh
kensa describe --format json           # machine-readable CLI manifest
kensa list --tree                      # suite hierarchy + case counts
kensa stats --format json              # priority / status distribution
```

### Scope changes to the right cases

```sh
# Get ids matching a condition, then update them
kensa filter "tag=auth and status=draft" --format ids \
  | xargs -I{} kensa update {} --set status=active

# Or use bulk (single write pass — preferred for large sets):
kensa bulk update --filter "tag=auth and status=draft" --set status=active --yes
```

### Prepare context before writing case bodies

```sh
# Full context for one case
kensa context show AUTH-001 --format json

# Pack a filtered set under a token budget for agent context window
kensa context bundle --filter "suite=auth" --format json
```

### Validate after bulk changes

```sh
kensa validate && echo "all good"
kensa lint --format json | jq '.[] | select(.severity=="error")'
```

### Find scope for cleanup

```sh
kensa duplicates --threshold 0.85 --format json
kensa stale --days 90 --format ids
kensa lint --format json
kensa doctor
```

### Safe bulk rename workflow

```sh
kensa bulk update --filter "tag=smoke" --set priority=medium --dry-run  # preview
kensa bulk update --filter "tag=smoke" --set priority=medium --yes      # apply
kensa validate                                                           # confirm
```

### Audit workflow (used by `/audit`)

Repository-wide health check. Read-only; combine the JSON outputs into a
single report. Order matters — cheap checks first, sample-based checks last.

```sh
# 1. Scope & preflight
kensa --version
kensa stats --format json

# 2. Mechanical checks — collect JSON, do not abort on exit code 3 from validate
kensa validate --format json
kensa lint --format json
kensa doctor --format json
kensa duplicates --threshold 0.85 --format json
kensa stale --days 90 --format json
kensa shared-step orphan --format json
kensa gaps --against shared-steps --format json
kensa coverage --by-source --format json
kensa coverage --by-tag --format json

# 3. Cross-reference (combine with .tms/memory/sot.yaml and learned/tags.md)
kensa filter 'source_id != ""' --format json          # all cases with a source
kensa filter 'tag:<X> and not tag:<Y>' --format ids   # required_with violations
kensa filter 'status = draft and tag:tbd and mtime > 30d' --format ids

# 4. Qualitative sample
kensa list --format ids                                # pick a stratified sample
kensa show <ID>                                        # for each sampled case
```

See `commands/audit.md` for the full Lead workflow including how to bucket
findings by severity and write the `.tms/reports/audit-YYYY-MM-DD.md`
artifact. The optional fix phase reuses existing CLI primitives (`rename-tag`,
`bulk delete --to-trash`, `bulk update --set status=deprecated`) with the
dry-run-then-`--yes` discipline above.
