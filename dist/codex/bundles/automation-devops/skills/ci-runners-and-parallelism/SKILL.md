---
name: ci-runners-and-parallelism
description: Framework-agnostic CI knowledge — runner choice (GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps), matrix/sharding fan-out, shard-by-timing, and containerization (official browser images, Selenium Grid, Testcontainers, cloud device farms). Load when the automation-devops agent wires a test suite into CI or picks a runner/parallelism model.
---

# CI runners and parallelism

How to put an automated test suite into CI fast, parallel, and reproducible — independent of the test framework. This skill covers **runner choice**, **matrix/sharding fan-out**, and **containerization** at the CI level. Playwright-specific Docker/CI wiring (image tags in a Playwright project, `playwright.config.ts` reporter, `merge-reports` flags) lives in **`playwright-ci-docker`** — cross-link it, don't duplicate it here.

The whole game is three primitives: **shard the suite across machines** (matrix/parallel jobs × the framework's native split), **persist JUnit XML plus failure artifacts**, and **gate merges on a fast smoke subset** while running the full sharded suite on merge-to-main and nightly. Sharding is the single highest-leverage move — splitting a 30–45 min suite across 4–10 machines routinely cuts wall-clock to 3–8 min.

## Concept

**Two levels of concurrency multiply.** In-process workers (Playwright `workers`, pytest-xdist `-n auto`, Jest default) × cross-machine shards. `workers: 4` × 4 shards = 16 concurrent executors.

**Shard by *timing*, not by file count.** File-count splitting (the Playwright/Jest `--shard` default) leaves one shard holding all the slow tests while others sit idle. CircleCI (`--split-by=timings`), Cypress Cloud, Knapsack Pro, and Azure DevOps's "previous test running times" all rebalance using historical duration data.

**Containers for reproducibility, farms for coverage.** Official browser images kill "works on my machine" flakiness and are cheapest/fastest for functional E2E. Cloud device farms (BrowserStack/Sauce Labs/LambdaTest) are the choice only when you need real devices or broad OS/browser coverage you can't reproduce headless.

**Free money:** concurrency cancellation (3 lines of YAML to cancel superseded runs) can cut 20–30% of billable minutes; lockfile-keyed dependency caching cuts 30–60% of build time.

## Rules

### Runner choice — pick where your code already lives

- **GitHub Actions** — GitHub repos and open source. Fan out with `strategy.matrix`; `fail-fast: false` keeps sibling shards running; `max-parallel` caps concurrency. Concurrency limits per GitHub Docs: **Free 20 concurrent jobs (5 macOS), Pro 40, Team 60 (5 macOS)**, Enterprise Cloud 500 / 50 macOS. Minute multipliers: **Linux 1×, Windows 2×, macOS 10×** — keep tests on Linux unless you genuinely need the others (2026 rate cuts brought Linux to $0.008/min, "reduced up to 39% from 2025 rates"). **Artifacts v4 is mandatory** (v3 shut down Jan 30 2025): up to 98% faster, but artifacts are *immutable*, names must be *unique* (matrix jobs can no longer append to one name — use `name-${{ matrix.x }}` + `download-artifact` `merge-multiple`), 500-artifact-per-job cap, 90-day default retention, **not supported on GHES** (use v3 there). The `blob` reporter + `merge-reports` need framework support (Playwright v1.37+).
- **GitLab CI** — integrated DevSecOps and self-hosted. Stages run sequentially, jobs within a stage in parallel. Two parallelism keywords: `parallel: N` (clones the job, exposing `CI_NODE_INDEX`/`CI_NODE_TOTAL`) and `parallel:matrix` (variable combinations). Excellent native JUnit: `artifacts:reports:junit` drives an MR widget comparing head vs base. The `parallel:matrix` aggregation bug was fixed in **GitLab 15.1**; total JUnit per job must be **< 100 MB**.
- **CircleCI** — best-in-class timing-based splitting with minimal config. Set `parallelism: N`, then `circleci tests run --split-by=timings` (newer, also enables rerun-failed) or `circleci tests split --split-by=timings` — uses historical timing from `store_test_results`, the most accurate built-in split of any runner. First run falls back to name-based until timing data exists. `CIRCLE_NODE_INDEX` is **0-based** while many `--shard` flags are 1-based — add 1.
- **Azure DevOps** — Microsoft/.NET shops. `strategy: parallel: N` (up to **99 agents**); Azure injects `System.JobPositionInPhase`/`System.TotalJobsInPhase`. The **VSTest task auto-slices** by test count, past running time, or assembly. **Test Impact Analysis (TIA)** runs only tests affected by a change — but managed .NET Framework VSTest only, **not .NET Core**. Tests tab + Test Analytics surface results after `PublishTestResults`.
- **Jenkins** — maximum on-prem control when you have the ops capacity. Declarative `parallel` runs stages across labeled agents; the `junit` step (in `post { always {…} }`) collects results. The **Parallel Test Executor plugin** splits into equal-time buckets from the previous build via `splitTests`. Provision more executors than parallel stages (6–8 for 4 stages). Highest maintenance burden.

### Shard count and balancing

- **Shard by timing wherever the runner supports it** (CircleCI `--split-by=timings`, Azure "previous test running times", Knapsack Pro, Cypress Cloud, pytest-split `--splitting-algorithm least_duration`). File-count default = idle shards.
- **Choosing N:** rule of thumb ~1 shard per 2–3 min of current runtime; match shards to available runners; watch per-shard variance.
- **Don't over-shard.** Each shard pays startup overhead (checkout + install + browser download). Over-sharding wastes minutes and *increases billable time* even as it cuts wall-clock time.
- **Native split flags:** Playwright `--shard=i/n` (file-level unless `fullyParallel: true`); Jest `--shard=i/n` (+ `--maxWorkers`); pytest = `pytest-xdist` for in-machine (`-n auto`, `--dist loadscope/loadfile/worksteal`) + `pytest-split` for cross-machine duration-balanced shards; Cypress = Cypress Cloud `--parallel --record` (or Currents/Sorry Cypress). Knapsack Pro splits by *test example* (70% threshold) to break single-file bottlenecks.

### Container choice

- **Official images first, pin exact tags:** `mcr.microsoft.com/playwright:v1.61.0-noble` (Ubuntu 24.04, browsers + deps; install the library via npm) and `cypress/included` (system deps + Cypress + browsers in one command — note browsers are *not* pre-installed on ARM images).
- **Self-hosted Selenium Grid / Grid on Kubernetes** when you want full control and no per-minute SaaS fees — but you maintain the grid, node scaling, and browser updates. Zalenium dynamically scales docker-selenium nodes and can overflow to cloud. **Testcontainers** spins up real dependencies (DBs, brokers) per run for integration testing.
- **Cloud device/browser farms** (BrowserStack / Sauce Labs / LambdaTest) **only for real-device, broad OS/browser, or visual parity** you can't reproduce headless. Sauce Labs advertises 900+ browser/OS combos and "1700+ emulators/simulators, 7500+ iOS/Android real devices" — stronger at enterprise-scale parallel CI and session logging/compliance; BrowserStack emphasizes speed, real-device breadth, quick CLI setup for smaller concurrent workloads. Tradeoff: farms reduce coverage gaps but add network latency and cost-per-minute.

## Code

A representative GitHub Actions sharded job with concurrency cancellation, v4 unique-name artifacts, and a merge job that fans the shards back into one report:

```yaml
# .github/workflows/test.yml — sharded suite + merged report (v4 artifacts)
name: tests
on: [pull_request]
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}   # free money
jobs:
  test:
    runs-on: ubuntu-latest                 # Linux 1× — avoid Windows 2× / macOS 10×
    strategy:
      fail-fast: false                     # one shard fails, siblings keep running
      matrix:
        shardIndex: [1, 2, 3, 4]
        shardTotal: [4]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'npm' }   # lockfile-keyed cache
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: blob-report-${{ matrix.shardIndex }}   # UNIQUE name — v4 requirement
          path: blob-report
          retention-days: 7

  merge:                                   # fan the shards back into one report
    if: ${{ !cancelled() }}
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'npm' }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with: { pattern: blob-report-*, merge-multiple: true, path: all-blob-reports }
      - run: npx playwright merge-reports --reporter=html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        with: { name: html-report, path: playwright-report }
```

The cross-machine shard pattern is identical on every runner — only the index variable changes. The slice expression per runner:

```bash
# GitHub Actions  --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
# GitLab CI       --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL                # parallel: N
# Azure DevOps    --shard=$(System.JobPositionInPhase)/$(System.TotalJobsInPhase)
# CircleCI        split by TIMING, not an index (0-based node index):
TESTFILES=$(circleci tests glob "src/**/*.test.js" | circleci tests split --split-by=timings)
npx jest $TESTFILES --reporters=default --reporters=jest-junit
# Jenkins         Parallel Test Executor plugin: splitTests() from previous build timing
```

GitLab e2e job on the official browser image, with JUnit + artifacts guarded `when: always`:

```yaml
e2e_tests:
  stage: test
  image: mcr.microsoft.com/playwright:v1.61.0-noble   # pinned official image
  parallel: 6
  script:
    - npm ci
    - npx playwright test --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL
  artifacts:
    when: always                                       # capture even on failure
    paths: [playwright-report/, test-results/]
    reports:
      junit: test-results/junit.xml                    # drives the MR widget
```

## Pitfalls

- **Shard by file count and call it parallel.** One shard ends up with every slow test; total time barely drops. Switch to timing-based splitting where the runner supports it.
- **Over-sharding.** 20 shards each paying 90s of checkout+install to run 30s of tests burns more billable minutes than 6 shards do — and the wall-clock win flattens. Tune to ~1 shard / 2–3 min of runtime.
- **Reusing one artifact name across a matrix on GitHub Actions v4.** v4 artifacts are immutable and names must be unique — the upload fails or clobbers. Use `name-${{ matrix.x }}` then `merge-multiple` (or `upload-artifact/merge`). Forgetting v3 is dead (Jan 30 2025) silently breaks pipelines; on GHES you must pin v3.x.
- **Uploading artifacts unconditionally.** Guard every upload with `if: always()` / `!cancelled()` or you lose exactly the failure traces you need — a cancelled run otherwise drops its evidence.
- **Defaulting to Windows/macOS runners.** 2× and 10× multipliers respectively. Keep the suite on Linux unless real OS coverage is the point.
- **No concurrency cancellation.** Superseded PR runs keep burning minutes. Three lines (`concurrency:` block) reclaim 20–30%.
- **Reaching for a device farm for ordinary functional E2E.** Headless containers are cheaper, faster, and more reproducible. Farms are for real devices / broad OS-browser / visual parity only — they add latency and cost-per-minute.
- **Off-by-one shard index.** CircleCI's `CIRCLE_NODE_INDEX` is 0-based while many `--shard` flags are 1-based — add 1, or one shard silently never runs.
- **Forgetting in-process × cross-machine multiply.** `workers` inside a shard compounds with shard count — set both deliberately or you over/under-subscribe the runner's CPUs.
- **GitLab JUnit over 100 MB per job, or `parallel:matrix` aggregation on < 15.1** — the report widget silently drops results.
- **Duplicating Playwright-specific config here.** Image tags inside a Playwright project, `reporter: process.env.CI ? 'blob' : 'html'`, `merge-reports` specifics → that's the `playwright-ci-docker` skill. This skill is the runner/parallelism/container layer only.
