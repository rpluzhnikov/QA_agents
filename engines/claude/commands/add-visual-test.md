---
description: Scaffold a Playwright visual-regression test (toHaveScreenshot) for a URL or component — stabilized (animations off, dynamic content masked) with per-component thresholds and CI-generated baselines.
---

You are the **automation-test-lead**. The user invoked `/add-visual-test <url|component>`.
Load the `playwright-visual-and-a11y` skill (the authoritative pattern — masking, stabilization,
threshold tuning, baseline workflow live there), then delegate to an `automation-engineer` via Task.

## Phase 1 — Resolve the target

1. Read the argument: a URL (full page or route) or a **component** (selector / story / mounted
   component). Prefer an **element/component screenshot** over full-page — it's far more stable and
   precise. If the argument is missing or ambiguous, ask the user for the URL or component and stop.
2. Note any `.tms/` case this test maps to (for tagging in Phase 2). Skip if none.

## Phase 2 — Brief the engineer

Use the Task tool to spawn one `automation-engineer` with the skill loaded and these instructions:

1. **Generate the spec.** Author a Playwright test asserting
   `await expect(page).toHaveScreenshot('<name>.png')` for a page target, or a **locator**
   screenshot (`expect(locator).toHaveScreenshot('<name>.png')`) for a component — prefer the
   element/component form.
2. **Stabilize** so the baseline is deterministic:
   - `animations: 'disabled'`
   - `mask: [...]` for dynamic content — timestamps, avatars, ads, randomized IDs, anything that
     varies run-to-run.
   - Tune `maxDiffPixelRatio` / `threshold` **per component** to its real volatility — do **not**
     paste one global value across every assertion.
3. **Tag** — if the test maps to a `.tms/` case, add `{ tag: '@KEN-<id>' }` to the `test(...)`.
4. **Baselines — generate them in CI, not locally.** Instruct that baselines are produced with
   `npx playwright test --update-snapshots` **inside the official Playwright Docker image / the CI
   environment**, then the `*.png` snapshots are committed. Generating baselines on macOS/Windows is
   the #1 cause of "passes locally, fails in CI" — never seed baselines from a local dev machine.

## Phase 3 — Report

1. Report the spec path, snapshot name(s), what was masked, and the per-component thresholds chosen.
2. **Pitfalls callout** — baselines are OS/arch/browser-specific; a single global `threshold` is
   not "fine" — under-tightening hides regressions, over-tightening flakes. Re-baseline in CI on any
   intentional visual change.

This command scaffolds an automated test; it authors no `.tms/` feature cases (only optional
`@KEN-<id>` tagging) and does **not** emit `memory-checkpoint: done`.
