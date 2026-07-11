---
description: Draft an ISTQB §5.1 test plan for an epic/feature, folding in existing risk/context/brainstorm artifacts.
argument-hint: <epic | feature | area>
---

Act as the **test-lead-agent**. Draft a test plan for: $ARGUMENTS

Using the `test-planning` skill (ISTQB §5.1):
- Objectives and scope (in/out).
- Test items, levels, and types; entry/exit (definition of ready/done) criteria.
- Approach, techniques, and environment needs.
- Estimation, prioritization, and the test pyramid balance.
- Risks and mitigations.

Fold in any existing artifacts you find for this area: a `/kensa-risk-assess`
register, a `/kensa-pull-context` dossier, or a `/kensa-brainstorm` decision. If
the *strategy itself* is contested, send the user to `/kensa-brainstorm` first
(strategist bundle — name the bundle if it isn't installed). Include a
deliverables/allocation section decomposing the work into `/kensa-new-feature` runs.

Write one plan in `.tms/reports/`. Read-only — no test cases; owes no memory
checkpoint (only `/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on).

End your final message with:

✅ **Done:** plan at .tms/reports/test-plan-<slug>-<date>.md — <N> areas, ~<X-Y> cases, <K> suggested /kensa-new-feature runs
➡️ **Next:** `/kensa-new-feature <ref>` × K — execute the plan run by run (each reads the plan + risk register automatically) · `/kensa-brainstorm <topic>` — only if the approach section flagged a contested strategy (strategist bundle).
