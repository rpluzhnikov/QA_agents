---
name: defect-management
description: ISTQB CTFL §5.5 — the defect management process (log → analyze → classify → decide → close), the mandatory fields in a defect report per ISO 29119-3 (unique id / title / date+author / test object & environment / context / failure description / expected vs actual / severity / priority / status / references), and severity vs priority distinction. Load when authoring a defect report, when reviewing a user-reported defect, or when teaching the user how to file Kensa-discovered defects into their tracker (Jira/Linear/etc.).
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 5 — Managing the Test Activities, §5.5 Defect Management.
> Learning objectives: FL-5.5.1 (K3) prepare a defect report.
> See also: §1.2.3 (error → defect → failure → root cause chain — get this right before writing a report); §3 (defects found via static testing have slightly different shape); the `sot-*` skills for filing defects into Jira/Linear/Confluence/Notion via MCP.

# Defect management

Defect management is a process, not just a report format. §5.5 defines
both: the process (workflow + classification) and the report
contents. Foundation-Level expects you can author a real defect
report (K3 — apply, not just understand).

For Kensa, the Test Lead and qa-engineer-agents author defect reports in
three situations:

1. **Static-testing defects** — review of the SOT spec finds an
   ambiguity, contradiction, or missing AC. Reported to the user.
2. **Testware defects** — Test Lead's review of a QA Engineer's cases finds
   problems. Reported to the QA engineer as send-back feedback.
3. **Dynamic-testing defects** — when the cases the user runs find a
   product bug. Kensa agents teach the user how to file these into
   their tracker; the actual filing typically happens through the
   user's chosen MCP (Jira/Linear/etc.).

## The defect management process (§5.5)

> "At a minimum, the defect management process includes a workflow
> for handling individual defects or anomalies from their discovery
> to their closure and rules for their classification. The workflow
> typically comprises activities to log the reported anomalies,
> analyze and classify them, decide on a suitable response such as
> to fix or keep it as it is and finally to close the defect report."
> — CTFL 4.0 §5.5

The five-step workflow:

1. **Log** — capture the anomaly with required fields.
2. **Analyze** — investigate. Is it a real defect or false positive?
   Reproduce. Find root cause.
3. **Classify** — assign severity, priority, category.
4. **Decide** — fix / defer / reject / convert to change request.
5. **Close** — mark resolved after confirmation testing.

> "It is advisable to handle defects from static testing (especially
> static analysis) in a similar way."
> — CTFL 4.0 §5.5

So a spec ambiguity flagged in lead review goes through the same
process: log it (in the report-back), classify it (severity:
medium, priority: high), decide (user clarifies → fix), close (lead
proceeds).

## What a defect report is for (§5.5)

> "Typical defect reports have the following objectives:
> - Provide those responsible for handling and resolving reported
>   defects with sufficient information to resolve the issue
> - Provide a means of tracking the quality of the work product
> - Provide ideas for improvement of the development and test
>   process."
> — CTFL 4.0 §5.5

Three audiences:

- The **fixer** (developer, spec author) needs reproduction info.
- The **quality tracker** (QA lead, manager) needs categorization
  and counts.
- The **process improver** (retrospective lead, QA manager) needs
  root-cause information.

If your report serves only the fixer, you've missed the other two
purposes.

## Fields in a defect report (§5.5)

§5.5 lists the fields explicitly. These are based on ISO/IEC/IEEE
29119-3 (which calls them "incident reports"). Memorize this list.

For a defect found via **dynamic testing**:

1. **Unique identifier** — auto-assigned by tracker (`KEN-203`,
   `LIN-455`).
2. **Title** — short summary of the anomaly. ONE LINE. The fixer
   should know what kind of bug from this alone.
3. **Date observed, issuing organization, author + role** — when,
   from where, by whom (including role).
4. **Identification of test object and test environment** — what
   was being tested, in what environment (browser, OS, build).
5. **Context** — the test case being run, test activity, SDLC phase,
   technique/checklist/data being used.
6. **Failure description** — to enable reproduction and resolution.
   Include test steps, logs, DB dumps, screenshots, recordings.
7. **Expected results and actual results** — both, side by side.
8. **Severity** — degree of impact (on stakeholders or requirements).
9. **Priority** — urgency of fix.
10. **Status** — open / deferred / duplicate / waiting / in confirm
    / re-opened / closed / rejected.
11. **References** — to the test case, the requirement, related
    defects.

> "Some of this data may be automatically included when using defect
> management tools (e.g., identifier, date, author and initial
> status)."
> — CTFL 4.0 §5.5

When filing in Jira/Linear via MCP, the unique ID and timestamps
are auto-assigned. Focus on the other fields.

## Severity vs priority — the key distinction

Both are 1-5 (or Low/Medium/High/Critical) but they measure
different things.

| | Severity | Priority |
|---|---|---|
| **Measures** | Impact when the defect occurs | Urgency of fix |
| **Determined by** | Tester / QA based on consequences | Product owner / management based on schedule |
| **Example: typo in marketing page** | Low (no functional impact) | High (visible to customers, embarrassing) |
| **Example: crash in admin tool used once/year** | High (functionality lost) | Low (rarely needed; can wait) |

A defect can be high-severity, low-priority (rare crash in
non-critical tool) or low-severity, high-priority (cosmetic bug on
the marketing homepage during launch week).

**Anti-pattern:** treating severity and priority as synonyms. They
are NOT. The same defect can have very different severity vs
priority values.

## Defect lifecycle states

Common states (extending §5.5's list):

```
                                   ┌──────────┐
                                   │ Rejected │ (not a defect)
                                   └──────────┘
                                        ▲
                                        │
[New] → [Open] → [Analysis] → [In Progress] → [Fixed] → [Verified] → [Closed]
                      │            │           │           │
                      │            │           │           ▼
                      ▼            ▼           ▼      [Re-opened] (regression)
                 [Duplicate]  [Deferred]  [Won't Fix]
```

Match the user's tracker vocabulary if it differs. Jira's default
workflow uses these names; Linear uses Triage / In Progress / Done.
The semantics are the same.

## Static-testing defects vs dynamic-testing defects

§5.5 says handle them similarly. The difference is in what FIELDS
apply:

| Field | Dynamic defect | Static defect (e.g., spec review) |
|---|---|---|
| Title | Required | Required |
| Test object | The product build | The spec / user story / case being reviewed |
| Test environment | Browser/OS/build | N/A (or "review session date") |
| Failure description | Reproduction steps + observed failure | The anomaly: what's wrong with the artefact |
| Expected vs actual | Yes | Often N/A (the artefact doesn't have "expected" — it IS the spec) |
| Severity | Impact on user | Impact on downstream work (e.g., "12 cases blocked") |
| Priority | Urgency to fix | Urgency to resolve before proceeding |

A static defect example: "AC-3 in LIN-89 is ambiguous — does
'reaction' mean any Unicode emoji or a curated picker subset? This
blocks scope decisions for ~5 cases."

## Defect report templates

### Template — dynamic-testing defect

For when the user runs a case and reports a bug to you, or when you
draft a report for filing into their tracker:

```markdown
## Defect — Discount not applied at total = $100

**Status:** Open

**Date observed:** 2026-05-25
**Reporter:** QA Engineer (Kensa session)
**Test object:** checkout.payment build #2451
**Test environment:** Chrome 124 on macOS 14.4, staging

**Context:**
- Test case: `checkout/discount/discount-001.md`
- Test activity: execution
- Technique: 3-value BVA on discount threshold ($100)

**Failure description:**
1. Log in as test user `qa-test-1@example.com`.
2. Add the test product `discount-eligible-item` ($100.00) to cart.
3. Navigate to checkout.
4. Observe discount line.

**Expected:** 10% discount applied (subtotal $100, discount -$10,
total $90). Per spec AC-2: "Orders of $100 or more receive a 10%
discount."

**Actual:** No discount applied. Total $100 (no discount line shown).

**Severity:** High (incorrect pricing on eligible orders;
financial/legal exposure if charged).

**Priority:** High (affects all customers at the threshold; in
production now).

**References:**
- Test case: `checkout/discount/discount-001.md`
- Requirement: LIN-89 AC-2
- Possibly related: LIN-203 (similar boundary defect 6 months ago —
  defect cluster signal per §1.3 principle 4)

**Suggested root cause area (not confirmed):**
The condition `total > 100` should likely be `total >= 100` per AC
wording. To be confirmed by dev investigation.
```

### Template — static-testing defect (spec ambiguity)

For when the Test Lead's spec review finds a problem:

```markdown
## Static defect — AC-3 ambiguity in LIN-89

**Status:** Open (blocks scope finalisation)

**Date observed:** 2026-05-25
**Reporter:** Test Lead (Kensa session)
**Test object:** LIN-89 spec (revision as of 2026-05-25)

**Context:**
- Review activity: pre-write spec review
- Review type: technical review (per §3.2.4)

**Anomaly description:**
AC-3 reads: "Users can react with any emoji". This is ambiguous:
- Reading A: full Unicode emoji set (~3700 emoji).
- Reading B: curated picker subset shown in UI.

Two reasonable readers will produce different test sets.

**Impact:** Blocks decision on ~5 cases (input partitioning,
performance with full set, picker UX).

**Severity:** Medium (test scope affected; not a product defect
yet).

**Priority:** High (need resolution to proceed with scope).

**Suggested resolution:**
PM clarifies AC-3 to either: "any emoji from the standard Unicode
set" OR "any emoji from the in-app picker (see design spec for
list)".

**References:**
- LIN-89 description
- design file Figma URL (if available)
```

### Template — testware defect (Test Lead → qa-engineer review)

For when the Test Lead reviews a QA Engineer's cases and finds problems:

```markdown
## Testware defect — verification preamble in steps

**Status:** Open (send-back)

**Date observed:** 2026-05-25
**Reporter:** Test Lead
**Test object:** Cases in `.tms/suites/auth/2fa/setup-*`

**Anomaly description:**
Multiple cases use "Verify that..." preamble in step descriptions,
which is an anti-pattern per `test-case-writing-craft`.

Examples:
- `setup-001.md` step 3: "Verify that the QR code is displayed."
- `setup-002.md` step 5: "Verify that the secret is shown."
- `disable-003.md` step 2: "Verify that re-auth is required."

**Expected pattern (per craft skill):**
- Step: "Click 'Enable 2FA'"
- Expected: "QR code appears below the button"

**Severity:** Medium (style; doesn't block execution but degrades
review quality).

**Priority:** High (block on merge until fixed).

**Suggested resolution:**
QA Engineer sweeps all auth/2fa/* cases for this pattern and
revises in-place.
```

## Filing defects into the user's tracker

When the user runs cases and finds bugs, they'll often want the
defect reports filed into Jira/Linear/Notion. Kensa agents can
generate the report content; the filing happens via the appropriate
`sot-*` skill MCP:

- `sot-jira` — Atlassian MCP to create Jira issues.
- `sot-linear` — Linear MCP.
- `sot-notion` — Notion MCP (for orgs that track bugs in Notion).
- `sot-confluence` — for spec defects raised against Confluence
  pages.

The Kensa report content maps onto tracker fields:

| ISTQB field | Jira field | Linear field |
|---|---|---|
| Title | Summary | Title |
| Failure description | Description | Description |
| Severity | Custom field or Priority | Priority + label |
| Priority | Priority | Priority |
| Test environment | Environment field or description | Description |
| References | Linked issues | Related issues |
| Status | Status | Status |

The MCP tool typically auto-assigns the unique ID and date/author.

## Anti-patterns — defect-report anti-patterns to avoid

§5.5 implies but doesn't enumerate these. Add them from
practitioner experience:

### Vague title ("Doesn't work")

A title is read in lists. "Doesn't work" is useless. Be specific:
"Discount not applied at total = $100 boundary."

### Missing steps to reproduce

If the fixer can't reproduce, the report can't be acted on. Steps
must be deterministic. Include test data values.

### Mixing severity and priority

"Severity = High, Priority = High because it's a high severity bug"
collapses the distinction. Severity is about impact; priority is
about urgency. They're independent.

### Over-classification taxonomy

Adding 12 custom fields and 8 categories to every report. ISTQB §5.5
lists what's needed; more usually wastes time.

### Speculating about root cause as if confirmed

If you suspect the cause, label as suggested or speculation. Don't
assert it. Final root cause is the fixer's call after investigation.

### Reporting symptoms as multiple defects

Three users report the same crash → one defect. Two cases that fail
for the same reason → one defect with two test-case references.

### Submitting on shared/flaky environment without environment
description

Always include the environment. "Works on my machine" defects waste
fixer cycles.

## Worked example — full defect from execution

User: "I ran the case `checkout/payment/declined-card-002.md` and
got an unexpected error. Can you write the defect report?"

Test Lead reasoning:

1. Read the case to understand expected behaviour.
2. Ask the user for actual behaviour + environment.
3. Apply §5.5 template.

Output:

```markdown
## Defect — Decline error message shows raw 4xx code instead of user
text

**Status:** Open

**Date observed:** 2026-05-25
**Reporter:** [user name] via Kensa session
**Test object:** Web app build #2451
**Test environment:** Chrome 124 on macOS 14.4, staging environment

**Context:**
- Test case: `.tms/suites/checkout/payment/declined-card-002.md`
- Step that failed: step 5 ("Submit form with declined card")
- Activity: execution

**Failure description:**
1. Logged in, went to checkout.
2. Entered the declined-card test token from `test-data.md`.
3. Filled remaining required fields with valid data.
4. Clicked "Pay".
5. Observed the response shown to the user.

**Expected (per AC-4):** A user-friendly message: "Your card was
declined. Please try a different card or contact your bank."

**Actual:** Raw text shown: "HTTP 402 — payment provider rejected
the request". Technical and unhelpful.

**Severity:** Medium (functional behaviour correct — the decline IS
handled — but the user experience is degraded).

**Priority:** High (every declined-card user sees this; pre-launch
should fix).

**References:**
- LIN-89 AC-4
- Test case: `checkout/payment/declined-card-002.md`

**Notes:** Suggest checking the error-mapping table in the payment
adapter; raw provider errors shouldn't reach the user. To be
confirmed by dev.
```

User can copy this into Jira (or have the Atlassian MCP file it
directly via `sot-jira`).

## When to load this skill

- Anyone authoring a defect report (static, testware, or dynamic).
- When teaching the user how to file Kensa-discovered defects into
  their tracker.
- When reviewing a user-provided defect report for quality
  (completeness, correct severity/priority).
- When the user asks "what's the severity vs priority?" — answer in
  §5.5 vocabulary.
- During retrospectives or `/save-memory` when discussing defect
  patterns — root-cause and classification feed forward.

## Anti-patterns

- Severity = Priority. They measure different things; treat them
  independently.
- Title that doesn't say what kind of defect it is.
- Reporting without environment or reproduction steps.
- Asserting root cause without dev confirmation.
- One defect per symptom instead of one per root cause when grouping
  is obvious.
- Skipping the static-defect path — pretending spec ambiguities
  aren't "real" defects. They are; report them through the same
  process.
- Over-classification (12 custom fields per report). Stick to the
  §5.5 list.
