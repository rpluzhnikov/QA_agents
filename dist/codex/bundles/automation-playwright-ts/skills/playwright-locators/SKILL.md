---
name: playwright-locators
description: Resilient locator priority (role/label/testid), anti-patterns, and codegen tooling. Load when the automation-engineer is choosing or fixing Playwright locators.
---

How you select an element decides whether a test survives the next DOM refactor. This sub-skill covers the recommended locator priority order, the anti-patterns to avoid, and the codegen tooling for Playwright + TypeScript. Locators are also what make auto-waiting work (see `playwright-waiting-and-assertions`), and they are the values you store in page objects (see `playwright-fixtures-and-pom`).

## Concept

A locator is a *description* re-resolved on every action — unlike a stale element handle, it is looked up fresh each time you act on it. This re-resolution is the foundation of auto-waiting. Prefer user-facing, accessibility-aligned locators so your tests match how real users and assistive tech perceive the page.

## Rules — recommended priority order

1. **`getByRole(role, { name })`** — the recommended default; mirrors how users + assistive tech perceive the page; resilient to DOM churn. Always pass the accessible `name`.
2. **`getByLabel`** — form fields.
3. **`getByPlaceholder` / `getByText` / `getByTitle`** — user-visible content.
4. **`getByTestId`** — for non-accessible / ambiguous / dev-only elements. Default attribute is `data-testid`; configure via `use: { testIdAttribute: 'data-pw' }`. It's stable and refactor-proof but bypasses accessibility coverage, so use sparingly.
5. **CSS / XPath via `page.locator()`** — last resort; brittle against DOM structure changes.

- **Avoid:** CSS class chains (`button.buttonIcon.episode-actions-later`), `nth-child`, deep XPath, and the removed `_react` / `_vue` / `:light` engines (removed in v1.58 — migrate to user-facing locators or standard CSS).
- **Chain + filter** to scope: `page.getByRole('listitem').filter({ hasText: 'Product 2' }).getByRole('button', { name: 'Add to cart' })`.
- **Tooling:**
  - `codegen` — `npx playwright codegen <url>` records interactions and emits locators.
  - `page.pickLocator()` (added in Playwright 1.59) "enters an interactive mode where hovering over elements highlights them and shows the corresponding locator. Click an element to get its Locator back."
  - `locator.normalize()` (added in 1.59) "converts a locator to follow best practices like test ids and aria roles."
  - Always review generated output.
- Use `locator.describe()` (v1.57) to label locators for the trace viewer.

## Code

```ts
await page.getByRole('textbox', { name: 'Email' }).fill('a@b.com');
await page.getByLabel('Password').fill('secret');
await page.getByRole('button', { name: 'Sign in' }).click();
await expect(page.getByText('Welcome back')).toBeVisible();
// scoped:
await page.getByRole('article', { name: 'Super Widget' })
          .getByRole('button', { name: 'Add to Cart' }).click();
```

## Pitfalls

- `getByRole('button')` with no name — matches every button, triggering a strict-mode violation.
- Using role locators for icon-only / dynamic-text elements — fall back to testid there.
- `locator.all()` on a dynamically-changing list — returns whatever is present immediately, so results are flaky; wait for the list to stabilize first (see `playwright-waiting-and-assertions`).
