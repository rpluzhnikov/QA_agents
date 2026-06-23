---
name: test-flakiness-governance
description: Systemic causes of test flakiness and the governance policy that contains it — detection → auto-quarantine-with-SLA → stabilize-or-delete, plus flake budgets and hermetic design. Load when the codereviewer or automation-test-lead handles flaky tests.
---

# Test flakiness governance

A flaky test passes and fails on the *same* code, so it carries no reliable signal. Past a low threshold, flakes don't just waste reruns — they teach engineers to ignore red builds, which silently disables the whole suite. Flakiness is not a stack of one-off bugs to swat; at scale it is a permanent property of the system that you *govern*, not eliminate. The lever is organizational, not a clever per-test trick.

## Concept

Flakiness is systemic and inevitable at scale. Google's numbers (John Micco, Google Testing Blog, May 2016) make this concrete: *"we see a continual rate of about 1.5% of all test runs reporting a 'flaky' result… Almost 16% of our tests have some level of flakiness associated with them,"* and *"about 84% of the transitions we observe from pass to fail involve a flaky test."* You cannot drive flakiness to zero — you keep it under a budget.

The danger is the trust cliff. *Software Engineering at Google* reports that at roughly **1% flakiness, tests become useless — engineers start ignoring failures** (Google's own measured rate hovers around **0.15%**). Once trust erodes, the spiral runs the other way: some organizations reach 50%+ flaky tests, after which developers hardly write tests at all. The cost is real even before the cliff: duplicate bug investigations chasing phantom failures, and apathy toward genuine regressions hiding behind the noise.

Systemic root causes — the levers a lead actually controls:
- **Non-hermetic tests** — shared DB/state, run-order dependence. Fix: enforce hermeticity/isolation as a merge gate.
- **Shared, drifting environments**. Fix: ephemeral hermetic environments per run.
- **Over-reliance on slow integrated E2E** where flakiness is inherent to the integrated condition. Fix: push assertions down the stack / to contract tests; keep a small E2E core.
- **No ownership or detection infrastructure**. Fix: per-test ownership, dashboards, flake-rate tracking.
- **Retry-as-reflex culture** — re-running until green normalizes a broken signal. Fix: quarantine on first flake instead of masking with retries.

## The policy

**Detection.** Confirm flake by re-running on the *same commit* — intermittent pass/fail with no code change is a flake; a real bug fails consistently. Track flake rate (failures/runs) per test over a rolling window so the trend, not a single bad night, drives action.

**Auto-quarantine with an SLA.** When a test exceeds the flakiness threshold, automatically move it to a non-blocking suite so it stops breaking CI, auto-file a ticket to the owning team with a due date, and notify via chat (the pattern behind Atlassian's "Flakinator," Datadog, and Trunk; Datadog's example auto-quarantines on a default-branch flake and auto-disables if unfixed after 30 days). Quarantine is a holding cell with a clock, **not** a graveyard — investigate and fix or delete within one sprint. Quarantine without investigation protects you from nothing.

**Stabilize-or-delete.** For each quarantined test, decide within the SLA:
1. **Triage by value.** Core/critical workflow (auth, pay/checkout, deploy)? High value → fix first. Low-value noise → quarantine or delete.
2. **Stabilize** if the root cause is fixable in the SLA: isolation, explicit waits over sleeps, mock/virtualize the unstable dependency, deterministic data.
3. **Delete** if it no longer maps to current requirements, the feature is gone, or it can't be made reliable in the SLA and gives false confidence — *"a flaky test produces no reliable quality signal and is worse than no test."* Document the coverage gap honestly and write a stable replacement.
4. **Google's caveat:** some genuinely valuable integrated tests are flaky *because* the conditions that make them flaky are the same conditions that caused the bug. Manage these with repetition/statistics on a non-blocking path rather than deleting.

**Flake budgets.** Alert when a single test exceeds ~1% flakiness over a 7-day window; hold the suite-level target well under 1% (Google operates near 0.15%). New/suspicious tests run many times before merge; enforce hermeticity (no network/sleep in small tests) as a CI rule. Every test has a named owner so flaky tickets route automatically. A quarantined test rejoins the blocking suite only after demonstrating health for a configured period.

**Hermetic / isolated design.** The cheapest flake is the one prevented at write time: tests own their state, depend on no run order, touch no shared mutable environment, and use deterministic data and clocks. Hermeticity is a merge gate, not a suggestion.

## What the reviewer flags

- Hard-coded `sleep`/`waitForTimeout` instead of waiting on a condition → flake under load. (Per-framework fix: `playwright-waiting-and-assertions`.)
- Tests that read or mutate shared state (global DB rows, singletons, the real clock, env vars) — order-dependent and non-hermetic.
- Reliance on wall-clock time, `now()`, timezone, or random data without a fixed seed.
- New E2E tests asserting deep into an integrated flow where a contract or lower-layer test would be stable.
- A test with no named owner, or a quarantine annotation with no linked ticket / due date.
- Retry counts being raised in config as the "fix" for a failing test.

## Pitfalls

- **Per-test retry as the "fix."** Bumping `retries` turns a visible flake into a silent one — the test still fails for users, you just stopped seeing it. Retries are a *temporary, visible quarantine* (surface recovered flakes with a fail-on-flaky gate), never a resolution. The CI mechanics live in `ci-flake-gating-and-hygiene`.
- **Un-owned quarantine lanes that never drain.** A quarantine suite with no SLA, no owner, and no re-entry criteria becomes a permanent dumping ground — coverage quietly rots while everyone believes it's "handled." Every quarantined test needs a ticket, a due date, and a stabilize-or-delete decision inside the SLA.
- Treating flakiness as a finite bug list to clear rather than a budget to hold — it regrows; govern it continuously.
- Deleting a flaky but genuinely valuable integrated test instead of moving it to a non-blocking statistical path (Google's caveat).

---

See also: `ci-flake-gating-and-hygiene` (the CI mechanics — gating, retry/flake reporting, hygiene) and `playwright-waiting-and-assertions` (per-framework anti-flake idioms).
