---
name: playwright-parallel-and-sharding
description: How Playwright parallelizes — fullyParallel (file vs test as the scheduling unit), worker count, and --shard sharding across machines, plus the gotchas. Load when the automation-engineer tunes parallelism or sharding for Playwright + TypeScript tests.
---

# Playwright parallelization and sharding

Playwright speeds up a suite on two axes: workers (parallel processes on one machine) and shards (the suite split across machines). This skill covers how the scheduling unit changes, how to set worker counts, and how `--shard` composes with workers.

## Concept

Playwright runs **test files** in parallel across worker processes — each worker is an isolated OS process with its own browser. Setting `fullyParallel: true` changes the scheduling unit from *file* to *individual test*, so tests within a file also distribute across workers. **Sharding** (`--shard=1/4`) splits the whole suite across *machines*, one CI job per shard. The two compose: 4 shards × 4 workers each = 16-way parallelism.

## Rules

- Set `fullyParallel: true` for even distribution and best speed — it's also what the docs recommend pairing with sharding to keep shards balanced.
- Default workers = half the logical CPU cores. On CI **start conservative** (`workers: 1` is the docs' safe starting point; a 2-vCPU GitHub runner tops out around 2–4) and raise it while watching for flake.
- **Sharding:** `--shard=1/4 … 4/4`, one CI job per shard. Combine with workers for 2-D parallelism.
- **Worker-scoped fixtures** (`{ scope: 'worker' }`) for per-process resources. Workers can't share state or variables — each is a separate process.
- **Serial mode** (`test.describe.configure({ mode: 'serial' })`, or globally `workers: 1`) only for genuinely interdependent flows (mutating shared account data, single-tenant envs). Docs call serial "not recommended" generally — prefer isolation. If one serial test fails, the rest in that block are skipped.
- Use `--fail-on-flaky-tests` to fail the run (exit code 1) on any flaky test; by default the run exits 0 if a retry recovers.

## Code

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  fullyParallel: true,                 // scheduling unit becomes the test, not the file
  workers: process.env.CI ? 1 : undefined, // conservative on CI; default (≈half cores) locally
});
```

```ts
// serial mode — ONLY for genuinely interdependent steps
import { test } from '@playwright/test';

test.describe.configure({ mode: 'serial' });

test.describe('checkout flow on a single shared cart', () => {
  test('add item', async ({ page }) => { /* ... */ });
  test('pay (depends on previous)', async ({ page }) => { /* ... */ });
});
```

```bash
# split the suite across 4 machines — one job per shard
npx playwright test --shard=1/4
npx playwright test --shard=2/4
npx playwright test --shard=3/4
npx playwright test --shard=4/4
```

## Pitfalls

- **`beforeAll` heavy seeding runs once per worker, not once total**, under `fullyParallel` — each worker is a fresh process. Move truly-global setup to a setup project or `globalSetup`.
- **Adding workers when the bottleneck is a shared backend** just piles on concurrent load against one dependency. Mock it, or give each worker/shard its own backend.
- **`--workers=1` locally but 4 on CI** is the classic "passes locally, flakes in CI" trap — you only hit the parallel races on CI. Run locally with the CI worker count when chasing flake.

Worker isolation is what makes per-worker test data and fixtures safe — see `playwright-test-data`. The CI sharding matrix (one job per shard, blob-report merge) lives in `playwright-ci-docker`.
