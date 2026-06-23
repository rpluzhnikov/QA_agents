---
name: white-box-techniques-overview
description: ISTQB CTFL §4.3 — statement and branch coverage at the level a manual-QA tester needs to recognize them in conversation with developers, even if the manual case itself can't directly produce code coverage. Load when the user or a dev mentions "we have 80% branch coverage" or when planning confirmation tests for a bug fix and you need to talk about whether the fix's added branch is exercised.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 4 — Test Analysis and Design, §4.3 White-Box Test Techniques (§4.3.1 statement testing, §4.3.2 branch testing, §4.3.3 value of white-box).
> Learning objectives: FL-4.3.1 (K2) explain statement testing; FL-4.3.2 (K2) explain branch testing; FL-4.3.3 (K1) recall the value of white-box testing.
> See also: §2.2.2 (white-box as a test type); §4.2 for the black-box techniques that DO drive Kensa case authoring; `test-design-techniques` for the techniques you actually USE when writing cases.

# White-box techniques — recognition level

This skill is deliberately scoped to **recognition**, not authoring.

Kensa agents don't read source code. They can't measure statement
coverage or branch coverage directly. What they CAN do:

- Recognize the terminology when a developer or the user uses it.
- Translate "80% branch coverage" into something meaningful (and
  unmeaningful) for the test session.
- Apply white-box THINKING to black-box test design when the spec
  describes branches and loops — exercise both sides of every
  visible decision, test loop boundaries 0/1/many.
- Push back politely when someone says "we have 100% coverage so it's
  fully tested" — that's a misconception worth correcting.

If you find yourself trying to author white-box cases inside a Kensa
session, you've drifted out of scope. Recognize, don't author.

## Why §4.3 is in the syllabus despite Kensa not authoring white-box

Foundation-level testers must:

1. Talk to developers without confusion when they bring up coverage.
2. Read a coverage report without misinterpreting it.
3. Recognize when a manual case can approximate white-box intent.
4. Avoid the "100% coverage = bug-free" fallacy.

That's the bar this skill sets.

## Statement testing and statement coverage (§4.3.1)

> "In statement testing, the coverage items are executable
> statements. The aim is to design test cases that exercise statements
> in the code until an acceptable level of coverage is achieved.
> Coverage is measured as the number of statements exercised by the
> test cases divided by the total number of executable statements in
> the code, and is expressed as a percentage."
> — CTFL 4.0 §4.3.1

What this means in practice:

```python
def discount(total):
    d = 0
    if total > 100:
        d = total * 0.10      # statement A
    return total - d          # statement B
```

A single test with `total=150` exercises both statement A and
statement B → 100% statement coverage. But this DOESN'T tell you the
function handles `total ≤ 100` correctly, because the `else` branch
(no statement, just falling through) wasn't tested.

### Limitations §4.3.1 explicitly calls out

- Doesn't detect data-dependent defects (e.g., division by zero only
  fails when denominator = 0).
- Doesn't ensure all decision logic is tested — may not exercise all
  branches.

## Branch testing and branch coverage (§4.3.2)

> "A branch is a transfer of control between two nodes in the control
> flow graph… In branch testing the coverage items are branches and
> the aim is to design test cases to exercise branches in the code
> until an acceptable level of coverage is achieved."
> — CTFL 4.0 §4.3.2

Same example:

```python
def discount(total):
    d = 0
    if total > 100:           # decision: true branch + false branch
        d = total * 0.10
    return total - d
```

100% branch coverage requires:

- `total=150` (true branch).
- `total=50` (false branch — the implicit else).

Now both possible outcomes of the decision are tested.

### The key relationship

> "Branch coverage subsumes statement coverage. This means that any
> set of test cases achieving 100% branch coverage also achieves
> 100% statement coverage (but not vice versa)."
> — CTFL 4.0 §4.3.2

So if a dev says "we have 95% branch coverage", that's stronger than
"95% statement coverage". And "100% statement coverage" is the lower
bar — common for dev teams to claim but it leaves untested branches.

### Limitations §4.3.2 explicitly calls out

- Doesn't detect defects requiring a specific path through the code
  (path coverage is stronger, not covered in CTFL).

## The value of white-box testing (§4.3.3)

> "A fundamental strength that all white-box test techniques share is
> that the entire software implementation is taken into account
> during testing, which facilitates defect detection even when the
> software specification is vague, outdated or incomplete."
> — CTFL 4.0 §4.3.3

But:

> "A corresponding weakness is that if the software does not
> implement one or more requirements, white-box testing may not
> detect the resulting defects of omission."
> — CTFL 4.0 §4.3.3

So:

- **White-box catches:** dead code, redundant logic, defects in
  implementation that the spec doesn't mention.
- **White-box misses:** missing features. Code that should exist but
  doesn't. The 100%-branch-covered system can still fail acceptance
  if a required behaviour was never coded.

That's why white-box and black-box are complementary, not
substitutes.

## Why manual QA still cares

Even though you don't author white-box cases:

### 1. Pairing on confirmation tests

When a developer fixes a bug, they add code — often a new branch.
The confirmation test you write (per §2.2.3) should exercise the new
branch's true outcome AND its false outcome, even if you can't see
the code. Ask the dev: "What new condition did you add? Show me an
input that triggers it and one that doesn't."

### 2. Reading a coverage report

If the user shares a coverage report, know what you're looking at:

- "Statement coverage: 92%" — 8% of code statements never executed
  by any test. Strong signal of untested feature paths.
- "Branch coverage: 65%" — 35% of decision outcomes never tested.
  Much weaker than the statement number suggests.
- "Line coverage" — usually a synonym for statement coverage in
  common tools.
- "Function coverage" — % of functions called by at least one test.
  Weakest of the four.

A coverage report does NOT measure:

- Whether the test assertions are correct.
- Whether the test would catch a regression.
- Whether the right things are being tested.

So when the user says "we have 90% coverage", an appropriate response
is: "That's a useful metric for executed code. It doesn't tell us
whether the cases would catch a bug, or whether anything is missing.
What are the cases checking against?"

### 3. Pushing back on "100% coverage = it's tested"

This is the absence-of-defects fallacy (§1.3, principle 7) wearing
a coverage-metric disguise. Polite pushback:

> "100% branch coverage means every branch was executed at least
> once. It doesn't mean every input was tried, every combination
> was checked, or every requirement is implemented. The acceptance
> tests are what validate it does what users need."

## When white-box thinking SHOULD influence a manual case

Even without source access, when the **spec** mentions branches,
decisions, or loops, apply white-box-style coverage to the
specification-visible structure:

### Visible decisions in the spec

Spec says: "If the user is a premium subscriber AND has more than 5
items in cart, apply a 15% discount; otherwise show the regular
total."

Apply branch-style coverage to the spec's visible decision:

- Premium + >5 items → discount
- Premium + ≤5 items → no discount
- Non-premium + >5 items → no discount
- Non-premium + ≤5 items → no discount

This is decision-table testing (per `test-design-techniques` §4.2.3),
but the reasoning is "every decision branch exercised", which is
white-box THINKING applied to a black-box artefact.

### Visible loops in the spec

Spec says: "User can attach up to 5 files; uploading a 6th replaces
the oldest."

Apply loop-boundary testing (0, 1, many, max, max+1):

- 0 files attached
- 1 file attached
- 3 files attached (typical)
- 5 files attached (max)
- 6 files attempted (max+1, triggers replacement)

That's white-box-derived discipline applied to a black-box scenario.

### Confirmation tests for bug fixes

The bug report says: "Discount doesn't apply when total = 100."

Likely root cause: off-by-one in the threshold check (`>` vs `≥`).
Your confirmation test should specifically exercise the boundary:

- `total = 99` (no discount expected)
- `total = 100` (discount expected after fix)
- `total = 101` (discount expected)

This is 3-value BVA (per `test-design-techniques` §4.2.2), but the
motivation comes from white-box reasoning about the fix.

## What's OUT OF SCOPE for this skill

Per §4.3.3, the syllabus explicitly leaves these to higher levels
(CTAL-TTA, code-coverage tools, automation):

- Path coverage — exercising every distinct execution path.
- MC/DC (Modified Condition/Decision Coverage) — used in
  safety-critical (DO-178C avionics, IEC 61508).
- LCSAJ, basis-path testing — older variants.
- API/structural testing at higher levels.

If the user asks for any of these, defer to a dev/automation engineer
or escalate. Kensa is not the right tool.

## Worked example — recognising white-box claims

User: "The dev team says they have 88% line coverage and 72% branch
coverage on the auth module. Are we covered for 2FA?"

Reasoning using §4.3:

1. Line coverage 88% ≈ statement coverage 88%. Branch coverage 72%
   means 28% of decision outcomes are never tested. That's
   significant.
2. The gap between line (88%) and branch (72%) suggests there are
   `if` statements where only one outcome is tested (often the happy
   path).
3. Coverage metrics don't validate the new 2FA acceptance criteria.
   Even if branch coverage were 100%, missing features wouldn't show
   up (§4.3.3 omission weakness).
4. Response to user: "Coverage tells us the unit tests exercise most
   of the code paths but not all decision outcomes. It doesn't tell
   us whether the 2FA acceptance criteria are correctly implemented
   end-to-end. Our system-level cases against the AC are still
   needed."

## Worked example — confirmation test for a bug fix

User: "Bug fix: discount was wrongly applied when total = 100.
Original logic used `total >= 100`. Dev changed it to `total > 100`.
Write the confirmation test."

Reasoning using §4.3 + §2.2.3:

1. The fix changes a branch condition. The original branch had a
   defect at the boundary value 100 — discount applied when it
   shouldn't.
2. Confirmation test must exercise the fixed condition at and near
   the boundary.
3. 3-value BVA on 100: test 99, 100, 101.

```yaml
---
id: checkout.discount.confirm-bug-203
title: Discount does not apply at total = 100 after fix
tags: [confirmation, bug-fix:LIN-203]
source_id: LIN-203
---

## Preconditions
- User is logged in
- Cart total can be set by adding items priced at $99, $100, $101

## Steps
| # | Action | Expected |
|---|---|---|
| 1 | Set cart total to $99 | No discount shown |
| 2 | Set cart total to $100 | No discount shown (fixed) |
| 3 | Set cart total to $101 | 10% discount shown |
```

You don't see the code. You used white-box THINKING (the bug was at
a boundary in a decision) to drive a black-box BVA test.

## When to load this skill

- Anyone (Test Lead or QA Engineer) when the user or a dev mentions coverage
  percentages, branch coverage, statement coverage, line coverage,
  path coverage, MC/DC.
- Test Lead when reviewing a confirmation-test brief for a bug fix in
  code with visible decision logic.
- Test Lead when teaching the user the difference between code coverage
  and test coverage of requirements.
- QA Engineer when the spec describes explicit branches/decisions/loops
  and you want to apply white-box-disciplined coverage on the
  spec-visible structure.

## Anti-patterns

- Authoring "white-box" cases inside Kensa. You can't see the source;
  you can't measure code coverage. If the situation demands real
  white-box testing, hand off to a developer.
- Repeating the "100% coverage = bug-free" claim. It violates
  principle 7 of §1.3 (absence-of-defects fallacy).
- Conflating "test coverage" (of requirements/AC) with "code
  coverage" (of statements/branches). They measure different
  things.
- Asking the user for source code so you can write white-box cases.
  Out of scope — defer to dev or automation engineers.
- Treating statement coverage and branch coverage as equivalent —
  branch is the stronger metric (subsumes statement).
