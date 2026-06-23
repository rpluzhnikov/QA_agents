---
description: Scaffold a Playwright visual-regression test (toHaveScreenshot) for a URL or component — stabilized (animations off, dynamic content masked) with per-component thresholds and CI-generated baselines.
argument-hint: [url or component name]
---

Act as the **automation-test-lead**. Scaffold a visual test for: $ARGUMENTS. Load the
`playwright-visual-and-a11y` skill (authoritative pattern for masking, stabilization, threshold
tuning, and the baseline workflow), then delegate the authoring to an `automation-engineer`.

1. **Resolve the target** — a URL (page/route) or a **component** (selector / story / mounted
   component). Prefer an **element/component screenshot** over full-page for precision and stability.
   If the argument is missing or ambiguous, ask the user and stop.
2. **Generate the spec** — assert `await expect(page).toHaveScreenshot('<name>.png')` for a page, or
   `expect(locator).toHaveScreenshot('<name>.png')` for a component (prefer the element form).
3. **Stabilize** — `animations: 'disabled'`; `mask: [...]` for dynamic content (timestamps, avatars,
   ads, randomized IDs); set `maxDiffPixelRatio` / `threshold` **per component** to its real
   volatility — never one global value across every assertion.
4. **Tag** — if the test maps to a `.tms/` case, add `{ tag: '@KEN-<id>' }` to the `test(...)`.
5. **Baselines in CI, not locally** — generate them with `npx playwright test --update-snapshots`
   **inside the official Playwright Docker image / CI environment**, then commit the `*.png`
   snapshots. Seeding baselines on macOS/Windows is the #1 cause of "passes locally, fails in CI".

Report the spec path, snapshot name(s), what was masked, and the per-component thresholds chosen.
Pitfalls callout: baselines are OS/arch/browser-specific, and a single global `threshold` is not
"fine" — re-baseline in CI on any intentional visual change.

This command authors no `.tms/` feature cases (only optional `@KEN-<id>` tagging) and does **not**
emit `memory-checkpoint: done`.
