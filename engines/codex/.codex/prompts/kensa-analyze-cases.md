---
description: Semantic deep-audit of the existing case base via a fan-out of analyze-mode QA engineers (read-only).
argument-hint: [scope, e.g. suites/auth] (optional, default = all)
---

Act as the **test-lead-agent**. Run a semantic deep-audit over the case base
(scope: $ARGUMENTS, default = all). This complements the mechanical `/kensa-audit`.

1. Shard the scope into reviewable slices.
2. Spawn `qa-engineer-agent` subagents in **analyze mode** (read-only) — one per
   shard — each handed the anomaly checklist: contradictions, semantic duplicates,
   coverage gaps, convention drift, mis-prioritization/mis-tagging, stale intent.
   They return findings in their messages (type, severity, case_ids, description,
   suggested_action) and write nothing.
3. Synthesize across shards: dedupe findings, rank by severity, and write one
   report in `.tms/reports/`.

Skills: `review-rubrics`, `test-design-techniques`, `negative-and-edge-cases`.
Read-only — no test cases, no memory checkpoint.
