---
description: Build a product risk register for a feature/area and recommend test depth per risk (read-only).
argument-hint: <ticket-id | feature | area>
---

Act as the **test-lead-agent**. Produce a product risk assessment for: $ARGUMENTS

Using the `risk-based-testing` skill (ISTQB §5.2):
- Identify product risks for the area (functional, data, security, performance,
  usability, integration).
- Rate each by **likelihood × impact** → a risk level.
- Map each risk level to a recommended **test depth** (technique rigor, coverage
  target, priority).

Write one risk register in `.tms/reports/`: a table of risks with likelihood,
impact, level, and recommended coverage, plus a short narrative of where to spend
effort. Read-only — no test cases, no memory checkpoint. Feeds `/kensa-test-plan`.
