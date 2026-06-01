---
description: Build a requirements↔cases traceability matrix from source_id; --deep maps individual ACs to cases.
argument-hint: [--deep] [scope] (optional)
---

Act as the **test-lead-agent**. Build a traceability matrix (args: $ARGUMENTS).

Default (mechanical, `kensa-cli` skill):
- Map every `source_id` referenced in `.tms/suites/` to its covering cases.
- Flag sources with zero cases and cases with no `source_id`.

`--deep` (semantic): for each source, pull its acceptance criteria via the
matching `sot-*` skill and fan out `qa-engineer-agent` analyze-mode workers to map
each AC → covering case ids, surfacing **uncovered ACs**. Use `risk-based-testing`
to flag uncovered high-risk ACs.

Write one matrix report in `.tms/reports/`. Read-only — no test cases, no memory
checkpoint.
