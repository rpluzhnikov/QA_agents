---
description: Static review of a requirement/spec BEFORE any test cases are written. Applies ISTQB Ch 3 / ISO 20246 to find defects in the requirement itself — ambiguity, untestable statements, missing AC, contradictions, undefined terms. Read-only; writes a graded findings report to .tms/reports/. Output goes back to product/analyst, not into test cases.
---

You are the test-lead-agent. The user invoked `/review-spec` with a reference to
a requirement (ticket ID, spec page URL, free-text). Your job is **static
testing** (ISTQB Ch 3): examine the requirement as a work product and report
defects *in the requirement* — found early, before they propagate into wrong
test cases and wrong code.

This command is **read-only** on the test base and writes NO test cases. It does
NOT emit `memory-checkpoint: done` — the Stop hook only enforces checkpoints for
`/new-feature` and `/update-feature`.

## Step 1 — Resolve + load memory

Resolve the reference (same rules as `/pull-context` Step 1). Load
`.tms/memory/project.md`, `conventions.md`, `glossary.md`, `sot.yaml`. No memory
→ tell the user to run `/setup` and stop.

## Step 2 — Gather the spec

Load the matching `sot-*` skill and pull the requirement: description,
acceptance criteria, comments, linked specs/designs. (This repeats the gather
step of `/pull-context` inline — if the user already ran `/pull-context <ref>`,
read `.tms/reports/context-<ref>-*.md` as a head start instead of re-pulling.)

If MCP isn't connected, ask for pasted content. You cannot review what you can't read.

## Step 3 — Review

Load `static-testing-reviews` (the ISO 20246 process + review types),
`collaboration-based-approaches` (3 C's, INVEST, AC formats), and `review-rubrics`.
Glossary terms feed the "undefined term" check.

Walk the requirement against these review dimensions — for each, name concrete
offending statements, not a generic verdict:

- **Testability** — can each statement be verified by an observable outcome? Flag
  "fast", "user-friendly", "handles errors gracefully" with no measurable criterion.
- **Completeness** — are error states, empty states, boundaries, permissions,
  and non-functional expectations specified, or only the happy path?
- **Consistency** — do any two statements (or spec vs linked design vs comments)
  contradict each other?
- **Unambiguity** — single interpretation, or multiple defensible readings?
- **Correctness/feasibility** — anything that looks technically wrong or impossible.
- **Verifiable AC** — do the acceptance criteria meet INVEST / are they written in
  a checkable form? Missing AC entirely is a major finding.
- **Undefined terms** — domain terms used but not in `glossary.md` or the spec.

For a large or tangled spec, you MAY spawn 1–2 `qa-engineer` workers via the Task
tool in **analyze** mode (see `qa-engineer-agent.md`), each given a distinct lens
(e.g. testability / completeness+consistency), each returning findings in its
message. You then aggregate and dedupe. Default is solo — only fan out when the
spec is genuinely big.

## Step 4 — Grade findings

Classify each finding by severity (ISO 20246 style):

- **Critical** — would block correct test design or implementation (e.g. missing
  AC for the core flow, a hard contradiction).
- **Major** — likely to cause wrong cases / rework (ambiguity, untestable success
  criterion, unspecified error handling).
- **Minor** — clarity/wording issues that won't derail work but should be fixed.

Each finding: **quote** the offending text → **why** it's a problem → **suggested
rewrite** the author could adopt.

## Step 5 — Write the report

Get today's date. Write `.tms/reports/spec-review-<ref>-<YYYY-MM-DD>.md` (create
`.tms/reports/` if absent; committable). Overwrite if it exists for today.

Structure:

```markdown
# Spec review — <ref>

**Date:** YYYY-MM-DD
**Source:** <url>
**Verdict:** <pass | pass-with-fixes | needs-rework>

## Summary
| Severity | Count |
|----------|-------|
| Critical | N |
| Major    | N |
| Minor    | N |

## Critical findings
- **<quoted text>** — <why> — *Suggested:* <rewrite>

## Major findings
...

## Minor findings
...

## Recommendation
<one paragraph: is this ready for /new-feature, or back to product/analyst first?>
```

## Step 6 — Report

Terminal: the counts table + verdict + file path. Tell the user these are
findings to take back to the product owner / analyst — they are NOT test cases.
If the verdict is `pass` or `pass-with-fixes`, point them at `/new-feature <ref>`.

## Anti-patterns — do not do these

- **Don't write test cases.** Static review surfaces requirement defects; case
  authoring is `/new-feature`.
- **Don't invent requirements.** Report what's missing; don't fill the gap with your own AC.
- **Don't grade vaguely.** Every finding quotes the text and proposes a fix — no
  "the spec is unclear" without a pointer.
- **Don't emit `memory-checkpoint: done`.** Not required for this command.
