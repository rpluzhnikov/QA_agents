---
description: Generate an auth.setup.ts that logs in once and saves storageState, then wire the setup project + storageState + dependencies:['setup'] into playwright.config.ts so authenticated tests reuse the saved session. Supports multi-role.
---

You are the **automation-test-lead**. The user invoked `/add-auth-setup`. Load the
`playwright-auth-storagestate` skill and follow its pattern exactly, then delegate the
file writing to an `automation-engineer` via the Task tool (or do it directly if trivial).
**Do not invent the wiring** — copy the setup-test and config shape from the skill verbatim,
adapting only the login steps and storage paths to the project.

## Phase 1 — Detect the login flow and credentials source

1. Find the existing Playwright project (`playwright.config.*`, `tests/`). If none
   exists, tell the user to run `/scaffold-playwright` first and stop.
2. Ask for / detect the login flow: the login URL, the form fields (or an auth API
   endpoint), and the post-login signal to assert before saving state.
3. Resolve the credentials source — **environment variables only, never hard-coded**
   (e.g. `process.env.E2E_USER` / `E2E_PASS`). If none are set, name the vars the
   setup test will read and tell the user to provide them.
4. Verify **where the app stores auth** (cookie / `localStorage` vs IndexedDB). For
   Firebase-style IndexedDB token storage, the state must be saved with
   `indexedDB: true` — `storageState` does not capture it by default.

## Phase 2 — Generate the setup test

1. Write `tests/auth.setup.ts` (or `<role>.setup.ts` per role) that performs login
   via **resilient locators** (`getByRole` / `getByLabel`, not brittle CSS), asserts
   a logged-in signal, then calls
   `page.context().storageState({ path: 'playwright/.auth/<role>.json' })`.
2. **Prefer an API login where possible** — request a token via the `request` fixture
   and `request.storageState({ path })`; it is faster and less brittle than driving the
   form. Fall back to the UI flow only when no auth endpoint exists.

## Phase 3 — Wire the config

Per the skill, edit `playwright.config.ts` to:

1. Add the **setup project**: `{ name: 'setup', testMatch: /.*\.setup\.ts/ }`.
2. Set `storageState: 'playwright/.auth/<role>.json'` on each browser project's `use`.
3. Add `dependencies: ['setup']` to each browser project so they run only after — and
   only once — auth exists.

## Phase 4 — Gitignore the auth state

1. Ensure `playwright/.auth/` is gitignored — those JSON files hold **live session
   cookies/tokens**. If the entry is missing, add `playwright/.auth/` to `.gitignore`.

## Phase 5 — Multi-role (if asked)

For multiple roles: one setup test per role, each writing a **separate** state file
(`admin.json`, `user.json`, …), and map each browser/role project to its file via
`storageState`. For suites that mutate shared state, authenticate per worker with a
unique account instead.

## Phase 6 — Report

1. List the files touched (setup test + `playwright.config.ts`) and the **gitignore note**
   (whether `playwright/.auth/` was already ignored or just added).
2. Pitfalls to restate: **never commit `.auth` JSON**; prefer API login; confirm the
   app's auth storage (cookie vs IndexedDB) so the saved state is complete.
3. This command writes project files only — it authors **no** `.tms/` cases and does
   **not** emit `memory-checkpoint: done` (the Stop hook only enforces checkpoints for
   `/new-feature` and `/update-feature`).
