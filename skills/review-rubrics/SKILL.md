---
name: review-rubrics
description: Rubrics for the Test Lead to review (1) QA Engineer checklists before they write cases, and (2) finished cases before reporting to the user. Two distinct rubrics with explicit acceptance criteria. Use during the review phases of /new-feature and /update-feature workflows. Test Lead-only skill.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 3 — Static Testing, §3.2.2 Review Process Activities, §3.2.4 Review Types.
> Learning objectives: FL-3.2.2 (K2) summarize review process activities (planning / initiation / individual review / communication & analysis / fixing) — the two rubrics implement the "individual review" and "communication & analysis" stages for checklist (Stage 1) and case (Stage 2) artefacts; FL-3.2.4 (K2) compare review types — these rubrics correspond to a technical review (semi-formal, defined process, peer-reviewer-led) per ISO 20246, with optional escalation to inspection for high-risk features.
> See also: §3.2.3 review roles (Test Lead = moderator + review leader; QA Engineer = author / reviewer); §3.2.5 success factors; the `static-testing-reviews` skill for the foundational Chapter 3 framing.

# Review rubrics

The Test Lead's job is not "vibe check". Review is structured. Two rubrics:
checklist review (Stage 1) and case review (Stage 2). Each has explicit
criteria with three outcomes: approve, approve-with-notes, send-back.

## Checklist review rubric

A QA Engineer has sent you their checklist. Before any case is written, this
is your chance to catch scope problems cheaply.

### Criteria

For each criterion, mark ✅ / ⚠️ / ❌.

**1. Coverage**
- ✅ Every acceptance criterion from SOT is represented
- ⚠️ Most ACs covered, 1-2 minor gaps
- ❌ Significant ACs missing

**2. Scope adherence**
- ✅ Nothing outside the assigned scope; nothing that belongs to another QA Engineer
- ⚠️ Minor drift, easily corrected
- ❌ Major scope creep or scope leak

**3. Negative scenarios**
- ✅ Negative paths included for each major positive flow
- ⚠️ Some negatives present, common ones missing
- ❌ Only happy paths

**4. Edge cases**
- ✅ Boundary values, error paths, race conditions called out where relevant
- ⚠️ Some edge cases, more should be there
- ❌ No edge cases at all

**5. References**
- ✅ Every non-obvious item has a SOT ref or `[ASSUMPTION]` marker
- ⚠️ Some unreferenced items that probably need refs
- ❌ Mostly unreferenced

**6. Prioritization**
- ✅ Clear must-have / should-have / nice-to-have grouping
- ⚠️ Grouped, but some items in the wrong tier
- ❌ Flat list, no prioritization

**7. Technique annotation**
- ✅ Where a specific test design technique applies, it's named and the
  checklist items implement it correctly
- ⚠️ Techniques mentioned but not implemented fully (e.g., "3-value BVA"
  but only 2 values shown)
- ❌ No techniques annotated where they should be

### Outcome decision

- **All ✅ or up to two ⚠️ on minor criteria** → **Approve.** QA Engineer
  proceeds to Stage 2.
- **Up to 3 ⚠️ or one ❌ on a non-critical criterion** → **Approve with
  notes.** QA Engineer proceeds with the notes in mind.
- **More than 3 ⚠️ OR any ❌ on a critical criterion (1, 2, 5)** →
  **Send back** with specific feedback.

### How to write feedback

Be specific, item-level. Not "improve negative scenarios" — but:

> "Negative scenarios for the login flow are missing. Add at least:
> - Invalid TOTP code
> - Expired TOTP code
> - 6-digit non-numeric input
>
> Also: AC-3 (disable flow) isn't represented at all. Add at least the
> happy path and the re-auth-required negative."

### The 2-round cap

If after two send-backs the QA Engineer and you still aren't converging,
escalate to the user with a concrete question. Example:

> "The QA Engineer and I disagree on whether 'admin disabling another user's
> 2FA' belongs in this batch. The ticket doesn't say either way. Decision?"

Don't loop indefinitely.

---

## Case review rubric

The QA Engineer has written cases. They live in `.tms/suites/<...>/`. Now you
check that they're actually good.

### Criteria

**1. Matches the approved checklist**
- ✅ Every approved checklist item has at least one case
- ⚠️ Most items covered, 1-2 missing
- ❌ Significant items not implemented

**2. Follows project conventions**
- ✅ Frontmatter complete per `conventions.md`; naming style matches;
  step granularity matches
- ⚠️ Mostly compliant, minor deviations
- ❌ Wrong style throughout (likely QA Engineer didn't read existing cases)

**3. Case anatomy quality**
- ✅ Steps atomic and imperative; expected results verifiable;
  preconditions vs steps boundary respected
- ⚠️ Mostly good, some compound steps or aspirational expected results
- ❌ Recurring quality problems

**4. Frontmatter completeness**
- ✅ Every case has id, title, priority, status, tags, source_id,
  generated_by
- ⚠️ Minor omissions on a few cases
- ❌ Multiple cases with missing critical frontmatter

**5. Shared step reuse**
- ✅ Existing shared steps used where they apply; no inline duplication
  of fixed prerequisites
- ⚠️ Some missed reuse opportunities
- ❌ Significant duplication

**6. Title quality**
- ✅ Each title is one verifiable claim
- ⚠️ Some titles combine multiple claims
- ❌ Many vague or compound titles ("Various login tests")

**7. Step quality**
- ✅ No "should", "must", "verify that" preambles; no "etc."; no
  implementation details
- ⚠️ A few anti-patterns slipping through
- ❌ Recurring anti-patterns

**8. Assumption hygiene**
- ✅ QA Engineer assumptions explicitly marked, addressable
- ⚠️ Some hidden assumptions surfaced during review
- ❌ Many silent assumptions that should have been flagged

### Outcome decision

Same three-tier:

- **All ✅ or minor ⚠️** → **Approve.** Cases stay where they are. Move
  to user report.
- **Several ⚠️ or one ❌ on style/anatomy** → **Approve with notes.** Have
  the QA Engineer fix in-place; don't gate the user report on this if the
  cases are functionally correct.
- **❌ on coverage (1) or recurring quality issues (3, 6, 7)** →
  **Send back.** Don't ship cases the user will look at and immediately
  spot quality problems.

### How to write feedback

Reference specific cases by ID or file path. Not "step quality is
inconsistent" — but:

> "In `auth/2fa/setup-001.md`, step 3 is:
> > Verify that the QR code is displayed.
>
> Should be:
> > Step 3: Click 'Enable 2FA'
> > Expected: QR code appears below the button.
>
> Same pattern in setup-002 step 5 and disable-003 step 2. Please go
> through all cases for this anti-pattern."

Make it actionable. Show the desired form.

---

## Special cases

### When the work is genuinely good

Approve quickly. Don't invent issues to look thorough. Two minor
suggestions in the approval message is fine; ten is overkill.

### When the QA Engineer is recurring-wrong on something

If the same pattern shows up across 5+ cases, that's a single root cause.
Address it once, ask the QA Engineer to do a sweep:

> "All cases use 'Verify that...' preamble in steps. This is an
> anti-pattern. Please remove this preamble from every step in every
> case and rerun. After the sweep, I'll re-review."

### When you and the user disagree about a convention

User says "we always do X". Existing cases show "we do mostly Y". Default
to user direction, but flag it:

> "Heads up: existing cases mostly use Y. You said X for this batch. I'll
> use X here, but consider updating `conventions.md` so future runs are
> consistent."
