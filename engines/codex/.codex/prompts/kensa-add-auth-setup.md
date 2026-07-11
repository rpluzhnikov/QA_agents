---
description: Generate an auth.setup.ts that logs in once and saves storageState, then wire the setup project + storageState + dependencies:['setup'] into playwright.config.ts so authenticated tests reuse the saved session. Supports multi-role.
argument-hint: [optional role name, e.g. admin]
---

Act as the **automation-test-lead**. Wire up storageState auth (role: $ARGUMENTS if given,
else `user`). Load the `playwright-auth-storagestate` skill and follow its pattern exactly —
**do not invent the wiring**; copy the setup-test and config shape from the skill verbatim,
adapting only the login steps and storage paths to the project.

1. **Detect flow + credentials** — find the Playwright project (`playwright.config.*`,
   `tests/`); if none exists, tell the user to run `/kensa-scaffold-playwright` first and
   stop. Identify the login URL + form fields (or an auth API endpoint) and the post-login
   signal to assert. Read credentials from **environment variables only, never hard-coded**
   (e.g. `process.env.E2E_USER` / `E2E_PASS`); if unset, name the vars and ask the user.
   Verify **where the app stores auth** (cookie/`localStorage` vs IndexedDB) — Firebase-style
   IndexedDB token storage needs `storageState({ ..., indexedDB: true })`.
2. **Setup test** — write `tests/<role>.setup.ts` that logs in via **resilient locators**
   (`getByRole` / `getByLabel`, not brittle CSS), asserts a logged-in signal, then calls
   `page.context().storageState({ path: 'playwright/.auth/<role>.json' })`. **Prefer an API
   login** (`request.post(...)` → `request.storageState({ path })`) where the app exposes an
   auth endpoint — faster and less brittle; fall back to the UI form only when it does not.
3. **Config** — edit `playwright.config.ts`: add the `setup` project
   (`{ name: 'setup', testMatch: /.*\.setup\.ts/ }`); set
   `storageState: 'playwright/.auth/<role>.json'` on each browser project's `use`; add
   `dependencies: ['setup']` so they run only after — and only once — auth exists.
4. **Gitignore** — ensure `playwright/.auth/` is gitignored (it holds live session
   cookies/tokens); add `playwright/.auth/` to `.gitignore` if missing.
5. **Multi-role** — for multiple roles, one setup test per role writing a **separate** state
   file (`admin.json`, `user.json`, …), each browser/role project mapped to its file via
   `storageState`. For suites that mutate shared state, authenticate per worker with a unique
   account instead.
6. **Report** — list the files touched (setup test + `playwright.config.ts`) and the
   **gitignore note**. Restate the pitfalls: **never commit `.auth` JSON**; prefer API login;
   confirm the app's auth storage (cookie vs IndexedDB) so the saved state is complete.

This command writes project files only — it authors **no** `.tms/` cases and owes no
memory checkpoint (only `/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on).

End your final message with:

✅ **Done:** auth.setup.ts + config wiring (<roles>); playwright/.auth/ gitignored <already/added>
➡️ **Next:** `/kensa-add-page-object <Name>` — POM for the first authenticated page · `/kensa-automate-case <KEN-id>` — first authenticated @KEN-tagged test.
