---
description: Scaffold a Playwright accessibility test with @axe-core/playwright (AxeBuilder) for a URL, scoped to WCAG 2.0/2.1 A+AA tags and asserting zero violations. Automated subset only — pairs with manual a11y testing.
---

You are the **automation-test-lead**. The user invoked `/add-a11y-test <url>`. Load the
`playwright-visual-and-a11y` skill, then delegate to an `automation-engineer` via the Task
tool. **Do not invent the pattern** — copy the `AxeBuilder` shape from the skill verbatim,
adapting only the URL, scope, and interaction steps.

## Phase 1 — Resolve the target

1. Take the URL (or page name) from the argument. If it's missing or ambiguous, **ask** —
   do not guess a route.
2. Note whether the a11y check is on first paint or on interaction-revealed UI (a modal,
   menu, or expanded panel that only renders after a click).

## Phase 2 — Ensure the dependency

1. Confirm `@axe-core/playwright` is installed; if not, `npm install -D @axe-core/playwright`.
2. **Pin deliberately.** Per the skill it does **not** follow SemVer — it tracks the
   major/minor of the `axe-core` it bundles (e.g. `4.11.x`), so a pin is to a rule set, not
   a stable API contract. Pin explicitly and treat a bump as a possible new-violations event.

## Phase 3 — Generate the spec

1. Author a spec that navigates to the target, then builds:
   `new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa']).analyze()`
   and asserts `expect(results.violations).toEqual([])`.
2. For **interaction-revealed UI**, perform the interaction and `waitFor` the revealed state
   **before** calling `analyze()` — otherwise axe scans the wrong DOM.
3. Scope with `.include()` / `.exclude()` and suppress known issues with `.disableRules()`
   only when justified, per the skill.

## Phase 4 — Share a fixture (optional)

1. If the project will hold several a11y specs, expose an `axeBuilder` fixture pre-tagged
   with the WCAG tags so each test calls `.analyze()` without repeating `.withTags(...)`.

## Phase 5 — Tag to TMS (optional)

1. If the test maps to a `.tms/` case, tag it `{ tag: '@KEN-<id>' }` so the run links back
   to the case.

## Phase 6 — Report

1. List the spec (and any fixture) created, the install/pin done, and the WCAG tags scoped.
2. **Pitfalls callout:** automated scans catch only a **subset** of WCAG — `violations.length === 0`
   is not full compliance. Combine with **manual/exploratory** accessibility testing (which
   lives on the manual side, not here), and complement with `toMatchAriaSnapshot()` to lock
   reading-order and landmark structure that axe won't catch.
3. This command authors **no** `.tms/` feature cases (beyond optional tagging) and does
   **not** emit `memory-checkpoint: done`.
