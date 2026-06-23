---
name: ci-artifacts-and-reporting
description: JUnit XML + traces/videos/screenshots artifacts and report tooling (native runner widgets, then Allure/ReportPortal/Currents). Load when the automation-devops agent configures CI test reporting and artifacts.
---

Framework-agnostic CI reporting: emit machine-readable results every runner can ingest, persist the artifacts that make a red build debuggable, and layer a history/analytics platform only once cross-run trends become the bottleneck. For the Playwright-specific blob/merge flow, cross-link **playwright-reporting-and-traces**.

## Concept

Two outputs matter on every CI run. **JUnit XML is the lingua franca** — every runner ingests it natively to render a pass/fail summary (GitLab MR widget, Azure DevOps Tests tab, Jenkins `junit` step, `dorny/test-reporter` as a GitHub check). **Rich failure artifacts** (traces, videos, screenshots) are what let an engineer diagnose a failure from the build alone, without re-running locally. Native HTML reporters are *stateless* — a fresh bundle each run, no memory of prior runs — so cross-run history and flake analytics require either CI scripting or a dedicated platform on top. Start native; add a platform when "what's our flake rate over time?" stops being answerable.

## Rules

- **Always emit JUnit XML**, even when you also produce a prettier HTML report. It is the one format every runner surfaces natively in the PR/MR — make it the floor, not an afterthought.
- **Capture rich artifacts for failures, not always.** Persist traces/videos/screenshots on failure or first-retry only (Playwright: `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`) to balance debuggability against artifact bloat and runtime cost.
- **Guard every upload** with `if: always()` / `if: !cancelled()` (or the runner's `when: always` / `condition: always()`) — a failed test step would otherwise skip the upload of the very artifacts you need to debug it.
- **Native-first reporting is good enough to start.** The runner's built-in widget (GitLab JUnit MR widget, Azure Tests tab, GitHub job summaries + annotations) covers per-run pass/fail with zero extra infra. Get this green and debuggable before reaching for anything else.
- **Layer a platform only when cross-run history / flake analytics become the bottleneck:**
  - **Allure Report** — open-source, framework-agnostic HTML reporter; persisting history requires CI scripting. **Allure TestOps** is the commercial layer adding centralized storage, trends, and flaky-test stability analytics.
  - **ReportPortal** — self-hosted/open-source (Docker Compose), ML-based failure clustering and a Flaky Test Cases widget tracking status flips across launches.
  - **Currents** — cloud SaaS purpose-built for Cypress/Playwright: real-time streaming, orchestration, and instant flaky badging (fail-then-pass-on-retry).
- **Dashboards/observability**: track flake rate as a metric over time (most teams investigate above ~2%); the platform above is what surfaces it. Native widgets show *this* run; the platform shows the *trend*.

## Code

```yaml
# Generic shard → JUnit + failure artifacts → native check (GitHub Actions shape)
test:
  strategy:
    fail-fast: false                 # one shard's failure must not cancel siblings
    matrix: { shard: [1, 2, 3, 4] }
  steps:
    - run: <runner> test --shard=${{ matrix.shard }}/4 --reporter=junit
    - uses: actions/upload-artifact@v4
      if: ${{ !cancelled() }}         # upload even when tests failed
      with:
        name: results-${{ matrix.shard }}   # unique name per shard (v4 requirement)
        path: |
          junit-*.xml
          test-results/                 # traces / videos / screenshots on failure
        retention-days: 7               # cap retention — these get large

report:
  needs: [test]                        # one aggregator job over all shards
  if: ${{ !cancelled() }}
  steps:
    - uses: actions/download-artifact@v4
      with: { pattern: results-*, merge-multiple: true }
    - uses: dorny/test-reporter@v1      # JUnit XML → a GitHub check + summary
      with: { name: tests, path: '**/junit-*.xml', reporter: java-junit }
```

GitLab equivalent: `artifacts: { when: always, reports: { junit: junit-$CI_NODE_INDEX.xml }, paths: [test-results/] }`. Azure: `PublishTestResults@2` with `testResultsFormat: JUnit` and `condition: always()`.

## Pitfalls

- **Only the last shard's report surviving.** v4 artifacts are immutable and require unique names — multiple matrix jobs can no longer append to one shared artifact. Name per shard (`results-${{ matrix.shard }}`) then collect with `download-artifact`'s `merge-multiple`, and run a single aggregator job; otherwise each shard overwrites or you publish just one shard's slice as "the" result.
- **Forgetting `if: always()` on the upload.** A failing test step skips subsequent steps by default, so the trace/video upload never runs — exactly when you need it.
- **Over-retaining huge artifacts.** Videos and traces are large; default 90-day retention across every shard of every PR run balloons storage and cost. Set short `retention-days` (e.g. 7) and capture media on failure/first-retry only.
- **Per-job JUnit size caps.** GitLab rejects JUnit reports over 100 MB per job; split or trim verbose output rather than letting the widget silently drop results.
- **Treating a native HTML report as history.** It is stateless — yesterday's run is gone. If you need trends or flake rate over time, that's the signal to add Allure TestOps / ReportPortal / Currents, not to script ever-more bespoke artifact archiving.
