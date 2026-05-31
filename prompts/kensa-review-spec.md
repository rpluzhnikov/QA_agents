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
the exact spec location, and a concrete suggested fix or clarifying question.
Read-only — no test cases, no memory checkpoint.
