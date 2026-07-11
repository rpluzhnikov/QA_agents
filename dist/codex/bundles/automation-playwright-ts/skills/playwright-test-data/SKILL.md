---
name: playwright-test-data
description: API seeding via the request fixture, data factories, and per-worker isolation for Playwright tests. Load when the automation-engineer sets up or isolates test data in Playwright + TypeScript.
---

# Playwright test data & isolation

How to seed, generate, and isolate test data so parallel tests never collide. Each test already gets an isolated `BrowserContext` (fresh cookies/storage) automatically — the rest is about the data behind the UI.

## Concept

Every test runs in its own `BrowserContext`, so browser state is isolated for free. Backend data is not. Seed it through the API rather than the UI, generate unique entities with factories, and key any shared per-worker resource on the worker index so parallel workers don't step on each other. Prefer fixtures over `beforeEach`/`afterEach` — they co-locate setup + teardown and compose in a type-safe way.

## Rules

- **Seed via API, not UI.** Use the `request` fixture (Playwright's `APIRequestContext`, which honors `baseURL` and `extraHTTPHeaders`) to create/reset data and to verify backend side-effects. Driving the UI to set up data is the largest avoidable slowdown.
- **Combine API seeding + UI verification in one test** for realistic, atomic scenarios — seed the entity over the API, then assert it appears/behaves correctly in the UI.
- **Use data factories** to generate unique entities. Prefer generated data over shared static data so parallel tests don't collide.
- **Isolate per-worker resources** (DB users, tenants) with **worker-scoped fixtures** keyed on `testInfo.workerIndex` / `parallelIndex`, or use timestamp/uuid-based unique data.
- **Make tests independent** — no test should depend on data left behind by another. For modify-shared-state suites, give each worker its own unique account.

## Code

Worker-scoped fixture for a unique per-worker DB user (created once per worker, torn down after):

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

API seeding via the `request` fixture, then UI verification in the same test:

```ts
test('new project shows in dashboard', async ({ page, request }) => {
  // seed over the API (request honors baseURL / extraHTTPHeaders)
  const res = await request.post('/api/projects', {
    data: { name: `proj-${Date.now()}` },
  });
  expect(res.ok()).toBeTruthy();
  const project = await res.json();

  // verify in the UI
  await page.goto('/dashboard');
  await expect(page.getByText(project.name)).toBeVisible();
});
```

## Pitfalls

- **Shared mutable test data across parallel workers** → race conditions. Generate unique data (factory / uuid / timestamp) or key the resource on `workerIndex`.
- **UI-based data setup** — logging in or creating records through the UI in every test is the biggest avoidable slowdown; seed over the API instead.

## See also

- `playwright-auth-storagestate` — the auth half of test-data isolation: log in once, reuse `storageState` across tests.
- `playwright-parallel-and-sharding` — how workers map to processes, which is what `workerIndex`-based isolation builds on.
