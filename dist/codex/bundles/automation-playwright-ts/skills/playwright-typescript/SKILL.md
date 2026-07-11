---
name: playwright-typescript
description: Version pins (Playwright 1.61.0, Node 22/24/26, @playwright/test) plus the canonical playwright.config.ts and scaffold-from-zero steps. Load this first when the automation-engineer writes or refactors Playwright + TypeScript E2E tests; then load the focused sibling sub-skill for the task at hand.
---

# Playwright + TypeScript E2E Testing

Framework/language reference for the `automation-engineer` agent. This is the index skill: load it first whenever a Playwright + TypeScript project is detected. It carries the version pins and the canonical config, then routes you to a tightly-scoped sibling sub-skill for the specific task.

The 2025–2026 Playwright/TS consensus is: **role-based locators + web-first auto-retrying assertions + page-objects-exposed-as-fixtures + storageState auth via a setup project**, run `fullyParallel` and sharded in CI behind the official Docker image with blob+merge reporting. The single biggest flake-reducer is *not configuration* — it is never using point-in-time checks (`isVisible()`, `textContent()`) or hard `waitForTimeout()`, and instead letting `expect(locator)` matchers auto-wait. Retries and `trace: 'on-first-retry'` are for diagnosing residual flake, not masking it.

## Version pins

- Pin to Playwright **1.61.0** (bundles Chromium 149.0.7827.55, Firefox 151.0, WebKit 26.5) — or the latest stable at scaffold time; whichever you pick, pin it exactly and keep the Docker image tag in sync (see `playwright-ci-docker`).
- 1.61.0 adds the WebAuthn virtual authenticator (`browserContext.credentials`), the WebStorage API (`page.localStorage` / `page.sessionStorage`), and Ubuntu 26.04 support.
- Node.js **22.x, 24.x, or 26.x** (Node 18 was deprecated in 1.54).
- Canonical package is **`@playwright/test`** (the Test runner), **not** `playwright` (the Library). Import automation APIs (`chromium`, etc.) directly from `@playwright/test` if needed.

## Scaffold from zero

- Scaffold with `npm init playwright@latest`, which installs `@playwright/test`, creates `playwright.config.ts`, a `tests/` directory, example specs, and optionally a GitHub Actions workflow. It downloads Chromium, Firefox, and WebKit binaries.
- Use `@playwright/test` (Test runner) — do **not** install `playwright` (Library) alongside it; `npx playwright test` breaks if both are installed.
- Keep a dedicated `tests/tsconfig.json` — Playwright only honors `allowJs`, `baseUrl`, `paths`, and `references` from tsconfig, and auto-discovers the nearest `tsconfig.json` / `jsconfig.json` per file.
- Set `baseURL` so specs use relative URLs (`page.goto('./login')`).
- Use `forbidOnly: !!process.env.CI` to fail the build if a stray `test.only` is committed.
- Tracing: `trace: 'on-first-retry'` (the official recommendation — `'on'` is performance-heavy). Use `'retain-on-failure'` if you don't enable retries, or the `retain-on-failure-and-retries` trace mode (added in 1.59, shipped April 1, 2026) for flake forensics — it keeps both the failing and the eventually-passing attempt to compare.
- `webServer` owns process startup + readiness ONLY — don't hide DB seeding/migrations in the start command. Set `reuseExistingServer: !process.env.CI`. Pick an honest readiness URL (one that only succeeds when the app is truly ready). Consider increasing `timeout` (e.g. `120 * 1000`).

Recommended directory layout:

```
tests/
  <feature>/<feature>.spec.ts   # specs grouped by feature/domain
  *.setup.ts                     # auth / data setup projects
fixtures/  (or e2e/fixtures)     # custom test.extend fixtures, base test
pages/     (or pom/)             # page object classes
utils/                           # helpers (data factories, etc.)
playwright.config.ts
tsconfig.json
```

## Canonical playwright.config.ts

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,    // start conservative on CI; tune up
  reporter: process.env.CI ? 'blob' : 'html', // blob is mergeable across shards
  use: {
    baseURL: process.env.BASE_URL ?? 'http://127.0.0.1:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    testIdAttribute: 'data-testid', // default; override e.g. 'data-pw' / 'data-qa'
  },
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    { name: 'chromium', use: { ...devices['Desktop Chrome'], storageState: 'playwright/.auth/user.json' }, dependencies: ['setup'] },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'], storageState: 'playwright/.auth/user.json' }, dependencies: ['setup'] },
    { name: 'webkit',   use: { ...devices['Desktop Safari'],  storageState: 'playwright/.auth/user.json' }, dependencies: ['setup'] },
  ],
  webServer: {
    command: 'npm run start',
    url: 'http://127.0.0.1:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
```

## Sub-skills

Load the focused sibling for the task:

- **playwright-locators** — choosing and chaining locators; role-based, `getByTestId`, filtering, avoiding brittle selectors.
- **playwright-fixtures-and-pom** — `test.extend` custom fixtures and page objects exposed as fixtures.
- **playwright-waiting-and-assertions** — web-first auto-retrying assertions; eliminating `waitForTimeout`/point-in-time checks.
- **playwright-auth-storagestate** — authentication via a `*.setup.ts` project and `storageState` reuse.
- **playwright-test-data** — data factories, fixtures-as-data, seeding and cleanup strategies.
- **playwright-parallel-and-sharding** — `fullyParallel`, workers, and sharding across CI machines.
- **playwright-reporting-and-traces** — blob + merge reporting, traces, screenshots, video for diagnosis.
- **playwright-ci-docker** — running behind the official Docker image and wiring up CI.
- **playwright-visual-and-a11y** — visual/snapshot testing and accessibility checks.

## Pitfalls

- Installing both `playwright` and `@playwright/test`.
- Hiding seed logic in `webServer.command`; using a shallow `/health` that lies about readiness.
- Forgetting `reuseExistingServer: !process.env.CI` → CI tries to reuse and times out, or local dev double-starts.
