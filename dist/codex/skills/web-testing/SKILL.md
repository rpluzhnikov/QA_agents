---
name: web-testing
description: Web-specific test scenarios for browser-based applications. Covers browser navigation (back/forward/refresh), form validation, deep linking, accessibility basics (keyboard, focus, screen reader), localStorage/cookies, responsive design at common breakpoints, internationalization, and progressive enhancement. Use when the feature under test is a web app. Loaded by the QA Engineer when the Test Lead specifies web platform.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 2 — Testing Throughout the SDLC, §2.2.2 Test Types (functional and non-functional — ISO 25010 quality characteristics: usability, compatibility, portability, reliability); Chapter 4 — Test Analysis and Design, §4.4.3 Checklist-Based Testing.
> Learning objectives: FL-2.2.2 (K2) distinguish test types (this skill enumerates web-relevant non-functional characteristics per ISO 25010); FL-4.4.3 (K2) explain checklist-based testing (this skill IS a domain checklist for web).
> See also: §2.2.1 test levels (web cases live mostly at system and acceptance levels); the `sdlc-and-test-lifecycle` skill for the test-type taxonomy.

# Web testing — what not to forget

Web apps surface a specific class of bugs that don't show up on
mobile or backend: browser navigation interactions, form chrome
quirks, accessibility specific to keyboard and screen readers,
storage / cookie hygiene, and responsive layout at boundary widths.

This skill is a structured walk across seven areas. Apply each to
the feature being tested and surface what's relevant.

When in doubt about *what* security cases to write for cookie
attributes or CSP, defer to the `security-testing` skill — this skill
covers behavior, that one covers security claims.

## 1. Browser navigation

The browser is a stateful environment with three buttons users will
press at the worst possible moments: back, forward, refresh.

### Back / forward button mid-flow

- **Test:** In a multi-step flow (checkout, wizard, signup), press
  Back from step 3 → does the form state on step 2 survive? Does
  pressing Forward again restore step 3?
- **Test:** After completing a one-shot action (placing an order),
  press Back → does the previous form show as "already submitted"
  or does it allow resubmit?
- **Bug pattern:** Refresh on a POST result page → browser shows
  "Resubmit form?" → user clicks Resubmit → duplicate order.

### Refresh mid-flow

- **Test:** Fill out a long form, refresh mid-typing — is the data
  preserved or warned about? `beforeunload` should fire for
  significant unsaved changes.
- **Test:** On a results page (`/order/12345`), refresh → still works,
  no "session lost" error.

### Open the same flow in two tabs

- **Test:** Open the cart in tab A and tab B. Add item X in A, item Y
  in B. Refresh both — both items present? Or last-writer-wins? The
  spec should say.
- **Test:** Start checkout in tab A, complete order. Tab B still has
  the cart — what happens on its Checkout click?

### Deep link to a gated page

- **Test:** Log out. Paste `/profile/settings` in URL bar → expect
  redirect to login with the original destination preserved (login
  → profile/settings, not login → home).
- **Test:** Logged in as user without permission. Paste an admin URL
  → expect 403 / clear "no access" page, not silent redirect to home.

### URL with stale or expired query params

- **Test:** Old shareable link with an expired filter / token / state
  → graceful "this link is expired" rather than blank page or crash.

### If your feature touches navigation, add to the checklist:

- Back / forward across multi-step flows
- Refresh on each significant page
- Same flow in two tabs (deduplication / last-write-wins behavior)
- Deep link to gated page (logged-out and wrong-role)

## 2. Forms

Forms are where bugs hide. HTML5 validation, browser autofill, and
chrome-vs-browser-vs-browser inconsistency.

### HTML5 validation vs server validation

- **Test:** Bypass HTML5 by disabling `required` via DevTools, submit
  → server-side validation catches it.
- **Test:** Pattern validation (`type="email"`) — does it accept
  RFC-valid weirdness like `"a b"@example.com`? Should it? Spec call.

### Submit on Enter

- **Test:** With cursor in any text field, press Enter → primary
  action fires (not a no-op or back-button).
- **Test:** In a form with multiple buttons, Enter submits the
  primary action (`type="submit"`), not the first button in DOM
  order if those differ.

### Tab order

- **Test:** Tab through every interactive element on the page — the
  order matches visual reading order, no traps, no skipped controls.
- **Test:** Shift-Tab reverses correctly.

### Required field behavior

- **Test:** On blur vs on submit — when does the inline error
  appear? Some specs ask for "show error after first submit attempt,
  then on each blur"; others want "show on blur from start". The
  case should match the spec.
- **Test:** Required marker visible (asterisk, "required" text) for
  screen readers via `aria-required="true"`.

### Autocomplete

- **Test:** Sensitive fields (password, CVV, MFA code) have
  `autocomplete="off"` or `autocomplete="one-time-code"` /
  `autocomplete="new-password"` as appropriate.
- **Test:** Non-sensitive fields (name, address, email) allow
  autofill and the autofilled value triggers validation correctly
  (some forms only validate on user keystrokes, not autofill events).

### If your feature has a form, add to the checklist:

- Server-side validation (bypass HTML5 via DevTools)
- Submit-on-Enter behavior
- Tab order walk
- Required marker for screen readers
- Autocomplete attribute on each sensitive field

## 3. Storage and cookies

What's stored, where, and what happens on logout.

### localStorage / sessionStorage on logout

- **Test:** Log in → DevTools → Application → Local/Session Storage
  → note keys. Log out → all auth-related entries should be cleared.
- **Test:** Specifically, no `access_token` / `refresh_token` / user
  PII should remain in localStorage after logout.

### Cookie attributes for auth

Covered in detail in `security-testing` §2.1. From a behavior
standpoint: `HttpOnly` cookies shouldn't appear in `document.cookie`;
`Secure` cookies don't survive a downgrade to HTTP.

### Storage full or blocked

- **Test:** In Application → Storage, "Clear storage" → does the app
  recover gracefully? Some apps assume localStorage exists and crash
  on `null`.
- **Test:** In browser privacy mode (or with localStorage disabled
  via extension) → does the app work, or does it cleanly tell the
  user "we need storage for this feature"?

### Cross-domain cookie behavior

- **Test:** If the app uses subdomain cookies (`.example.com`),
  verify they propagate across subdomains as intended.
- **Test:** Third-party cookie blocking enabled (default in Safari,
  Firefox; coming to Chrome) → embedded checkout / SSO iframes still
  work?

### If your feature touches storage, add to the checklist:

- Authenticated data cleared on logout
- Recovery from cleared storage (no crash on `null`)
- Third-party cookie blocking (Safari default)

## 4. Responsive design

### Common breakpoints

Test at four widths:
- Mobile portrait: 375 px (iPhone SE) and 414 px (iPhone Pro Max)
- Tablet portrait: 768 px
- Desktop: 1280 px
- Wide desktop: 1920 px

### Edge cases at breakpoint boundaries

- **Test:** Resize the window from 767 px → 768 px — does the layout
  flip cleanly at the breakpoint, or does it stutter at intermediate
  widths?
- **Test:** Very narrow (320 px) — does any UI still need to fit?

### Print stylesheet

- **Test (if relevant):** Print preview the main pages — does the
  app print readable content (no nav bars, no decorative imagery
  pushed to a second page)?

### Browser zoom

- **Test:** Zoom to 200 % via Ctrl/Cmd-+ → all content remains
  reachable, no overlapping text, no horizontal scroll on standard
  viewports.
- **Test:** Zoom to 50 % → no truncation issues, layout still sane.

### If your feature has a UI surface, add to the checklist:

- Walk at four breakpoints (375 / 768 / 1280 / 1920)
- 200 % zoom walk for accessibility
- Print preview (if applicable)

## 5. Accessibility (manual-verifiable)

The slice of accessibility a manual tester can verify without
specialized tools. For comprehensive WCAG audits, escalate to an a11y
specialist.

### Keyboard-only navigation

- **Test:** Unplug the mouse. Walk the primary user journey using
  only Tab, Shift-Tab, Enter, Space, arrow keys, Escape. Every
  interactive element is reachable in logical order.

### Visible focus indicator

- **Test:** Tab to each interactive element. The focus ring is
  visible (browser default OR custom but high-contrast) on every
  element, including buttons, links, inputs, and custom controls.
- **Bug pattern:** `outline: none` in CSS without a replacement
  focus style.

### Skip-to-content link

- **Test:** Press Tab once on the first load of any page. If the
  page has more than ~5 nav items, the first focus should be a
  "Skip to main content" link, hidden by default but visible on focus.

### Form labels associated with inputs

- **Test:** DevTools → inspect each `<input>` → there's a `<label
  for="...">` pointing at it, or `aria-label` / `aria-labelledby`
  set. Placeholder is NOT a substitute for a label.

### Alt text on meaningful images

- **Test:** `<img>` tags that convey information have non-empty
  `alt`. Decorative `<img>` has `alt=""` (empty, not missing).
- **Test:** Icon-only buttons have `aria-label` describing their action.

### Heading hierarchy

- **Test:** Use a browser extension (HeadingsMap) or DevTools to see
  the heading outline. There's exactly one `<h1>` per page, and
  headings descend in order (no `<h1>` → `<h3>` skipping `<h2>`).

### Color contrast

- **Test:** Eyeball: any low-contrast text obvious? For exact
  numbers, use Chrome DevTools → Inspect → Styles → Contrast ratio
  for each text-on-background pair. WCAG AA: 4.5:1 normal, 3:1
  large text and meaningful non-text UI.

### If your feature has a UI, add to the checklist:

- Keyboard-only walk of primary journey
- Visible focus indicator on every interactive element
- Form labels associated with inputs (not placeholder-as-label)
- Alt text on meaningful images
- Heading outline (one h1, no skipped levels)

## 6. Browser variations

### The big four

- **Chrome** (Blink) — usually the dev's daily driver, fewest surprises
- **Firefox** (Gecko) — different rendering of borders, focus, some forms
- **Safari** (WebKit) — strictest cookie behavior, idiosyncratic on
  date inputs, no IndexedDB in private mode (historically)
- **Edge** (Blink) — similar to Chrome but has its own enterprise modes

Test the main user journey on each. Most bugs that survive Chrome
testing show up in Safari first.

### Cookies disabled

- **Test:** Disable all cookies in browser settings → does the app
  cleanly tell the user "cookies required" or does it loop on login?

### JS disabled

- **Test (if applicable):** Disable JS → does the app show a
  meaningful message ("JavaScript required"), or a blank page? Some
  apps deliberately work without JS (server-rendered fallback);
  others should clearly require it.

### Third-party cookies blocked

- **Test:** In Safari (default-blocks) or Chrome with third-party
  cookies disabled → does any embedded iframe (SSO, payment) still work?

### If your feature is web-facing, add to the checklist:

- Smoke on Chrome, Firefox, Safari (mac), Edge
- Cookies-disabled clean-fail
- Third-party-cookie-blocked Safari default behavior

## 7. Internationalization (i18n)

### RTL languages

- **Test:** Switch system / app language to Arabic or Hebrew.
  Horizontal layouts mirror; nav chevrons flip; text aligns right.
- **Test:** Mixed content (English brand name embedded in Arabic
  paragraph) still reads correctly.

### Long translations

- **Test:** German often runs 30–40 % longer than English. Switch to
  German (or check the longest available translation) → any text
  truncated, overlapping, or pushed off-screen?
- **Test:** Hard tested example: "Settings" → "Einstellungen" — does
  the menu item still fit?

### Locale-specific date / number formats

- **Test:** Switch locale to `de-DE` → dates display as DD.MM.YYYY,
  numbers as `1.000,50`, not `1,000.50`.
- **Test:** Switch to `ja-JP` → dates as YYYY/MM/DD; full-width
  characters in Japanese input render correctly.

### Currency display

- **Test:** Switch currency to EUR → price displays as `€1.000,50`
  (with locale-correct separator) or `EUR 1,000.50` per spec.
- **Test:** Currency change without page reload (if supported) →
  all on-screen prices update.

### If your feature is i18n-relevant, add to the checklist:

- RTL walk (Arabic or Hebrew)
- Long-translation walk (German)
- Locale date / number / currency format
- Mixed LTR-in-RTL content rendering

## How to apply

A typical web feature surfaces 5–15 items from this walk. The walk
takes ~10 minutes once you're practiced. Skip what doesn't apply —
a backend API has no responsive layout, an admin tool may not need
i18n. Add only what's a real test against this feature, not "we
should test this in theory".

Mark each item in the checklist with `[web]` plus the relevant
sub-section, e.g. `[web §5 — keyboard-only walk]`.
