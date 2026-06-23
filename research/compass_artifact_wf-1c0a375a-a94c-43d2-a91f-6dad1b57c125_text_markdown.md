# Skill: Playwright + TypeScript E2E Testing (Best Practices)

> **Skill type:** Framework/language knowledge for the `automation-engineer` agent (kensa-qa).
> **Load when:** writing, refactoring, or reviewing Playwright + TypeScript E2E tests.
> **Current as of:** June 2026. Pin to Playwright **1.61.0** (released June 15, 2026), which bundles Chromium 149.0.7827.55, Firefox 151.0, and WebKit 26.5, and adds the WebAuthn virtual authenticator (`browserContext.credentials`), the WebStorage API (`page.localStorage`/`page.sessionStorage`), and Ubuntu 26.04 support. Node.js **22.x, 24.x, or 26.x** (Node 18 was deprecated in 1.54). Canonical package is **`@playwright/test`** (the Test runner), not `playwright` (the Library).

---

## TL;DR
- In 2025–2026 the Playwright/TS consensus is: **role-based locators + web-first auto-retrying assertions + page-objects-exposed-as-fixtures + storageState auth via a setup project**, run `fullyParallel` and sharded in CI behind the official Docker image with blob+merge reporting. This is the spine of every idiomatic suite.
- The single biggest flake-reducer is *not configuration* — it is **never using point-in-time checks (`isVisible()`, `textContent()`) or hard `waitForTimeout()`**, and instead letting `expect(locator)` matchers auto-wait. Retries and `trace: 'on-first-retry'` are for diagnosing residual flake, not masking it.
- Plugin-wise, this should ship as one `playwright-typescript` skill plus tightly-scoped sub-skills (locators, auth/storageState, fixtures+POM, parallel/sharding, visual+a11y, CI/Docker) that the `automation-engineer` loads on demand.

---

## 1. Project structure & `playwright.config.ts`

### Concept
Scaffold from zero with `npm init playwright@latest`, which installs `@playwright/test`, creates `playwright.config.ts`, a `tests/` directory, example specs, and optionally a GitHub Actions workflow. It downloads Chromium, Firefox, and WebKit binaries.

### Rules
- Use `@playwright/test` (Test runner) — do **not** install `playwright` (Library) alongside it; `npx playwright test` breaks if both are installed. Import automation APIs (`chromium`, etc.) directly from `@playwright/test` if needed.
- Keep a dedicated `tests/tsconfig.json` — Playwright only honors `allowJs`, `baseUrl`, `paths`, and `references` from tsconfig, and auto-discovers the nearest `tsconfig.json`/`jsconfig.json` per file.
- Set `baseURL` so specs use relative URLs (`page.goto('./login')`).
- Use `forbidOnly: !!process.env.CI` to fail the build if a stray `test.only` is committed.
- Tracing: `trace: 'on-first-retry'` (the official recommendation — `'on'` is performance-heavy). Use `'retain-on-failure'` if you don't enable retries, or the `retain-on-failure-and-retries` trace mode (added in Playwright 1.59, shipped April 1, 2026) for flake forensics — it keeps both the failing and the eventually-passing attempt to compare.
- `webServer` owns process startup + readiness ONLY — don't hide DB seeding/migrations in the start command. Set `reuseExistingServer: !process.env.CI`. Pick an honest readiness URL (one that 2xx/3xx/400/401/402/403s only when the app is truly ready). Consider increasing `timeout` (e.g. `120 * 1000`).
- Recommended directory layout:
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

### Canonical config
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

### Pitfalls
- Installing both `playwright` and `@playwright/test`.
- Hiding seed logic in `webServer.command`; using a shallow `/health` that lies about readiness.
- Forgetting `reuseExistingServer: !process.env.CI` → CI tries to reuse and times out, or local dev double-starts.

---

## 2. Design patterns: POM vs fixtures vs Screenplay

### Concept
Three approaches exist. The 2025–2026 ecosystem consensus: **combine the Page Object Model with Playwright's fixture system** — write POM classes for page logic, then expose them as custom fixtures via `test.extend` so tests receive ready-to-use, auto-instantiated page objects.

### Rules
- **Default (recommended):** POM-as-fixtures. POMs encapsulate page locators/actions; fixtures handle instantiation + setup/teardown so tests don't do `new LoginPage(page)` repeatedly. The Playwright docs themselves demonstrate page objects as fixtures.
- Do **not** instantiate POMs inside the test body; get them through fixtures. This keeps setup in one place and is the "Playwright-native" way (you extend the framework rather than importing modules ad hoc).
- **Plain POM (no fixtures)** is acceptable for very small suites — but boilerplate compounds as the suite grows.
- **Screenplay pattern** (via Serenity/JS — `@serenity-js/playwright-test`, `@serenity-js/web`, etc.): a user-centric Actors/Abilities/Tasks/Questions model with composition over inheritance and rich BDD reporting. It's a legitimate choice for large orgs wanting business-readable, tool-agnostic scenarios and living documentation, but it's a heavier abstraction and a smaller ecosystem. **Recommendation for kensa-qa's `automation-engineer`: default to POM-as-fixtures; only reach for Screenplay when the project already uses Serenity/JS or explicitly wants BDD/living docs.**
- Keep POMs free of assertions where possible (return locators/values; assert in specs), though small "expect the page is ready" helpers are fine.

### Code: POM-as-fixture
```ts
// pages/login-page.ts
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly email: Locator;
  readonly password: Locator;
  readonly submit: Locator;

  constructor(page: Page) {
    this.page = page;
    this.email = page.getByLabel('Email');
    this.password = page.getByLabel('Password');
    this.submit = page.getByRole('button', { name: 'Sign in' });
  }

  async goto() { await this.page.goto('./login'); }
  async login(email: string, pw: string) {
    await this.email.fill(email);
    await this.password.fill(pw);
    await this.submit.click();
  }
}
```
```ts
// fixtures/base.ts
import { test as base, expect } from '@playwright/test';
import { LoginPage } from '../pages/login-page';
import { DashboardPage } from '../pages/dashboard-page';

type Fixtures = { loginPage: LoginPage; dashboardPage: DashboardPage };

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => { await use(new LoginPage(page)); },
  dashboardPage: async ({ page }, use) => { await use(new DashboardPage(page)); },
});
export { expect };
```
```ts
// tests/auth/login.spec.ts
import { test, expect } from '../../fixtures/base';

test('user can sign in', async ({ loginPage, dashboardPage }) => {
  await loginPage.goto();
  await loginPage.login('user@example.com', 'secret');
  await expect(dashboardPage.heading).toBeVisible();
});
```

### Pitfalls
- POMs that re-fetch elements with brittle CSS instead of storing `Locator`s built from role/label.
- Over-abstracting tiny suites into Screenplay before there's a need.
- Putting heavy assertions deep in POMs, making failures hard to read.

---

## 3. Locator strategy

### Concept
A locator is a *description* re-resolved on every action (unlike a stale element handle) — this is the foundation of auto-waiting. Prefer user-facing, accessibility-aligned locators.

### Rules — recommended priority order
1. **`getByRole(role, { name })`** — the recommended default; mirrors how users + assistive tech perceive the page; resilient to DOM churn. Always pass the accessible `name`.
2. **`getByLabel`** — form fields.
3. **`getByPlaceholder` / `getByText` / `getByTitle`** — user-visible content.
4. **`getByTestId`** — for non-accessible/ambiguous/dev-only elements. Default attribute is `data-testid`; configure via `use: { testIdAttribute: 'data-pw' }`. It's stable and refactor-proof but bypasses accessibility coverage, so use sparingly.
5. **CSS / XPath via `page.locator()`** — last resort; brittle against DOM structure changes.
- **Avoid:** CSS class chains (`button.buttonIcon.episode-actions-later`), `nth-child`, deep XPath, and the removed `_react`/`_vue`/`:light` engines (removed in v1.58 — migrate to user-facing locators or standard CSS).
- **Chain + filter** to scope: `page.getByRole('listitem').filter({ hasText: 'Product 2' }).getByRole('button', { name: 'Add to cart' })`.
- Tooling: `codegen` (`npx playwright codegen <url>`); `page.pickLocator()` (added in Playwright 1.59) which per the release notes "enters an interactive mode where hovering over elements highlights them and shows the corresponding locator. Click an element to get its Locator back."; and `locator.normalize()` (added in 1.59) which "converts a locator to follow best practices like test ids and aria roles." Always review generated output.
- Use `locator.describe()` (v1.57) to label locators for the trace viewer.

### Code
```ts
await page.getByRole('textbox', { name: 'Email' }).fill('a@b.com');
await page.getByLabel('Password').fill('secret');
await page.getByRole('button', { name: 'Sign in' }).click();
await expect(page.getByText('Welcome back')).toBeVisible();
// scoped:
await page.getByRole('article', { name: 'Super Widget' })
          .getByRole('button', { name: 'Add to Cart' }).click();
```

### Pitfalls
- `getByRole('button')` with no name (matches every button → strict-mode violation).
- Using role locators for icon-only/dynamic-text elements — fall back to testid there.
- `locator.all()` on a dynamically-changing list (returns whatever is present immediately → flaky); wait for the list to stabilize first.

---

## 4. Waiting / synchronization (anti-flake core)

### Concept
Playwright auto-waits: before any action (`click`, `fill`, `check`, …) it runs actionability checks (visible, stable, enabled, receives events). Web-first assertions (`expect(locator).…`) auto-retry until the condition holds or the timeout expires.

### Rules
- **Use web-first assertions** — `toBeVisible()`, `toHaveText()`, `toHaveValue()`, `toBeEnabled()`, `toHaveURL()`, etc. They poll automatically (default assertion timeout 5s).
- **Never** put point-in-time queries inside assertions: `expect(await locator.isVisible()).toBe(true)` and `textContent()` do **not** retry → race conditions. Use `await expect(locator).toBeVisible()`.
- **Never** use `page.waitForTimeout(ms)` in committed tests ("Never wait for timeout in production"). It's debugging-only.
- Avoid manual `waitForSelector` when an assertion already waits — `await expect(locator).toBeVisible()` replaces `await page.waitForSelector(...)` + check.
- For non-DOM/eventual conditions use **`expect.poll()`** (poll a function until a matcher passes) or **`expect.toPass()`** (retry a whole block). Tune `intervals` (default `[100, 250, 500, 1000]`) and `timeout`.
- Improve **locator precision first** before reaching for `poll`/`toPass`; most "flaky assertion" problems are actually ambiguous locators or a missing `await`.
- Legitimate explicit waits exist: `locator.waitFor({ state })`, `page.waitForResponse(pattern)`, `page.waitForURL()` — use when you need a signal Playwright can't infer from the action itself.
- Enforce `@typescript-eslint/no-floating-promises` to catch missing `await`s before Playwright calls.

### Code
```ts
// ✅ auto-retrying
await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

// ✅ eventual backend state
await expect.poll(async () => {
  const res = await page.request.get('/api/job/123');
  return (await res.json()).state;
}, { timeout: 15_000, message: 'job should complete' }).toBe('completed');

// ✅ retry a flaky open/close interaction
await expect(async () => {
  await page.getByRole('button', { name: 'Toolbar 1' }).click();
  await page.locator('#modal1').getByText('Close').click();
}).toPass();
```

### Pitfalls
- Mixing `await` placement: `await expect(...)` (correct) vs `expect(await ...)` (no retry).
- Asserting on text with `textContent()` then `expect(...).toBe(...)`.
- Reaching for `toPass`/`poll` to paper over a bad locator.

---

## 5. Test data, setup/teardown, isolation

### Concept
Each test gets an isolated `BrowserContext` (fresh cookies/storage) automatically. Prefer fixtures over `beforeEach`/`afterEach` for reusable setup because fixtures co-locate setup+teardown and are composable/type-safe.

### Rules
- **Auth:** use `storageState` + a **setup project** (see §1 config and the canonical example). Log in once, save cookies/localStorage/IndexedDB (IndexedDB via the `indexedDB` option, useful for Firebase-style token storage) to `playwright/.auth/*.json`, reuse everywhere. Keep `playwright/.auth` out of source control. Delete state when it expires.
- Project dependencies are preferred over `globalSetup`/`globalTeardown` because they integrate with the runner: HTML report includes setup, traces are recorded, fixtures work.
- **Seed via API**, not UI — use the `request` fixture (Playwright's `APIRequestContext`, honors `baseURL`/`extraHTTPHeaders`) to create/reset data and verify backend side-effects. Combine API seeding + UI verification in one test for realistic, atomic scenarios.
- **Factories / data-factory** helpers for generating unique entities; prefer generated data over shared static data so parallel tests don't collide.
- **Isolation:** make tests independent. For per-worker resources (DB users, tenants) use **worker-scoped fixtures** keyed on `testInfo.workerIndex` / `parallelIndex`, or timestamp/uuid-based unique data.
- Multi-role: one setup test per role writing separate state files; map projects to roles. For modify-shared-state suites, authenticate once per worker with a unique account each.

### Code
```ts
// worker-scoped unique DB user
export const test = base.extend<{}, { dbUserName: string }>({
  dbUserName: [async ({}, use) => {
    const name = `user-${test.info().workerIndex}`;
    // await createUserInTestDatabase(name);
    await use(name);
    // await deleteUserFromTestDatabase(name);
  }, { scope: 'worker' }],
});
```

### Pitfalls
- Logging in through the UI in every test (largest avoidable slowdown).
- Committing `.auth` JSON (contains live session/secrets).
- Shared mutable test data across parallel workers → race conditions.
- Note: `storageState` does **not** persist sessionStorage by default in older flows and service-worker/IndexedDB nuances exist — verify what your app stores auth in.

---

## 6. Parallelization & sharding

### Concept
Playwright runs **test files** in parallel across worker processes (each an isolated OS process with its own browser). `fullyParallel: true` changes the scheduling unit from *file* to *individual test*. Sharding splits the suite across *machines*.

### Rules
- Set `fullyParallel: true` for even distribution and best speed (and it's what the docs recommend to pair with sharding for balanced shards).
- Default workers = half the logical CPU cores. On CI start conservative (`workers: 1` is the docs' safe starting point; 2 vCPU GitHub runners → 2–4 max) and increase while watching for flake.
- **Sharding:** `--shard=1/4 … 4/4`, one CI job per shard. Combine with workers for 2-D parallelism (4 shards × 4 workers = 16-way).
- **Worker-scoped fixtures** (`{ scope: 'worker' }`) for per-process resources; remember workers can't share state/variables.
- **Serial mode** (`test.describe.configure({ mode: 'serial' })` or `workers: 1`) only for genuinely interdependent flows (mutating shared account data, single-tenant envs). Docs: serial is "not recommended" generally — prefer isolation. If a serial test fails, subsequent ones are skipped.
- `--fail-on-flaky-tests` (recent) sets exit code 1 on any flaky test (default exit is 0 if a retry recovers).

### Pitfalls
- `beforeAll` doing expensive seeding runs **once per worker** under `fullyParallel`, not once total — move truly-global setup to a setup project/`globalSetup`.
- Adding workers when the bottleneck is a shared backend → just increases concurrent load; mock or give each worker/shard its own backend.
- Running `--workers=1` locally but 4 on CI → "passes locally, flakes in CI."

---

## 7. Reporting, traces, artifacts

### Concept
Built-in HTML reporter + Trace Viewer (time-travel debugging: DOM snapshots, network, console per action) + screenshots/video. Blob reporter exists specifically to be merged across shards (introduced v1.37).

### Rules
- Local: `reporter: 'html'`; CI: `reporter: 'blob'` then merge.
- `npx playwright merge-reports --reporter html ./all-blob-reports` (or `json`/`junit`) combines per-shard blobs into one report. Each shard uploads its `blob-report/` as a CI artifact; a dependent merge job downloads all and merges.
- Trace: `'on-first-retry'` (CI default); open with `npx playwright show-trace trace.zip`, drag-drop onto `trace.playwright.dev`, or `npx playwright show-trace <url>` (mind CORS). Traces process locally — nothing is uploaded.
- `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'` keep artifacts small.
- Attach arbitrary data via `testInfo.attach()`. Keep individual traces under ~20 MB by splitting mega-tests.
- New (recent releases): "Copy prompt" button on errors in HTML report/trace viewer/UI mode (pre-fills an LLM fixing prompt); failed `expect()` attaches the accessibility snapshot of the target element; CLI trace analysis (`npx playwright trace`, introduced in Playwright 1.59) lets coding agents "explore Playwright Trace and understand failing or flaky tests from the command line."

### Pitfalls
- `trace: 'on'` everywhere → 10–25% slower, huge artifacts.
- Forgetting to set `reporter: 'blob'` for sharded runs → only the last shard's report survives.

---

## 8. Retries & soft assertions

### Rules
- `retries: process.env.CI ? 2 : 0`. Retries + `trace: 'on-first-retry'` capture a trace exactly when a test fails-then-passes.
- **Retries diagnose flake; they must not be a permanent mask.** Use `--fail-on-flaky-tests` in quality gates so silently-recovered flakes still surface. Fix the root cause (locator/wait) rather than bumping retries.
- **`expect.soft(...)`** accumulates failures without aborting the test — use for independent checks on one page (status + ETA + heading) so one run reports all mismatches. Combine with `expect.configure({ soft: true })` or `expect.soft.poll(...)`.
- Use a hard assertion (default) when later steps are meaningless if it fails; use soft when you want a complete picture of one screen.
- `expect.configure({ timeout })` for a pre-tuned slow `expect`.

### Code
```ts
await expect.soft(page.getByTestId('status')).toHaveText('Success');
await expect.soft(page.getByTestId('eta')).toHaveText('1 day');
await page.getByRole('link', { name: 'next page' }).click();
```

### Pitfalls
- Treating a high retry count as "fixed" — it hides real, user-facing flakiness.
- Soft assertions for preconditions (test proceeds in a broken state).

---

## 9. CI specifics unique to Playwright/TS
*(General CI/CD platform setup is deferred to a separate skill; this covers only Playwright-specific concerns.)*

### Rules
- **Official Docker image:** `mcr.microsoft.com/playwright:v1.61.0-noble` (Ubuntu 24.04; also `-jammy` = 22.04). Pin the exact version — `:latest`/`:focal`/`:jammy` floating tags are no longer published; a silent base change can flip a passing suite to flaky. The image ships browsers + system deps but **not** the Playwright package — install it via `npm ci`. **Alpine/musl is unsupported** (browsers need glibc).
- Use `--ipc=host` (Chromium OOM/crash otherwise) and `--init` (avoid zombie PID-1 processes). Root user disables Chromium sandbox (fine for trusted E2E); for untrusted content use `pwuser` + seccomp profile.
- **Without Docker:** `npx playwright install --with-deps` installs browsers + OS deps in one step. Install only needed browsers on CI to save time/space.
- Use `npm ci` (deterministic) not `npm install`. Cache browser binaries / use the Docker image to avoid re-downloading (~90–180s per job).
- Keep browser binary version in sync with the `@playwright/test` version (run `npx playwright install` after upgrades; if connecting to a remote/Docker server, versions must match).
- Sharding in CI: matrix job runs `--shard=${i}/${n}` with `reporter: 'blob'`, uploads `blob-report`, then a `needs:`-dependent job merges. (Full GH Actions YAML lives in the CI skill.)
- Use Linux on CI (cheapest); generate visual baselines in the same Docker image you run CI in.

### Pitfalls
- Alpine base image; missing `--ipc=host`; floating image tags.
- Version drift between test package and Docker/browser binaries.

---

## 10. Accessibility & visual testing

### Accessibility (`@axe-core/playwright`, latest 4.11.3)
- Install `@axe-core/playwright` (Deque's official integration). Note it **does not follow SemVer** — per the npm page it "uses the major and minor version of axe-core that the package uses" (currently axe-core v4.11.x), so `4.11.3` tracks axe-core 4.11.x. Import `AxeBuilder`, navigate, `analyze()`, assert no violations.
- Scope with `.include()`/`.exclude()`; constrain rules with `.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa'])`; suppress known issues with `.disableRules()`.
- For interaction-revealed UI, interact (and `waitFor` the state) **before** `analyze()`.
- Share config via a fixture (`axeBuilder` fixture pre-tagged) across tests.
- Automated scans catch only a subset of WCAG issues — combine with manual testing. Complement with `toMatchAriaSnapshot()` (locks accessibility-tree structure; catches reading-order/landmark issues axe won't).
```ts
import AxeBuilder from '@axe-core/playwright';
test('home page has no detectable a11y violations', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

### Visual (`toHaveScreenshot()`)
- `await expect(page).toHaveScreenshot('name.png')` — first run writes the golden image; later runs diff pixel-by-pixel (pixelmatch). Use `toHaveScreenshot()` (auto-retries until stable) over `toMatchSnapshot()` (no retry, flaky) for screenshots.
- Snapshot files are suffixed `<name>-<project>-<platform>.png` (e.g. `-chromium-linux`). **Rendering differs by OS/arch/browser** → generate baselines in the **same environment** as CI (the official Docker image). This is the #1 cause of "passes locally, fails in CI" for visual tests.
- Update workflow: `npx playwright test --update-snapshots` (optionally `--grep "name"`); review PNG diffs in the PR. Commit baselines to git.
- Stabilize: `animations: 'disabled'`, `mask: [locator,…]` for dynamic content (timestamps/avatars/ads), or `stylePath` CSS to hide volatile elements. Tune `maxDiffPixels` / `maxDiffPixelRatio` / `threshold` (per-component, not one global value). Prefer component/element screenshots over full-page for precision.
- `snapshotPathTemplate` + the `{testFileBaseName}` token (added v1.60) keep snapshot folders readable.
- Set an explicit `updateSnapshots` policy (e.g. `'missing'` locally, `'none'` in CI) to control regeneration; in CI, generate-and-PR new baselines rather than silently overwriting.

### Pitfalls
- Generating baselines locally (macOS/Windows) then failing on Linux CI.
- One global threshold for all screenshots; not masking dynamic content; not disabling animations.
- Treating axe `violations.length === 0` as full WCAG compliance.

---

## 11. Top pitfalls (quick list) & references

### Top pitfalls
1. Point-in-time checks in assertions (`isVisible()`, `textContent()`) — no retry → flake.
2. `waitForTimeout()` hard waits.
3. Brittle locators (CSS class chains, `nth-child`, XPath) instead of role/label/testid.
4. `getByRole` without an accessible `name`.
5. UI login in every test instead of `storageState` + setup project.
6. Committing `playwright/.auth` secrets.
7. Shared mutable data across parallel workers (no `workerIndex` isolation).
8. `beforeAll` heavy seeding under `fullyParallel` (runs per worker).
9. Visual baselines generated outside the CI environment.
10. Retries/`toPass`/`poll` used to mask a bad locator instead of fixing it.
11. Installing both `playwright` and `@playwright/test`.
12. Floating Docker tags / version drift between package and browser binaries.
13. Missing `--ipc=host`/`--init` in Docker (Chromium crashes, zombies).
14. `trace: 'on'` everywhere (slow, huge artifacts).
15. Missing `await` on `expect`/actions (add `@typescript-eslint/no-floating-promises`).

### Curated references (authoritative)
- **Official docs (playwright.dev):** Best Practices, Locators, Auto-waiting (Actionability), Assertions, Fixtures, Auth, Global setup & teardown, Parallelism, Sharding, Trace Viewer, Reporters, Retries, Visual comparisons, Accessibility testing, Docker, API testing, Page object models.
- **Playwright GitHub** (`microsoft/playwright`) — releases/release notes; `docs/src/auth.md`.
- **Docker Hub / MCR:** `mcr.microsoft.com/playwright`.
- **`@axe-core/playwright`** (Deque) — official a11y integration.
- **Serenity/JS** (`serenity-js.org`, `@serenity-js/playwright-test`) — Screenplay pattern.
- **Community exemplars:** Checkly blog (POM+fixtures), `vasu31dev/playwright-ts` (framework template), `playwrightsolutions.com` (API data factories).

> **Flux / likely-to-change flags:** (a) Playwright ships ~monthly; pin versions and re-verify the Docker tag, browser bundle, and Node support each upgrade. (b) The 1.56–1.61 line is heavily "agentic" (Playwright Agents: planner/generator/healer; MCP; CLI trace/debug) — expect AI-assisted authoring/healing features to keep evolving; treat them as additive, not load-bearing for stable suites. (c) `@axe-core/playwright` versioning tracks axe-core, not SemVer — pin and bump deliberately. (d) `storageState` sessionStorage/IndexedDB persistence behavior has changed across releases (IndexedDB option is recent) — verify against your auth storage mechanism.

---

## How this maps to the plugin

This knowledge should ship as a **`playwright-typescript` skill** for the `automation-engineer` agent, decomposed into focused sub-skills (each ≈ one concept, loaded on demand):

**Skills / agent-knowledge files**
- `playwright-typescript` (index/overview skill — the canonical config, version pins, and links to sub-skills; loaded whenever the agent detects a Playwright+TS project).
- `playwright-locators` — locator priority, `getByRole` patterns, testid config, anti-patterns.
- `playwright-fixtures-and-pom` — POM-as-fixtures, `test.extend`, worker vs test scope; Screenplay as an alternative note.
- `playwright-waiting-and-assertions` — auto-wait, web-first assertions, `expect.poll`/`toPass`, soft assertions, anti-flake idioms.
- `playwright-auth-storagestate` — setup project + `storageState`, multi-role, API login.
- `playwright-test-data` — API seeding via `request`, data factories, isolation.
- `playwright-parallel-and-sharding` — `fullyParallel`, workers, `--shard`, serial mode.
- `playwright-reporting-and-traces` — HTML/blob/merge, trace viewer, artifacts.
- `playwright-ci-docker` — official image, `--with-deps`, caching, sharded CI (cross-links the generic CI/CD skill).
- `playwright-visual-and-a11y` — `toHaveScreenshot()` workflow + `@axe-core/playwright`.

**Slash commands**
- `/kensa-scaffold-playwright` — run `npm init playwright@latest` equivalent + drop in the canonical config, `fixtures/base.ts`, `*.setup.ts`, and `tests/` layout.
- `/kensa-add-page-object <name>` — generate a POM class + register it as a fixture in `fixtures/base.ts`.
- `/kensa-add-auth-setup` — generate `auth.setup.ts` + wire the setup project + `storageState` into config.
- `/kensa-add-visual-test <url|component>` and `/kensa-add-a11y-test <url>` — scaffold a `toHaveScreenshot()` / `AxeBuilder` spec.
- `/kensa-fix-flake <spec>` — analyze a spec for the top flake pitfalls (hard waits, point-in-time checks, brittle locators) and rewrite using web-first assertions.

**Agent referencing convention:** the `automation-engineer` loads `playwright-typescript` first (gets versions + canonical config), then pulls the specific sub-skill for the task at hand (e.g. `playwright-auth-storagestate` when writing login flows). Keep each sub-skill self-contained with `concept → rules → code → pitfalls` so the agent can load exactly one concept's worth of context.