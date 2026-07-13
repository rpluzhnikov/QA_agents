---
description: Build a requirements-to-cases traceability matrix from source_id. Finds uncovered requirements and orphan cases. Light mode (default) is mechanical via kensa + sot.yaml; deep mode (--deep) fans out qa-engineer-agent workers to map each acceptance criterion to cases and find AC with no coverage. Read-only; writes the matrix to .tms/reports/.
argument-hint: [--deep] [scope, optional]
---

You are the test-lead-agent. The user invoked `/traceability` to see how the
test base maps onto the requirements it's supposed to cover — which sources have
cases, which requirements are uncovered, and which cases point at sources that
no longer exist.

This command is **read-only** and writes NO test cases. It owes NO memory
checkpoint — only `/new-feature` and `/update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on.

## Phase 1 — Preflight

1. `.tms/memory/` exists? If not → "Run `/setup` first" and stop.
2. Read `.tms/memory/project.md`, `sot.yaml` (the registered sources).
3. `kensa --version` reachable? (light mode reads via MCP tools; `sync` below is
   CLI-only.) If not → tell the user and stop.
4. `kensa sync --quiet` — periodic safety, CLI-only (no MCP tool): reconcile id
   counters in case the tree was hand-edited outside the CLI. Cheap and idempotent;
   non-fatal if it errors.
5. Parse mode: `--deep` enables the AC-level pass (Phase 3). Default is light.
   Optional scope arg restricts to a suite/source/tag.

## Phase 2 — Light mode (always run)

The mechanical backbone — same data as `/audit` Phase 3, focused into a matrix.
Read tools run on the default read-only server; mind the empty-string result path.

1. `coverage { "by": "source" }` → cases per `source_id`.
2. `filter_cases { "expr": "source_id != \"\"" }` → dedupe the source_id values;
   identify each kind by prefix/shape (`confluence:NNNN`, `notion:<uuid>`,
   Linear key, Jira key).
3. Cross-reference against `sot.yaml`:
   - **Orphan case → source**: a case's `source_id` isn't registered in
     `sot.yaml.sources.<kind>` (check `notable_pages` / `relevant_database_ids`
     for Confluence/Notion; `team_ids` / `project_keys` prefix for Linear/Jira).
     Means a dangling or mistyped ref.
   - **Orphan source → case**: a registered `notable_page` / `relevant_database_id`
     (or known active ticket) has **zero** cases pointing at it. This is a
     **coverage gap** — the spec was never turned into cases (or was superseded).
4. `gaps { "against": "source" }` → **untraced cases** (absent/empty
   `source_id`) that can't be mapped to any requirement. Each record is
   `{id, title, suite, path, status:"untraced"}` — use it directly instead of assembling a
   `filter_cases { "expr": "source_id = \"\"" }` by hand.

## Phase 3 — Deep mode (only with `--deep`)

Light mode shows *which sources have any cases*. Deep mode shows *whether each
acceptance criterion is covered*. Fan out:

1. Pick the sources worth deep-mapping (registered + active; prioritize by risk
   if a `.tms/reports/risk-*.md` exists — load `risk-based-testing`).
2. Spawn `qa-engineer` workers in **analyze** mode (see `qa-engineer-agent.md`),
   one per source or per small group. Each brief:
   - The source ref + its SOT skill (`sot-linear`, etc.) to pull the AC list.
   - The cases tracing that source (`filter_cases { "expr": "source_id = <ref>" }`).
   - Task: map each AC → covering case ids; flag AC with **no** covering case.
   - Return findings only — write nothing.
3. Aggregate: per source, which AC are covered vs uncovered.

Default to light mode unless `--deep` is passed — deep mode pulls SOT and costs
tokens.

## Phase 4 — Report

Get today's date. Write `.tms/reports/traceability-<YYYY-MM-DD>.md` (create
`.tms/reports/` if absent; committable; one per day — overwrite).

Terminal: coverage %, count of uncovered sources, count of orphan/untraced
cases, and the file path.

File structure:

```markdown
# Traceability — <date>

**Mode:** <light | deep>   **Scope:** <whole base | ...>

## Matrix
| Source | Kind | Registered? | Cases | (deep) AC covered / total |
|--------|------|-------------|-------|---------------------------|
| LIN-89 | linear | yes | 12 | 7/9 |

## Coverage gaps (uncovered requirements — prioritized)
- **<source>** — registered, 0 cases. <risk note if available> → `/new-feature <source>`
- (deep) **<source> AC "<text>"** — no covering case.

## Orphan / untraced cases
- **<case id>** — source_id `<ref>` not registered in sot.yaml (dangling/typo).
- **<case id>** — no source_id at all.

## Recommendations
<prioritized: close highest-risk gaps first; fix or retire dangling refs>
```

## Anti-patterns — do not do these

- **Don't write or modify cases.** This maps coverage; closing gaps is `/new-feature`,
  fixing refs is `/update-feature`.
- **Don't fan out in light mode.** Light mode is pure mechanical cross-reference —
  solo. Fan-out is deep-mode only.
- **Don't create the checkpoint marker.** This command owes no memory checkpoint.

## Epilogue (required)

End your final message with exactly this block:

✅ **Done:** matrix at .tms/reports/traceability-<date>.md — <N> sources, <X> uncovered, <Y> orphan cases
➡️ **Next:**
- `/new-feature <source>` — close the highest-risk uncovered requirements
- `/update-feature <ref>` — fix or retire the dangling source refs
- `/audit` — if orphan volume is high, a full health pass is worth it
