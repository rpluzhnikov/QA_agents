---
description: Semantic deep-audit of the whole (or scoped) test base by a fan-out of 1-N qa-engineer workers in analyze mode. Finds what the mechanical /audit can't — cross-case contradictions, semantic duplicates, convention drift, coverage gaps vs source, mis-prioritized/mis-tagged cases. Read-only by default; optional per-batch fixes at the end. Built for large projects.
---

You are the test-lead-agent. The user invoked `/analyze-cases` to get a deep,
*semantic* read of the test-case base — the kind of judgment `kensa-cli` can't
make. Where `/audit` runs mechanical checks (schema, lint, exact duplicates,
stale, orphan refs) solo, `/analyze-cases` shards the base and fans out
`qa-engineer` workers to reason over it, then synthesizes their findings.

This command is **read-only by default**: workers do NOT write or modify cases —
they return findings in their message; you write one report. It does NOT emit
`memory-checkpoint: done` — the Stop hook only enforces checkpoints for
`/new-feature` and `/update-feature`.

**See also `/audit`** — run it first for the mechanical baseline; `/analyze-cases`
is the semantic layer on top.

## Phase 1 — Preflight

1. `.tms/memory/` exists? If not → "Run `/setup` first" and stop.
2. Read `.tms/memory/project.md`, `conventions.md` (full — the rubric), and
   `learned/tags.md` (taxonomy).
3. `kensa-cli --version` on PATH? If not → tell the user and stop.
4. `kensa-cli stats --format json` for repo size. **If < 20 cases → do a solo pass
   yourself** (no sharding, no workers — read them all, apply the checklist
   below) and skip to Phase 4. Fan-out only pays off at scale.
5. Optional scope: if the user passed a scope (`/analyze-cases suites/auth`, a
   tag, or a source_id), restrict to it. Default is the whole base.

## Phase 2 — Shard the base

Cut the base into N shards sized to fit a worker's context budget. Choose the
shard axis by what makes cases comparable (so contradictions/dupes land in the
same shard where possible):

- **By suite subtree** (default) — `suites/auth/*`, `suites/payments/*`, …
- **By source_id** — all cases tracing the same ticket together.
- **By tag** — when a behavior spans suites under one tag.

Pick **N between 1 and 10**, driven by size (rough target ~30-60 cases or a
bounded token budget per shard). Announce the shard plan to the user in one
message (how many shards, the axis, what each covers). No hard sync gate — but
if the plan is obviously wrong they can redirect.

## Phase 3 — Fan-out (analyze mode)

Spawn N `qa-engineer` workers in the SAME turn via the Task tool, each in
**analyze** mode (see `qa-engineer-agent.md` → Mode: analyze). Each brief contains:

- **Shard contents** — the case ids/paths in its shard. Tell it to load them via
  `kensa-cli context bundle --filter '<shard filter>'` under a token budget rather
  than reading whole suites.
- **Skills to load** — `testing-fundamentals`, `test-design-techniques`,
  `negative-and-edge-cases`, `review-rubrics`, `checklist-design`.
- **The anomaly checklist** (what to hunt for, return findings only — write nothing):
  - **Contradictions** — two cases asserting different expected results for the same behavior.
  - **Semantic duplicates** — cases that test the same thing in different words (beyond the CLI's string similarity).
  - **Coverage gaps** — checklist conditions a reasonable engineer would expect for this area but no case covers (negatives, boundaries, error/empty states).
  - **Convention drift** — titles/steps/expected-results that violate `conventions.md` (passed in the brief).
  - **Mis-prioritization / mis-tagging** — `priority`/`tags` that don't match the case's actual risk or content.
  - **Staleness of intent** — cases describing flows the spec/glossary suggests no longer exist.
- **Return format** — a findings list: `{type, severity, case_ids, one-line description, suggested action}`. Findings in the message body. No file writes.

Spawn all N in one tool-use block. Wait for all to return. Re-spawn just the ones
that fail or return unusable output.

## Phase 4 — Cross-shard pass + dedupe

The fan-out is blind across shard boundaries. You aren't:

1. Collect all findings. Dedupe (two workers may flag the same cross-shard pair).
2. Run a focused second pass on **cross-shard suspects** — e.g. a possible
   duplicate where one case is in shard A and its twin in shard B. Do this
   yourself (read the two cases) or, for many suspects, a small second fan-out.
3. Apply `review-rubrics` to decide which findings are real and worth reporting —
   filter out low-signal noise (the goal is signal, not volume).

## Phase 5 — Report

Get today's date. Write `.tms/reports/analyze-cases-<YYYY-MM-DD>.md` (create
`.tms/reports/` if absent; committable; one report per day — overwrite).

Terminal: a ~15-line summary (counts by type × severity, top examples) + the file
path. Don't dump every finding in the terminal — push detail to the file.

File structure:

```markdown
# Semantic analysis — <date>

**Scope:** <whole base | suites/... | tag:...>
**Shards:** N (axis: <suite|source|tag>)   **Cases analyzed:** M

## Summary
| Finding type | Critical | Major | Minor | Examples |
|--------------|----------|-------|-------|----------|
| Contradictions | ... |
| Semantic duplicates | ... |
| Coverage gaps | ... |
| Convention drift | ... |
| Mis-prioritization | ... |
| Stale intent | ... |

## Findings by type
<each finding: type · severity · case ids · description · suggested action>

## Recommendations
<prioritized next actions — e.g. "resolve the 3 contradictions in suites/pay
before next release; merge the 5 semantic dupes; /new-feature LIN-12 to close
the 4 coverage gaps">
```

## Phase 6 — Optional fix offer (opt-in, per-batch)

After presenting the report, ask ONCE whether to attempt safe fixes. Only offer
mechanical, reversible actions via `kensa-cli` (e.g. retag, flip stale → deprecated,
trash a confirmed duplicate `--to-trash`). For each accepted batch: show a
dry-run → wait for explicit confirmation → apply with `--yes` → `kensa-cli validate`.
Anything requiring judgment (resolving a contradiction, closing a coverage gap)
is NOT auto-fixed here — route it to `/update-feature` or `/new-feature`. If the
user declines or doesn't respond — stop, don't nudge.

## Anti-patterns — do not do these

- **Don't let workers write or modify cases.** Analyze mode returns findings; the
  Test Lead writes the single report. Fixes are Phase 6, opt-in, per-batch.
- **Don't re-run the mechanical checks.** Those are `/audit`. Reference its report
  if present; don't duplicate schema/lint/exact-dupe scanning here.
- **Don't report noise.** Filter through `review-rubrics` — every reported finding
  should be worth the user's time.
- **Don't shard so finely that context is lost.** Comparable cases must share a shard.
- **Don't emit `memory-checkpoint: done`.** Not required for this command.
