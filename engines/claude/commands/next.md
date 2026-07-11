---
description: Read-only situation router — inspects the .tms/ project state (memory, base size, fresh reports, pending checkpoint, audit age) and recommends the 2-3 most useful next commands with reasons. The "I'm back, where were we?" command.
argument-hint: (no args)
---

You are the test-lead-agent. The user invoked `/next` to find out where the
project stands and what's worth doing now. This command is **read-only**: it
writes nothing, modifies nothing, and owes no memory checkpoint.

## Step 1 — Probe the state (cheap checks, in order)

Collect facts; don't report them yet. Skip gracefully past anything that errors.

1. **Plugin usable?** `kensa --version`. Missing CLI is itself a finding.
2. **Project exists?** `.tms/` present? `.tms/memory/project.md` present?
3. **Pending checkpoint?** `.tms/.pending-checkpoint` exists → an authoring run
   was interrupted before its memory checkpoint.
4. **Base size & shape:** `kensa stats --format json` (case count, status
   distribution), `kensa coverage --by-source --format json` (sources with 0 cases).
5. **Fresh handover artifacts:** list `.tms/reports/` — `context-*`,
   `spec-review-*`, `risk-*`, `test-plan-*` newer than the newest cases that
   reference the same ref suggest an unfinished pipeline; note `audit-*` /
   `analyze-cases-*` / `traceability-*` dates (or their absence).
6. **Brainstorms:** `.tms/brainstorms/*` without matching cases → a decided
   strategy nobody executed.
7. **Routines:** does `.tms/routines/` have RT-* files?
8. **Assumptions ledger:** `.tms/reports/assumptions-*` with open items.

## Step 2 — Rank recommendations

Map findings to commands, most urgent first. The heuristics:

| Finding | Recommendation |
|---|---|
| No `.tms/` or no memory | `/setup` (or `/adapt-schema` first if they have a TMS export to migrate) |
| `kensa` missing | install/expose the CLI — nothing else works without it |
| Pending checkpoint marker | `/save-memory` — close the interrupted authoring run |
| Fresh `context-*`/`spec-review-*`/`risk-*` with no cases for that ref | `/new-feature <ref>` — the analysis is done, the cases aren't |
| `spec-review-*` verdict needs-rework | chase product/analyst; re-run `/review-spec <ref>` after |
| Brainstorm artifact, no cases | `/new-feature <ref>` pointing at it |
| Sources with 0 cases in coverage | `/traceability` (qa-analytics) or `/new-feature <source>` |
| No audit report ever / audit older than ~a month with an active base | `/audit` |
| Base grew a lot since last `analyze-cases` | `/analyze-cases` (qa-analytics) |
| Routines exist, user mentioned the app is running | `/run-routine` |
| Empty base, memory exists | `/new-feature <ref>` — start authoring |

Only recommend bundle commands whose bundle is installed — otherwise name the
bundle as the thing to install.

## Step 3 — Report

A short status snapshot (3-6 lines: base size, last audit, open artifacts,
anything pending) followed by the standard epilogue block. No file output.

## Epilogue (required)

✅ **Status:** <one line — e.g. "142 cases, audit 3 weeks old, risk register for LIN-89 unexecuted, checkpoint pending">
➡️ **Next:**
- <top recommendation with the reason from Step 2>
- <second>
- <third, optional>
