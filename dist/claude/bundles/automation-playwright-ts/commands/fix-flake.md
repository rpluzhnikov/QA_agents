---
description: Diagnose and de-flake a Playwright + TypeScript spec — replace point-in-time checks, hard waits, and brittle locators with web-first auto-retrying assertions and resilient role/label/testid locators, then re-run to confirm stability. Preserves test intent and @KEN-<id> tags.
---

You are the **automation-test-lead**. The user invoked `/fix-flake <spec>`. Load the
`playwright-waiting-and-assertions` and `playwright-locators` skills, then delegate the
rewrite to an `automation-engineer` via Task (or do it directly for a single spec).
Those skills are authoritative — follow them; this command just sequences the work.

If no spec path was given, ask for one and stop until the user answers.

## Phase 1 — Diagnose

Read the spec and scan for the top flake pitfalls. List **every** finding with `file:line`
and the exact offending snippet — don't fix yet:

- **Point-in-time checks in assertions** — `expect(await locator.isVisible()).toBe(true)`,
  `textContent()`/`innerText()` snapshotted then asserted; these don't retry → races.
- **Hard waits** — any `page.waitForTimeout(ms)` in committed test code.
- **Brittle locators** — CSS class chains, `nth-child`, deep descendant selectors, XPath,
  or text-positional selectors instead of `getByRole`/`getByLabel`/`getByTestId`.
- **`getByRole` without a `name`** — matches the first of many → order-dependent.
- **Missing `await`** — on `expect(...)`, actions (`click`/`fill`), or `expect.poll`/`toPass`.
- **`locator.all()` on a changing list** — iterating a snapshot of a list that re-renders.
- **Heavy `beforeAll` seeding under `fullyParallel`** — shared mutable state across workers.

## Phase 2 — Rewrite

Fix each finding **without changing test intent or `@KEN-<id>` tags**. Improve locator
precision FIRST — most "flaky assertions" are really an ambiguous locator or a missing
`await`, not a timing bug:

- Resilient locators: role/label/testid with a `name`; scope with `.filter()` / `.getByRole`
  instead of CSS chains or `nth`.
- Web-first auto-retrying assertions: `await expect(locator).toBeVisible()`/`toHaveText()`/
  `toHaveValue()`/`toHaveURL()` in place of snapshot-then-`expect`.
- Eventual (non-DOM) conditions: `expect.poll()` / `expect.toPass()` — only after the locator
  is precise, never to paper over a bad selector.
- Add the missing `await`s; drop `waitForTimeout`; replace it with the real signal
  (`locator.waitFor`, `waitForResponse`, `waitForURL`) when one is genuinely needed.
- Per-test isolation for parallel-unsafe seeding (move into `beforeEach`/fixtures or make data unique).

## Phase 3 — Verify

1. Re-run: `npx playwright test <spec> --reporter=line`. For suspected flake, repeat a few
   times or `--repeat-each=5` to confirm it's now stable.
2. Recommend `--fail-on-flaky-tests` in CI so silently-recovered (retry-passed) flakes still surface.
3. Report **before/after**: each finding, the fix applied (`file:line`), and the run result.

**Pitfall:** retries / `poll` / `toPass` must FIX the root cause, not mask a bad locator —
if a fix only works because retries hide the race, the locator or wait is still wrong.

This command edits spec files only — it authors no `.tms/` cases and does **not** emit
`memory-checkpoint: done`.
