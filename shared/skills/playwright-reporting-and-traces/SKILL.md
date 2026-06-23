---
name: playwright-reporting-and-traces
description: HTML/blob/merge reporting, the Trace Viewer time-travel debugger, and screenshot/video artifacts. Load when the automation-engineer configures reporting or debugs failures in Playwright + TypeScript.
---

When a test fails, the report and trace are how you find out *why* without re-running locally. Configure them once so every failure ships a time-travel trace and trimmed media — and so sharded CI runs don't silently throw away all but one shard's report.

## Concept

Playwright ships a built-in **HTML reporter** plus a **Trace Viewer**: time-travel debugging with per-action DOM snapshots, network, and console. The **blob reporter** (v1.37+) exists specifically to be merged across shards — each shard emits a `blob-report/`, and a dependent job merges them into one HTML report. Traces, screenshots, and videos are artifacts attached per test; traces process entirely locally — nothing is uploaded.

## Rules

- **Local: `reporter: 'html'`. CI (sharded): `reporter: 'blob'`, then merge.** A single HTML report on CI only survives from the last shard otherwise.
- Merge blobs with `npx playwright merge-reports --reporter html ./all-blob-reports` (also `json` / `junit`). Each shard uploads its `blob-report/` as a CI artifact; a dependent merge job downloads all of them and merges.
- **Trace: `'on-first-retry'`** (the CI default) — captures a trace exactly when a test fails-then-passes, with near-zero overhead on green runs.
- Open a trace with `npx playwright show-trace trace.zip`, drag-drop the zip onto `trace.playwright.dev`, or `npx playwright show-trace <url>` (mind CORS for remote URLs). Traces process locally.
- Keep media small: **`screenshot: 'only-on-failure'`**, **`video: 'retain-on-failure'`**.
- Attach arbitrary data (logs, API payloads, computed diffs) to a test via `testInfo.attach()`; it shows up in the HTML report and trace.
- Keep individual traces under ~20 MB by splitting mega-tests — huge traces are slow to load and to upload.
- Recent releases help triage: a **"Copy prompt"** button on errors in the HTML report / trace viewer / UI mode pre-fills an LLM fixing prompt; a failed `expect()` attaches the accessibility snapshot of the target element; and **CLI trace analysis (`npx playwright trace`, Playwright 1.59)** lets coding agents explore a trace and understand failing/flaky tests from the command line.

## Code

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Local: rich HTML report. CI (sharded): blob, merged in a later job.
  reporter: process.env.CI ? 'blob' : 'html',
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  retries: process.env.CI ? 2 : 0,
});
```

```ts
// Attach context to a test for the report / trace
test('checkout', async ({ page }, testInfo) => {
  const body = await (await page.request.get('/api/cart')).text();
  await testInfo.attach('cart-response', { body, contentType: 'application/json' });
});
```

```bash
# Merge per-shard blobs into one HTML report (downloaded from all shard jobs)
npx playwright merge-reports --reporter html ./all-blob-reports

# Open a trace locally (time-travel viewer)
npx playwright show-trace trace.zip

# Explore a trace from the CLI (Playwright 1.59+) — agent-friendly failure analysis
npx playwright trace trace.zip
```

## Pitfalls

- **`trace: 'on'` everywhere** → 10–25% slower runs and huge artifacts. Use `'on-first-retry'`; reserve `'on'` for targeted local debugging.
- **Forgetting `reporter: 'blob'` for sharded runs** → only the last shard's report survives; you lose every other shard's results. Blob + merge is mandatory once you shard.
- Skipping the merge job — uploaded `blob-report/` artifacts are not viewable on their own; they must be merged into HTML/json/junit.
- Oversized traces from mega-tests (>20 MB) — slow to load and upload; split the test.

## See also

- `playwright-parallel-and-sharding` — blob + merge is the reporting half of sharding; pair them.
- `playwright-ci-docker` — wiring the shard upload + dependent merge job into the pipeline.
