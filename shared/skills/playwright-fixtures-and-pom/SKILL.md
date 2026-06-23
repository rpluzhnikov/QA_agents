---
name: playwright-fixtures-and-pom
description: POM-as-fixtures (test.extend) is the 2025-2026 default for structuring Playwright + TypeScript page objects; Screenplay (Serenity/JS) is an alternative only when the project already uses it. Load when the automation-engineer structures page objects / test fixtures in Playwright + TypeScript.
---

# Playwright fixtures and Page Object Model

Three approaches exist for organizing Playwright test architecture: plain Page Object Model (POM), POM exposed through Playwright's fixture system, and the Screenplay pattern. This skill covers when to use each and how to wire POM classes into custom fixtures.

## Concept

The 2025-2026 ecosystem consensus: **combine the Page Object Model with Playwright's fixture system**. Write POM classes for page logic, then expose them as custom fixtures via `test.extend` so tests receive ready-to-use, auto-instantiated page objects. The Playwright docs themselves demonstrate page objects as fixtures.

## Rules

- **Default (recommended):** POM-as-fixtures. POMs encapsulate page locators/actions; fixtures handle instantiation + setup/teardown so tests don't do `new LoginPage(page)` repeatedly.
- Do **not** instantiate POMs inside the test body; get them through fixtures. This keeps setup in one place and is the "Playwright-native" way — you extend the framework rather than importing modules ad hoc.
- **Plain POM (no fixtures)** is acceptable for very small suites — but boilerplate compounds as the suite grows.
- **Screenplay pattern** (via Serenity/JS — `@serenity-js/playwright-test`, `@serenity-js/web`, etc.): a user-centric Actors/Abilities/Tasks/Questions model with composition over inheritance and rich BDD reporting. It's a legitimate choice for large orgs wanting business-readable, tool-agnostic scenarios and living documentation, but it's a heavier abstraction and a smaller ecosystem. **For the `automation-engineer`: default to POM-as-fixtures; only reach for Screenplay when the project already uses Serenity/JS or explicitly wants BDD/living docs.**
- Keep POMs free of assertions where possible (return locators/values; assert in specs), though small "expect the page is ready" helpers are fine.

POMs should store role/label `Locator`s (see `playwright-locators`) rather than re-fetching brittle CSS on each call. Fixtures are also where shared state and auth belong — use worker-scoped or test-scoped fixtures for storage state (see `playwright-auth-storagestate`) and for seeding/providing test data (see `playwright-test-data`).

## Code

### POM-as-fixture

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

## Pitfalls

- POMs that re-fetch elements with brittle CSS instead of storing `Locator`s built from role/label.
- Over-abstracting tiny suites into Screenplay before there's a need.
- Putting heavy assertions deep in POMs, making failures hard to read.
