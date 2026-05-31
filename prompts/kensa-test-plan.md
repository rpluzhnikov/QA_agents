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
the *strategy itself* is contested, send the user to `/kensa-brainstorm` first.

Write one plan in `.tms/reports/`. Read-only — no test cases, no memory checkpoint.
