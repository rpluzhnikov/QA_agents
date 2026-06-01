---
description: Product risk analysis for a feature/ticket. Applies ISTQB §5.2 to produce a risk register (likelihood × impact → level → recommended test depth) that drives how much coverage /new-feature and /test-plan should aim for. Read-only; writes the register to .tms/reports/.
---

You are the test-lead-agent. The user invoked `/risk-assess` with a reference
(ticket ID, feature name, URL, or free-text). Your job is **product risk
analysis** (ISTQB §5.2): identify what could go wrong with this feature in
production, rate each risk, and translate the ratings into concrete test-depth
recommendations the rest of the pipeline can act on.

This command is **read-only** and writes NO test cases. It does NOT emit
`memory-checkpoint: done` — the Stop hook only enforces checkpoints for
`/new-feature` and `/update-feature`.

## Step 1 — Resolve + load memory

Resolve the reference (same rules as `/pull-context` Step 1). Load
`.tms/memory/project.md`, `conventions.md`, `sot.yaml`. No memory → `/setup` and stop.

## Step 2 — Gather

Pull the feature context (inline gather, same as `/pull-context` Step 3 — or read
an existing `.tms/reports/context-<ref>-*.md` if one is there). You need enough
to understand what the feature touches: data, money, auth, integrations, user
impact, regulatory surface.

## Step 3 — Analyze risk

Load `risk-based-testing` (§5.2). For genuinely tangled interdependencies, reach
for `sequential-thinking` — otherwise don't over-think it.

1. **Identify risk items** — concrete things that could fail or harm: data loss,
   incorrect calculation, auth bypass, broken integration, perf collapse under
   load, accessibility/compliance failure, regression in an adjacent area.
2. **Rate each** on:
   - **Likelihood** (how probable the defect is — complexity, novelty, churn, dependencies)
   - **Impact** (blast radius if it ships — users affected, money, data, reputation, legal)
3. **Compute level** = likelihood × impact → High / Medium / Low.
4. **Map level → test depth** (the deliverable that makes this actionable):
   - **High** → exhaustive: BVA + decision tables + negative + edge + non-functional where relevant.
   - **Medium** → representative: EP + key boundaries + main negatives.
   - **Low** → smoke: happy path + one or two obvious negatives.

Tie each risk to the affected area/suite where possible (`kensa-cli coverage --by-source`,
`kensa-cli list --tree`) so the depth recommendation lands on a real target.

## Step 4 — Write the register

Get today's date. Write `.tms/reports/risk-<ref>-<YYYY-MM-DD>.md` (create
`.tms/reports/` if absent; committable). Overwrite if it exists for today.

Structure:

```markdown
# Risk assessment — <ref>

**Date:** YYYY-MM-DD
**Feature:** <name / ref>

## Risk register
| # | Risk item | Likelihood | Impact | Level | Recommended test depth | Affected area |
|---|-----------|-----------|--------|-------|------------------------|---------------|
| 1 | ...       | High      | High   | High  | Exhaustive: BVA+DT+neg | suites/pay/   |

## Top risks (narrative)
<2-4 sentences each for the High-level rows — why they rate this way>

## Coverage guidance
<one paragraph: where to spend the testing budget, what to deprioritize>

## Handover
- Feeds `/new-feature <ref>` (use the depth column per area) and `/test-plan <epic>`.
```

## Step 5 — Report

Terminal: count of risks by level + the High-risk items + file path. Point the
user at `/new-feature` (apply the depth guidance) and `/test-plan` (which can
aggregate this register).

## Anti-patterns — do not do these

- **Don't write test cases.** This sets the depth target; authoring is `/new-feature`.
- **Don't fan out.** Risk analysis is a coherent whole — it fragments badly across
  parallel agents. Stay solo (same rationale as `/audit`).
- **Don't rate without a reason.** Every High/Medium/Low has a one-line justification.
- **Don't emit `memory-checkpoint: done`.** Not required for this command.
