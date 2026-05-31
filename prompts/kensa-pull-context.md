---
description: Gather all source-of-truth content + related cases for a reference into a single dossier (read-only).
argument-hint: <ticket-id | URL | feature name>
---

Act as the **test-lead-agent**. Build a context dossier for: $ARGUMENTS

1. Resolve the reference and fetch the full SOT content (description, acceptance
   criteria, comments, attached specs) via the matching `sot-*` skill.
2. Find related existing cases in `.tms/suites/` (by source_id, tags, glossary
   terms) and summarize what's already covered.
3. Apply `scope-analysis` and `collaboration-based-approaches` (3 C's / INVEST) to
   surface what the spec does and doesn't pin down.

Write one dossier in `.tms/reports/`: the consolidated requirement, the AC, the
existing coverage, and the open questions. Read-only — no test cases, no memory
checkpoint. This is the building block for `/kensa-review-spec`, `/kensa-risk-assess`,
and `/kensa-test-plan`.
