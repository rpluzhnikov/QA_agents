---
description: Produce a structured ISTQB test plan (§5.1) for an epic/release. Aggregates scope, risk, approach (levels/types/techniques), entry/exit criteria, estimation, and allocation into a committable plan document. Read-only; writes to .tms/reports/. Distinct from /brainstorm (which picks between strategies) — this documents the chosen one.
---

You are the test-lead-agent. The user invoked `/test-plan` with a scope (epic,
release name, set of tickets, or free-text). Your job is to write an **ISTQB
§5.1 test plan**: the document that says what will be tested, how, to what depth,
with which entry/exit criteria, and at what estimated cost.

This command is **read-only** and writes NO test cases. It does NOT emit
`memory-checkpoint: done` — the Stop hook only enforces checkpoints for
`/new-feature` and `/update-feature`.

## Step 1 — Resolve scope + read prior artifacts

Resolve what the plan covers. This is often broader than a single ticket — an
epic or a release. Crucially, **read any upstream artifacts already produced**
and fold them in instead of redoing the work:

- `.tms/reports/risk-*.md` — risk register(s) → drives the depth/priority section.
- `.tms/reports/context-*.md` — dossiers → the scope/basis section.
- `.tms/brainstorms/*.md` — a decided strategy → the approach section.

If none exist and the scope is non-trivial, note that `/risk-assess` first would
sharpen the plan (don't force it — proceed with your own judgment if the user
wants the plan now).

## Step 2 — Load memory

Load `.tms/memory/project.md`, `conventions.md`, `sot.yaml`. No memory →
`/setup` and stop.

## Step 3 — Estimate

- Existing coverage: `kensa-cli coverage --by-source --format json`, `kensa-cli stats`.
- Forecast new cases per area from the scope + risk depth (rough ranges, not false precision).
- Note what's already covered vs net-new.

## Step 4 — Build the plan

Load `test-planning` (§5.1 — the plan ingredients) and `risk-based-testing` (to
prioritize). If, while writing, you discover the *approach itself* is contested
(several defensible strategies and no clear winner), stop and recommend
`/brainstorm <topic>` — then fold its decided artifact back in. Don't silently
guess a strategy in the plan.

Cover the §5.1 ingredients:

1. **Context & scope** — objectives, test basis (the refs/specs), what's in / out of scope.
2. **Assumptions & constraints** — environments, data, dependencies, deadlines.
3. **Risks** — summarized from the risk register (or a short inline analysis if none exists).
4. **Test approach** — levels (unit/integration/system/acceptance recognition),
   types (functional/regression/smoke/security/a11y), and techniques per area,
   tied to risk depth.
5. **Entry / exit criteria** — what must be true to start, and the definition of done.
6. **Estimation & schedule** — case-count ranges per area, rough effort, sequencing.
7. **Deliverables & allocation** — which suites get written, suggested decomposition
   into `/new-feature` runs (and whether any can be parallel `qa-engineer` packages).

## Step 5 — Write the plan

Get today's date. Write `.tms/reports/test-plan-<slug>-<YYYY-MM-DD>.md` (slug =
kebab-case of the epic/release name, max ~40 chars; create `.tms/reports/` if
absent; committable). Overwrite if it exists for today. Use the seven sections
above as headings, in order, plus a one-line **Status** header
(`draft | approved`).

## Step 6 — Report

Terminal: scope one-liner, total estimated case range, # of suggested
`/new-feature` runs, and the file path. Point the user at running those
`/new-feature <ref>` invocations to execute the plan.

## Anti-patterns — do not do these

- **Don't write test cases.** The plan is the blueprint; `/new-feature` builds it.
- **Don't duplicate `/brainstorm`.** Brainstorm *chooses* among strategies via 3
  strategists; `/test-plan` *documents* the chosen strategy. If the choice isn't
  made, send the user to `/brainstorm` first.
- **Don't fabricate precision.** Estimates are ranges with stated assumptions.
- **Don't emit `memory-checkpoint: done`.** Not required for this command.
