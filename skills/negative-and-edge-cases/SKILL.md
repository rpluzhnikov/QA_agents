---
name: negative-and-edge-cases
description: Systematic checklist of negative scenarios and edge cases to consider when designing tests for any feature. Used by workers during checklist design to ensure non-happy-path coverage isn't an afterthought. Catalog organized by input, action, state, and environment dimensions — apply each dimension to the feature in question and surface what's relevant.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 4 — Test Analysis and Design, §4.4 Experience-Based Test Techniques (§4.4.1 error guessing, §4.4.3 checklist-based testing).
> Learning objectives: FL-4.4.1 (K2) explain error guessing; FL-4.4.3 (K2) explain checklist-based testing.
> The four-dimension walk (input / action / state / environment) IS a taxonomy-based error-guessing technique in the CTFL §4.4.1 sense, operationalised as a checklist per §4.4.3.
> See also: §1.3 testing principle 4 (defect clustering) as the empirical basis; §5.2 risk-based testing for prioritising which dimensions matter most.

# Negative and edge cases — the systematic walk

Junior testers and AI both share the same failure mode: they write
beautiful happy-path coverage and call it a day. Negative scenarios get
sketched in, edge cases barely. This skill is the fix — a structured
walk across four dimensions of "what could go wrong", applied to
whatever feature you're testing.

Use this skill at the **checklist design** phase, not at the case-writing
phase. The point is to surface scenarios you'd otherwise miss, then let
`checklist-design` and `test-case-writing-craft` shape them into cases.

## The four dimensions

1. **Input** — what the user (or upstream system) provides
2. **Action** — what the user does (timing, order, repetition)
3. **State** — what the system is in when the action happens
4. **Environment** — what's around the system (network, device, time)

Walk each dimension. Apply only those rows that are meaningful for the
feature.

## Dimension 1 — Input

For every input the feature accepts (form field, URL param, API body,
file upload, drag-drop content):

### Emptiness and absence
- [ ] Empty string `""`
- [ ] Whitespace only `"   "`
- [ ] Null / undefined / missing field entirely
- [ ] Empty array `[]` where array expected
- [ ] Empty object `{}` where object expected

### Length
- [ ] One character
- [ ] Maximum allowed length
- [ ] Maximum + 1 (boundary)
- [ ] Very long (10x max, 1MB, etc.)
- [ ] Single emoji (1 grapheme = 4+ bytes — common bug)

### Numeric ranges (if input is numeric)
- [ ] Zero
- [ ] Negative
- [ ] Negative max (smallest possible)
- [ ] Decimal where integer expected
- [ ] Scientific notation `1e10`
- [ ] Locale separators (`1,000.00` vs `1.000,00`)
- [ ] Integer overflow values (`2^31`, `2^53`, `2^63`)
- [ ] `NaN`, `Infinity`, `-0`

### Character classes
- [ ] Pure ASCII letters
- [ ] Digits in a string field
- [ ] Special characters: `' " \ / < > & %`
- [ ] Whitespace inside (`hello world`, `hello\tworld`, `hello\nworld`)
- [ ] Leading / trailing whitespace
- [ ] Null bytes `\x00`
- [ ] Unicode emoji 🎉
- [ ] Multi-byte UTF-8 (Cyrillic, Chinese, Arabic, etc.)
- [ ] Right-to-left override `‮`
- [ ] Zero-width joiners and combining marks
- [ ] Mixed scripts (`раypal` — Cyrillic а in "paypal")

### Format-specific
- [ ] Email: `user@`, `@domain`, `user@.com`, valid edge cases like
      `"a b"@example.com` (RFC-valid but rare)
- [ ] URL: missing scheme, javascript:, data:, file:, localhost,
      IP literal, IDN domain
- [ ] Date: leap year Feb 29, year 1900, year 9999, DST transitions
- [ ] Phone: country code present/absent, local formatting variations
- [ ] File: wrong extension, double extension `.tar.gz`, hidden
      `.htaccess`, no extension, very long name, traversal `../../etc/passwd`
- [ ] JSON in a string field, SQL fragments, script tags `<script>alert(1)</script>`

### Adversarial
- [ ] SQL injection probes (`'; DROP TABLE--`, `' OR 1=1--`)
- [ ] XSS probes (`<img src=x onerror=alert(1)>`)
- [ ] Command injection (`; cat /etc/passwd`, `| whoami`)
- [ ] Path traversal (`../../`, encoded `%2e%2e%2f`)

Apply security probes only when relevant — for a password field,
SQL injection check is appropriate; for a "what's your mood today"
field, it's overkill.

## Dimension 2 — Action

For every action the user takes (clicking buttons, submitting forms,
making API calls):

### Timing
- [ ] Click rapidly twice (double-click on action button)
- [ ] Submit before the previous submission completes
- [ ] Take very long between starting and finishing the action
  (session timeout mid-action)
- [ ] Submit at the exact moment of a deadline / expiry boundary

### Order
- [ ] Skip required prior step (deep-link past the wizard)
- [ ] Go back in browser/app mid-flow and resubmit
- [ ] Refresh page mid-flow
- [ ] Open same flow in two tabs and complete both
- [ ] Open same flow in two tabs, complete one, try to complete the other

### Repetition
- [ ] Do the same idempotent action twice (should be safe)
- [ ] Do the same non-idempotent action twice (should be guarded)
- [ ] Spam the action N times in a second (rate limit)

### Cancellation
- [ ] Cancel mid-flow at every stage
- [ ] Close browser/app mid-flow
- [ ] Lose network mid-flow
- [ ] Background app mid-flow (mobile)

## Dimension 3 — State

For the state the feature operates in:

### Auth state
- [ ] Logged out
- [ ] Logged in but session expired (token stale)
- [ ] Logged in as wrong role (e.g., regular user attempts admin action)
- [ ] Logged in as different user than the resource owner (IDOR check)
- [ ] Account in unusual state (locked, deactivated, pending verification)

### Resource state
- [ ] Resource doesn't exist
- [ ] Resource exists but deleted/archived
- [ ] Resource exists but user lacks permission
- [ ] Resource in an unexpected status for this action
  (cancel an already-shipped order, edit a published doc, etc.)
- [ ] Resource has dependent state (orphans, references, foreign keys)

### Concurrency
- [ ] Two users editing the same resource
- [ ] User A modifies, User B reads stale version, B submits
- [ ] Race on a uniqueness constraint (two users grab the same username)

### Subscription / quota state
- [ ] Subscription expired
- [ ] Subscription in grace period
- [ ] At quota limit (one more = block)
- [ ] Over quota (already past)

## Dimension 4 — Environment

For the environment around the system:

### Network
- [ ] Offline at action start
- [ ] Network drops mid-action
- [ ] Slow network (high latency, low bandwidth)
- [ ] Network flapping (connect / disconnect repeatedly)
- [ ] Captive portal / VPN
- [ ] Specific corporate proxies (if relevant)

### Device (mobile)
- [ ] Low battery / low power mode
- [ ] Low storage
- [ ] Background by OS interruption (call, alarm)
- [ ] Permission denied / revoked while running
- [ ] OS version below supported, above supported, latest beta

### Locale / time
- [ ] Different timezone than server
- [ ] DST transition during action
- [ ] Different date format (DD/MM vs MM/DD)
- [ ] RTL language for the UI
- [ ] User's clock is wrong (skew with server)

### Browser / client (web)
- [ ] Different browsers (Chrome / Firefox / Safari / Edge)
- [ ] Different OS (mac / win / linux / mobile browsers)
- [ ] Cookies disabled
- [ ] JS disabled (where graceful degradation is intended)
- [ ] Third-party cookies blocked
- [ ] Local storage full / unavailable
- [ ] Browser zoom level (50%, 200%)
- [ ] Reduced motion / high contrast / forced colors

## How to apply

You will NOT use every row above for every feature. The walk is:

1. Open the dimension that applies to your feature.
2. Read each row.
3. Ask: "Does this row produce a meaningful test case for this feature?"
4. If yes, add it to the checklist. If no, skip.

A typical feature surfaces 5-15 items from this walk. Not 50, not 2.

### Example: applying to "Add 2FA via TOTP"

**Input dimension** — TOTP code input field:
- ✅ Empty → reject
- ✅ 5 chars vs 6 chars vs 7 chars (BVA)
- ✅ Non-numeric 6 chars → reject
- ✅ Whitespace around valid code → trim and accept? (depends on spec)
- ✅ Leading zeros in code preserved? (`012345` — common bug to strip)

**Action dimension** — TOTP submission:
- ✅ Submit a code at the exact moment of expiry boundary
- ✅ Submit the same valid code twice (replay protection)
- ✅ Submit rapidly to test rate limit

**State dimension**:
- ✅ User already has 2FA enabled — enable flow should error / no-op
- ✅ Session expired mid-setup → graceful handling
- ✅ Recovery code used during this session, then TOTP attempted —
  any cross-effect?

**Environment**:
- ✅ Mobile auth app vs hardware token — both should produce
  equivalently valid codes (parity test)
- ⛔ Browser variations — not particularly relevant for 2FA code input
- ⛔ DST — TOTP uses UTC, not user time

End result: ~8 negative/edge items added to the checklist. Combined with
happy-path coverage and explicit checklist structure, you have a real
test plan.

## Avoiding the "exhaustive" trap

This list is NOT a coverage goal. Covering every row is not the point.
The point is to systematically surface the relevant ones so you don't
miss the obvious bug.

Two anti-patterns:

1. **Apply all rows blindly** — leads to 100-item checklists with 60
   useless cases. Test Lead will reject.
2. **Skip the walk because it feels tedious** — leads to happy-path-only
   coverage. Test Lead will reject.

Walk the dimensions. Apply judgment. Skip what doesn't fit. Add what
does.
