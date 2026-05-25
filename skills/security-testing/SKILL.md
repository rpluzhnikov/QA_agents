---
name: security-testing
description: OWASP-grounded security scenarios that a MANUAL QA tester can verify with a browser and DevTools — no pentest tooling required. Covers authentication, session management, access control, input validation, sensitive data exposure, transport security, security headers, business logic abuse, privacy/consent, and mobile-specific items. Explicitly marks items that are OUT OF SCOPE for manual QA (require Burp Suite, payload crafting, source review, etc.) so the skill doesn't give false confidence. Use when the feature has any security-sensitive surface (auth, payments, PII, access control).
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 2 — Testing Throughout the SDLC, §2.2.2 Test Types (security as an ISO 25010 quality characteristic); Chapter 4 — Test Analysis and Design, §4.4.3 Checklist-Based Testing; Chapter 5 — Managing the Test Activities, §5.2 Risk Management.
> Learning objectives: FL-2.2.2 (K2) distinguish test types (security is a non-functional test type — ISO 25010 quality characteristic with sub-characteristics confidentiality, integrity, non-repudiation, accountability, authenticity); FL-4.4.3 (K2) explain checklist-based testing (this skill IS an OWASP-grounded checklist scoped to what manual QA can credibly cover); FL-5.2.3 (K2) explain product-risk-analysis influence on test scope (security risks drive prioritisation of which checks to run on which surfaces).
> See also: the `risk-based-testing` skill for the §5.2 risk register that selects security focus areas.

# Security testing — what manual QA can credibly cover

A manual QA tester equipped with only a browser, DevTools, and normal
app interaction can credibly cover roughly the **OWASP ASVS v4.0.3
Level 1** surface and the browser-observable subset of the **OWASP
WSTG v4.2**. Concretely: password policy alignment with NIST SP
800-63B Rev. 4, cookie attribute checks, IDOR / vertical-privilege
URL probing, reflected-XSS smoke tests, security-header inspection,
business-logic abuse cases, and observable privacy/consent behavior.

**Out of scope (do not promise coverage):** anything requiring an
intercepting proxy (Burp, ZAP, Caido, mitmproxy), crafted payload
generation, source code review, dependency scanning, cryptographic
primitive analysis, or fuzzing. These are pentest activities — hand
them off rather than claim coverage.

**The framing that matters.** QA writes test cases that verify visible
security *behavior* (does the app do what its security spec
promises?). Pentest verifies *resistance to attack* (can the spec be
broken with adversarial techniques?). Confusing these is how teams
ship apps that "passed security testing" and still get breached.

Three structural points govern the rest:

1. **ASVS Level 1 is the right anchor.** ASVS 4.0.3 describes L1 as
   "completely penetration testable" without source code or
   configuration access — i.e. designed to be black-box-verifiable.
2. **WSTG is uneven for QA.** Many tests assume an intercepting proxy
   from step one. The QA-doable subset is roughly: WSTG-IDNT-04,
   WSTG-ATHN-01/03/07/09, WSTG-ATHZ-02/04, WSTG-SESS-02/03/06,
   WSTG-CONF-04/07/12, WSTG-CLNT-04/09, and the entire WSTG-BUSL-*
   business logic family.
3. **NIST 800-63B Rev. 4 (finalized July 31 2025) shifted password
   guidance under most QA teams' feet.** Verifiers SHALL NOT impose
   composition rules or periodic rotation; passwords must be ≥ 8
   characters (15 recommended where password is the only factor),
   allow ≥ 64 characters, accept all printable ASCII and Unicode
   including spaces, and be screened against breach lists. Any test
   case asserting "must contain uppercase + digit + symbol" is
   testing a control NIST now explicitly forbids.

Throughout this skill, items are tagged:
- `[QA-DOABLE]` — manual tester can verify with eyes/clicks
- `[DEVTOOLS-ASSISTED]` — needs browser DevTools (Network, Cookies, Storage)
- `[OUT-OF-SCOPE]` — pentest scope; do not commit to in QA

Each section ends with a **Reportable** line — what the worker can
honestly write in their report.

---

## 1. Authentication

### 1.1 [QA-DOABLE] Password policy aligns with NIST 800-63B Rev. 4

- **Check:** Registration and password-change forms enforce
  length-based rules (min 8, accept ≥ 64, all printable ASCII +
  Unicode) and do NOT enforce composition rules or periodic rotation.
- **Steps:** (1) 7-char password → reject. (2) 8-char all lowercase →
  accept (composition rules SHALL NOT be enforced). (3) 64-char
  passphrase with spaces and emoji → accept. (4) Known-breached
  password like `Password1!` → reject. (5) Confirm no forced rotation.
- **OWASP:** ASVS V2.1.1, V2.1.2, V2.1.4, V2.1.7, V2.1.9, V2.1.10.
  WSTG-ATHN-07.
- **Risk:** Composition rules + rotation produce predictable patterns
  (`Password1` → `Password2`). Failing to screen against breach lists
  enables credential-stuffing against new signups.

### 1.2 [DEVTOOLS-ASSISTED] Account lockout / rate limiting on login

- **Check:** After N failed logins, further attempts throttled.
- **Steps:** (1) Submit 10–20 wrong passwords for a known username.
  (2) Network tab — observe codes, messages, timing. (3) Try fresh
  tab/incognito — is limit per-IP, per-account, or both? (4) Submit
  correct password; record time to legitimate recovery.
- **OWASP:** ASVS V2.2.1. WSTG-ATHN-03.
- **Risk:** Without rate limiting, attackers with stolen username
  lists run offline credential stuffing at line speed.

### 1.3 [DEVTOOLS-ASSISTED] Password reset — token-in-URL, reuse, expiry, enumeration

- **Check:** Reset tokens are single-use, time-limited, not reusable.
  Request-reset endpoint returns same response for valid and invalid
  emails.
- **Steps:** (1) Request reset for valid email; note body, status,
  timing. (2) Request reset for `not-a-user@example.com`; compare —
  any difference is enumeration. (3) Use the reset link once
  successfully, paste it again → reject. (4) Wait past expiry → reject.
  (5) Tamper user ID in the link (`?userid=1&token=...` → `?userid=2`)
  — does the token validate against the wrong account?
- **OWASP:** WSTG-ATHN-09 explicitly warns about the `userid` +
  `token` pattern. WSTG-IDNT-04. ASVS V2.5.1.
- **Risk:** Reusable / long-lived tokens are persistent backdoors;
  enumeration leaks user emails for phishing.

### 1.4 [DEVTOOLS-ASSISTED] "Remember me" and session timeout

- **Check:** "Remember me" stores only a non-sensitive long-lived
  token, not the password; session times out per spec.
- **Steps:** (1) Log in with "remember me". (2) DevTools → Application
  → Cookies AND Local Storage; search for the literal password →
  must not be present. (3) Close and re-open browser → silent re-auth
  works. (4) Leave tab idle past idle timeout (and absolute timeout)
  and try a protected action.
- **OWASP:** WSTG-ATHN-05. ASVS V3.3.1 (idle), V3.3.2 (absolute).

### 1.5 [DEVTOOLS-ASSISTED] Logout completeness (server-side invalidation)

- **Check:** Logout invalidates the session server-side, not just
  clears the cookie locally.
- **Steps:** (1) Log in; copy the session cookie value. (2) Log out via
  UI. (3) Fresh incognito; manually set that cookie via DevTools →
  Application → Cookies → "Add cookie"; navigate to a protected page.
  (4) Expect redirect to login.
- **OWASP:** ASVS V3.3.1, V3.3.3. WSTG-SESS-06.
- **Risk:** Client-only logout leaves the session valid server-side;
  anyone with the token (shared computer, browser history, logs)
  retains access.

### 1.6 [QA-DOABLE] MFA UI flow integrity

- **Check:** MFA challenge cannot be skipped by navigating to a
  post-login URL or going "back" mid-flow.
- **Steps:** (1) Begin login; after password, capture MFA prompt URL.
  (2) New tab — directly visit `/dashboard` → expect redirect back to
  MFA. (3) On MFA page, try browser-back + replay; submit empty /
  whitespace code; submit obviously expired code.
- **OWASP:** WSTG-ATHN-11. ASVS V2.7.x.
- **Risk:** MFA bypass via forced browsing is a common
  authentication-failure pattern (OWASP Top 10 2021/2025 A07).

### 1.7 [DEVTOOLS-ASSISTED] OAuth / SSO redirect URI handling

- **Check:** Redirect URI accepted by OAuth flow matches allow-listed
  value exactly.
- **Steps:** (1) Begin SSO; Network tab → capture authorization
  request URL. (2) Locate `redirect_uri=`. (3) Modify to
  `https://evil.example/` or subdomain `https://yourapp.evil.com/` →
  expect IdP refusal. (4) Try appending fragment or extra path.
- **OWASP:** WSTG-ATHZ-05. ASVS V2.10.

### Where this stops being QA

- Token entropy analysis (needs Burp Sequencer or stats tools)
- Forced-browsing fuzzing of auth endpoints (WSTG-ATHN-04 beyond
  trivial back-button case — proxy + replay)
- Password storage hash review (Argon2/bcrypt/scrypt parameters —
  source code or config required; ASVS V2.4 is L2/L3)

### Reportable

> "Authentication — verified ASVS V2.1.x password policy alignment
> with NIST 800-63B Rev. 4, rate limiting on login per V2.2.1, reset
> token hygiene per WSTG-ATHN-09, logout server-side invalidation per
> V3.3.3, MFA bypass-via-forced-browsing per WSTG-ATHN-11."

---

## 2. Session management

### 2.1 [DEVTOOLS-ASSISTED] Session cookie attributes

- **Check:** Authentication cookies have `Secure`, `HttpOnly`, and
  `SameSite` attributes set.
- **Steps:** (1) Log in. (2) DevTools → Application → Cookies →
  inspect session cookie. (3) Verify columns. (4) `document.cookie`
  in console — session cookie name must be absent (HttpOnly).
- **OWASP:** ASVS V3.4.1, V3.4.2, V3.4.3. WSTG-SESS-02.
- **Risk:** No HttpOnly → reflected-XSS exfiltrates session. No
  Secure → leak over HTTP downgrade. No SameSite → CSRF.

### 2.2 [DEVTOOLS-ASSISTED] Session fixation — session ID changes after login

- **Check:** Pre-auth session ID is replaced after successful login.
- **Steps:** (1) Incognito, no login. (2) Cookies → record session
  cookie value. (3) Log in. (4) Recheck — must differ.
- **OWASP:** WSTG-SESS-03. ASVS V3.2.1.

### 2.3 [QA-DOABLE] Idle and absolute session timeout

- **Check:** Sessions expire after documented idle period AND after a
  hard absolute period regardless of activity.
- **Steps:** (1) Log in; leave idle past idle window + 1 min → expect
  re-auth on protected action. (2) Log in; keep clicking for longer
  than absolute timeout → expect re-auth at the absolute boundary.
- **OWASP:** ASVS V3.3.1, V3.3.2.

### 2.4 [QA-DOABLE] "Sign out everywhere" effectiveness

- **Check:** "Sign out of all sessions" invalidates other live
  sessions.
- **Steps:** (1) Log in on Browser A and Browser B. (2) In A, trigger
  sign-out-everywhere. (3) In B, try any authenticated action →
  expect re-auth.

### 2.5 [DEVTOOLS-ASSISTED] Session tokens never in URLs

- **Check:** Session IDs do not appear in URL query strings, fragments,
  or referrers.
- **Steps:** (1) Log in. (2) Click around. (3) Network tab → filter
  for the session cookie value in `Request URL` column → expect 0 hits.
- **OWASP:** ASVS V3.1.1.

### Where this stops being QA

- Session-token entropy analysis (WSTG-SESS-01)
- CSRF testing beyond observation of SameSite (requires forging
  cross-origin POSTs)

### Reportable

> "Session management — verified Secure/HttpOnly/SameSite per V3.4.1-3,
> session fixation absent per V3.2.1, idle + absolute timeout per
> V3.3.x, sign-out-everywhere effective, no session token in URLs per
> V3.1.1."

---

## 3. Access control / authorization

The category where manual QA delivers the most security ROI. **Broken
Access Control is #1 in OWASP Top 10:2025**, on 3.73 % of tested apps.

### 3.1 [DEVTOOLS-ASSISTED] Horizontal privilege escalation (IDOR via URL/ID swap)

- **Check:** User A cannot access User B's resources by altering an ID.
- **Preconditions:** Two test accounts, A and B, each with a private
  resource (order, document, profile).
- **Steps:** (1) Log in as A; note A's resource ID in URL
  (`/orders/1042`). (2) Log in as B; note B's ID (`/orders/1058`).
  (3) As B, edit URL to A's ID (`/orders/1042`). (4) Expect 403/404
  or generic "not found" — NOT A's data.
- **OWASP:** WSTG-ATHZ-04. ASVS V4.1.3, V4.2.1.

### 3.2 [QA-DOABLE] Vertical privilege escalation (regular user → admin URL)

- **Check:** Non-admin navigating to an admin URL is denied.
- **Steps:** (1) As admin, browse to `/admin/users`; note path. (2)
  Log out; log in as regular user. (3) Paste `/admin/users` into URL
  bar → expect 403 / redirect.
- **OWASP:** WSTG-ATHZ-03. ASVS V4.1.1.

### 3.3 [DEVTOOLS-ASSISTED] Hidden UI elements still callable

- **Check:** A "Delete" or "Edit" button hidden in UI doesn't
  correspond to a callable endpoint when revealed via DevTools.
- **Steps:** (1) As low-privilege user, open a page where admin-only
  buttons would normally appear. (2) DevTools → Elements → search DOM
  for `disabled` / hidden actions. (3) Remove `disabled` attribute or
  `hidden` class manually and click. Expect 403, not action success.
- **OWASP:** ASVS V4.1.1.

### 3.4 [QA-DOABLE] Privilege checks on dangerous actions

- **Check:** Delete / transfer / role-change actions require current
  password or fresh auth step.
- **Steps:** For each high-impact action (account deletion, fund
  transfer, role change, API key rotation) — verify re-authentication
  or step-up MFA is required.
- **OWASP:** ASVS V3.7.1.

### Where this stops being QA

- Bulk IDOR fuzzing across hundreds of object IDs (needs proxy / script)
- HTTP verb tampering (`GET` allowed but `PUT` allowed too — WSTG-CONF-06)
- API-level authorization bypass (parameter pollution, mass-assignment
  — WSTG-INPV-04, WSTG-INPV-20)

### Reportable

> "Access control — verified absence of horizontal IDOR per
> WSTG-ATHZ-04 / ASVS V4.2.1 across N resources, vertical privilege
> escalation absent per V4.1.1, hidden-UI-callable absent, step-up
> auth required for sensitive actions per V3.7.1."

---

## 4. Input validation (UI-observable)

### 4.1 [QA-DOABLE] Reflected XSS smoke test

- **Check:** Untrusted input rendered back into the page is HTML-escaped.
- **Steps:** (1) In each free-text field and URL parameter that is
  echoed back, submit `<script>alert(1)</script>` then
  `"><img src=x onerror=alert(1)>` then a benign `<b>bold</b>`. (2)
  Popup or actual bold = interpreted as HTML; literal string = escaped.
  (3) View Source to confirm `&lt;`/`&gt;`.
- **OWASP:** WSTG-INPV-01. ASVS V5.3.3.

### 4.2 [QA-DOABLE] HTML injection in user-generated content

- **Check:** Names, comments, profile bios that render across users
  escape HTML.
- **Steps:** Submit `<b>test</b>` and `<img src=x onerror=alert(1)>`
  as display name or comment; view as another user. Bold output or
  popups = vulnerable.
- **OWASP:** WSTG-INPV-02. WSTG-CLNT-03.

### 4.3 [DEVTOOLS-ASSISTED] File upload validation

- **Check:** Type, size, and filename validation occur server-side
  (not just client-side); uploaded files aren't served from a path
  that allows execution.
- **Steps:** (1) Upload `.txt` renamed to `.jpg` → note result. (2)
  `.html` file with `<script>alert(1)</script>` inside; navigate to
  served URL — popup is critical. (3) Filenames with traversal
  (`../../etc/passwd`), null bytes (`file.jpg%00.php`), spaces,
  Unicode, very long. (4) File ≥ documented max + 1 byte. (5) Tamper
  `Content-Type` if your stack allows DevTools Network → Replay.
- **OWASP:** WSTG-BUSL-09. ASVS V12.x.

### 4.4 [QA-DOABLE] Open redirect via `?next=` / `?returnUrl=` params

- **Check:** Redirect-target parameters can't send users to
  attacker-controlled domains.
- **Steps:** (1) Find any flow with `?next=`-style URL after login.
  (2) Replace value with `https://example.org/` or `//example.org/`
  and complete the flow. (3) Expect same-origin allow-list rejection
  or clear "you are leaving this site" warning.
- **OWASP:** WSTG-CLNT-04. ASVS V5.1.5.

### 4.5 [QA-DOABLE] Numeric input boundaries

- **Steps:** For each numeric input (quantity, price, dates, IDs):
  try `-1`, `0`, `0.1`, `999999999999`, `1e10`, `NaN`, leading zeros,
  scientific notation, locale-specific separators (`1,000.00` vs
  `1.000,00`).
- **OWASP:** ASVS V5.1.4.

### 4.6 [QA-DOABLE] Special characters smoke test

- **Steps:** Submit `'`, `"`, `\`, `<`, `>`, `&`, `%00`, ` `,
  emojis, RTL marks, zero-width joiners. Observe stack traces,
  broken rendering, or 500 errors (any of which is a finding).

### Where this stops being QA

- SQL injection beyond a single-quote smoke test (WSTG-INPV-05) —
  QA notes "the page returned a SQL error when I typed an
  apostrophe" and escalates; QA does NOT run SQLMap
- Stored XSS in deeply nested contexts, DOM XSS, CSP bypass, template
  injection (WSTG-INPV-18), SSRF (WSTG-INPV-19)
- Command injection, LDAP/XPath/XML injection

### Reportable

> "Input validation — verified reflected XSS smoke (V5.3.3 / WSTG-INPV-01)
> across N free-text fields, file-upload validation per WSTG-BUSL-09,
> open-redirect protection per V5.1.5 / WSTG-CLNT-04."

---

## 5. Sensitive data exposure (observable)

### 5.1 [DEVTOOLS-ASSISTED] PII in URL query strings

- **Steps:** Walk major user flows; Network tab → scan Request URL
  for anything that looks like PII (email, phone, name, account
  number) or a token.
- **OWASP:** ASVS V8.3.1.
- **Risk:** URLs land in browser history, server logs, third-party
  analytics, and Referer headers.

### 5.2 [DEVTOOLS-ASSISTED] PII in client-side storage

- **Steps:** DevTools → Application → Local Storage / Session
  Storage / IndexedDB. Browse every key. Then log out and recheck —
  authenticated data should be cleared.
- **OWASP:** ASVS V8.2.2, V8.2.3.

### 5.3 [QA-DOABLE] Sensitive data in error messages

- **Steps:** Trigger errors deliberately (malformed input, missing
  required field, unauthorized actions). Read the response — anything
  beyond "An error occurred" is a finding (stack traces, internal
  paths, DB schema, framework versions).
- **OWASP:** WSTG-ERRH-01. ASVS V7.4.1.

### 5.4 [DEVTOOLS-ASSISTED] Tokens leaking via Referer

- **Steps:** (1) Open a page with a token in URL (magic-link
  mid-flow). (2) Click outbound link. (3) On destination, Network →
  first request → Headers → check `Referer`.
- **OWASP:** ASVS V8.3.1.

### 5.5 [DEVTOOLS-ASSISTED] Backup files / source maps publicly accessible

- **Steps:** Probe predictable paths: `/.git/config`, `/.env`,
  `/web.config.bak`, `/backup.zip`, `/index.html.old`. Check whether
  minified JS bundles ship with `.map` files in prod (Sources tab
  reveals original source if so).
- **OWASP:** WSTG-CONF-04.

### 5.6 [DEVTOOLS-ASSISTED] Autocomplete behavior on sensitive fields

- **Steps:** DevTools → Elements → inspect each sensitive input's
  `autocomplete`. Password fields should use `type="password"`; CVV /
  MFA-code / SSN should have `autocomplete="off"` or
  `autocomplete="one-time-code"`.

### Where this stops being QA

- Memory dumps, disk forensics of cached pages
- Server response cache-control completeness across every endpoint
  at scale (proxy/scanner job)

### Reportable

> "Sensitive data exposure — verified absence of PII in URLs per
> V8.3.1, no auth-protected data in client storage per V8.2.2-3,
> no stack traces in error responses per V7.4.1, no public backup /
> source-map files per WSTG-CONF-04."

---

## 6. Transport security (DevTools-observable)

### 6.1 [DEVTOOLS-ASSISTED] HTTPS enforced; HTTP redirects to HTTPS

- **Steps:** (1) Type `http://` in address bar → expect 301/308 to
  HTTPS. (2) Network tab → look for any request still on HTTP after.
- **OWASP:** ASVS V9.1.1.

### 6.2 [DEVTOOLS-ASSISTED] HSTS header present

- **Steps:** Network → any response → Headers →
  `Strict-Transport-Security` with `max-age ≥ 6 months (15724800)`
  and ideally `includeSubDomains`.
- **OWASP:** WSTG-CONF-07.

### 6.3 [QA-DOABLE] Mixed content warnings

- **Steps:** Browse main flows with DevTools → Console open. Any HTTP
  resource loaded from an HTTPS page produces a warning.

### 6.4 [DEVTOOLS-ASSISTED] Secure flag on auth cookies
See §2.1.

### Where this stops being QA

- Cipher-suite review, TLS protocol-version enforcement (TLS 1.0/1.1
  disabled), certificate chain validation — needs `testssl.sh`,
  `nmap --script ssl-enum-ciphers`, or `sslyze`.

### Reportable

> "Transport security — HTTPS enforced with HTTP→HTTPS redirect per
> V9.1.1, HSTS present with max-age 6 months per WSTG-CONF-07, no
> mixed content warnings on main flows."

---

## 7. Security headers (Network tab inspection)

For each, in DevTools → Network → any document response → Headers,
confirm the header is present and inspect its value.

### 7.1 [DEVTOOLS-ASSISTED] Content-Security-Policy

- **Check:** `Content-Security-Policy` is set; at minimum
  `default-src`, `script-src`, and `frame-ancestors`; `'unsafe-inline'`
  and `'unsafe-eval'` absent from script-src.
- **OWASP:** ASVS V14.4.7. WSTG-CONF-12.

### 7.2 [DEVTOOLS-ASSISTED] X-Frame-Options / frame-ancestors (clickjacking)

- **Check:** Either `X-Frame-Options: DENY|SAMEORIGIN` OR
  `Content-Security-Policy: frame-ancestors 'self'|'none'`.
- **Steps:** Confirm header. Optionally, create local
  `<iframe src="https://yourapp.com">` file and open → expect blank/refused.
- **OWASP:** ASVS V14.4.7. WSTG-CLNT-09.

### 7.3 [DEVTOOLS-ASSISTED] X-Content-Type-Options: nosniff
- **OWASP:** ASVS V14.4.6.

### 7.4 [DEVTOOLS-ASSISTED] Referrer-Policy
- **Check:** Set to `no-referrer`, `same-origin`,
  `strict-origin-when-cross-origin`, or tighter.
- **OWASP:** ASVS V14.4.5.

### Where this stops being QA

- Full CSP bypass-resistance review (whitelisting trusted hosts that
  are themselves exploitable, dangerous `data:` URIs) — CSP Evaluator
- CORS preflight policy correctness across endpoints — proxy-based

### Reportable

> "Security headers — verified CSP per V14.4.7 / WSTG-CONF-12, frame
> protection per V14.4.7 / WSTG-CLNT-09, X-Content-Type-Options
> nosniff per V14.4.6, Referrer-Policy per V14.4.5."

---

## 8. Business logic vulnerabilities — QA's strength

The category where QA is structurally *better* than pentest. OWASP
WSTG: "Automation of business logic abuse cases is not possible and
remains a manual art relying on the skills of the tester and their
knowledge of the complete business process and its rules." A QA
tester who already knows the spec end-to-end has the inputs needed to
write abuse cases that a pentester would charge per-day to
reverse-engineer.

### 8.1 [QA-DOABLE] Race conditions on critical actions (double-submit)

- **Check:** Submitting the same critical action twice within ~100 ms
  does not produce two effects.
- **Steps:** (1) Same action page in two tabs (transfer money, redeem
  coupon, place order). (2) Identical inputs. (3) Submit in both tabs
  as close to simultaneously as possible (or Network → Right-click →
  Replay rapidly). (4) Verify only one transaction posts; second
  returns clear "already processed" error.
- **OWASP:** WSTG-BUSL-04.
- **Risk:** Double-submit race wins produce duplicate orders, double-
  spent coupons, double-counted loyalty credits.

### 8.2 [QA-DOABLE] Multi-step flow integrity

- **Check:** Required prior steps cannot be skipped by direct URL
  hopping; back-button replay doesn't repeat irreversible actions.
- **Steps:** For each multi-step wizard (checkout, KYC, onboarding):
  note URL of each step. After step 1, jump directly to step 4 URL →
  expect redirect back. After completing flow, press Back and
  resubmit → expect "already complete", not a duplicate effect.
- **OWASP:** WSTG-BUSL-06.

### 8.3 [QA-DOABLE] Negative quantities / decimal-integer confusion in commerce

- **Check:** Cart, refund, transfer, coupon flows reject negative
  amounts, fractional units of integer-only items, and overflow
  values.
- **Steps:** In any quantity/amount input: try `-1`, `0`, `0.5`
  (where ints expected), `999999999`, scientific notation. Add an
  item then change the input via DevTools to `-1` and submit.
- **Risk:** Negative-quantity bugs have repeatedly led to refunds for
  fictional purchases.

### 8.4 [QA-DOABLE] Coupon / discount stacking, expiry bypass

- **Steps:** Apply same single-use coupon twice (same cart and two
  sequential carts). Try expired coupon. Try two "exclusive" coupons
  together. Capture and replay the coupon-apply request from Network
  in a different cart.

### 8.5 [QA-DOABLE] State machine violations (cancel/refund a shipped order)

- **Steps:** Drive an order to "shipped" status (in staging). Then
  attempt to cancel/refund via the UI; via a stale browser tab
  showing the older state; via direct URL to the cancel endpoint.

### Where this stops being QA

- Massively parallel race exploitation (TOCTOU windows at scale —
  scripted tools)
- Cryptographic-replay attacks against signed tokens

### Reportable

> "Business logic — exercised double-submit race per WSTG-BUSL-04,
> multi-step skip / back-replay per WSTG-BUSL-06, negative-quantity
> guard, coupon stacking, illegal state transitions."

---

## 9. Privacy and consent

### 9.1 [DEVTOOLS-ASSISTED] Cookie consent actually respected

- **Check:** Rejecting analytics/marketing cookies in the consent
  banner does not load those third-party scripts or set their cookies.
- **Steps:** (1) Incognito. (2) Visit site; click "Reject all". (3)
  Network tab → filter for known tracker domains (Google Analytics,
  Facebook, Hotjar, Segment). (4) Cookies — verify no
  analytics/marketing cookies set.
- **OWASP:** ASVS V8.3.3.
- **Risk:** "Consent theater" is now a direct GDPR enforcement target.

### 9.2 [QA-DOABLE] "Delete my account" actually deletes

- **Steps:** Create throwaway account; add content; trigger delete.
  Wait for any documented grace period. Try login → expect failure.
  Try password-reset for that email → observe whether enumeration
  occurs.

### 9.3 [QA-DOABLE] Data export (GDPR-style) completeness

- **Steps:** Compare the export against the privacy policy line by
  line. Any field listed in policy but missing from export is a
  finding.
- **OWASP:** ASVS V8.3.2.

### Where this stops being QA

- Lawful-basis analysis, DPIA review, cross-border transfer compliance
  (legal/privacy team scope)

### Reportable

> "Privacy — consent banner choices honored per V8.3.3, account
> deletion effective, data export matches privacy policy per V8.3.2."

---

## 10. Mobile-specific (brief)

The OWASP Mobile Top 10 (2024 final) is led by M1 Improper Credential
Usage and M2 Inadequate Supply Chain Security. Most of M2 and M7 are
out of scope for manual QA; the items below are QA-doable.

For mobile-platform-specific coverage beyond security, cross-link to
the `mobile-testing` skill.

### 10.1 [QA-DOABLE] Screenshots in app switcher exposing sensitive screens

- **Steps:** Open sensitive screen (balance, password entry, payment),
  send to background → observe multitasking preview. Sensitive
  content visible = finding.
- **OWASP:** Mobile Top 10 2024 M9 / M6.

### 10.2 [QA-DOABLE] Pasteboard leakage of sensitive data

- **Steps:** Long-press password field — is "Copy" offered? Copy a
  sensitive value, background app for documented timeout, foreground
  another app and paste.

### 10.3 [QA-DOABLE] Deep links bypassing auth gates

- **Steps:** Log out. Use OS deep-link invocation
  (`adb shell am start -W -a android.intent.action.VIEW -d
  "yourapp://protected/screen"` or `xcrun simctl openurl booted
  "yourapp://protected/screen"`) or tap a deep link from email.
  Confirm auth required first.
- **OWASP:** Mobile Top 10 2024 M3.

### 10.4 [QA-DOABLE] WebView misconfigurations

- **Steps:** Try to coerce WebView (via malformed deep link or
  hosted-content URL param) into loading `https://example.org`.
  Observe whether navigation succeeds.

### Where this stops being QA

- Static analysis of APK/IPA for hardcoded credentials (M1) — needs
  MobSF, jadx, otool/class-dump
- Certificate pinning verification — requires mitm proxy with
  custom CA
- Binary tampering / root/jailbreak detection (M7)
- Runtime data-storage inspection (M9) — needs `frida`, file-system
  access on rooted device

### Reportable

> "Mobile — app switcher preview hardened (M9), pasteboard hygiene
> for sensitive fields, deep-link auth-gate enforcement (M3),
> WebView navigation allow-list."

---

## How to position security testing in your test plan

Insert one paragraph into the test plan: "Security testing performed
by QA is limited to ASVS Level 1 / WSTG browser-DevTools-observable
items. It does NOT substitute for penetration testing, dependency
scanning, or source-code review."

This single line prevents stakeholders from interpreting "QA passed"
as "secure."

## How to use this skill in your checklist

When the Lead specifies `security-testing`:

1. Walk sections 1–10 and ask "does this feature have any surface in
   this area?"
2. For each "yes", add the relevant test cases.
3. Tag each with its ASVS or WSTG identifier for traceability.
4. End the security section of the checklist with the matching
   **Reportable** lines so the user knows exactly what coverage the
   batch will deliver.

A typical security-relevant feature surfaces 5–15 items from this
walk. Avoid both extremes: 30+ items (over-coverage; pad-padding) or
0–1 items on a clearly security-sensitive feature (you missed the
walk).

## Caveats on standards versioning

- **ASVS 5.0.0 was released May 30 2025**, renumbering many
  requirements. This skill anchors on **v4.0.3**; if your org
  standardizes on 5.0, requirement IDs need to be remapped (the
  controls are substantively similar — session management moves V3
  → V7, auth V2 → V6).
- **OWASP Top 10:2025** is final. Broken Access Control remains #1.
  Security Misconfiguration is now #2. New: A03 Software Supply
  Chain Failures, A10 Mishandling of Exceptional Conditions. SSRF
  was rolled into Broken Access Control.
- **NIST SP 800-63B Rev. 4** is universally applicable but not
  universally adopted — PCI-DSS 4.0.1, some healthcare regulations,
  and some government contracts still mandate periodic rotation.
  Where a specific regulation conflicts with NIST, the regulation
  wins. Document the rationale either way.
