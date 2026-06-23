---
name: playwright-ci-docker
description: Official Playwright Docker image, --with-deps, browser caching, exact version pinning, sharded CI. Load when the automation-engineer runs Playwright + TypeScript in CI or containers; defers generic CI/CD platform setup to the kensa-qa CI/devops skill.
---

Playwright-**specific** CI and container concerns only. The generic CI/CD platform setup — GitHub Actions / GitLab YAML scaffolding, runners, full matrix mechanics, artifact retention — lives in the separate **kensa-qa CI/devops skill**. Cross-link to it rather than re-deriving the pipeline here; this skill covers what Playwright adds on top: the image, the browser install, version sync, and the sharded blob-report flow.

## Concept

The official image `mcr.microsoft.com/playwright:vX.Y.Z-noble` ships the browsers **and** their system dependencies, but **not** the `@playwright/test` package — you still install that with `npm ci`. Browsers are native binaries built against glibc, so the base must be glibc (Ubuntu noble/jammy), never Alpine/musl. Chromium and Browserify-style sandboxing also need correct container flags (`--ipc=host`, `--init`) to avoid OOM crashes and zombie PID-1 processes. Whether you use the Docker image or a bare runner, the browser binary version must match the installed `@playwright/test` version — drift is the most common "works locally, fails in CI" cause.

## Rules

- **Use the official image, pinned to an exact version:** `mcr.microsoft.com/playwright:v1.61.0-noble` (Ubuntu 24.04; `-jammy` = 22.04). **No floating tags** — `:latest` / `:focal` / `:jammy` are no longer published, and a silent base change can flip a passing suite to flaky.
- **Alpine/musl is unsupported** — browsers require glibc. Always use a glibc base (noble/jammy).
- The image ships browsers + OS deps but **not** the Playwright package — install it with **`npm ci`** (deterministic), never `npm install`.
- **Without Docker:** run `npx playwright install --with-deps` to get browsers + OS deps in one step. Install only the browsers you actually run on CI to save time/space.
- Pass **`--ipc=host`** (Chromium OOMs/crashes otherwise) and **`--init`** (reap zombie PID-1 processes) on every `docker run`.
- Root user disables the Chromium sandbox — fine for trusted E2E. For untrusted content, run as `pwuser` with a seccomp profile.
- **Cache browser binaries** (or just use the Docker image) to avoid re-downloading ~90–180s per job.
- **Keep the browser binary in sync with `@playwright/test`** — run `npx playwright install` after every upgrade; if connecting to a remote/Docker browser server, the versions must match exactly.
- Run on **Linux** in CI (cheapest) and generate visual baselines in the **same Docker image** you run CI in, so screenshots are pixel-stable.

## Code

```bash
# Containerized run — note the two required flags
docker run --rm --ipc=host --init \
  -v "$PWD":/work -w /work \
  mcr.microsoft.com/playwright:v1.61.0-noble \
  /bin/bash -c "npm ci && npx playwright test"

# Bare runner (no Docker): browsers + OS deps in one step,
# only the browsers you run, after a deterministic install
npm ci
npx playwright install --with-deps chromium
npx playwright test
```

```yaml
# Sharded matrix SKETCH — full pipeline lives in the kensa-qa CI/devops skill.
# Each shard emits a blob report; a needs-dependent job merges them.
test:
  strategy:
    matrix: { shard: [1, 2, 3, 4] }
  steps:
    - run: npx playwright test --shard=${{ matrix.shard }}/4 --reporter=blob
    - uses: actions/upload-artifact@v4
      with: { name: blob-report-${{ matrix.shard }}, path: blob-report }

merge-reports:
  needs: [test]            # runs only after all shards finish
  steps:
    - uses: actions/download-artifact@v4   # collect every blob-report-*
    - run: npx playwright merge-reports --reporter=html ./all-blob-reports
```

## Pitfalls

- **Alpine/musl base image** — browsers won't launch (no glibc). Use noble/jammy.
- **Missing `--ipc=host`** — Chromium OOMs and crashes intermittently.
- **Missing `--init`** — zombie PID-1 / orphaned browser processes leak across jobs.
- **Floating image tags** (`:latest`/`:focal`/`:jammy`) — unpublished and/or silently mutating; a base change turns a green suite flaky. Always pin the exact `vX.Y.Z`.
- **Version drift** between the `@playwright/test` package and the Docker/browser binaries — re-run `npx playwright install` after upgrades; remote browser servers must match exactly.
