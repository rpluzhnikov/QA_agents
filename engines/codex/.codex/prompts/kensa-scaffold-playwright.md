---
description: Scaffold a Playwright + TypeScript E2E project from zero — install @playwright/test, browsers, and the canonical playwright.config.ts + fixtures/pages/utils/tests layout. Confirms before touching an existing Playwright project.
argument-hint: [target dir or app base URL] (optional)
---

Act as the **automation-test-lead**. Scaffold a Playwright + TypeScript E2E project for:
$ARGUMENTS. Load the `playwright-typescript` skill for the canonical config and project
layout, and follow it exactly — **do not invent config**. Copy the canonical
`playwright.config.ts` and directory layout from the skill verbatim, adapting only
`baseURL` / `webServer` to the project.

1. **Detect** — check the target for `package.json`, `playwright.config.*`
   (`.ts`/`.js`/`.mts`), an existing `tests/` tree, or `playwright/.auth/`. If a
   Playwright project already exists, **do not clobber it**: report what's present and
   ask whether to overwrite the config / add only the missing pieces, or stop. Wait for
   confirmation before writing over any file. If clean (or confirmed), continue.
2. **Install** — `npm install -D @playwright/test` (the Test runner, **not** `playwright`
   the Library — having both breaks `npx playwright test`), then `npx playwright install`
   (`--with-deps` on CI/Linux). Pin to the version the skill specifies; keep a dedicated
   `tests/tsconfig.json`.
3. **Config** — write `playwright.config.ts` exactly from the skill: `setup` project +
   `storageState: 'playwright/.auth/user.json'` with `dependencies: ['setup']`,
   `fullyParallel: true`, `forbidOnly: !!process.env.CI`, `trace: 'on-first-retry'`,
   blob reporter on CI (`reporter: process.env.CI ? 'blob' : 'html'`), and the `webServer`
   block with `reuseExistingServer: !process.env.CI`. Adapt only `baseURL` and
   `webServer.command`/`url`; leave every other value as defined.
4. **Structure** — create `fixtures/base.ts` (`test.extend` base test, page objects as
   fixtures), a sample `tests/auth.setup.ts` (logs in, saves `storageState` to
   `playwright/.auth/user.json`, matched by the `setup` project), and `tests/`/`pages/`/
   `utils/` dirs with one example spec importing `test` from `fixtures/base.ts` and using
   a role-based locator + web-first assertion.
5. **Report** — list the files/dirs created and the install commands run.

This command scaffolds project files only — it authors **no** `.tms/` cases and owes no
memory checkpoint (only `/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on).

End your final message with (only suggest commands whose bundle is installed —
otherwise name the bundle):

✅ **Done:** Playwright + TS scaffolded — <files/dirs created>, browsers installed
➡️ **Next:** `/kensa-add-auth-setup` — wire real authentication (setup project + storageState) · `/kensa-add-page-object <Name>` — first POM for your main page · then `/kensa-automate-case <KEN-id>` — first @KEN-tagged test from a manual case · CI wiring (runners, sharding, artifacts) → ask `@automation-devops` (automation-devops bundle).
