---
description: Ingest an automation result report via kensa results, walk the matched/orphaned split, and close the traceability loop.
argument-hint: <path to report> [--report-format <fmt>]
---

Act as the **test-lead-agent**. Load the `kensa-results` skill. Report path: $ARGUMENTS

1. **Preflight** — `kensa --version` (missing → stop); `.tms/memory/` exists
   (missing → `/kensa-setup` and stop); report file exists.
2. **Ingest** — `kensa results ingest <path> --format json` (add
   `--report-format` if auto-detect exits 2). Read the matched/orphaned split;
   the run lands in `.tms/automation-runs/`.
3. **Walk the split** (confirm-first for every write): matched → offer to tag
   cases `automated`; orphaned → either the test's `@KEN-<id>` tag is wrong
   (name the test file to fix) or no case exists → offer `kensa new` (external
   ref in `--source-id`, tag `automated`) and instruct writing the new id back
   into the test as a `@KEN-<id>` tag so the next ingest matches.
4. **Report** counts, then end with:
   ✅ **Done:** <N> ingested — <X> matched / <Y> orphaned; <B> cases created
   ➡️ **Next:** write `@KEN` tags back into mis-tagged tests ·
   `/kensa-traceability` (qa-analytics bundle) · `/kensa-automate-case <id>`
   (automation bundle)

No memory checkpoint owed.
