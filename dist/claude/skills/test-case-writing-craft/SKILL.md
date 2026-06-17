---
name: test-case-writing-craft
description: How to write high-quality manual test cases. Covers case anatomy, step granularity, expected results, preconditions vs steps, frontmatter discipline, when to extract shared steps, and the most common anti-patterns. Use whenever writing or reviewing individual test cases — this is the craft layer, separate from design techniques (which decide what to test) and platform skills (which decide what to look for).
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 1 — Fundamentals of Testing, §1.4.1 Test Activities and Tasks (test design), §1.4.3 Testware (test cases as testware artefact), §1.4.4 Traceability between Test Basis and Testware.
> Learning objectives: FL-1.4.1 (K2) explain test activities (test design produces test cases); FL-1.4.3 (K2) differentiate the testware (the test case is the canonical testware artefact); FL-1.4.4 (K2) explain the value of traceability — the `source_id` frontmatter field IS the test-basis-to-testware link required by §1.4.4, enabling impact analysis, coverage queries, and audit readiness.
> See also: §4.1–§4.4 for techniques that decide *what* the case tests; §3.2 review process for case-level review.

# Test case writing — the craft

Writing test cases is closer to writing technical prose than to writing code.
The reader is another tester (often you in 6 months) who needs to execute the
case quickly, predictably, and without ambiguity. Three things matter:
**one case = one goal**, **steps are atomic actions**, **expected results are
verifiable observations**.

This skill is about quality of individual cases. It does NOT decide *what* to
test (that's `test-design-techniques`) or *which scenarios* to cover
(that's `checklist-design`).

## Case anatomy

A well-formed Kensa case has:

```yaml
---
id: AUTH-001
title: Login with valid credentials redirects to dashboard
priority: critical
status: draft
tags: [smoke, auth, login]
source_id: LIN-89
preconditions: |
  - User account exists: test+std@example.com / Valid-Pass-1
  - User has confirmed their email
  - User is on /login
generated_by: kensa-qa@0.13.0
---

## Steps

1. Enter email `test+std@example.com`
2. Enter password `Valid-Pass-1`
3. Click "Sign in"
   - Expected: redirect to `/dashboard`
   - Expected: greeting "Hi, Standard User" visible

## Description

Happy-path login. Smoke gate on every release.
```

Required parts:
- **Title** — single verifiable claim, imperative or declarative
- **Preconditions** — state of the system BEFORE step 1
- **Steps** — actions, one action per step, in order
- **Expected results** — what to observe, attached to the step that produces it
- **Frontmatter** — id, title, priority, status, tags, source_id, generated_by

Optional but recommended:
- **Description** — one paragraph of context (why this case exists, what risk it covers)
- **Per-step expected results** in addition to or instead of a single end-state

## The "one case, one goal" rule

A case verifies **one claim**. The title is that claim, written as something
you can observe a pass or a fail of.

**Good titles** (one verifiable claim each):
- "Login with valid credentials redirects to dashboard"
- "Login with wrong password shows 'Invalid credentials' error"
- "Login form rejects empty email with inline validation"

**Bad title** (combines several claims):
- "Login form works correctly with various inputs"

If you find yourself adding "and also" / "and verify that" / "также" /
"и при этом" in the title — split the case.

**Exception:** when multiple observations all follow from the same successful
action and a single failure should fail the whole case, keep them as separate
expected results within one case:

- Step: Click "Sign in"
  - Expected: redirect to `/dashboard`
  - Expected: greeting "Hi, X" visible
  - Expected: nav shows "Logout" button

That's still one case, one goal ("successful login lands user on dashboard
with logged-in chrome"), even though there are three observations.

## Steps — atomic actions

Each step is **one action a human can do in one operation**. The granularity
test: "could a junior tester pause halfway through this step and not know what
to do next?" If yes, split it.

**Good — atomic:**
1. Open `/login`
2. Enter email `test@example.com`
3. Enter password `Valid-Pass-1`
4. Click "Sign in"

**Bad — compound:**
1. Open `/login`, enter valid credentials, and click "Sign in"

The bad version isn't shorter where it matters — it's just harder to point
at the failure if step "1" fails because the password field isn't accepting
input.

**Exception:** trivial repetitions in the same UI surface can be grouped if
splitting adds nothing:

- Step: Fill the form
  - email: `test@example.com`
  - password: `Valid-Pass-1`
  - country: `US`
  - terms: checked

Fine if the form is a long signup. The action is "fill the form"; the
data table is auxiliary. Do NOT do this for a 2-3 field form — there it
adds nothing.

## Step verbs — imperative

Use **imperative**: "Open", "Click", "Enter", "Submit".

Not "User opens" / "The user clicks" / "Opens" — those add words without
information.

Not "Should click" / "Need to enter" — those soften the instruction
unnecessarily.

The case is read by someone about to execute it. The implicit subject is
"you, the tester, now". Imperative matches that.

## Expected results — verifiable observations

A good expected result tells the tester **what to look for**, not what
*should* be true in some abstract sense.

**Good:**
- Toast appears at top right: "Profile saved"
- URL changes to `/profile/edit`
- `POST /api/v1/profile` returns 200 with body containing `"updated_at"`

**Bad:**
- Profile should be saved
- The system works correctly
- No errors should occur

If the expected result can't be observed by a tester from outside the
system, it's not an expected result. Either find the observable proxy or
note explicitly: "Verified via DB query — see admin tooling."

### Where expected results live

Two valid patterns. Pick one per project and stick to it (record in
`conventions.md`).

**Pattern A — per-step expected:**

1. Click "Save"
   - Expected: toast "Profile saved"
   - Expected: form fields become read-only

**Pattern B — end-state expected:**

## Steps
1. Click "Save"

## Expected
- Toast "Profile saved"
- Form fields become read-only

Pattern A is better when you want failure points granular. Pattern B is
better when many small steps lead to one final state and intermediate
observations don't add value. Default to A.

## Preconditions vs the first step

A common point of confusion. The rule:

- **Preconditions** = state that must be true BEFORE the case begins. Setup.
  Not what's being tested.
- **Step 1** = the first action whose result is being evaluated.

"Log in as admin" is a precondition if the case is testing what admin sees.
"Log in as admin" is step 1 if the case is testing admin login.

Common preconditions that belong out of steps:
- Specific user account exists with specific properties
- System is in a specific state (some other case ran successfully, some
  setting is configured)
- Tester is on a specific URL or in a specific app section
- Test data exists (seed data, specific records)

If your case has 10 steps and the first 6 are "log in, navigate, set up
filters", you're testing the wrong thing. Either:
- Move setup into preconditions (and assume the tester knows how to do it,
  or link to a setup helper case), OR
- Split into two cases: one for the setup-as-test, one for the actual scenario.

## Length — when to split

A case over ~12 steps is suspect. Possible causes:

1. **You're testing too many goals in one case** → split by goal.
2. **Setup is in steps** → move to preconditions or shared step.
3. **It's a multi-screen flow that genuinely needs all those steps** →
   acceptable, but consider whether each screen could have its own case
   for the per-screen validations, and one end-to-end case for the flow.

Hard rule: if you can't summarize the case in one sentence (the title),
the case is too big.

## Shared steps — when to extract

Extract to `.tms/shared-steps/<name>.md` when:

- The same sequence of 3+ steps appears in 3+ cases.
- The sequence is a fixed prerequisite for a feature area (e.g., "log in as
  admin and navigate to user management").
- The sequence is owned by a different team (e.g., the auth flow), and you
  want their changes to propagate automatically to your cases.

Do NOT extract when:

- The sequence appears once or twice.
- The sequence is specific to one case and not reused.
- You'd be hiding the test setup behind indirection for no real saving.

Reference shared steps inline:

```markdown
1. Use shared step: `auth/login-as-admin`
2. Navigate to "User management"
3. ...
```

## Frontmatter discipline

Every field present in your project's `conventions.md` must be present in
every case. No "I'll fill it later" — that's how `status: draft` cases
become permanent.

**`source_id`** — always include the SOT reference even if it's just a
ticket ID. This is the link back to the source of truth and to
`/update-feature` later.

**`tags`** — match the project's tag taxonomy from `learned/tags.md`. Don't
invent new tags without telling the Test Lead.

**`priority`** — be honest. Default to `medium` if unsure; reserve
`critical` for actual smoke / release-gate cases.

## Common anti-patterns

### 1. "Should" / "Must" in expected results

> Expected: The button should be enabled.

Cut "should". State the observation:

> Expected: The button is enabled.

"Should" is fine in the spec ("the button should be enabled when..."). In
a test case, you're describing what you'll observe, not what ought to be
true philosophically.

### 2. "Verify that..." preamble in every step

> 1. Verify that the user can click the login button.

Just:

> 1. Click the login button.
>    - Expected: ...

"Verify" is redundant — that's what every step is doing.

### 3. Implementation details in steps

> 1. Click the element with selector `#login-btn` (xpath: `//button[@id='login-btn']`)

The tester clicks "Sign in" (or whatever the button says). Selector lives
in automation code, not in the manual case.

### 4. Snapshot-coupled expected results

> Expected: The page looks like screenshot-2024-01-15.png

Brittle. Either describe the observable state in words, or attach the
screenshot as a reference but state the textual claim:

> Expected: The header shows "Welcome back, Jordan" with the avatar to its left.

### 5. Test data inline when it should be in preconditions

> 1. Create a user with email test_a@example.com, password Pass-1, role admin, ...
> 2. Log in as test_a@example.com
> 3. ...

User creation is precondition (or a shared step) unless creating the user IS
the test. Then step 1 should be "Submit the registration form with [data]" —
the action whose result you're evaluating.

### 6. Ambiguous "etc."

> Steps:
> - Fill in name, email, country, etc.

"Etc." in a test case is a bug. List the fields or say "all required
fields per spec" and reference the spec.

## Output checklist for a finished case

Before considering a case done, check:

- [ ] Title is a single verifiable claim
- [ ] Preconditions describe pre-action state, not pre-test actions
- [ ] Steps are atomic and imperative
- [ ] Expected results are observable, not aspirational
- [ ] Frontmatter complete per project conventions
- [ ] `source_id` set
- [ ] `generated_by` set
- [ ] Shared steps used where they exist
- [ ] No "should", "must", "etc." in steps or expected results
- [ ] Case fits in your head (you could re-state it in one sentence)
