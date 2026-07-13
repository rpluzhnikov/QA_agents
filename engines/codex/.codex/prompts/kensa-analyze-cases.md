---
description: Semantic deep-audit of the existing case base via a fan-out of analyze-mode QA engineers (read-only).
argument-hint: [scope, e.g. suites/auth] (optional, default = all)
---

Act as the **test-lead-agent**. Run a semantic deep-audit over the case base
(scope: $ARGUMENTS, default = all). This complements the mechanical `/kensa-audit`.

1. Preflight: `.tms/memory/` exists (else "run `/kensa-setup` first" and stop);
   `kensa --version` reachable (workers use `kensa context bundle`, a CLI-only op;
   else stop); `project_stats {}` (MCP) — if the base has < 20
   cases, skip the fan-out and do a solo pass yourself with the same checklist.
   Otherwise shard the scope into reviewable slices.
2. Spawn `qa-engineer-agent` subagents in **analyze mode** (read-only) — one per
   shard — each handed the anomaly checklist: contradictions, semantic duplicates,
   coverage gaps, convention drift, mis-prioritization/mis-tagging, stale intent.
   They return findings in their messages (type, severity, case_ids, description,
   suggested_action) and write nothing.
3. Synthesize across shards: dedupe findings, rank by severity, and write one
   report in `.tms/reports/`.

Skills: `review-rubrics`, `test-design-techniques`, `negative-and-edge-cases`.
Read-only — no test cases; owes no memory checkpoint (only `/kensa-new-feature`
and `/kensa-update-feature` create the `.tms/.pending-checkpoint` marker the Stop
hook keys on).

End your final message with:

✅ **Done:** <N> semantic findings (<contradictions/dupes/gaps/…>); report at .tms/reports/analyze-cases-<date>.md
➡️ **Next:** `/kensa-update-feature <ref>` — resolve contradictions / merge duplicates (judgment fixes) · `/kensa-new-feature <ref>` — close the coverage gaps · re-run `/kensa-audit` after fixes land to confirm a clean mechanical baseline.
