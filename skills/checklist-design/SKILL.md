---
name: checklist-design
description: How to structure a coverage checklist for a feature before writing test cases. Used by QA Engineers in Stage 1 (checklist phase) and by the Test Lead when reviewing those checklists. A checklist is not a list of test cases — it's a list of claims that need cases, organized so the Test Lead can confirm coverage at a glance.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 1 — Fundamentals of Testing, §1.4.1 Test Activities and Tasks, §1.4.3 Testware; Chapter 4 — Test Analysis and Design, §4.5.2 Acceptance Criteria; Chapter 5 — Managing the Test Activities, §5.1.5 Test Case Prioritization.
> Learning objectives: FL-1.4.1 (K2) explain test activities (the checklist is the output of test analysis — naming test conditions); FL-1.4.3 (K2) differentiate the testware (the checklist is testware produced by test analysis); FL-4.5.2 (K2) classify AC formats (the checklist consumes AC as test conditions); FL-5.1.5 (K3) apply prioritization (must / should / nice tiers = risk-based + requirements-based prioritization).
> See also: §4.4.3 checklist-based testing technique; §5.2 risk-based testing for how risk drives the priority tiers.

# Checklist design

A checklist is the "table of contents" of the test cases that will be
written next. Its purpose is to make coverage **inspectable** before
the QA engineer writes 30 cases that may need restructuring.

A good checklist:

- Lists **claims to verify**, not **cases to write**
- Groups by area / scenario / risk class so the reader can scan
- Marks priority (must-have vs nice-to-have)
- References SOT for each non-obvious claim
- Is short enough to read in under 2 minutes

## Structure

```markdown
# Checklist — <feature name>

**Source:** <SOT ref> · **Suite target:** `<suite path>` · **Estimated cases:** ~N

## Must-have (release blocker)

### Happy path
- [ ] Enable 2FA: scan QR, enter valid code, setup completes [LIN-89 §AC-1]
- [ ] Login with 2FA: password + valid TOTP → success [LIN-89 §AC-2]
- [ ] Disable 2FA: re-auth + confirm → 2FA off [LIN-89 §AC-3]

### Validation / negative
- [ ] Enter invalid TOTP code (random 6 digits) → error, don't proceed
- [ ] Enter expired TOTP code (>30s old) → error
- [ ] Re-use a TOTP code within 30s window → second attempt rejected
- [ ] Disable 2FA without re-auth → re-auth prompt appears

### Error / edge
- [ ] Enable 2FA when already enabled → idempotent or appropriate error
- [ ] Server unavailable during setup → graceful error, no half-state

## Should-have

### Recovery codes
- [ ] Recovery codes are shown at setup [LIN-89 §AC-4]
- [ ] Recovery code can be used in place of TOTP
- [ ] Used recovery code can't be reused
- [ ] Regenerating codes invalidates old codes

### Cross-cutting
- [ ] Active sessions behavior when 2FA enabled (ASSUMPTION: kept active)
- [ ] 2FA setting appears in account export (GDPR-relevant)

## Nice-to-have (if scope allows)

- [ ] Audit log entry created for enable / disable
- [ ] Email notification on enable / disable
```

## Composition rules

### What goes in must-have

- Anything explicitly in the acceptance criteria
- Anything whose absence would block release
- Smoke-test-level cases (happy paths for the primary flows)

### What goes in should-have

- Validation and negative paths for the primary flows
- Edge cases the spec doesn't mention but a reasonable PM would expect
- Cross-cutting concerns (sessions, audit, GDPR, accessibility, i18n)
  where applicable

### What goes in nice-to-have

- Tangential observations (audit log content, email copy)
- Improvements over what's strictly required
- Coverage that would be valuable but isn't critical for this batch

### What does NOT belong

- Implementation details ("verify the database column is named `totp_secret`")
- Code review items ("verify the secret is encrypted at rest")
- Performance ("response time < 200ms") — separate test discipline
- Things outside the QA Engineer's assigned scope

## References

Each non-obvious item should link to its source. Use the same shorthand
across the checklist:

- `[LIN-89]` — ticket
- `[LIN-89 §AC-2]` — specific acceptance criterion
- `[fig: 12:345]` — Figma node ID
- `[wiki: 2fa-spec]` — Confluence/Notion doc
- `[ASSUMPTION]` — no source, you're filling a gap

Items without references should be either obvious from the feature
(happy path) or marked `[ASSUMPTION]`.

## Annotating techniques

If you're applying a specific test design technique, note it in the
checklist so the Test Lead can verify the right technique was chosen:

```markdown
### TOTP code input field [3-value BVA]
- [ ] 5-digit code → rejected
- [ ] 6-digit code (valid) → accepted
- [ ] 7-digit code → rejected
- [ ] 6-digit non-numeric → rejected
```

Or for a state machine:

```markdown
### 2FA enable flow [state transitions — all valid]
- [ ] Disabled → Setup → Enabled
- [ ] Setup → Cancel → Disabled
- [ ] Enabled → DisablePrompt → Enabled (if user cancels)
- [ ] Enabled → DisablePrompt → Disabled (if user confirms)
```

This makes review trivial — the Test Lead can verify "yes, valid transitions
are all covered".

## Length

Aim for under 30 items per QA Engineer package. If you have more, either:

- The scope is too big (talk to Test Lead about splitting)
- You're listing cases-as-claims (compress: "Login with N variants of
  invalid TOTP" instead of 5 separate items, where they'd just be data
  variations)

## What the Test Lead checks

When the Test Lead reviews your checklist, expect them to look for:

1. **Coverage gaps** — anything in the spec / AC not represented?
2. **Out-of-scope items** — anything that should be in a different QA Engineer
   package?
3. **Missing references** — items with no source where one should exist
4. **Wrong technique** — if you marked `[3-value BVA]` and didn't include
   both neighbors of each boundary, the Test Lead will catch that
5. **Assumption pile-up** — too many `[ASSUMPTION]` markers signal you
   should have stopped and asked

If the Test Lead sends back with comments, address each comment specifically.
Don't just re-submit the checklist with a paragraph saying "addressed
feedback".
