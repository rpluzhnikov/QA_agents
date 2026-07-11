---
name: test-code-review-standards
description: Review standards for automated test code — DAMP-over-DRY, behavior-focused (not implementation-detail) assertions, unchanging tests, and the right abstraction layer (page objects → screenplay). Load when the codereviewer agent reviews automated tests.
---

When you review automated **test code** (not production code), the goal is different: a test is a piece of executable documentation that must stay readable, survive refactors, and fail only for real, useful reasons. Optimize for clarity and stability, not for cleverness or maximal deduplication.

## Concept

**DAMP over DRY in tests.** Favor **DAMP** (Descriptive And Meaningful Phrases) in test code and **DRY** in production code. They aren't truly opposed: apply DRY to the *how* (extract and name the mechanics — test-data builders, custom assertions) and DAMP to the *what* (keep arrange/act/assert visible and self-explanatory). Google's guidance: "in test code, stick to straight-line code over clever logic, and consider tolerating some duplication when it makes the test more descriptive and meaningful." Over-DRYing tests creates brittle, hard-to-debug suites where a failure forces you to chase abstractions instead of reading the test.

**Behavior, not implementation details.** A test should assert observable behavior through public APIs, prefer state over interactions, and "strive for unchanging tests" (Google) — tests that survive refactoring and only break when behavior actually changes. Kent C. Dodds frames the same idea: test what the user experiences, not internal wiring. Tests coupled to implementation detail break on every refactor and erode trust.

**Right abstraction layer for UI/E2E.**
- **Page Objects** wrap a page/fragment with an application-specific API so tests manipulate meaningful elements, not raw HTML — without them "your tests will be brittle to changes in the UI" (Fowler). Good starting abstraction; fine for smaller suites.
- **Screenplay pattern (Serenity)** is an actor-centric refactor of page objects toward SOLID — Actors with Abilities perform Tasks via Actions and ask Questions, so tests read as business intent. More readable/reusable/scalable, but proliferates small classes and "takes quite a lot of effort and discipline" — adopt when suite scale justifies it.

## Rules

Apply these as concrete checks against the test diff:

- [ ] **Tests behavior, not implementation details** — survives refactoring; no assertions on private internals, DOM structure, or call wiring that a refactor would change.
- [ ] **Tests via public APIs**, asserting **state not interactions** where possible (avoid over-verifying mock call counts).
- [ ] **Named after the behavior** under test; the failure message alone tells you what broke and why.
- [ ] **No logic in tests** — no loops/conditionals/branches that can hide bugs; straight-line, DAMP arrange/act/assert.
- [ ] **One reason to fail** — a focused boundary; the test "only fails for useful reasons," not for incidental changes.
- [ ] **Hermetic & isolated** — no run-order dependence, no shared mutable fixtures, no real network/sleep in small tests.
- [ ] **Mechanics extracted (DRY); intent kept visible (DAMP)** — builders/helpers carry setup noise, but the meaningful values and assertions stay inline in the test body.
- [ ] **Right layer and right test double** — page objects vs screenplay matches suite scale; the chosen double matches the dependency.
- [ ] **Deterministic data** — factories/seeds, not random or time/zone-dependent values.
- [ ] **Anti-flake idioms present** — web-first auto-retrying assertions, no hardcoded sleeps (see `playwright-waiting-and-assertions`).
- [ ] **Traceability tag present** — each test carries its `@KEN-<id>` tag linking back to the source requirement (see `ken-traceability`).

**Brittle smells to reject:** assertion-free tests; tests asserting on internal structure; deep helper/util chains ("test helpers/utils are some of the worst offenders"); hard-coded sleeps; shared fixtures that couple unrelated tests; brittle full-DOM snapshots that fail on cosmetic changes.

## Code

```ts
// ❌ Over-DRY: intent hidden behind a helper; assertion checks implementation detail;
//    KEN id embedded in the title string (dis-preferred — see ken-traceability)
test('checkout @KEN-412', async ({ page }) => {
  await runScenario(page, 'happy-path');               // what does this set up?
  expect(store.getState().cart.__internalFlag).toBe(1); // asserts internal wiring
});

// ✅ DAMP: arrange/act/assert visible; asserts user-observable behavior;
//    KEN id as a structured tag (the canonical form per ken-traceability)
test('completes checkout and shows order confirmation',
  { tag: '@KEN-412' },
  async ({ page }) => {
    const user = await createUser({ cart: [aBook({ price: 10 })] }); // DRY mechanics, named
    await checkoutPage.goto(user);
    await checkoutPage.payWith(aValidCard());                        // act

    await expect(page.getByRole('heading', { name: 'Order confirmed' })).toBeVisible();
    await expect(page.getByTestId('order-total')).toHaveText('$10.00');
  });
```

The mechanics (`createUser`, `aBook`, `aValidCard`) are deduplicated and named, but the meaningful values (`price: 10`, `$10.00`) and the behavioral assertion stay inline so the test reads as documentation and survives a refactor of the store.

## Pitfalls

- **Over-DRY helpers that hide intent** — a test that's three opaque helper calls. The reviewer should not have to open three files to learn what is being verified. Push setup into named builders, keep the *what* in the test.
- **Asserting implementation details** — checking private fields, internal state flags, or exact mock interaction counts. These break on every refactor; assert observable behavior through public APIs instead.
- **Brittle snapshots** — large auto-generated snapshots that fail on cosmetic changes and get blindly re-baselined. Prefer targeted assertions on the specific values that matter.
- **Logic in tests** — loops/conditionals computing expected values can encode the same bug as the code under test. Spell out the expectation.
- **Missing the basics** — a test with no `@KEN-<id>` tag (`ken-traceability`) or a hardcoded `waitForTimeout` (`playwright-waiting-and-assertions`) is a flag regardless of how clean the rest reads.
