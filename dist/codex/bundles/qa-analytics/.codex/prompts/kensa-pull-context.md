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
existing coverage, and the open questions. End the dossier with a **Handover**
section: `/kensa-new-feature <ref>` for test cases (it reads this dossier
automatically); `/kensa-update-feature <ref>` instead if related cases show
*supersedes / overlaps*; `/kensa-review-spec <ref>` first if the spec looks shaky;
`/kensa-risk-assess <ref>` for coverage-depth decisions.

Read-only — no test cases; owes no memory checkpoint (only `/kensa-new-feature`
and `/kensa-update-feature` create the `.tms/.pending-checkpoint` marker the Stop
hook keys on). This is the building block for `/kensa-review-spec`,
`/kensa-risk-assess`, and `/kensa-test-plan`.

End your final message with (mirror the dossier's Handover; only suggest commands
whose bundle is installed — otherwise name the bundle):

✅ **Done:** dossier at .tms/reports/context-<ref>-<date>.md — <N> AC, <M> related cases, <K> gaps
➡️ **Next:** `/kensa-review-spec <ref>` — if the gaps look serious · `/kensa-risk-assess <ref>` — coverage depth · `/kensa-new-feature <ref>` — write the cases (reads this dossier automatically) · `/kensa-update-feature <ref>` — if this work supersedes existing cases.
