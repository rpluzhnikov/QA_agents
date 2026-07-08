# Kensa CLI Reference (`kensa`)

> Authoritative, source-derived reference for the `kensa` command-line binary
> that ships with the Kensa QA test-case IDE. Every claim in this document traces
> to `crates/kensa-cli/src/` (the CLI) and `crates/kensa-core/src/` (the data
> model) as of workspace version **0.52.0**. When this doc and any other doc
> (CLAUDE.md, the `kensa-cli` skill) disagree, the **code wins** — see the
> [Discrepancies](#discrepancies-vs-claudemd--the-skill) appendix.

---

## 1. Overview

### What it is

`kensa` is a fast, local, single-binary CLI written in Rust (crate `kensa-cli`,
built on `kensa-core`). It reads, edits, validates, and maintains QA test cases
stored on disk in the Kensa `.tms/` + `suites/` project format. It also carries
a set of adjacent "tool" families: an HTTP request runner, a CDP browser driver,
an Android/iOS device driver, automation-result ingestion, and blueprint
automation graphs.

The clap command name is **`kensa`** (the compiled binary file is
`kensa-cli`; it is renamed to `kensa` when distributed).

### How it is distributed

The binary ships as a Tauri **`externalBin` sidecar** (packaged per platform,
distributed separately from the GUI). Inside the Kensa GUI's embedded terminal,
`src-tauri/src/pty.rs` injects it onto `PATH` and sets two environment variables
so it "just works" without arguments:

- `KENSA_PROJECT_ROOT` — the open project's root directory.
- `KENSA_VERSION` — the running GUI/CLI version.

Outside the GUI it is an ordinary CLI: run it from anywhere inside a project
directory, or point it at one with `--dir` / `KENSA_PROJECT_ROOT`.

### The `.tms/` project model (one paragraph)

A Kensa project root is any directory that contains a `.tms/` subdirectory. Test
cases are plain Markdown files (YAML frontmatter + a structured body of steps)
living under `suites/` (nested folders = suites). `.tms/` holds project
metadata: `config.yaml` (id counters like `next_id`), `schema.yaml` (custom
field definitions, v1/v2), `shared-steps/*.md`, `plans/*.json`,
`runs/*.json` + `automation-runs/*.json`, `blueprints/BP-NNN.json`,
`tools/http/*.http` + `tools/http/env/*.json`, `routines/RT-NNN.md`,
`trash/`, and an ephemeral `.cache/`. The TypeScript IDE is the source of truth
for this on-disk format; the Rust core round-trips it **byte-for-byte** (parity
is a hard rule).

### Global flags

These are `global = true` and may appear before or after the subcommand.

| Flag | Type | Default | Meaning |
|------|------|---------|---------|
| `--format <FORMAT>` | enum | `table` on a tty, `json` when piped | Output format: `table`, `json`, `jsonl`, `ids`, `paths`. An unknown value exits 2. |
| `--quiet` | switch | off | Suppress progress/info messages on stderr. |
| `--verbose` | switch | off | Print extra diagnostic info on stderr. |
| `-C`, `--dir <DIR>` | path | — | Run as if started in `<DIR>`; overrides project-root resolution. If `<DIR>` has no `.tms/`, exit 2. |
| `-V`, `--version` | switch | — | Print the workspace version (`0.52.0`) and exit. |
| `-h`, `--help` | switch | — | Print help. With no subcommand, help is printed and exit is non-zero (`arg_required_else_help`). |

### Output conventions

**stdout = data only. stderr = every human message** (progress, counts,
warnings, notes). This is enforced everywhere, so `kensa ... > out.json`
produces clean data and `2>` captures the chatter.

The five formats (`crates/kensa-cli/src/output.rs`):

- **`table`** — pretty box table (`comfy-table` UTF8_FULL). Column order = the
  first record's field order. Empty result set prints nothing.
- **`json`** — pretty-printed JSON array (list commands) or object (single-object
  commands). Field insertion order is preserved.
- **`jsonl`** — one compact JSON object per line (newline-delimited).
- **`ids`** — one record's `id` field per line. Errors (exit 1) if a record has
  no `id` field.
- **`paths`** — one record's `path` field per line. Errors (exit 1) if a record
  has no `path` field.

Color in `table` output is enabled only when stdout is a tty **and** `NO_COLOR`
is unset.

A downstream `BrokenPipe` (e.g. `kensa ... | head`) is treated as a clean exit 0.

### Exit codes (`crates/kensa-cli/src/exit.rs`)

| Code | Name | When |
|------|------|------|
| `0` | OK | Success, **including empty result sets**. |
| `1` | General error | I/O failure, malformed/unreadable case, `show <id>` not found, per-item bulk write failure, output-field-missing for `ids`/`paths`. |
| `2` | Invalid args | clap parse error, bad filter DSL, unknown `--format`, not inside a project, git-required command with no git/repo/ref, bad profile args, etc. |
| `3` | Validation failed | `validate` found ≥1 violation; `lint` found an **error**-severity violation; `doctor` found problems; `sync --check` detected drift; `blueprint validate` found errors; `schema apply/preview` proposal invalid; `schema migrate` future-version refusal; `export` invalid/unsupported profile format. |
| `4` | Schema/version mismatch | `validate` when `schema.yaml` major version is outside the supported set (`1`–`2`). |

### Error output shape

Most commands print `error: <message>` to stderr and exit with the code above.
The **`kensa mobile`** family additionally writes a machine-readable envelope to
**stdout** when the effective format is `json`/`jsonl`:

```json
{"error": "<message>", "hint": "<hint>"}
```

(the `hint` key is omitted when there is none). No other command family emits
this stdout envelope. The iOS delegation path re-wraps sim-use's own
`{"ok":true,"data":…}` as `{"ok":true,"data":…,"source":"sim-use"}`.

### Project-root resolution (`crates/kensa-cli/src/project.rs`)

For any command that needs a project, the root is resolved in this order:

1. `--dir` / `-C` value (must contain `.tms/`, else exit 2).
2. `KENSA_PROJECT_ROOT` env var (must contain `.tms/`, else exit 2).
3. Walk up from the current directory until a `.tms/` is found.
4. Otherwise exit 2 with a hint.

**Project-independent commands** skip this entirely and run in any directory:
`completions`, `man`, `browser …`, `mobile …`, `blueprint signal` (internal),
and `results push`.

### Environment variables

| Variable | Used by | Effect |
|----------|---------|--------|
| `KENSA_PROJECT_ROOT` | project resolution | Preset project root (set by the GUI in the embedded terminal). |
| `KENSA_VERSION` | (informational) | Set by the GUI alongside `KENSA_PROJECT_ROOT`. |
| `NO_COLOR` | table output | Any value disables ANSI color. |
| `KENSA_CDP_URL` | `browser` | CDP WebSocket URL (loopback only), used when `--cdp-url` is absent. |
| `KENSA_TOKEN` | `results push` | Auth token fallback when `--token` is absent. |
| `ANDROID_HOME` | `mobile` | Helps resolve the `adb` binary (via `kensa_core::mobile::resolve_adb`). |
| `KENSA_RUN_ID`, `KENSA_NODE_ID`, `SIGNAL_TOKEN` | `blueprint signal` | Read by an agent child process during a blueprint run (internal). |

### Path conventions

All project paths in output and arguments are **POSIX forward-slash** strings
(e.g. `suites/auth/AUTH-1.md`), regardless of host OS. Suite arguments reject
backslashes, absolute/drive-prefixed paths, and `.`/`..` components.

---

## 2. Command reference

The command surface has **38 top-level commands / families**. Grouped below by
purpose.

### 2.1 Read / query

#### `list [SUITE] [--tree]`

List cases, optionally within a suite subtree, or render the suite tree.

- `SUITE` (positional, optional): restrict to this suite path (POSIX, relative to
  `suites/`) and its descendants.
- `--tree`: render the suite hierarchy with per-suite case counts (text output;
  bypasses `--format`).

Output records: `id`, `title`, `suite`, `priority`, `status`, `tags`, `path`.
Sorted by (suite, id). Malformed case files are **skipped with a stderr
warning** (not fatal). Exit 0.

```sh
kensa list
kensa list auth/flows
kensa list --tree
kensa list --format ids
```

#### `show <ID> [--field <NAME>] [--raw]`

Show a single case by id.

- `<ID>` (positional, required).
- `--field <NAME>`: print only that frontmatter field's value (`id`/`suite` are
  convenience projections; otherwise looked up in known then unknown
  frontmatter). Absent field → exit 1.
- `--raw`: write the file bytes verbatim to stdout.

Default (`table`): a human-readable block (id, title, suite, priority, status,
tags, source, steps, notes). `json`/`jsonl`: an object with `id`, `title`,
`suite`, `priority`, `status`, `tags`, `source_id`, `steps` (count), `path`.
Missing id → exit 1.

```sh
kensa show AUTH-001
kensa show AUTH-001 --field priority
kensa show AUTH-001 --raw
```

#### `filter <EXPR>`

Filter cases with the Kensa filter DSL (see [§3](#3-filter-dsl)).

- `<EXPR>` (positional, required): a filter expression. Parse/validation errors
  render a caret-pointed message to stderr and exit 2.

Output records: `id`, `title`, `suite`, `priority`, `status`, `tags`, `path`,
sorted by (suite, id). Empty match set is success (exit 0). This command loads
cases **strictly** (a malformed case file aborts with exit 1).

```sh
kensa filter "tag=auth and priority=high"
kensa filter "status in [draft, active]" --format ids
kensa filter "modified > 30d" --format paths
```

#### `find <QUERY> [--limit <N>]`

Fuzzy-find cases (nucleo matcher) across title + tags (full weight) and body
fragments — step text, expected results, step/case notes, extra sections
(reduced weight 0.6). Best per-case score wins.

- `<QUERY>` (positional, required): trimmed; empty → exit 2.
- `--limit <N>` (default `20`): max results.

Output records: `id`, `title`, `suite`, `score`, `match_field`
(`title|tag|step|expected|notes|section`), `path`. Sorted by score descending.
Empty result → exit 0.

```sh
kensa find "login flow"
kensa find payment --limit 5
```

#### `stats`

Aggregate statistics over the project. Emits a single object: `total_cases`,
`by_priority` (map), `by_status` (map), `by_tag` (map), `avg_steps`,
`missing_source_id` (count of cases with no `source_id`). Maps are alphabetically
sorted. Empty priority/status buckets key as `(none)`.

```sh
kensa stats
kensa stats --format json
```

#### `validate`

Validate every case's custom fields against `.tms/schema.yaml` (port of the
IDE's `validateCustomField`: required + per-type checks for
text/textarea/number/date/checkbox/url/select/multiselect). System fields
(priority/status/tags/preconditions) are skipped.

Output records (violations): `id`, `path`, `field`, `message`. **Exit 3 if any
violation; 0 if clean.** No `schema.yaml` → exit 0 (nothing to validate). Schema
major version outside `1`–`2` → **exit 4**. Loads cases strictly (malformed →
exit 1).

```sh
kensa validate
kensa validate --format json
```

#### `describe`

Emit a machine-readable JSON manifest of the CLI surface, derived by walking
clap's own command tree at runtime (so it cannot drift). Includes
`schema_version`, `kqa_version`, `project` paths (root, schema_yaml, suites_dir),
`commands[]` (name, command, about, args, flags with values/defaults, switches),
and `definitions.Case` (the standard case field shape). Always JSON to stdout.

```sh
kensa describe
kensa describe | jq '.commands[].name'
```

#### `index`

Rebuild `.tms/INDEX.md` and each suite's `_index.md`. Byte-deterministic and
idempotent: a target is written only if its bytes changed (no git/mtime churn).
Malformed cases are skipped (stderr warning) and excluded from suite counts.
stdout lists the target paths (records with `path`/`id`), so it composes with
`--format paths`. Exit 0.

```sh
kensa index
```

### 2.2 Create / write (single case)

#### `new --suite <PATH> [flags]`

Create a new case with an atomically allocated id and a frontmatter-only scaffold
file. Reconciles the id counter against on-disk stems before allocating
(`reconciled = max(stored next_id, max_on_disk + 1)`), writes the case, then
bumps `config.yaml`'s `next_id` (file-then-counter for crash safety).

- `--suite <PATH>` (required): suite path relative to `suites/` (POSIX). `""` =
  suites root. Rejected (exit 2) if it contains backslashes, is absolute /
  drive-prefixed, or has `.`/`..`/empty components.
- `--title <TITLE>`: defaults to `"Untitled case"`.
- `--priority <PRIORITY>`: validated like `update --set priority=`.
- `--status <STATUS>`: defaults to `"draft"`.
- `--tag <TAG>`: repeatable (union/dedup).
- `--source-id <SID>`: set the `source_id` frontmatter (requirement link).
- `--dry-run`: print the plan (`id`, `path`, `suite`, `would_create`) and write
  nothing.

Output on apply: `id`, `path`, `suite`, `status`. A collision (id already exists
anywhere under `suites/`) → exit 1 with a "run `kensa sync`" hint. Missing/
malformed `config.yaml` → exit 2. After writing, prints the "run `kensa index`"
hint to stderr.

```sh
kensa new --suite auth/flows --title "Login with OTP" --priority high --tag smoke
kensa new --suite "" --dry-run
```

#### `update <ID> [--set FIELD=VALUE]... [--add-tag TAG]... [--remove-tag TAG]... [--dry-run]`

Update a single case. **Applies immediately** (single-case writes are not
gated by `--yes`); `--dry-run` prints the plan and writes nothing.

- `<ID>` (positional, required).
- `--set FIELD=VALUE` (repeatable): `title`/`priority`/`status` (built-ins,
  accept any string) or a custom schema field (validated against its
  type/options). `id` is immutable (exit 2); `tags` must use `--add-tag`/
  `--remove-tag` (exit 2); `custom`/`source_id`/`created_at`/`updated_at`/
  `preconditions` are not `--set`-able (exit 2); an unknown non-built-in with no
  schema field → exit 2.
- `--add-tag TAG` (repeatable): union/dedup.
- `--remove-tag TAG` (repeatable): no-op if absent.
- `--dry-run`.

At least one of `--set`/`--add-tag`/`--remove-tag` is required (else exit 2).
Output: one plan record per change (`id`, `path`, `change`). Missing id → exit 1.
Writes are atomic and byte-compatible with the IDE.

```sh
kensa update AUTH-001 --set priority=high --set status=active
kensa update AUTH-001 --add-tag regression --remove-tag smoke
kensa update AUTH-001 --set title="New title" --dry-run
```

### 2.3 Bulk / corpus writes

All bulk/corpus writes are **dry-run by default**; `--yes` applies and
`--dry-run` wins over `--yes`. Plan records go to stdout; a "would change /
applied" banner + a "run `kensa index`" hint go to stderr. Writes are per-item
independent — accumulated per-item errors are noted to stderr and cause exit 1
after applying the rest.

#### `bulk update --filter <EXPR> --set FIELD=VALUE... [--dry-run] [--yes]`

Set fields on all cases matching a filter. At least one `--set` is required
(exit 2). Same `--set` classification/validation as `update`.

```sh
kensa bulk update --filter "tag=wip" --set status=draft --yes
```

#### `bulk add-tag <TAG> --filter <EXPR> [--dry-run] [--yes]`

Add `<TAG>` to all matching cases (no-op cases are not counted).

```sh
kensa bulk add-tag regression --filter "suite=auth" --yes
```

#### `bulk remove-tag <TAG> --filter <EXPR> [--dry-run] [--yes]`

Remove `<TAG>` from all matching cases.

```sh
kensa bulk remove-tag deprecated --filter "status=active" --yes
```

#### `bulk move --filter <EXPR> --to <SUITE> [--dry-run] [--yes]`

Move all matching cases to `<SUITE>` (POSIX, relative to `suites/`; `""` = root).
Plan records: `id`, `path`, `from`, `to`. On apply: no-op if already there; a
missing destination directory is a per-item error (exit 1); moves are plain
renames (overwrite same-named target — IDE parity).

```sh
kensa bulk move --filter "tag=auth" --to auth/flows --yes
```

#### `bulk delete --filter <EXPR> --to-trash [--dry-run] [--yes]`

Move matching cases to `.tms/trash/`. `--to-trash` is **required** (hard delete
is not supported; exit 2 without it). Plan records: `id`, `path`, `trash_path`.

```sh
kensa bulk delete --filter "status=deprecated" --to-trash --yes
```

#### `rename-tag <OLD> <NEW> [--dry-run] [--yes]`

Rename a tag across the whole project (every case carrying `<OLD>`). Dry-run by
default. Plan records: `id`, `path`, `change`.

```sh
kensa rename-tag smoke regression --dry-run
kensa rename-tag smoke regression --yes
```

#### `bulk-apply <SCRIPT> [--dry-run] [--yes]`

Apply a declarative YAML batch script over filtered cases. Dry-run by default.

Script shape (`version: 1` + a non-empty `operations` list):

```yaml
version: 1
operations:
  - filter: "tag=wip"           # required (Kensa DSL)
    set:                        # optional map: field -> value
      status: draft
    add_tags: [triage]          # optional list
    move_to: "backlog"          # optional destination suite
```

Each operation needs `filter` plus at least one of `set`/`add_tags`/`move_to`.
Unknown top-level or op keys, missing/invalid `version`, empty `operations`, bad
YAML, or an invalid `--set` value → **exit 2**. Multiple operations accumulate
on the same case. Partial-apply failures → exit 1.

```sh
kensa bulk-apply ops/triage.yaml --dry-run
kensa bulk-apply ops/triage.yaml --yes
```

### 2.4 Quality / maintenance

#### `lint`

Run the built-in `kensa-core` rule registry over all cases. Records: `id`,
`path`, `rule`, `severity`, `message`. **Exit 3 if any `error`-severity
violation; 0 otherwise** (warnings alone are exit 0). Malformed cases are
skipped with a stderr warning.

```sh
kensa lint
kensa lint --format json | jq '.[] | select(.severity=="error")'
```

#### `duplicates [--threshold <0.0-1.0>] [--mark] [--dry-run] [--yes]`

Find near-duplicate cases by title similarity (Jaro-Winkler).

- `--threshold` (default `0.85`): similarity cutoff.
- `--mark`: additionally add a `dup-candidate` tag to flagged cases (needs
  `--yes` to apply; dry-run by default).
- `--dry-run` / `--yes`.

Pair records: `id_a`, `id_b`, `score`, `title_a`, `title_b`. With `--mark`, also
emits per-case tag-plan records. Exit 0.

```sh
kensa duplicates
kensa duplicates --threshold 0.90
kensa duplicates --mark --yes
```

#### `coverage (--by-tag | --by-source | --by-suite) [--uncovered]`

Count cases grouped by tag, `source_id` provider prefix, or suite. **Exactly one
grouping flag is required** (clap-enforced; exit 2). Records: `key`, `count`,
sorted by count desc then key asc. Empty buckets key as `(none)`/`(root)`.

- `--uncovered`: with `--by-suite`, list empty suites (zero direct cases). With
  `--by-tag`/`--by-source`, exit 2 with a redirect to `kensa gaps --against
  source`.

`--format ids`/`paths` are rejected (records have no id/path field) → exit 2.

```sh
kensa coverage --by-tag
kensa coverage --by-suite --uncovered
```

#### `gaps [--against <shared-steps|source>]`

Traceability gap report.

- `--against shared-steps` (default): shared-step files in `.tms/shared-steps/`
  whose id is not mentioned by any case body. Records: `shared_step`, `path`,
  `status`.
- `--against source`: cases whose `source_id` is absent/empty/whitespace.
  Records: `id`, `title`, `suite`, `path`, `status`.
- Any other value → exit 2.

```sh
kensa gaps --against shared-steps
kensa gaps --against source --format ids
```

#### `doctor`

Integrity report — walks files directly so one bad file is a **reported problem**
rather than an abort. Checks: duplicate ids, malformed/unreadable case files,
stray `.md` files outside `suites/` that look like cases, and broken
`@shared:ID` references. Records: `kind`, `id`, `path`, `message`. **Exit 3 if
any problem; 0 if clean.**

```sh
kensa doctor
kensa doctor --format json
```

#### `sync [--check]`

Recount `config.yaml` id counters (`next_id`, and siblings
`next_shared_step_id` / `next_plan_id` when their key exists or their artifact
dir is non-empty) after external case writes. `reconciled = max(stored,
max_on_disk + 1)`.

- default: atomically write `config.yaml` if any counter changed. Emits per-
  counter records (`counter`, `old`, `new`, `changed`, `cases_scanned`).
- `--check`: never write; **exit 3 if drift detected**, 0 if already in sync.

Missing/malformed `config.yaml` (`project` not a mapping, `next_id` not a
non-negative integer) → exit 2. A directory read error aborts before any write.

```sh
kensa sync
kensa sync --check
```

#### `schema migrate`

Version-stamp schema migration. Compares `.tms/schema.yaml`'s version to
`CURRENT_SCHEMA_VERSION` and applies registered migrations (registry is
currently empty, so this is usually "already up to date"). A schema newer than
the CLI supports → **exit 3** (read-only refusal). No `schema.yaml` → exit 0.
(See also `schema apply/preview/show` under [Schema / Adapt](#210-schema--adapt).)

```sh
kensa schema migrate
```

### 2.5 Trash

Flat `.tms/trash/` directory of `.md` files; on a name collision the basename
gets a `-<epoch_ms>` suffix.

#### `trash list`

Enumerate trashed cases. Records: `id` (frontmatter id or stem), `name`, `path`,
`trashed_at` (epoch-ms parsed from the collision suffix, else null).

#### `trash restore <ID>`

Restore a trashed file back to `suites/` **root** (the original suite is not
recorded in flat trash). Matches by frontmatter id, then filename stem. Refuses
to overwrite a live case (exit 1). Applies immediately (no `--yes`). Records:
`id`, `restored_to`.

#### `trash purge [--older-than <DURATION>] [--dry-run] [--yes]`

Permanently delete trashed files — the **only hard-delete** in the CLI, and only
ever inside `.tms/trash/`. Dry-run by default; `--yes` deletes.

- `--older-than <DURATION>`: only files older than the duration (e.g. `30d`,
  `12w`, `6m`); omit = all. An invalid duration → exit 2.

```sh
kensa trash list
kensa trash restore AUTH-001
kensa trash purge --older-than 30d --yes
```

### 2.6 Agent integration

#### `context show <ID>`

Editing context for one case: frontmatter summary + up to 5 related cases
(scored by shared tags = 3 each, same `source_id` = 5, same suite = 1) + a
snippet (first ~500 chars) of `.tms/memory/conventions.md` if present.
`json`/`jsonl` emit a structured object; other formats print a readable block.
Missing id → exit 1.

#### `context bundle --filter <EXPR> [--max-tokens <N>]`

Pack matching cases under a soft token budget for agent context.

- `--filter <EXPR>` (required): Kensa DSL.
- `--max-tokens <N>` (default `8000`): soft budget (chars/4 heuristic).

Cases are ranked by priority (high=3/medium=2/low=1) desc, step count desc, id
asc. Those within budget get full serialized bodies (`mode: full`); the rest are
frontmatter-only (`mode: frontmatter`). **All matched cases always appear.**
`json` emits an array with `id`/`mode`/`title`/`body`; `jsonl` one per line;
table emits `id`/`mode`/`title`.

```sh
kensa context show AUTH-001 --format json
kensa context bundle --filter "suite=payments" --max-tokens 4000 --format json
```

#### `explain <ID>`

Human/agent-readable case explanation: title/priority/status/tags,
preconditions, steps summary ("what it covers"), related cases, and likely
failure points (steps with **no** expected results). `json`/`jsonl` emit a
structured object; other formats print prose. Missing id → exit 1.

#### `shared-step list | usage <NAME> | orphan`

Read-only shared-step reports (references matched by exact `@shared:<stem>`
tokens in step text).

- `list`: every shared step + its `use_count` (`id`, `title`, `use_count`,
  `path`).
- `usage <NAME>`: cases referencing the step (`case_id`, `title`, `path`). The
  `.md` suffix is optional; unknown step → exit 1.
- `orphan`: shared steps with zero references (`id`, `title`, `path`).

```sh
kensa shared-step list
kensa shared-step usage LOGIN
kensa shared-step orphan
```

### 2.7 Git-temporal

These shell out to the system `git` binary and degrade gracefully: no git / not
a repo / a bad ref all exit 2 with a clear note.

#### `changed --since <GIT-REF>`

Cases changed since a git ref (`git diff --name-only <ref> -- suites/`), mapped
back to cases by relative path. Records: `id`, `path`. A bad ref → exit 2.

```sh
kensa changed --since main
kensa changed --since HEAD~5 --format ids
```

#### `stale [--days <N>]`

Cases not modified in the last N days (default `90`). "Last modified" is the last
git commit time of the file when in a repo (`git log -1 --format=%ct`), else the
filesystem mtime; a tracked-but-uncommitted file falls back to mtime. The stderr
note states which source was used. Records: `id`, `path`, `age_days` (oldest
first).

```sh
kensa stale
kensa stale --days 180 --format ids
```

#### `blame <ID>` / `log <ID>`

Resolve `<ID>` to its file (same lookup as `show`) and stream `git blame` /
`git log` output verbatim to stdout. Missing id → exit 1; no git / not a repo →
exit 2 with a "use `kensa show <id>`" hint.

```sh
kensa blame AUTH-001
kensa log AUTH-001
```

### 2.8 Blueprint

Blueprint automation graphs stored as `.tms/blueprints/BP-NNN.json` (schema v1,
byte-parity with the TS store). Blueprint ids must match `^BP-\d+$` (validated
before any path join).

#### `blueprint new <NAME>`

Allocate the next `BP-NNN` (max-id scan of existing files, config-neutral) and
scaffold a canonical Input→Output graph. Writes the file atomically (retry on
id collision). Prints the allocated id to stdout.

```sh
kensa blueprint new "Nightly regression"   # -> BP-004
```

#### `blueprint list`

List blueprints. Records: `id`, `name`, `nodeCount`. Files whose embedded id
mismatches the filename stem are skipped with a stderr warning. Empty project
prints `[]` in JSON.

#### `blueprint show <ID> [--json]`

Show a blueprint. Default: summary object (`id`, `name`, `description?`,
`nodeCount`, `edgeCount`, `createdAt`, `updatedAt`). `--json`: the full canonical
JSON graph (byte-stable re-serialization). Not found → exit 1;
`ID_FILENAME_MISMATCH` → exit 3.

#### `blueprint validate <ID>`

Run the static graph validator. **Exit 3 if any error** (errors printed to
stderr with node/edge/pin loci), 0 if clean. `ID_FILENAME_MISMATCH` → exit 3.

#### `blueprint run <ID> [--input KEY=VALUE]... [--input-file PATH] [--allow-scripts] [--format json]`

Execute a blueprint headlessly and persist a `kind:"blueprint"` run record under
`.tms/runs/BPR-NNN.json`.

- `--input KEY=VALUE` (repeatable): seed a run input. The value is parsed as JSON
  when possible, else a string. **Highest precedence.**
- `--input-file PATH`: read inputs from a JSON object file.
- `--allow-scripts`: consent gate — permit shell `script` nodes to execute
  (default off).
- `--format json`: emit the `RunFinished` projection; otherwise emit the run
  outputs object and a stderr status line.

Input precedence: declared defaults < `--input-file` < `--input` flags.
**Exit 0 if the run succeeded, 1 if it failed.** Not found → exit 1.

```sh
kensa blueprint run BP-001 --input env=staging --allow-scripts --format json
```

#### `blueprint signal <RUN_ID> <NODE_ID> <PHASE> --token <T>` (hidden, internal)

Not for direct use — an agent child process writes an agent-node lifecycle signal
(`start`/`done`/`fail`) during a run. Dispatched project-independently; token-
guarded. Hidden from `--help`.

### 2.9 Results (automation ingestion)

Parses test-result reports into the normalized run model, matches tests to
cases, and stores/pushes.

#### `results ingest <PATH> [--report-format <FORMAT>] [--match <STRATEGY>]`

Parse a report, run the case↔test matcher, store the normalized run under
`.tms/automation-runs/<id>.json`, and print a summary.

- `<PATH>` (positional, required).
- `--report-format <FORMAT>` (default `auto`): one of `auto`, `junit`, `allure`,
  `ctrf`, `playwright`, `gotest`, `trx`, `nunit`, `xunit`, `mochawesome`,
  `newman`, `cucumber` (11 explicit formats).
- `--match <STRATEGY>`: `by-tag` or `by-name`; omit = the full match chain
  (automation-map > id-tagged > fuzzy).

`auto` detection precedence: NDJSON (`Action` key) → gotest; XML root
(`<TestRun>`→trx, `<test-run>`→nunit, `<assemblies>`→xunit,
`<testsuites>`/`<testsuite>`→junit); JSON signature (array→cucumber,
`reportFormat:"CTRF"`→ctrf, config+stats+suites→playwright, `run.executions`→
newman, stats+results-array→mochawesome, `status` key→allure). Ambiguous → exit 2
(no blind extension fallback). Summary (`X matched / Y orphaned`) → stderr; the
written path (table) or the normalized run JSON (`--format json`) → stdout.

```sh
kensa results ingest report.xml
kensa results ingest results.json --report-format playwright
kensa results ingest out.ndjson --match by-name
```

#### `results push <PATH> [--token <TOKEN>] [--project <ID>] [--report-format <FORMAT>]`

Parse a local report and post it through an injectable transport seam. **Project-
independent** (no `.tms/` needed). Push-only (no local write).

- `--token`: defaults to `KENSA_TOKEN`. **No token → stderr notice + exit 0** (CI
  must not hard-fail before a token is configured).
- `--project <ID>`: attach a project identifier to the run.
- `--report-format`: `auto`/`junit`/`allure` only in `push` (the other 9 formats
  return "use `kensa results ingest`" → exit 2).

The current transport is a **stub** (no real network call — it logs the payload
size to stderr). This is the documented future egress boundary.

```sh
KENSA_TOKEN=… kensa results push report.xml --project my-app
```

### 2.10 Schema / Adapt

#### `schema apply --from <PATH|->`

Apply a JSON schema proposal (`{version, fields:[…]}`, or bare-array shape).
Validates + builds the canonical schema, **backs up** any existing
`.tms/schema.yaml` to `schema.yaml.bak-<ms>`, then atomically writes the new
schema via the parity-canonical serializer. `-` reads the proposal from stdin.
Invalid JSON / unknown type / duplicate keys → exit 3; I/O error → exit 1.

#### `schema preview --from <PATH> --sample <CASE.md>`

Render a sample case under a **draft** schema proposal — **writes nothing**.
Prints each draft field with the sample's value (system fields from top-level
frontmatter; others from the `custom:` map; absent → `(no value)`). A "test
render → ok/not-ok" confirmation step. Invalid proposal → exit 3.

#### `schema show`

Print the current project schema. Default (`table`): a fields table (key, name,
type, required, options, order, system). `--format json`: the proposal JSON
shape that round-trips back into `schema apply --from -`. No `schema.yaml` →
exit 0 with a note.

```sh
kensa schema show --format json > proposal.json
kensa schema preview --from proposal.json --sample suites/auth/AUTH-1.md
cat proposal.json | kensa schema apply --from -
```

#### `adapt ready [--message <TEXT>]`

Signal the Kensa GUI that an AI schema-adaptation routine has finished. Writes a
sentinel `.tms/.cache/adapt-ready.json` (`{ts, schema:true, message?}`) that the
GUI's fs-watcher picks up. `--message` stores an optional display message. I/O
error → exit 1.

```sh
kensa adapt ready --message "schema adapted from TestRail export"
```

### 2.11 HTTP tool

CRUD + execution over HTTP collections. Requests are stored as `.http` text
files under `.tms/tools/http/` (legacy `.json` still read/written);
environments are JSON under `.tms/tools/http/env/`. Collection/env names must be
bare file stems (no separators/`..`/absolute — exit 2 otherwise).

#### `http list`

List all collections and their requests (records: `collection`, `name`,
`method`, `url`). Malformed collections are skipped with a stderr warning.

#### `http show <COLLECTION> [--request <NAME>]`

Print a request (all requests if `--request` is omitted) as an object with
`collection`, `name`, `method`, `url`, `query`, `headers`, `body_type`,
`body_text`, `captures`, `vars`. Unknown request → exit 1.

#### `http new <COLLECTION> [--request <NAME>]`

Create a new collection (`<name>.http`) with a first request
(default name `"New request"`). Already exists → exit 1.

#### `http add <COLLECTION> --request <NAME>`

Append an empty request to an existing collection. Duplicate name → exit 1.

#### `http edit <COLLECTION> --request <NAME> [flags]`

Update fields on a request (non-interactive, all upserts).

- `--set FIELD=VALUE` (repeatable): `name`, `method` (upper-cased), `url`,
  `body`, `body_type`|`body-type` (`json`/`xml`/`text`; default `json`). Unknown
  field → exit 2.
- `--header NAME=VALUE`, `--query NAME=VALUE`, `--var NAME=VALUE`,
  `--capture NAME=PATH` (each repeatable, upsert-by-name).

```sh
kensa http edit api --request Login --set method=post --set url='{{base}}/login' \
  --header Content-Type=application/json --capture token=$.token
```

#### `http run <COLLECTION> [--request <NAME>] [--env <ENV>]`

Execute a request (or all requests in order) via a blocking HTTP client (30s
timeout, ≤10 redirects, no invalid certs). `{{var}}` templating resolves in
precedence: request-local vars > captured vars (threaded across the run) >
collection `@file` vars > env file. An **undefined `{{var}}`** anywhere (URL,
query, header, body) is a hard error (exit 2) — never sent literally. `json`/
`jsonl` emit `{request, status, statusText, headers, body}`; other formats print
a raw HTTP response block.

```sh
kensa http run api --request Login --env staging
kensa http run api --format json
```

#### `http env list | set <NAME> <KEY> <VALUE> | get <NAME> <KEY>`

Manage `env/*.json` files. `set` creates the file if absent; `get` prints the
value (missing key → exit 1).

```sh
kensa http env set staging base https://staging.example.com
kensa http env get staging base
kensa http env list
```

### 2.12 Browser tool (CDP)

Drive a GUI-launched Chrome over the DevTools Protocol. **Project-independent.**
Each call connects, acts, disconnects (page/cookies/DOM persist across calls;
in-page JS variables do not). Sync, tokio-free.

**Endpoint resolution** (top-level `--cdp-url` overrides all):
`--cdp-url` → `KENSA_CDP_URL` env → `endpoint.json` in the OS app-cache dir →
exit 2 with a hint. Every channel is validated as a **loopback-only `ws://`**
URL (127.0.0.1 / localhost / [::1]; userinfo and non-ws schemes rejected).

```
kensa browser [--cdp-url <ws-url>] <subcommand> [args]
```

Subcommands:

| Subcommand | Args / flags | Notes |
|------------|--------------|-------|
| `open <URL>` (alias `navigate`) | `--wait load\|domcontentloaded\|networkidle` (default `load`), `--timeout <MS>` (30000), `--capture-console`, `--capture-network` | Navigate. |
| `reload` | same wait/timeout/capture flags | Reload current page. |
| `back` / `forward` | `--timeout <MS>` (30000) | History nav. |
| `url` / `title` | — | Current URL / title. |
| `click <SELECTOR>` | `--nth <N>` (0), `--timeout <MS>` (30000), `--capture-console`, `--capture-network` | Click a CSS match. |
| `type <SELECTOR> <TEXT>` | `--clear`, `--delay <MS>` (0), `--timeout <MS>` (30000) | Type into an element. |
| `fill <SELECTOR> <VALUE>` | `--timeout <MS>` (30000) | Set value (fires input/change). |
| `press <KEY>` | `--timeout <MS>` (30000) | Dispatch a key press. |
| `screenshot` | `--out <PATH>` (**required**; `-` = base64 on stdout), `--selector <SEL>`, `--full-page` | Capture. Missing `--out` → exit 2 before connecting. |
| `dom` | `--selector <SEL>` (omit = document element) | Element outerHTML. |
| `html` | — | Full page source. |
| `query <SELECTOR>` | — | All matching elements (list). |
| `text <SELECTOR>` | `--timeout <MS>` (30000) | Inner text. |
| `attr <SELECTOR> <NAME>` | `--timeout <MS>` (30000) | Attribute value. |
| `eval <JS>` | `--arg <JSON>` (repeatable → `$args`), `--await` | Evaluate JS. |
| `wait` | `--selector <SEL>` (+ `--state visible\|hidden\|attached`), `--text <STR>`, `--load networkidle\|domcontentloaded`, `--timeout <MS>` (30000) | Wait for a condition. |
| `status` | — | Probe the endpoint (`endpoint`, `reachable`, `browserVersion`, `protocolVersion`, `targetCount`). |
| `targets` | — | List open targets (`targetId`, `type`, `title`, `url`). |

A connection failure exits 2 (config-level); a runtime failure against a
reachable browser (selector not found, timeout, eval throw) exits 1. Boolean
result fields (`clicked`/`filled`/`pressed`/`waited`) serialize as real JSON
booleans.

```sh
kensa browser open https://example.com --wait networkidle
kensa browser click "button.submit"
kensa browser screenshot --out shot.png --full-page
kensa browser eval "document.title" --format json
```

### 2.13 Mobile tool (Android / iOS)

Observe→act driver for Android devices via `adb` (everywhere) and iOS Simulators
via a delegated `sim-use` binary on macOS. **Project-independent** (machine-
scoped). Sync, tokio-free; every spawn goes through `kensa_core::mobile`
primitives.

`--device <ID>` is a **global** flag on this family (accepted before or after the
subcommand). Routing: a UUID-shaped id (`8-4-4-4-12` hex, case-insensitive) →
iOS; anything matching the Android serial charset `[A-Za-z0-9._:-]+` → Android;
other charset → exit 2. When `--device` is omitted, the target auto-selects if
exactly one candidate device is reachable (0 → exit 2 "no devices"; many →
exit 2 listing candidates).

**iOS gate:** any iOS-routed verb on a non-macOS host → exit 2 ("requires
macOS"); on macOS with `sim-use` absent → a distinct "sim-use binary not found"
(exit 2). There is deliberately no env override.

**JSON error envelope:** in `json`/`jsonl` mode a failing verb writes
`{"error":…, "hint"?:…}` to stdout (in addition to the stderr message + non-zero
exit).

| Subcommand | Args | Behavior |
|------------|------|----------|
| `devices` | — | List Android devices (`adb devices -l`) + iOS Simulators on macOS. Records: `id`, `platform`, `state`, `model`. **Exit 2 only when adb is unresolved AND the list is still empty**; else 0 (empty list with adb present is a valid result). |
| `ui` | — | Capture a compact banded outline of the current screen (`~0.5–2s`), render it (text or JSON envelope), and persist the per-device alias cache. |
| `tap` | `[@N \| #resource-id]` positional, or `--label <TEXT>`, or `-x <X> -y <Y>` | **Exactly one** selector source. `@N`/`#id`/`--label` resolve against the last `ui` cache; `-x/-y` are raw device coords (bypass cache). Ambiguous/unknown selectors → exit 2 with hints. |
| `swipe` | `--from X,Y --to X,Y [--duration-ms <MS>]` | Straight-line swipe. |
| `type <TEXT>` | — | Types printable ASCII (0x20–0x7E) only on Android; spaces → `%s`; newlines/non-ASCII → exit 2 (Unicode is fine on iOS delegate). |
| `button <NAME>` | — | `back`/`home`/`enter`/`recents` (Android keyevents 4/3/66/187); on iOS only `home` forwards. Unknown → exit 2. |
| `screenshot` | `--out <PATH>` (**required**; `-` = base64 on stdout) | PNG via `adb exec-out screencap -p` (binary-safe). Missing `--out` → exit 2 before device resolution. |

The alias cache lives at `<app-cache>/kensa-mobile/ui-cache-<sanitized-device>.json`
and is overwritten on each `ui`. A snapshot older than 5 minutes prints a stale-
warning (never blocks the tap).

```sh
kensa mobile devices
kensa mobile --device emulator-5554 ui
kensa mobile ui --device emulator-5554 --format json
kensa mobile tap @3
kensa mobile tap --label "Sign in"
kensa mobile swipe --from 500,1500 --to 500,300 --duration-ms 300
kensa mobile type "hello world"
kensa mobile button back
kensa mobile screenshot --out screen.png
```

### 2.14 Import / Export

#### `export --profile <PATH> [--filter <EXPR>] [--out <PATH>]`

Profile-driven deterministic export.

- `--profile <PATH>` (required): export profile JSON
  (`{format, fieldMap?, static?}`). **Supported formats: `universal-csv`,
  `testrail-csv`** — any other (`qase-json`, `allure-json`, …) → exit 3 ("use
  the GUI export wizard").
- `--filter <EXPR>`: optional Kensa DSL to select cases.
- `--out <PATH>`: output path; `-` (default) writes to stdout.

`fieldMap` maps foreign column → kensa key (builtins id/title/priority/status/
tags/suite/source_id, or a custom field); `static` maps foreign column →
literal (wins over fieldMap). Column order is deterministic (fieldMap keys, then
static-only keys). Invalid/malformed profile JSON → exit 3.

```sh
kensa export --profile .tms/tools/export-profiles/testrail.json --filter "tag=smoke" --out out.csv
```

#### `import --from <PATH> --dry-run [--sample <N>] [--profile <PATH>]`

Tolerant import **mapping report only** — this slice supports `--dry-run` only;
omitting it → exit 2 ("full import is not yet supported; use `--dry-run`").

- `--from <PATH>` (required): the foreign CSV file.
- `--dry-run` (required): report column mapping quality without writing.
- `--sample <N>` (default `40`): rows to count for the report.
- `--profile <PATH>`: apply the profile's `fieldMap` before checking known keys.

Columns are classified against built-in keys (id/title/priority/status/tags/
source_id/suite/preconditions) + schema custom keys. Table output:
`N mapped clean, M with leftovers`; JSON: `{sample_rows, columns_total,
mapped_clean, leftovers, leftover_columns}`. Never fails on unknown columns
(exit 0); bad `--profile` JSON → exit 2.

```sh
kensa import --from testrail-export.csv --dry-run --format json
```

### 2.15 Completions / Man

Both are **project-independent** (run in any directory).

#### `completions <SHELL>`

Generate a shell completion script to stdout. `<SHELL>` ∈ `bash`, `zsh`, `fish`,
`powershell`.

```sh
kensa completions bash > ~/.local/share/bash-completion/completions/kensa
kensa completions powershell | Out-File $PROFILE -Append
```

#### `man`

Emit a roff man page for the top-level `kensa` command to stdout.

```sh
kensa man > /usr/local/share/man/man1/kensa.1
```

---

## 3. Filter DSL

Used by `filter`, `bulk update/add-tag/remove-tag/move/delete`,
`bulk-apply` op filters, `context bundle`, and `export --filter`. Defined in
`crates/kensa-core/src/filter.rs`. The grammar is a stability contract.

### Grammar

```
expr        := orExpr
orExpr      := andExpr ( "or"  andExpr )*
andExpr     := notExpr ( "and" notExpr )*
notExpr     := "not" notExpr | atom
atom        := "(" expr ")" | comparison
comparison  := field op value
op          := "=" | "!=" | "~" | "!~" | ">" | "<" | ">=" | "<=" | "in" | "not in"
value       := string | bareword | number | duration | list | /regex/[i]
```

Precedence (lowest→highest): `or` < `and` < `not` < comparison. `and`/`or`/
`not`/`in` are case-insensitive keywords. Errors are reported with a caret
pointing at the byte offset and a "did you mean" hint for unknown fields (exit 2).

### Operators

| Op | Meaning |
|----|---------|
| `=` | Exact equality (case-sensitive). |
| `!=` | Not equal (also true when the field is missing). |
| `~` | Substring match, or `/regex/` match. |
| `!~` | Negated `~`. |
| `>` `<` `>=` `<=` | Numeric (`steps`) or duration (`modified`/`created`) comparison. |
| `in` / `not in` | Membership in a list literal `[a, b, c]`. |

### Fields

`BUILTIN_FIELDS` = **`id`, `title`, `tag`, `priority`, `status`, `source`,
`source_id`, `suite`, `steps`, `modified`, `created`** — plus any schema custom
field key, and any explicit `custom.<key>` reference.

Field semantics:

- **String fields** (`id`, `title`, `priority`, `status`, `source`/`source_id`,
  `suite`, custom): `=`, `!=`, `~`, `!~`, `in`, `not in`. Ordering ops → error.
- **`tag`** (membership over the tag list): `=`/`!=` test membership, `~`/`!~`
  substring/regex over tags, `in`/`not in` list intersection.
- **`steps`** (numeric = step count): `=`, `!=`, `>`, `<`, `>=`, `<=`, `in`.
  `~`/`!~` → error.
- **`modified`, `created`** (date/age): require an **ordering op with a duration
  value** (e.g. `modified > 30d`). `modified` uses the file mtime; `created`
  uses `created_at` frontmatter (else no match). `=`/`!=`/`~`/`in` → error.

### Value literals

- **Strings/barewords**: unquoted words; double-quoted strings support `\"` /
  `\\` escapes; single-quoted are literal.
- **Numbers**: parsed for numeric fields.
- **Durations**: `<N>h` (hours), `<N>d` (days), `<N>w` (weeks), `<N>m` (30-day
  months), `<N>y` (365-day years).
- **Lists**: `[a, b, c]` (empty `[]` is an error).
- **Regex**: `/pattern/` with optional `i` (case-insensitive) flag.

### Examples

```sh
kensa filter "tag=auth and priority=high"
kensa filter "status in [draft, active]"
kensa filter "title ~ /login/i"
kensa filter "modified > 30d"                 # older than 30 days
kensa filter "created < 7d"                   # created within the last 7 days
kensa filter "steps >= 5"
kensa filter "not tag=deprecated"
kensa filter "suite = auth/flows and status != deprecated"
kensa filter "custom.owner = alice"
```

---

## 4. Common workflows

### Create a case, then verify

```sh
kensa new --suite auth/flows --title "Login with OTP" --priority high --tag smoke
kensa index          # refresh INDEX.md / _index.md
kensa validate       # confirm it passes the schema
```

### Scope changes to the right cases (bulk vs per-id)

```sh
# Preview, then apply, in one write pass (preferred for large sets):
kensa bulk update --filter "tag=auth and status=draft" --set status=active --dry-run
kensa bulk update --filter "tag=auth and status=draft" --set status=active --yes

# Or pipe ids into per-case updates:
kensa filter "tag=auth and status=draft" --format ids \
  | xargs -I{} kensa update {} --set status=active
```

### Bulk-tag / rename a tag safely

```sh
kensa bulk add-tag regression --filter "suite=auth" --yes
kensa rename-tag smoke regression --dry-run
kensa rename-tag smoke regression --yes
kensa validate
```

### Ingest automation results and match to cases

```sh
# Auto-detect format, match (map > id-tag > fuzzy), store under .tms/automation-runs/
kensa results ingest ./ci/junit.xml
kensa results ingest ./ci/playwright.json --report-format playwright --format json
# stderr shows "N matched / M orphaned"
```

### Drive a mobile device (observe → act)

```sh
kensa mobile devices                                   # find a target
kensa mobile --device emulator-5554 ui                 # snapshot + alias cache
kensa mobile tap --label "Sign in"                     # resolve against the snapshot
kensa mobile type "user@example.com"
kensa mobile button enter
kensa mobile screenshot --out after-login.png
```

### Author and run a blueprint

```sh
kensa blueprint new "Smoke pipeline"                   # -> BP-005
kensa blueprint validate BP-005                        # exit 3 if graph errors
kensa blueprint run BP-005 --input env=staging --format json
```

### Prepare agent context before editing bodies

```sh
kensa describe | jq '.commands[].name'                 # self-orient
kensa context show AUTH-001 --format json
kensa context bundle --filter "suite=auth" --max-tokens 6000 --format json
```

### Health sweep

```sh
kensa doctor
kensa lint --format json | jq '.[] | select(.severity=="error")'
kensa duplicates --threshold 0.9 --format json
kensa stale --days 90 --format ids
kensa gaps --against source
kensa sync --check                                     # exit 3 if the id counter drifted
```

---

## 5. Notes for tooling authors

- **Machine-readable output**: pass `--format json` (or `jsonl` for streaming).
  `describe --format json` is a self-describing manifest of every subcommand,
  flag, default, and enum value — walked from clap at runtime, so it never drifts
  from the real surface. Use it to discover the CLI programmatically.
- **stdout vs stderr**: never parse stderr for data. All records go to stdout;
  progress/counts/warnings go to stderr. Redirect stderr to `/dev/null` for clean
  captures.
- **`ids` / `paths` formats** are the pipe-friendly projections — one `id` or
  `path` per line. `coverage` has no id/path field and rejects them (exit 2).
- **Exit codes are load-bearing**: gate scripts on them. Notably `validate`→3,
  `lint`(errors)→3, `doctor`→3, `sync --check`(drift)→3, schema mismatch→4,
  `blueprint validate`→3, `blueprint run`(failed)→1, `results push`(no token)→0.
- **Dry-run by default** for every corpus write (`bulk *`, `rename-tag`,
  `bulk-apply`, `duplicates --mark`, `trash purge`) — you must pass `--yes` to
  apply, and `--dry-run` always wins. `update` and `trash restore` (single-case)
  apply immediately.
- **Idempotency / determinism**: `index` and `sync` are idempotent and byte-
  deterministic (re-running produces no churn). Schema/blueprint/case writes are
  atomic (temp + rename) and byte-parity with the TS IDE format.
- **Reindex after writes**: case writes do not update `INDEX.md`/`_index.md`.
  Commands print a "run `kensa index`" hint; run it when the indexes matter.
- **Path convention is POSIX**: pass and expect forward-slash relative paths.
  Suite arguments reject backslashes, absolute/drive-prefixed paths, and
  `.`/`..`.
- **Project independence**: `completions`, `man`, `browser`, `mobile`,
  `blueprint signal`, and `results push` run without a `.tms/` project. Everything
  else resolves a project via `--dir` / `KENSA_PROJECT_ROOT` / cwd-walk.
- **Env for tooling**: set `KENSA_PROJECT_ROOT` to avoid cwd ambiguity;
  `KENSA_CDP_URL` for the browser driver; `KENSA_TOKEN` for `results push`;
  `ANDROID_HOME`/`ANDROID_HOME/platform-tools` on `PATH` for `mobile`. Set
  `NO_COLOR` to strip ANSI from table output.
- **Mobile specifics**: outputs a stdout `{"error","hint?"}` envelope in JSON
  mode; the `@N` aliases come from the last `kensa mobile ui` and are invalidated
  by any screen change — re-run `ui` after rotation/navigation. The alias cache
  is machine-scoped (`<app-cache>/kensa-mobile/`), not in the project.
- **Browser specifics**: endpoints are validated loopback-only; in-page JS state
  does not persist across separate `eval` calls (each call reconnects).
- **Parity guarantee**: the Rust core round-trips the `.tms/` format byte-for-
  byte with the TypeScript IDE (goldens at `tests/fixtures/tms-parity/`). The CLI
  never invents a serialization — treat its writes as interchangeable with the
  GUI's.

---

## Discrepancies vs CLAUDE.md / the skill

Where prior docs and the code disagree, this reference follows the **code**.

1. **Command count / blueprint verbs.** CLAUDE.md says "~38 commands" and lists
   blueprint as **Phase-0** `new/list/show/validate`. The code's blueprint family
   also ships **`run`** (headless execution that persists a `BPR-NNN` run record
   under `.tms/runs/`) and a hidden internal **`signal`**. The top-level command
   count is exactly **38** families.

2. **Filter field names.** The `kensa-cli` skill lists the date field as `mtime`
   and the tag field as `tags`. The actual `BUILTIN_FIELDS` are `id`, `title`,
   **`tag`** (singular, membership), `priority`, `status`, `source`, `source_id`,
   `suite`, **`steps`** (numeric), **`modified`** (not `mtime`), and `created`.
   Use `modified`/`created` with duration ordering ops, and `tag` for membership.

3. **`gaps --against`.** The skill says only `--against shared-steps` is
   supported. The code also supports **`--against source`** (untraced cases with
   no `source_id`).

4. **`coverage`.** The skill omits **`--uncovered`** (list empty suites with
   `--by-suite`) and the `--by-source` grouping-prefix behavior; both exist in
   the code.

5. **`schema` subcommands.** CLAUDE.md highlights `schema apply/preview/show`.
   The code additionally has **`schema migrate`** (4 subcommands total).

6. **`sync`.** Not called out in CLAUDE.md's command list but present as a
   first-class command (`recount next_id`, with `--check`).

7. **`export` formats.** CLAUDE.md's export wizard supports TestRail/Allure/Qase/
   Universal, but the **CLI `export`** only implements **`universal-csv`** and
   **`testrail-csv`**; other formats exit 3 pointing to the GUI wizard.

8. **`results push` formats.** `results ingest` supports 11 formats, but
   **`results push`** currently supports only `auto`/`junit`/`allure` (the other
   9 return "use `kensa results ingest`", exit 2), and its transport is a
   no-network **stub**.

9. **`import`.** Only the **`--dry-run` mapping report** is implemented; a real
   import exits 2.

10. **Binary name.** The Cargo `[[bin]]` is `kensa-cli`; the clap command name
    and the distributed sidecar are `kensa`.
