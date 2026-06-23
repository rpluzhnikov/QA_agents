---
name: playwright-visual-and-a11y
description: @axe-core/playwright accessibility scans + toHaveScreenshot visual diffing. Load when the automation-engineer adds accessibility or visual-regression checks to Playwright + TypeScript tests.
---

# Playwright visual & accessibility testing

The two automatable QA layers Playwright adds on top of functional specs: accessibility scans (`@axe-core/playwright`) and pixel-diff visual regression (`toHaveScreenshot()`). Both catch a subset of real issues automatically — the rest is manual/exploratory work that belongs to the manual side, not here.

## Accessibility (`@axe-core/playwright`)

Install `@axe-core/playwright` (Deque's official integration). It **does not follow SemVer** — per the npm page it "uses the major and minor version of axe-core that the package uses" (currently axe-core 4.11.x), so a pin like `4.11.3` tracks axe-core 4.11.x rather than a stable API contract. Import `AxeBuilder`, navigate, `analyze()`, then assert no violations.

```ts
import AxeBuilder from '@axe-core/playwright';
test('home page has no detectable a11y violations', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

- Scope with `.include()` / `.exclude()`; constrain rules with `.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa'])`; suppress known issues with `.disableRules()`.
- For interaction-revealed UI, interact (and `waitFor` the state) **before** `analyze()`.
- Share config via a fixture (an `axeBuilder` fixture pre-tagged) across tests.
- Combine with `toMatchAriaSnapshot()` — it locks the accessibility-tree structure and catches reading-order/landmark issues that axe won't.

## Visual (`toHaveScreenshot()`)

`await expect(page).toHaveScreenshot('name.png')` — the first run writes the golden image; later runs diff pixel-by-pixel (pixelmatch). Prefer `toHaveScreenshot()` (auto-retries until the page is stable) over `toMatchSnapshot()` (no retry, flaky).

```ts
test('dashboard matches baseline', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png', {
    animations: 'disabled',
    mask: [page.getByTestId('timestamp'), page.getByTestId('avatar')],
    maxDiffPixelRatio: 0.01,
  });
});
```

Update baselines (review the PNG diffs in the PR, then commit the baselines to git):

```bash
npx playwright test --update-snapshots
```

- Snapshot files are suffixed `<name>-<project>-<platform>.png` (e.g. `-chromium-linux`). Rendering differs by OS/arch/browser, so **generate baselines in the same environment as CI** (the official Playwright Docker image). This is the #1 cause of "passes locally, fails in CI" for visual tests.
- Stabilize with `animations: 'disabled'`, `mask: [locator, …]` for dynamic content (timestamps/avatars/ads), or a `stylePath` CSS file to hide volatile elements.
- Tune `threshold` / `maxDiffPixels` / `maxDiffPixelRatio` per component, not one global value. Prefer component/element screenshots over full-page for precision.
- Use `snapshotPathTemplate` (with the `{testFileBaseName}` token, added v1.60) to keep snapshot folders readable, and set an explicit `updateSnapshots` policy (e.g. `'missing'` locally, `'none'` in CI) so baselines aren't silently overwritten.

## Pitfalls

- **Generating baselines locally (macOS/Windows) then failing on Linux CI.** Always regenerate in the CI image.
- **One global threshold for every screenshot.** Tune per component; a value that's fine for a static card is too tight for an animated one.
- **Not masking dynamic content** (and not disabling animations) — guarantees flaky diffs on timestamps, avatars, ads.
- **Treating axe `violations.length === 0` as full WCAG compliance.** Automated scans catch only a subset of WCAG; the rest needs manual/exploratory accessibility testing, which lives on the manual side — keep this skill to the automatable subset.
