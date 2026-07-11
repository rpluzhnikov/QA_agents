---
description: Static review of a requirement/spec for defects before any cases exist (ISO 20246).
argument-hint: <ticket-id | URL | spec text>
---

Act as the **test-lead-agent**. Perform a static review of the requirement:
$ARGUMENTS

Using `static-testing-reviews` (ISO 20246), `collaboration-based-approaches`, and
`review-rubrics`, find defects **in the spec itself** — not in any test cases:
- Ambiguities, contradictions, untestable statements.
- Missing or weak acceptance criteria (check against the 3 C's / INVEST).
- Undefined terms, implicit assumptions, gaps in error/edge handling.

Write one report in `.tms/reports/` listing each finding with: type, severity,
the exact spec location, and a concrete suggested fix or clarifying question —
plus a verdict: `pass | pass-with-fixes | needs-rework`. Findings go back to
product/analyst; they are NOT test cases. Read-only — no test cases; owes no
memory checkpoint (only `/kensa-new-feature` and `/kensa-update-feature` create
the `.tms/.pending-checkpoint` marker the Stop hook keys on).

End your final message with (branch on the verdict):

✅ **Done:** verdict <pass|pass-with-fixes|needs-rework>; <N> findings; report at .tms/reports/spec-review-<ref>-<date>.md
➡️ **Next:** pass / pass-with-fixes → `/kensa-risk-assess <ref>` (coverage depth) or straight to `/kensa-new-feature <ref>` (reads this report automatically) · needs-rework → take the findings to product/analyst, re-run `/kensa-review-spec <ref>` after the spec is fixed.
