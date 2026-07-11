---
name: ci-flake-gating-and-hygiene
description: CI flake handling (retry caps, quarantine lanes), merge-gating policy (smoke vs full, nightly), and hygiene (caching, secrets, cost). Load when the automation-devops agent sets CI retry/gating/cost policy.
---

Framework-agnostic CI mechanics for keeping a test suite trustworthy, fast, and cheap. This skill is the **CI plumbing**: where retries, gates, caches, and budgets live in the pipeline. The **organizational** flake policy — quarantine SLAs, who owns which ticket, flake-budget targets and the consequences of blowing them — belongs to the **automation-test-lead**, whose playbook is the `test-flakiness-governance` skill (automation-codereview bundle); wire up what they decide, don't set the policy here.

## Concept

A CI suite earns trust by failing only when something is actually broken. Three knobs protect that: bounded **retries** (absorb infra noise without hiding real bugs), a **gating** split (fast feedback on PRs, exhaustive coverage on main/nightly), and **hygiene** (caching, concurrency, secrets, cost) so the pipeline stays fast and affordable. Auto-retrying without tracking is the cardinal sin — it converts a visible bug into an invisible one and erodes the signal the suite exists to provide.

## Flaky handling

- **Cap retries: 0 locally, 1–2 in CI.** `retries: process.env.CI ? 2 : 0` is the standard — zero locally so you see flakes immediately, 1–2 in CI to absorb infrastructure noise. Retries above 2 are a smell; they mask bugs instead of surfacing them.
- **Surface, don't mask.** In pre-merge pipelines, *fail* the build on any flaky result (e.g. `--fail-on-flaky-tests` / `failOnFlakyTests: true`) so a fail-then-pass-on-retry can't sneak into the codebase. Auto-retry-without-tracking is what turns flakes into hidden bugs.
- **Quarantine into a non-blocking lane.** Tag flaky tests (`@flaky`), run the main suite with `--grep-invert @flaky`, and run the flaky lane separately with `continue-on-error: true` so it doesn't block merges. Open an **owned ticket with a deadline immediately** — "when everyone's responsible, nobody is."
- **Track flake rate as a metric.** Most teams investigate above **~2%**; CI trust collapses in the mid-single digits. Reserve `continue-on-error`/`allow_failure` for the quarantine lane only — never the main suite.
- **Fix the cause, not the symptom.** Root causes are dominated by async/timing waits and resource contention. Fix with web-first assertions, stable locators, test isolation, and network mocking rather than more retries.

## Gating policy

- **Smoke vs. full split.** Gate PRs on a fast smoke subset (lint + unit + critical-path E2E, target **under ~10 min**). Run the full sharded suite and cross-browser matrix on **merge to main** and on a **nightly schedule**.
- **Required checks + branch protection.** Require specific checks before merge; require branches up to date; optionally require code-owner review and linear history. Watch the skip semantics: a *job* skipped by a conditional reports "Success" (won't block), but a *workflow* skipped by a path filter stays "Pending" and **will block** a required check — move path filters to job-level conditionals so the workflow still runs.
- **Single aggregator check.** Use one "status-check" job that `needs` all matrix shards and fails if any result is failure/cancelled, then require only that one check. For merge queues, add the `merge_group` trigger or required checks never report.
- **fail-fast vs. continue-on-error.** Set `fail-fast: false` on test matrices so one shard's failure doesn't cancel the others (you want the full failure picture); reserve `continue-on-error` for experimental or quarantined lanes.

## Hygiene

- **Cache deps and browsers.** Key on the **lockfile hash**, not branch/date (`hashFiles('**/package-lock.json')`); cache browser binaries keyed on the framework version. Caching alone yields 30–60% build-time reductions.
- **Concurrency cancellation.** Cancel superseded runs on feature branches (saves 20–30% of minutes) but **not** on main — queue there instead, to avoid half-finished deploys.
- **Secrets.** Store in the runner's secret store (GitHub Secrets, GitLab CI variables, Jenkins Credentials, Azure variable groups); inject via `env:`; never commit. Prefer **OIDC federation** to cloud providers over long-lived static keys.
- **Run-time budgets & cost control.** Set per-job timeouts to kill runaway jobs; path-filter docs-only changes; right-size runners (a machine 1.67× faster but 4× the rate is a net loss); audit OS usage (move off macOS/Windows where possible); run only **affected** tests on PRs (Nx/Turborepo affected graphs, GitLab `rules:changes` per service).

```yaml
# Concurrency: cancel superseded feature-branch runs, queue on main
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

steps:
  - uses: actions/cache@v4
    with:
      path: |
        ~/.npm
        ~/.cache/ms-playwright        # browser binaries
      # key on the lockfile hash, NOT branch or date
      key: deps-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
  - run: npm ci
    timeout-minutes: 10                # run-time budget: kill runaways
```

## Pitfalls

- **Auto-retry without tracking** — the worst anti-pattern; a fail-then-pass-on-retry that no one records is a masked bug. Always surface flaky results and open a ticket.
- **Retries > 2** — stops absorbing noise and starts hiding real failures. Cap at 1–2 in CI, 0 locally.
- **`continue-on-error` on the main suite** — defeats the gate. It belongs only on the quarantine/experimental lane.
- **Path filter at workflow level on a required check** — leaves the check "Pending" forever and blocks merge. Filter at job level so the workflow still reports.
- **`fail-fast: true` on a test matrix** — one shard cancels the rest, so you debug blind. Use `fail-fast: false` and a single aggregator check.
- **Cache key on branch/date** — near-zero hit rate. Key on the lockfile (deps) and framework version (browsers).
- **Cancel-in-progress on main** — risks half-finished deploys. Cancel on feature branches only; queue on main.
- **Setting flake-rate budgets and quarantine SLAs here** — those are the automation-test-lead's call. This skill only wires up the mechanics.
