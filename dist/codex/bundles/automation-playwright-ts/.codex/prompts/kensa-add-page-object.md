---
description: Generate a Page Object Model class for a named page/component and register it as a fixture in fixtures/base.ts — resilient role/label locators, no assertions in POMs, exposed via test.extend.
argument-hint: [page/component name, e.g. Checkout]
---

Act as the **automation-test-lead**. Create a page object for: $ARGUMENTS. Load the
`playwright-fixtures-and-pom` and `playwright-locators` skills and follow their idiom, then
delegate to an `automation-engineer` (or do it directly if trivial).

1. **Resolve the name** from the argument (e.g. `Checkout`). If none was given, ask the user
   and stop until they answer.
2. **Locate the layout** — find the existing `pages/` directory and `fixtures/base.ts`.
   Respect the project's actual structure; if either is missing, follow the
   `playwright-fixtures-and-pom` skill's layout and note it.
3. **Generate `pages/<name>-page.ts`** — a class taking `page: Page`, fields built from
   `getByRole`/`getByLabel` (resilient locators per `playwright-locators`) stored as
   `readonly Locator`s, plus action methods. **No heavy assertions in the POM** — return
   locators/values; a small "page is ready" helper is fine.
4. **Register the fixture** in `fixtures/base.ts` via `test.extend` (add to the `Fixtures`
   type + a `<name>Page` entry that does `use(new <Name>Page(page))`) so tests receive it
   ready-instantiated. Do **not** instantiate POMs in the test body — get them through the
   fixture.
5. **Report** the files touched (created + edited, with paths) and the fixture name tests
   now receive.

This command authors no `.tms/` cases and does **not** emit `memory-checkpoint: done`.
