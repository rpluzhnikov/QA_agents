---
name: playwright-auth-storagestate
description: storageState + a setup project for log-in-once auth reuse in Playwright + TypeScript — log in one time, save cookies/localStorage/IndexedDB, reuse across projects, plus multi-role and API-login variants. Load when the automation-engineer writes authentication for Playwright tests.
---

# Playwright auth with storageState

Authenticating through the UI in every test is the single largest avoidable slowdown in a Playwright suite. The fix: log in **once**, persist the browser session to a JSON file, and have every other test start already-authenticated. Playwright wires this together with `storageState` plus a dedicated **setup project** that other projects depend on.

## Concept

Each test gets an isolated `BrowserContext` with fresh cookies/storage. `storageState` lets you snapshot a logged-in context (cookies + `localStorage`, and optionally IndexedDB) to a file and replay it into new contexts. A **setup project** (a normal test matched by `*.setup.ts`) performs the login once and writes that file; the real browser projects declare `dependencies: ['setup']` and point `use.storageState` at the saved file, so they run only after auth exists and start signed in.

Prefer a setup project over `globalSetup`: it integrates with the runner — it appears in the HTML report, records traces, and can use fixtures — whereas `globalSetup` runs outside all of that.

## Rules

- **Log in once, reuse everywhere.** A setup test signs in, then `page.context().storageState({ path })` saves the session to `playwright/.auth/*.json`. Browser projects load it via `use: { storageState }`.
- **Use a setup project, not `globalSetup`/`globalTeardown`.** Project dependencies integrate with the runner (report, traces, fixtures); `globalSetup` does not.
- **`dependencies: ['setup']`** makes the setup project a prerequisite — it runs first, and only once, before the dependent projects.
- **Keep `playwright/.auth` out of source control** — the JSON contains live session cookies/tokens. Add it to `.gitignore`. Delete/refresh the state when it expires.
- **IndexedDB:** for apps that store auth tokens in IndexedDB (Firebase-style), pass `indexedDB: true` to `storageState()` so it's captured too — cookies + `localStorage` alone won't be enough.
- **Multi-role:** write one setup test per role to a separate state file, and map each browser project to the role's file. For suites that mutate shared state, authenticate per worker with a unique account instead.
- **Seed via API, not UI** (see `playwright-test-data`) — and the same applies to login: an API login (below) is faster and less brittle than driving the login form.

## Code

### `auth.setup.ts` — log in once and save state

```ts
// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import path from 'node:path';

const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_USER!);
  await page.getByLabel('Password').fill(process.env.E2E_PASS!);
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Wait for a post-login signal before saving — never save mid-redirect.
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

  // Persist cookies + localStorage (add indexedDB for Firebase-style token storage).
  await page.context().storageState({ path: authFile });
  // await page.context().storageState({ path: authFile, indexedDB: true });
});
```

### Config wiring — setup project + `storageState` + `dependencies`

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  use: { baseURL: process.env.BASE_URL ?? 'http://127.0.0.1:3000' },
  projects: [
    // 1. The setup project: matches *.setup.ts, runs the login once.
    { name: 'setup', testMatch: /.*\.setup\.ts/ },

    // 2. Real browser projects start already-authenticated and depend on setup.
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], storageState: 'playwright/.auth/user.json' },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'], storageState: 'playwright/.auth/user.json' },
      dependencies: ['setup'],
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'], storageState: 'playwright/.auth/user.json' },
      dependencies: ['setup'],
    },
  ],
});
```

Tests under the dependent projects need no login step — they open already signed in:

```ts
// tests/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test('dashboard loads for authenticated user', async ({ page }) => {
  await page.goto('/dashboard'); // already authenticated via storageState
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

### Multi-role variant

One setup test per role writes a separate state file; map projects to roles.

```ts
// tests/auth.setup.ts
import { test as setup } from '@playwright/test';

setup('auth as admin', async ({ page }) => {
  // ...log in as admin...
  await page.context().storageState({ path: 'playwright/.auth/admin.json' });
});

setup('auth as user', async ({ page }) => {
  // ...log in as standard user...
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

```ts
// playwright.config.ts — projects (excerpt)
projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  {
    name: 'admin',
    testMatch: /.*\.admin\.spec\.ts/,
    use: { ...devices['Desktop Chrome'], storageState: 'playwright/.auth/admin.json' },
    dependencies: ['setup'],
  },
  {
    name: 'user',
    testMatch: /.*\.user\.spec\.ts/,
    use: { ...devices['Desktop Chrome'], storageState: 'playwright/.auth/user.json' },
    dependencies: ['setup'],
  },
],
```

For suites that modify shared state, prefer authenticating **once per worker with a unique account** so parallel tests don't collide.

### API login (faster, less brittle)

When the app exposes an auth endpoint, skip the form entirely — request a token and write it straight into the storage state:

```ts
setup('authenticate via API', async ({ request }) => {
  const res = await request.post('/api/login', {
    data: { email: process.env.E2E_USER, password: process.env.E2E_PASS },
  });
  expect(res.ok()).toBeTruthy();
  // request shares the storage state target → cookies set by the API are saved
  await request.storageState({ path: 'playwright/.auth/user.json' });
});
```

## Pitfalls

- **Committing `.auth` JSON** — it contains live session cookies/tokens. Always `.gitignore` `playwright/.auth/`.
- **Logging in through the UI in every test** — the largest avoidable slowdown. Centralize it in the setup project.
- **Saving state mid-redirect** — call `storageState()` only after asserting a logged-in signal, or you snapshot a half-authenticated context.
- **`sessionStorage` / IndexedDB nuances** — `storageState` persists cookies + `localStorage`; it does **not** persist `sessionStorage` by default, and IndexedDB requires the `indexedDB: true` option. Service-worker and IndexedDB token storage have their own quirks — verify where your app actually keeps auth.
- **Stale state** — sessions expire; delete/regenerate the auth file when tests start failing on auth (or build a freshness check into the setup test).

## See also

- `playwright-test-data` — seed accounts and fixtures via the API `request` fixture instead of the UI.
- `playwright-fixtures-and-pom` — where shared auth state and worker-scoped fixtures belong.
