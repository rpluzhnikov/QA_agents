---
name: collaboration-based-approaches
description: ISTQB CTFL §4.5 — collaborative user-story writing (3 C's + INVEST), acceptance-criteria formats (scenario-oriented Given/When/Then vs rule-oriented bullet/table), and ATDD as a test-first approach. Load when evaluating a user story's testability, when AC are missing or vague (so you can offer one of the two ISTQB formats), or when the user asks for ATDD-style work.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 4 — Test Analysis and Design, §4.5 Collaboration-based Test Approaches (§4.5.1 collaborative user story writing, §4.5.2 acceptance criteria, §4.5.3 ATDD).
> Learning objectives: FL-4.5.1 (K2) explain how collaborative user story writing helps; FL-4.5.2 (K2) classify AC formats; FL-4.5.3 (K2) explain how ATDD is used.
> See also: §1.4.1 (test conditions = AC); §2.1.3 (TDD/ATDD/BDD as test-first approaches); §3 (static testing of user stories is a sibling activity); `checklist-design` for how AC feeds the checklist.

# Collaboration-based approaches

§4.5 is about **defect avoidance through collaboration**, not just
defect detection. The previous techniques (§4.2 black-box, §4.3
white-box, §4.4 experience-based) all assume "the spec exists, derive
tests from it". This section assumes "the spec doesn't fully exist
yet, and the act of writing it collaboratively prevents defects".

Two things you'll use this skill for inside Kensa:

1. **Evaluating a user story's testability** when the SOT is a user
   story (Linear/Jira). If the story fails INVEST or the 3 C's, push
   back BEFORE writing cases.
2. **Recommending an AC format** when the user's AC are missing or
   vague — offer one of the two ISTQB-standard formats and translate
   between them.

ATDD is also covered — when the user invokes `/new-feature` on a
spec that has no implementation yet, your output IS the ATDD test
set.

## User stories — the 3 C's (§4.5.1)

> "A user story represents a feature that will be valuable to either
> a user or purchaser of a system or software. User stories have
> three critical aspects (Jeffries 2000), called together the '3 C's':
> Card – the medium describing a user story; Conversation – explains
> how the software will be used; Confirmation – the acceptance
> criteria."
> — CTFL 4.0 §4.5.1

| C | Meaning | What to expect |
|---|---|---|
| **Card** | The medium (Linear/Jira ticket, index card, board entry) | A short story in the standard format |
| **Conversation** | How the software will be used (verbal or written) | Comments, design notes, threads. Often where the real requirement lives. |
| **Confirmation** | The acceptance criteria | A separate field, or a templated section in the description |

When you read a SOT story in Kensa:

- **Card** = the ticket title + the user-story format line ("As a X,
  I want Y, so that Z").
- **Conversation** = ticket comments, attached docs, design files,
  Slack threads (which you may or may not see).
- **Confirmation** = the AC section.

If the **conversation** isn't surfaced in the SOT, you're working
blind. Ask the user: "Anything in the threads/comments I should know
about beyond the ticket body?"

## The standard user-story format

> "As a [role], I want [goal to be accomplished], so that I can
> [resulting business value for the role]"
> — CTFL 4.0 §4.5.1

If a SOT story doesn't follow this shape, it doesn't necessarily
mean it's bad — but it often means the **business value** ("so that")
wasn't articulated. That matters because:

- Without the "so that", you can't tell what acceptance really means.
- Without the "so that", you may write cases that verify the
  mechanism but not the value.

If business value is missing, flag back to the user during
scope-analysis.

## INVEST — the testability checklist (§4.5.1)

> "Good user stories should be: Independent, Negotiable, Valuable,
> Estimable, Small and Testable (INVEST)."
> — CTFL 4.0 §4.5.1

Use INVEST as your pre-write check:

| Letter | Means | If it fails, the symptom is |
|---|---|---|
| **I**ndependent | Can be tested without depending on other unfinished stories | "We can't test this until LIN-104 ships" → defer or split |
| **N**egotiable | Details aren't locked in stone; collaboration possible | Spec is a contract treated as immutable → ask "is this final?" |
| **V**aluable | Delivers value to a user or purchaser | Spec describes refactoring/internal work → it's not a user story |
| **E**stimable | Team can estimate effort | Estimate is wildly variable → spec is too vague |
| **S**mall | Fits in one iteration | Spec spans 6 weeks of work → split into smaller stories |
| **T**estable | Can be verified | AC vague or absent → push back; can't write cases against "make it better" |

> "If a stakeholder does not know how to test a user story, this may
> indicate that the user story is not clear enough, or that it does
> not reflect something valuable to them, or that the stakeholder
> just needs help in testing (Wake 2003)."
> — CTFL 4.0 §4.5.1

If YOU (the test-lead-agent or qa-engineer-agent) don't know how to
test a story, that's the same signal. Don't proceed silently. Ask.

## Acceptance criteria (§4.5.2)

> "Acceptance criteria for a user story are the conditions that an
> implementation of the user story must meet to be accepted by
> stakeholders. From this perspective, acceptance criteria may be
> viewed as the test conditions that should be exercised by the
> tests."
> — CTFL 4.0 §4.5.2

**AC = test conditions** (per §1.4.1). This is the key bridge:
the test analysis activity takes AC as input and produces
prioritized test conditions… which often ARE the AC themselves.
That's why the Kensa `qa-engineer-agent`'s checklist often maps
1:1 to AC.

### What AC are used for (§4.5.2)

- Define the scope of the user story
- Reach consensus among stakeholders
- Describe both positive and negative scenarios
- Serve as a basis for user story acceptance testing
- Allow accurate planning and estimation

### The two ISTQB-standard AC formats

The CTFL recognises two:

#### 1. Scenario-oriented (Given/When/Then)

Same format BDD uses (per §2.1.3). Each scenario is a concrete
sequence.

Example:

```gherkin
Scenario: Successful 2FA setup
  Given I am logged in to my account
  And 2FA is not yet enabled
  When I navigate to Settings → Security
  And I click "Enable 2FA"
  And I scan the QR code with my authenticator
  And I enter the 6-digit code
  Then 2FA is enabled
  And I receive a confirmation message

Scenario: Setup fails with invalid code
  Given I am at the 2FA setup screen
  When I enter "000000" as the verification code
  Then I see "Invalid code, please try again"
  And 2FA remains disabled
```

**When to recommend:** features with sequence-dependent behaviour
(flows, wizards, multi-step interactions), teams that already use
BDD, when stakeholders include non-technical readers.

#### 2. Rule-oriented (bullet list or input-output table)

Each criterion is a verifiable rule.

Example bullets:

```markdown
**Acceptance criteria for "Add 2FA":**
- User can enable 2FA from Settings → Security
- QR code is displayed and includes the issuer name
- A 16-character base32 secret is shown below the QR
- Invalid TOTP code shows error and does not enable 2FA
- After enabling, "2FA enabled" is shown on the Security page
- After enabling, login requires both password and TOTP code
- Disabling 2FA requires re-entering the password
```

Example table:

| Input | Expected |
|---|---|
| Valid TOTP, within ±30s window | Setup completes |
| Valid TOTP, outside ±30s window | Setup fails with "code expired" |
| 6 chars non-numeric | Setup fails with "invalid format" |
| Empty code | Setup fails; submit button disabled |

**When to recommend:** features that are predominantly business rules
(pricing, eligibility, permissions, configuration), input-output
mappings, when scenario sequences would be tedious.

### Translating between formats

Sometimes the user's AC is in one format and you need the other
(e.g., to feed `test-design-techniques` decision-table thinking).

**Rule → scenario:**

> "Invalid TOTP code shows error and does not enable 2FA"
> →
> Given I am at the 2FA setup screen, When I enter an invalid TOTP
> code, Then I see an error message AND 2FA is not enabled.

**Scenario → rule:**

> "Given I'm logged in, When I click Enable 2FA, Then a QR code is
> displayed and a base32 secret is shown"
> →
> Bullet: "Enable 2FA shows a QR code and a 16-character base32
> secret."

Don't change the meaning, just the form.

### Custom AC formats

> "Most acceptance criteria can be documented in one of these two
> formats. However, the team may use another, custom format, as
> long as the acceptance criteria are well-defined and unambiguous."
> — CTFL 4.0 §4.5.2

If `project.md` documents a project-specific AC format, use it. The
ISTQB framing is permissive: any format that's well-defined and
unambiguous is acceptable.

## ATDD — Acceptance Test-Driven Development (§4.5.3)

> "ATDD is a test-first approach. Test cases are created prior to
> implementing the user story. The test cases are created by team
> members with different perspectives, e.g., customers, developers,
> and testers."
> — CTFL 4.0 §4.5.3

### The ATDD workflow

1. **Specification workshop** — team analyses, discusses, and writes
   the user story and its AC together. Ambiguities resolved here.
2. **Create test cases** — based on AC. By team or by tester. These
   are examples of how the software should work.
3. **Implement** — developers write code that makes the tests pass.
4. **Automate (optional)** — if expressed in a framework-supported
   format, tests become executable requirements.

### Order of cases per §4.5.3

> "Typically, the first test cases are positive, confirming the
> correct behavior without exceptions or error conditions… After the
> positive test cases are done, the team should perform negative
> testing. Finally, the team should cover non-functional quality
> characteristics."
> — CTFL 4.0 §4.5.3

Order: **positive → negative → non-functional.** This is the order
the qa-engineer-agent should organise the checklist in too.

### Important ATDD constraints (§4.5.3)

- **Tests must cover all characteristics of the user story.** Every
  AC has at least one test.
- **Tests should not go beyond the story.** Scope discipline — if
  it's not in the AC, it's not in the tests (or it's flagged as
  proposed addition).
- **No two test cases should describe the same characteristics of
  the user story.** No duplicates.

These map exactly to the Kensa case-review rubric:

- "Coverage" (every AC has a case) — direct ATDD requirement.
- "Scope adherence" (nothing outside the assigned scope) — direct
  ATDD requirement.
- "Title quality" (each title is one verifiable claim — no
  duplicates) — direct ATDD requirement.

So when the user invokes `/new-feature` on a pre-implementation
spec, the Kensa workflow IS ATDD operationalised.

## Cross-reference — AC as test conditions

§1.4.1 defines test analysis as: "analyzing the test basis to
identify testable features. Associated **test conditions** are
defined and prioritized."

§4.5.2 says AC ARE test conditions.

So when the qa-engineer-agent reads the AC and produces a checklist,
they're doing test analysis. The checklist items are prioritized
test conditions. The cases that come from them are the test design
output. See `testing-fundamentals` for the activity model.

## Worked example — INVEST review of a SOT story

User-provided Linear story:

```
LIN-89: "Improve security"

As a user, I want better security, so that my account is safe.

AC:
- Add 2FA
- Make passwords stronger
- Reduce risk of account takeover
```

INVEST review:

- **I**ndependent: ⚠️ "Add 2FA" and "make passwords stronger" could be
  separate stories that ship independently.
- **N**egotiable: ✅ (assumed; nothing locked).
- **V**aluable: ⚠️ "Make account safe" is value but not measurable.
- **E**stimable: ❌ Effort wildly variable — could be 1 week or 6
  weeks depending on what "stronger" means.
- **S**mall: ❌ This is three stories (2FA, password policy,
  takeover detection).
- **T**estable: ❌ "Reduce risk of account takeover" is not directly
  testable as one criterion.

Feedback to user:

> "This story fails INVEST in 4/6 dimensions. Recommend splitting
> into:
>
> - LIN-89a: Enable TOTP-based 2FA (testable, small, valuable)
> - LIN-89b: Enforce password policy (specify min length, complexity,
>   reuse window — currently undefined)
> - LIN-89c: Lockout after N failed attempts (specify N, duration)
>
> Each can have its own AC. Want me to draft the AC for 89a as a
> starting point?"

That's static testing of the user story per Chapter 3, using INVEST
as the review checklist.

## Worked example — AC drafting in scenario format

Story is well-formed but has no AC. Test Lead offers to draft:

```markdown
## Suggested AC for "User can enable TOTP 2FA"

**Scenario-oriented format:**

Scenario: Successful 2FA setup
  Given I am logged in
  And 2FA is not enabled on my account
  When I navigate to Settings → Security → Two-Factor Authentication
  And I click "Enable"
  And I scan the QR code with my authenticator app
  And I enter the 6-digit verification code
  Then 2FA is enabled
  And the Security page shows "Two-Factor Authentication: On"

Scenario: Setup fails with invalid code
  Given I am at the 2FA verification step
  When I enter "000000"
  Then an error "Invalid code" is shown
  And 2FA remains disabled
  And I can retry

Scenario: Re-authentication required to disable
  Given 2FA is enabled on my account
  When I click "Disable" on the Security page
  Then I am prompted to re-enter my password
  And only after correct password 2FA is disabled

Want me to proceed with these AC, or would rule-oriented format
suit your team better?
```

This is the Test Lead doing collaborative AC creation per §4.5.1.

## Worked example — ATDD workflow

User invokes `/new-feature` on a spec with no implementation yet:

```
LIN-104: "Add per-comment reactions"
Status: Not started
Implementation: None
AC: present
```

Test Lead identifies this as ATDD context (test-first). Workflow:

1. **Specification check:** AC are present and pass INVEST. Test Lead
   reviews them statically and flags one ambiguity to the user.
2. **Test analysis:** qa-engineer-agent produces checklist mapped to
   AC. Positive cases first, then negatives, then non-functional
   (perf, a11y).
3. **Test design:** qa-engineer-agent writes cases. These become
   executable specification — when dev implements the feature, they
   make these cases pass.
4. **Report to user:** "ATDD set ready. These cases define
   acceptance — devs can use them to drive implementation."

In an automated/BDD-capable project, these cases would later be
translated to executable scenarios. In Kensa they stay as manual
test cases used as authoritative requirements during dev.

## When to load this skill

- QA Engineer (qa-engineer-agent) at the start of test analysis when the
  SOT is a user story — check INVEST, parse AC.
- Test Lead during scope-analysis when the spec is a user story — flag
  testability issues per INVEST.
- Either agent when AC are missing or vague — offer to draft AC in
  one of the two ISTQB formats.
- When the user mentions ATDD, BDD, or specification workshops —
  recognize the workflow and adapt.
- When `/new-feature` is invoked on a spec without implementation —
  recognize it as ATDD context.

## Anti-patterns

- Writing cases against a story that fails INVEST. You'll produce
  bad cases. Push back first.
- Assuming AC exhaust the test conditions. AC are the spec'd
  conditions; you still need to derive negative paths and
  non-functional checks per `negative-and-edge-cases`.
- Going "beyond the story" — adding cases for behaviour not in AC.
  Per §4.5.3, scope discipline matters. If you think extra cases
  are needed, flag as proposed additions, don't silently add.
- Writing AC in a format the user's team doesn't use. Match
  `project.md` conventions first.
- Forcing Given/When/Then on a feature that's a rules/lookup table
  (better as rule-oriented), or vice versa. Match the format to
  the feature shape.
