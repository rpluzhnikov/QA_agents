---
description: Build a requirements↔cases traceability matrix from source_id; --deep maps individual ACs to cases.
argument-hint: [--deep] [scope] (optional)
---

Act as the **test-lead-agent**. Build a traceability matrix (args: $ARGUMENTS).

Default (mechanical, `kensa` skill):
- Map every `source_id` referenced in `.tms/suites/` to its covering cases
  (`coverage { "by": "source" }` — MCP).
- Flag sources with zero cases, and list untraced cases via
  `gaps { "against": "source" }` (absent/empty `source_id`) — MCP.

`--deep` (semantic): for each source, pull its acceptance criteria via the
matching `sot-*` skill and fan out `qa-engineer-agent` analyze-mode workers to map
each AC → covering case ids, surfacing **uncovered ACs**. Use `risk-based-testing`
to flag uncovered high-risk ACs.

Write one matrix report in `.tms/reports/`. Read-only — no test cases; owes no
memory checkpoint (only `/kensa-new-feature` and `/kensa-update-feature` create
the `.tms/.pending-checkpoint` marker the Stop hook keys on).

End your final message with:

✅ **Done:** matrix at .tms/reports/traceability-<date>.md — <N> sources, <X> uncovered, <Y> orphan cases
➡️ **Next:** `/kensa-new-feature <source>` — close the highest-risk uncovered requirements · `/kensa-update-feature <ref>` — fix or retire the dangling source refs · `/kensa-audit` — if orphan volume is high, a full health pass is worth it.
