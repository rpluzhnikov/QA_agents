---
name: static-testing-reviews
description: ISTQB CTFL Chapter 3 — static testing of specs, user stories, test cases themselves, and any work product; the ISO 20246 review process (planning → initiation → individual review → communication & analysis → fixing); review roles; review types (informal / walkthrough / technical / inspection) and how to pick one. Load before reviewing a SOT spec for testability, before reviewing other QA Engineers' cases, or when teaching the user how the plugin's own 2-pass review fits ISTQB Ch 3.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 3 — Static Testing, §3.1 Static Testing Basics, §3.2 Feedback and Review Process.
> Learning objectives: FL-3.1.1 (K1) recognize work products examinable by static testing; FL-3.1.2 (K2) explain the value of static testing; FL-3.1.3 (K2) compare static vs dynamic testing; FL-3.2.1 (K1) identify benefits of early stakeholder feedback; FL-3.2.2 (K2) summarize review process activities; FL-3.2.3 (K1) recall review roles; FL-3.2.4 (K2) compare review types; FL-3.2.5 (K1) recall review success factors.
> See also: §1.3 (early-testing principle); §4.5 (collaborative user story writing as a static-testing activity); the existing `review-rubrics` skill for the Kensa-specific Test Lead-review machinery.

# Static testing and reviews

Static testing finds defects without executing code. It applies to
specs, user stories, design documents, test cases, project plans,
contracts, models — anything that can be read. In Kensa, this skill
governs two distinct review surfaces:

1. **Reviewing the SOT** (spec, AC, design) BEFORE writing any case —
   so you catch ambiguity and missing requirements cheaply.
2. **Reviewing testware** (other QA Engineers' checklists and cases) —
   the Test Lead's job per the `review-rubrics` skill.

Both are static testing per Chapter 3. This skill gives you the
ISTQB framing; `review-rubrics` gives you the Kensa-specific
acceptance criteria.

## Why static testing matters (§3.1.2)

> "Static testing can detect defects in the earliest phases of the
> SDLC, fulfilling the principle of early testing. It can also
> identify defects which cannot be detected by dynamic testing
> (e.g., unreachable code, design patterns not implemented as
> desired, defects in non-executable work products)."
> — CTFL 4.0 §3.1.2

In practical Kensa terms:

- An ambiguous AC is a defect in the test basis. A reviewer can find
  it in 2 minutes; a tester following it produces 14 broken cases.
- An undefined error message is a spec defect. Catch it before code.
- A test case with two assertions in one step is a testware defect.
  Catch it in Test Lead review, not after the user deploys cases.

## Static vs dynamic (§3.1.3)

| Aspect | Static testing | Dynamic testing |
|---|---|---|
| Software runs? | No | Yes |
| What's examined | The work product itself | The behaviour |
| Defects found | Directly | Inferred from observed failures |
| Applies to | Executable + non-executable artefacts | Executable artefacts only |
| Cheaper to find | Requirements defects, design defects, certain code defects | Behavioural defects, performance issues |

In Kensa, the `test-lead-agent`'s SOT-review step is static testing
applied to the test basis; the `qa-engineer-agent`'s case-writing is
preparation for dynamic testing (the cases will be run later by a
human).

## Defect types easiest to find with static testing (§3.1.3)

Pull these straight from §3.1.3 — they're the things to scan FOR
when reviewing a spec:

- **Requirements defects** — inconsistencies, ambiguities,
  contradictions, omissions, inaccuracies, duplications.
- **Design defects** — poor modularisation, inefficient structures.
- **Coding defects** — undefined variables, unreachable code (mostly
  for dev review, not for QA agents).
- **Standards deviations** — naming conventions, format compliance.
- **Interface defects** — mismatched parameters in an API spec.
- **Security vulnerabilities** — certain classes (buffer overflows)
  identifiable from source review.
- **Coverage gaps in test basis** — *missing tests for an AC*. This is
  the gap the test-lead-agent's review most often finds.

## The five review process activities (§3.2.2, ISO 20246)

Memorize these in order. Every review you run — formal or informal —
goes through them implicitly.

### 1. Planning

Define the scope: what's being reviewed, the quality characteristics
to evaluate, focus areas, exit criteria, time-box.

*Kensa application:* before the Test Lead reads a spec, decide what to look
for (testability of AC, scope clarity, completeness). For a
QA Engineer-checklist review, the rubric in `review-rubrics` IS the plan.

### 2. Review initiation

Make sure everyone is prepared: has access to the work product,
understands their role, has supporting materials.

*Kensa application:* the Test Lead reads `project.md`, `conventions.md`,
and the SOT before reviewing — that's initiation. A QA Engineer briefed
on a Stage 1 task is being initiated for case review later.

### 3. Individual review

Each reviewer reads the work product, applies review techniques
(checklist-based reviewing, scenario-based reviewing), and logs
anomalies, recommendations, and questions.

*Kensa application:* the Test Lead reading a QA Engineer's checklist alone
against the `review-rubrics` criteria IS individual review.

### 4. Communication and analysis

Discuss the anomalies. Decide which are defects vs false positives.
Assign status, ownership, and required actions.

*Kensa application:* the Test Lead's "send back with feedback" message to
the QA engineer IS the communication and analysis step. Each anomaly
becomes a concrete action item.

### 5. Fixing and reporting

Defects logged in a defect report so corrective actions can be
followed up. Once exit criteria reached, work product accepted.
Results reported.

*Kensa application:* the QA Engineer revising the checklist or cases is
"fixing"; the Test Lead's final approval is "reporting" (accept). The
user-facing report includes the result of the review process.

## The six review roles (§3.2.3)

| Role | Responsibility | Kensa mapping |
|---|---|---|
| **Manager** | Decides what to review; provides resources | The **user** — they say "review this spec" or "review these cases" |
| **Author** | Creates and fixes the work product | The **user** for the spec; the **qa-engineer-agent** for cases |
| **Moderator** (facilitator) | Runs the review meeting; mediates; time-keeps | The **test-lead-agent** during checklist/case review |
| **Scribe** (recorder) | Records anomalies and decisions | The **test-lead-agent** (writes the send-back message) |
| **Reviewer** | Performs the review | The **test-lead-agent** for testware; **qa-engineer-agent** when reviewing a SOT spec for testability |
| **Review leader** | Decides who's involved, when, where | The **test-lead-agent** (or the user via command invocation) |

In Kensa most reviews collapse to two participants (Test Lead + QA Engineer),
and the Test Lead wears multiple hats (moderator + scribe + review leader).
That's allowed by the syllabus — `inspections are the most formal,
and even there, "the author cannot act as the review leader or
scribe"` (§3.2.4) — meaning one person can do multiple roles in less
formal reviews.

## The four review types (§3.2.4)

Pick the right type for the situation. Higher formality = more
overhead = more defect-finding power.

### Informal review

- No defined process, no documented output.
- Main objective: detect anomalies.
- *Kensa use:* the user pinging the Test Lead "does this spec look
  reasonable?" — quick sanity check.

### Walkthrough

- Led by the **author**.
- Multi-objective: evaluate quality, build confidence, educate
  reviewers, gain consensus, motivate the author.
- *Kensa use:* the user walking the Test Lead through a feature spec to
  share context, where the Test Lead might ask questions. Not the default
  Kensa flow but useful for complex domains.

### Technical review

- Performed by technically qualified reviewers.
- Led by a moderator (not the author).
- Objectives: gain consensus on technical problems, detect anomalies,
  evaluate quality.
- *Kensa use:* **THIS IS THE KENSA DEFAULT.** Test Lead reviews of QA Engineer
  checklists and cases are technical reviews — the Test Lead is
  technically qualified (knows ISTQB + project conventions), moderates,
  and the author (qa-engineer-agent) responds.

### Inspection

- Most formal type. Follows the complete generic process strictly.
- Main objective: find the maximum number of anomalies.
- Metrics are collected and used to improve the process.
- The author cannot be review leader or scribe.
- *Kensa use:* escalate to this for high-risk features (payments,
  safety-critical, regulatory). Practically: the Test Lead spends extra
  time, applies more checklists, asks the user to confirm AC, and
  the case quality rubric is applied strictly.

### How to pick

| Situation | Type |
|---|---|
| Quick "does this look right?" | Informal |
| User explaining unfamiliar domain to the Test Lead | Walkthrough |
| Test Lead reviewing QA Engineer output (Kensa default) | Technical review |
| Auth, payments, medical, safety-critical, audit-track | Inspection |

## Pre-write review checklist — what to flag back to the user

When the Test Lead reviews a SOT spec **before** writing cases, look for:

### Testability of acceptance criteria

- Is each AC observable? ("System is fast" — not testable. "Search
  returns in <500ms" — testable.)
- Is each AC unambiguous? (Two reasonable readers should agree on
  what passing means.)
- Is each AC scoped to one claim? ("Login works and password reset
  works" — split into two AC.)

### Completeness of spec

- Are error paths described, or only the happy path?
- Are authorization rules stated, or implied?
- Are persistence requirements stated, or assumed?
- Are mobile/web/API parity expectations explicit, or silent?
- Are i18n / a11y requirements scoped?

### Consistency

- Does the AC contradict the description?
- Do comments override the original spec? Identify the authoritative
  version.
- Do screenshots match the described behaviour?

### Terminology consistency

- Same concept named two different ways ("user" vs "account holder")?
- Project-specific terms not in `glossary.md`?

### Coverage of risk areas

- Does the spec address the high-risk attributes (security, data
  integrity, concurrency)?
- Are there obvious failure modes the spec doesn't address?

When you find any of these, flag back to the user as part of the
scope-analysis output:

```markdown
**Spec review (static testing) — issues found**

1. AC-2 "Users can manage their profile" is too broad. What actions
   are in scope? Edit name? Change email? Delete account?
2. The description says "max 100 items" but the screenshot shows
   pagination at 50. Which is correct?
3. No mention of what happens when the user is offline.
   Should we treat this as out of scope, or do you want offline
   coverage?
```

This is shift-left in action.

## Static testing applied to testware itself

Every Kensa case is itself a work product subject to static testing.
The Test Lead's case-review step applies the same review process:

- **Planning:** the `review-rubrics` skill defines what to look for.
- **Initiation:** Test Lead reads `conventions.md` and the suite to set
  context.
- **Individual review:** Test Lead reads each case file.
- **Communication and analysis:** Test Lead writes the send-back message
  with specific item-level feedback.
- **Fixing and reporting:** QA Engineer revises; Test Lead approves or sends
  back again.

## Success factors for reviews (§3.2.5)

Internalize these — they show up as feedback patterns:

- **Clear objectives and measurable exit criteria.** "Approve when all
  ✅ or ≤2 minor ⚠️" — that's measurable. "Looks good" is not.
- **Right review type.** Don't inspect a draft sketch; don't
  informally review a payment flow.
- **Small chunks.** Don't review 50 cases in one sweep — reviewer
  fatigue produces missed defects. Batch.
- **Feedback to authors.** Don't just mark "send back" — say WHY
  with examples.
- **Adequate prep time.** The Test Lead reading a spec at 3am while
  scoping is degraded review.
- **Management support.** The user's willingness to act on review
  findings (e.g., revise the spec) IS management support.
- **Culture / learning.** `/save-memory` after each session captures
  what reviews caught; future sessions avoid the same defects.
- **Adequate training for roles.** This skill IS that training.
- **Facilitating meetings.** For Kensa, async equivalent: clear,
  structured send-back messages.

> "Evaluation of participants should never be an objective."
> — CTFL 4.0 §3.2.5

The Test Lead's job is not to grade the QA Engineer — it's to improve the work
product. Phrase feedback against the artefact ("step 3 has a
verification preamble"), never the QA engineer ("you keep making this
mistake").

## Worked example — reviewing a spec for testability

User: "Here's the spec for the new comment-reactions feature.
Please write tests."

The Test Lead's static-testing pass before any case writing:

```markdown
## Static review of spec (before writing cases)

**Spec quality:** mostly good. AC are bulleted and observable.

**Issues found:**

1. **Ambiguity (AC-3):** "Users can react with any emoji" — does
   this mean the full Unicode emoji set, or a curated subset shown
   in a picker? Two reasonable readings.
2. **Omission:** No mention of how many reactions per user per
   comment. Can the same user add 👍 and ❤️ to the same comment? Spec
   silent.
3. **Inconsistency:** Description says "reactions are public";
   screenshot shows a count without names. Which is the requirement?
4. **Missing non-functional:** No limit on total reactions per
   comment. Is there a perf threshold? (1k reactions on one comment?
   10k?)

**Recommendation:** resolve 1 and 3 before I write cases (they
change scope). For 2 and 4 I can proceed with assumptions if you
want — flagged in the plan.
```

That's static testing producing actionable defect reports against
the test basis.

## Worked example — reviewing a worker checklist

```markdown
## Checklist review for package P1 (auth/2fa)

**Rubric:** see `review-rubrics`

**Coverage:** ⚠️ AC-4 (disable flow) has only one item; needs at least
re-auth-required negative and "disabled state visible in Settings".

**Scope adherence:** ✅

**Negative scenarios:** ⚠️ TOTP entry has happy path only; add: invalid
code, expired code, 5-digit input, non-numeric input.

**Edge cases:** ❌ no boundary on TOTP window (±30s) — explicit
[3-value BVA] group expected here.

**References:** ✅

**Outcome:** SEND BACK. Address coverage gap on AC-4, expand TOTP
negatives, and add the BVA group for the time window. After, ready
for case-writing stage.
```

Communication and analysis output, ready for the QA engineer.

## When to load this skill

- Test Lead at session start: before reviewing the user's spec for
  testability (scope-analysis input).
- Test Lead during review phases: before reviewing checklists or cases.
  Pair with `review-rubrics`.
- QA Engineer (qa-engineer-agent) when reviewing the SOT for testability
  gaps that should be flagged BEFORE writing cases.
- When the user asks "how does your review work?" — answer in
  ISTQB §3 vocabulary (technical review, four roles, five process
  activities).
- When deciding whether to escalate to inspection (high-risk
  feature) instead of the default technical review.

## Anti-patterns

- Skipping the spec review and jumping straight to cases — every
  ambiguity becomes a QA Engineer assumption that may be wrong.
- "Send back" with vague feedback like "improve quality" — fails
  success factor #4 (feedback to authors). Always include specific
  examples.
- Inspecting everything because "more formal is better" — wastes
  time on low-risk artefacts.
- Mixing static and dynamic testing in conversation. When you say
  "let's test it", be clear whether you mean "review the spec" or
  "run cases against the build".
- Letting the author act as review leader on high-risk work
  (violates §3.2.4 inspection rules).
- Treating QA Engineer review as a grading exercise. Per §3.2.5:
  "Evaluation of participants should never be an objective."
