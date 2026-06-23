---
description: Scaffold a Playwright accessibility test with @axe-core/playwright (AxeBuilder) for a URL, scoped to WCAG 2.0/2.1 A+AA tags and asserting zero violations. Automated subset only — pairs with manual a11y testing.
argument-hint: [url or page name]
---

Act as the **automation-test-lead**. Scaffold an accessibility test for: $ARGUMENTS. Load the
`playwright-visual-and-a11y` skill and follow it exactly — **do not invent the pattern**; copy
the `AxeBuilder` shape verbatim, adapting only the URL, scope, and interaction steps.

1. **Resolve** — take the URL (or page name) from the argument. If missing or ambiguous,
   **ask** — don't guess a route. Note whether the check is on first paint or on
   interaction-revealed UI (modal/menu/panel that only renders after a click).
2. **Dependency** — confirm `@axe-core/playwright` is installed; if not,
   `npm install -D @axe-core/playwright`. **Pin deliberately:** per the skill it does **not**
   follow SemVer — it tracks the major/minor of the bundled `axe-core` (e.g. `4.11.x`), so a
   pin is to a rule set, not a stable API contract; treat a bump as a possible new-violations event.
3. **Spec** — author a spec that navigates to the target, builds
   `new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa']).analyze()`, and
   asserts `expect(results.violations).toEqual([])`. For **interaction-revealed UI**, perform the
   interaction and `waitFor` the revealed state **before** `analyze()` (else axe scans the wrong
   DOM). Scope with `.include()` / `.exclude()`; `.disableRules()` only when justified.
4. **Fixture (optional)** — if the project will hold several a11y specs, expose an `axeBuilder`
   fixture pre-tagged with the WCAG tags so each test calls `.analyze()` without repeating
   `.withTags(...)`.
5. **TMS tag (optional)** — if the test maps to a `.tms/` case, tag it `{ tag: '@KEN-<id>' }`.
6. **Report** — list the spec (and any fixture) created, the install/pin done, and the WCAG
   tags scoped.

**Pitfalls:** automated scans catch only a **subset** of WCAG — `violations.length === 0` is not
full compliance. Combine with **manual/exploratory** accessibility testing (it lives on the manual
side, not here), and complement with `toMatchAriaSnapshot()` to lock reading-order and landmark
structure that axe won't catch.

This command authors **no** `.tms/` feature cases (beyond optional tagging) and does **not** emit
`memory-checkpoint: done`.
