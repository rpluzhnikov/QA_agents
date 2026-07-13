---
description: Ingest an automation test-result report (JUnit / Playwright / Allure / CTRF and 7 more) via kensa results, walk the matched/orphaned split, and close the traceability loop — author missing cases for orphans and tag matched cases as automated.
argument-hint: <path to report file> [--report-format <fmt>]
---

You are the test-lead-agent. The user invoked `/import-results` with a path to a
CI/automation report. Load the `kensa-results` skill — it owns the format list,
the match chain, and the orphan-remediation loop; this command sequences it.

## Step 1 — Preflight

1. `kensa --version` — missing CLI → tell the user and stop.
2. `.tms/memory/` exists? If not → "Run `/setup` first" and stop (matching needs
   a case base to match against).
3. The report file exists? If the path is missing or wrong, ask and stop.

## Step 2 — Ingest

Run `kensa results ingest <path> --format json` (pass `--report-format <fmt>`
if the user gave one or auto-detection exits 2 — the skill lists the 11 formats).
Read the **matched / orphaned** split from the output. The normalized run lands
in `.tms/automation-runs/`.

## Step 3 — Walk the split

1. **Matched tests** — offer to tag their cases `automated` where missing:
   `filter_cases { "expr": "..." }` (MCP) → dry-run the bulk tag (CLI write) → confirm → apply.
2. **Orphaned tests** — for each (batch by suite/area):
   - the case exists but the test's `@KEN-<id>` tag is wrong/missing → tell the
     user which test file to fix (the fix itself lives in automation code);
   - no case exists → offer to author one (`kensa new`, external ref in
     `--source-id`, tag `automated`), then instruct that the **new case id must
     be written back into the test as a `@KEN-<id>` tag** so the next ingest
     matches instead of re-orphaning.
   Every write is confirm-first: show the list, get a yes, then create.

## Step 4 — Report

Counts: N parsed / X matched / Y orphaned → of Y: A annotation-fixes to make in
test code, B new cases created, C skipped (user's call). Name the run file in
`.tms/automation-runs/`.

This command can create cases (confirm-first) but owes no memory checkpoint —
only `/new-feature` and `/update-feature` create the `.tms/.pending-checkpoint`
marker the Stop hook keys on.

## Epilogue (required)

✅ **Done:** <N> results ingested — <X> matched / <Y> orphaned; <B> cases created; run stored in .tms/automation-runs/
➡️ **Next:**
- write the `@KEN-<id>` tags back into the <A> mis-tagged tests (automation repo)
- `/traceability` — see the updated requirements↔cases picture (qa-analytics bundle)
- `/automate-case <KEN-id>` — cover the manual cases that still have no automation (automation bundle)
