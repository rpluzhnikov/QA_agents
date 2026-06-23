---
name: playwright-waiting-and-assertions
description: Auto-wait + web-first assertions, expect.poll/toPass, soft assertions, retries — the anti-flake idioms. Load when the automation-engineer writes assertions or fixes flaky Playwright + TypeScript tests.
---

This is the **#1 flake reducer** in a Playwright + TypeScript suite. Almost every "flaky test" traces back to a point-in-time check, a hardcoded `waitForTimeout`, or a missing `await` — not to a real timing bug in the app. Use web-first auto-retrying assertions everywhere and never assert on a value snapshot.

## Concept

Playwright auto-waits: before any action (`click`, `fill`, `check`, …) it runs actionability checks (visible, stable, enabled, receives events). Web-first assertions (`expect(locator).…`) auto-retry until the condition holds or the timeout expires (default assertion timeout 5s). You almost never need to wait manually — let the assertion do the polling.

## Rules

- **Use web-first assertions** — `toBeVisible()`, `toHaveText()`, `toHaveValue()`, `toBeEnabled()`, `toHaveURL()`, etc. They poll automatically.
- **Never** put point-in-time queries inside assertions: `expect(await locator.isVisible()).toBe(true)` and `textContent()` do **not** retry → race conditions. Use `await expect(locator).toBeVisible()`.
- **Never** use `page.waitForTimeout(ms)` in committed tests ("Never wait for timeout in production"). It's debugging-only.
- Avoid manual `waitForSelector` when an assertion already waits — `await expect(locator).toBeVisible()` replaces `await page.waitForSelector(...)` + check.
- For non-DOM/eventual conditions use **`expect.poll()`** (poll a function until a matcher passes) or **`expect.toPass()`** (retry a whole block). Tune `intervals` (default `[100, 250, 500, 1000]`) and `timeout`.
- Improve **locator precision first** before reaching for `poll`/`toPass`; most "flaky assertion" problems are actually ambiguous locators or a missing `await`. See `playwright-locators`.
- Legitimate explicit waits exist: `locator.waitFor({ state })`, `page.waitForResponse(pattern)`, `page.waitForURL()` — use when you need a signal Playwright can't infer from the action itself.
- Enforce `@typescript-eslint/no-floating-promises` to catch missing `await`s before Playwright calls.

## Retries & soft assertions

- `retries: process.env.CI ? 2 : 0`. Retries + `trace: 'on-first-retry'` capture a trace exactly when a test fails-then-passes.
- **Retries diagnose flake; they must not be a permanent mask.** Use `--fail-on-flaky-tests` in quality gates so silently-recovered flakes still surface. Fix the root cause (locator/wait) rather than bumping retries.
- **`expect.soft(...)`** accumulates failures without aborting the test — use for independent checks on one page (status + ETA + heading) so one run reports all mismatches. Combine with `expect.configure({ soft: true })` or `expect.soft.poll(...)`.
- Use a hard assertion (default) when later steps are meaningless if it fails; use soft when you want a complete picture of one screen.
- `expect.configure({ timeout })` for a pre-tuned slow `expect`.

## Code

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

```ts
// ✅ soft assertions — independent checks on one screen, all reported in one run
await expect.soft(page.getByTestId('status')).toHaveText('Success');
await expect.soft(page.getByTestId('eta')).toHaveText('1 day');
await page.getByRole('link', { name: 'next page' }).click();
```

## Pitfalls

- Mixing `await` placement: `await expect(...)` (correct) vs `expect(await ...)` (no retry).
- Asserting on text with `textContent()` then `expect(...).toBe(...)`.
- Reaching for `toPass`/`poll` to paper over a bad locator (see `playwright-locators`).
- Treating a high retry count as "fixed" — it hides real, user-facing flakiness.
- Soft assertions for preconditions (test proceeds in a broken state).
