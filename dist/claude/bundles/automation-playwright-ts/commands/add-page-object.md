---
description: Generate a Page Object Model class for a named page/component and register it as a fixture in fixtures/base.ts — resilient role/label locators, no assertions in POMs, exposed via test.extend.
argument-hint: <page/component name, e.g. Checkout>
---

You are the **automation-test-lead**. The user invoked `/add-page-object <name>`. Load the
`playwright-fixtures-and-pom` and `playwright-locators` skills, then delegate to an
`automation-engineer` via Task (or do it directly if trivial).

## Phase 1 — Resolve & locate

1. Resolve the page/component name from the argument (e.g. `Checkout`, `LoginForm`). If
   none was given, ask the user and stop until they answer.
2. Check a Playwright project exists (`playwright.config.*` or `@playwright/test`
   in `package.json`). If none, tell the user to run `/scaffold-playwright` first
   and stop.
3. Locate the project's actual layout — find the existing `pages/` directory and
   `fixtures/base.ts`. Respect what's there (different roots, `src/`, naming casing); do
   not assume. If just these two are missing inside an otherwise-real Playwright
   project, follow the structure the `playwright-fixtures-and-pom`
   skill prescribes and say so in the report.

## Phase 2 — Generate, register, report

1. Generate `pages/<name>-page.ts` — a class taking `page: Page`, with fields built from
   `getByRole`/`getByLabel` (resilient locators per `playwright-locators`) stored as
   `readonly Locator`s, plus action methods (`goto`, fills, clicks). **No heavy assertions
   in the POM** — return locators/values; a small "page is ready" helper is fine. Match the
   idiom in the `playwright-fixtures-and-pom` skill exactly.
2. Register it as a fixture in `fixtures/base.ts` via `test.extend` so tests receive it
   ready-instantiated — add the field to the `Fixtures` type and a `<name>Page: async ({ page }, use) => { await use(new <Name>Page(page)); }` entry. Do **not** instantiate POMs in the
   test body; tests get them through the fixture.
3. Report the files touched (created + edited, with paths) and the fixture name tests now
   receive.

This command authors no `.tms/` cases and owes no memory checkpoint.

## Epilogue (required)

End your final message with exactly this block:

✅ **Done:** pages/<name>-page.ts created; fixture `<name>Page` registered in fixtures/base.ts
➡️ **Next:**
- `/automate-case <KEN-id>` — write the first spec that uses the new fixture
- `/add-visual-test <component>` — if this page needs a visual baseline
- `/add-page-object <NextName>` — next page in the flow
