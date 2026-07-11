---
description: Diagnose and de-flake a Playwright + TypeScript spec — replace point-in-time checks, hard waits, and brittle locators with web-first auto-retrying assertions and resilient role/label/testid locators, then re-run to confirm stability. Preserves test intent and @KEN-<id> tags.
argument-hint: [path to spec file]
---

Act as the **automation-test-lead**. Diagnose and de-flake the spec: $ARGUMENTS. Load the
`playwright-waiting-and-assertions` and `playwright-locators` skills and follow them — they
are authoritative on the anti-flake idioms. If no spec path was given, ask for one and stop.

1. **Diagnose** — read the spec and list **every** flake pitfall with `file:line` and the
   offending snippet (don't fix yet): point-in-time checks in assertions
   (`expect(await locator.isVisible()).toBe(true)`, `textContent()` snapshotted then asserted);
   hard `page.waitForTimeout(ms)`; brittle locators (CSS class chains, `nth-child`, deep
   descendants, XPath) instead of `getByRole`/`getByLabel`/`getByTestId`; `getByRole` without a
   `name`; missing `await` on `expect`/actions/`poll`/`toPass`; `locator.all()` on a changing
   list; heavy `beforeAll` seeding under `fullyParallel`.
2. **Rewrite** — fix each finding **without changing test intent or `@KEN-<id>` tags**. Improve
   **locator precision FIRST** (resilient role/label/testid with a `name`; scope via
   `.filter()`/`.getByRole`, not CSS chains or `nth`) — most "flaky assertions" are an ambiguous
   locator or a missing `await`. Then use web-first auto-retrying assertions
   (`await expect(locator).toBeVisible()`/`toHaveText()`/`toHaveValue()`/`toHaveURL()`) in place
   of snapshot-then-`expect`; `expect.poll`/`expect.toPass` for eventual non-DOM conditions only
   after the locator is precise; add missing `await`s; drop `waitForTimeout` (use
   `locator.waitFor`/`waitForResponse`/`waitForURL` when a real signal is needed); isolate
   parallel-unsafe seeding into `beforeEach`/fixtures or make data unique.
3. **Verify** — re-run `npx playwright test <spec> --reporter=line`; repeat a few times or
   `--repeat-each=5` to confirm stability. Recommend `--fail-on-flaky-tests` in CI so
   silently-recovered (retry-passed) flakes still surface. Report **before/after**: each finding,
   the fix applied (`file:line`), and the run result.

**Pitfall:** retries / `poll` / `toPass` must FIX the root cause, not mask a bad locator — if a
fix only passes because retries hide the race, the locator or wait is still wrong.

This command edits spec files only — it authors no `.tms/` cases and owes no memory
checkpoint — only `/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on.

End your final message with (only suggest what's installed — otherwise name the bundle):

✅ **Done:** <spec> de-flaked — <N> findings fixed; re-run <result, e.g. 5/5 green with --repeat-each=5>
➡️ **Next:** CI flake gating (`--fail-on-flaky-tests`, quarantine policy) → ask `@automation-devops` (automation-devops bundle) · systemic flake policy across the suite → `@codereviewer` review pass (automation-codereview bundle) · `/kensa-fix-flake <next-spec>` if the run surfaced more flaky specs.
