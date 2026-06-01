---
name: scope-analysis
description: How the Test Lead analyzes a feature spec, identifies what's in and out of scope, and decomposes the work into QA Engineer packages. Use at the start of every /new-feature and /update-feature, before delegating any work. This skill is for the Test Lead role only.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 1 — Fundamentals of Testing, §1.4.1 Test Activities and Tasks, §1.4.2 Test Process in Context; Chapter 5 — Managing the Test Activities, §5.1 Test Planning (especially §5.1.1 purpose & content of a test plan), §5.2 Risk Management.
> Learning objectives: FL-1.4.1 (K2) explain test activities (this skill operationalises planning + test analysis); FL-1.4.2 (K2) explain impact of context (project type, lifecycle, stakeholders shape scope); FL-5.1.1 (K2) exemplify test plan purpose and content (scope analysis produces a mini test plan: in/out scope, decomposition, risks, estimate); FL-5.2.1 (K1) identify risk level via likelihood × impact; FL-5.2.3 (K2) explain risk analysis influence on thoroughness and test scope.
> See also: the `test-planning` skill for full §5.1 treatment; the `risk-based-testing` skill for the §5.2 register; `testing-fundamentals` for the named activities.

# Scope analysis — how the Test Lead plans

Most quality problems in test case authoring start at scope. Cases that
weren't needed get written; cases that were critical get missed; two
QA Engineers cover the same area; one case secretly tests two things. Good
scope analysis prevents most of this before any case is written.

## Inputs

- The SOT content (ticket description, acceptance criteria, comments,
  attached specs, design files)
- The user's framing of the request (often more specific than the ticket)
- Project memory:
  - `project.md` — what kinds of testing are in scope for THIS TMS
  - `conventions.md` — granularity expectations
  - `learned/patterns.md` — past patterns for similar features
- Related existing cases in `.tms/suites/`

## Output

A scope plan with these sections:

1. **In scope** — testable claims you intend to cover
2. **Out of scope** — things that look like they should be covered but
   won't be, with a one-line reason
3. **Decomposition** — how the in-scope work splits across QA Engineers
4. **Estimated case count** — per package, ballpark
5. **Open questions** — things you couldn't resolve from SOT alone
6. **Risks** — areas where you're uncertain whether coverage is adequate

This goes to the USER for approval before any QA Engineer spawns.

## Step 1 — Read the SOT critically

For each piece of SOT content, ask:

- **What's the user-visible behavior being described?** Translate from
  spec language to observable claims.
- **What are the acceptance criteria explicitly?** These usually map
  1:N to test cases.
- **What's NOT said but implied?** Common omissions:
  - Error paths (spec describes happy path only)
  - Authorization (spec describes the feature, not who can use it)
  - Persistence (spec describes the action, not "and is it saved across
    sessions?")
  - Mobile/web parity (spec written for one, but feature ships on both)
  - i18n behavior (spec in English, but product supports other languages)
- **What's said but doesn't apply?** Comments and old descriptions often
  contradict the final scope. Trust the most recent authoritative source
  (usually the last comment from PM, or the acceptance criteria).

If the SOT is structured (Linear/Jira with AC field), AC is the
authoritative list of things to verify. Read it as a test plan in
disguise.

## Step 2 — Form the "in scope" list

Convert every claim from the spec into a **testable statement** of the
form: "Given [precondition], when [action], then [observable result]."

Don't yet write cases — these are bullet points the user can scan in
30 seconds.

Example for "Add 2FA via TOTP" feature:

- User can enable 2FA from Settings → Security
- After enabling, user gets a QR code and a secret string
- Scanning QR with an authenticator app and entering a valid code
  completes setup
- After setup, login requires both password AND TOTP code
- User can disable 2FA from Settings (with re-auth)
- Recovery codes are issued at setup and can be used in place of TOTP

## Step 3 — Form the "out of scope" list

Explicitly list what you're NOT covering and why. This serves two
purposes: it gives the user a chance to push back ("wait, that should be
covered"), and it gives you scope cover for the report.

Examples:

- **SMS-based 2FA** — not in this feature, separate ticket
- **2FA enforcement by admin** — out of scope per AC, future work
- **Email 2FA option** — exists but no changes, no new cases needed
- **Performance under load** — handled by separate performance team

Be honest: if you're cutting scope because you don't know how to test
something, say so as an open question rather than hiding it in
"out of scope".

## Step 4 — Decompose into QA Engineer packages

Default: ONE QA Engineer package per feature.

Split into multiple packages ONLY when:

1. **Independent surfaces** — the feature touches surfaces that can be
   tested without knowing about each other (UI flow + API contract;
   mobile + web; admin panel + user-facing).
2. **Different platform skills needed** — one part is web, another is
   mobile; one part is security-heavy, another is functional.
3. **Estimated case count > 15 and the split is clean.**

If you split, each package must have:
- Independent SOT references (the QA engineer doesn't need to read the other
  package's spec)
- No overlap (no claim covered by two packages)
- A clear interface (what the other package assumes about this one, if
  anything)

If you can't write the package boundaries cleanly, don't split. One
QA Engineer, sequential cases.

## Step 5 — Estimate case count

Rough ballpark per package. Order-of-magnitude is enough; the goal is to
tell the user "this is small / medium / large", not to estimate billable
hours.

Heuristics from CTFL test design techniques:

- Each **acceptance criterion** → 1-3 cases (positive + 1-2 negatives)
- Each **state in the state machine** → cases for entering, valid
  transitions out, invalid transitions attempted
- Each **decision rule** (decision table column) → 1 case
- Each **boundary** in a numeric input → 2-4 cases (2-value or 3-value BVA)
- **Permutations** across roles / configurations → don't multiply blindly;
  use pairwise if it explodes

For a typical "add a setting" type feature: 5-10 cases.
For a typical "new flow with several steps": 12-20 cases.
For a typical "major feature with multiple surfaces": 30-60 cases across
2-3 QA Engineers.

Mark the estimate as `~`. It's a planning number, not a contract.

## Step 6 — Surface open questions

After reading the SOT and forming scope, you'll have residual uncertainty.
Categorize:

- **Critical** — can't proceed without an answer. Ask the user before
  spawning QA Engineers. (Examples: contradiction in the spec; missing
  acceptance criterion for a major behavior.)
- **Important** — can proceed with an assumption, but the user should
  weigh in. Surface in the plan as "I'll assume X unless you say
  otherwise." (Examples: behavior on edge cases not in spec.)
- **Minor** — can proceed with a reasonable default. QA Engineer will mark
  with `ASSUMPTION:` in the case, you'll catch in review.

Batch the critical and important ones into ONE message to the user. Don't
drip-feed.

## Step 7 — Identify risks

Risks are areas where you're not confident the plan covers what matters.
Common risk patterns:

- **Unfamiliar domain** — the feature is in an area the project hasn't
  touched before (e.g., first time adding payments to an app)
- **Recent regression history** — the area has had bugs recently (check
  git log if available)
- **Cross-cutting concerns** — feature touches auth/permissions/data
  consistency in non-obvious ways
- **External dependencies** — feature depends on a 3rd party (payment
  provider, identity provider) where you can't fully control the test
  environment

For each risk, write one line in the plan: "Risk: X. Mitigation: Y
(extra cases for Z, or note for user)."

## Output format

Send to the user as a single message:

```markdown
## Plan for LIN-89 — Add TOTP-based 2FA

**In scope**
- Enable 2FA flow (QR + secret + verify)
- Login with 2FA enforced
- Disable 2FA (with re-auth)
- Recovery codes (generation + usage)

**Out of scope**
- SMS 2FA (separate ticket LIN-103)
- Admin-enforced 2FA (future)
- Performance / scale (perf team)

**Decomposition**
- 1 QA Engineer, web-focused (no mobile surfaces in this ticket)
- ~14 cases, target suite `.tms/suites/auth/2fa/`

**Open questions for you**
1. Recovery codes — one-time use each, or are they reusable per device?
   Spec doesn't say.
2. What happens to active sessions when 2FA is enabled? Force logout or
   keep them?

**Assumptions I'll make unless you say otherwise**
- TOTP window: ±30s (industry default, not in spec)
- Recovery codes: shown only once at setup (industry default)

**Risk**
- Account lockout interaction with 2FA failures — I'll add 1-2 cases
  for it but the spec doesn't define the lockout policy here.

Ready to proceed?
```

## When to revise after user response

- User narrows scope → update in/out lists, re-estimate, proceed.
- User adds scope → update lists, possibly add a QA Engineer package,
  re-estimate, proceed.
- User answers open questions → bake answers into QA Engineer briefs, drop
  the assumptions.
- User says "looks good" → proceed to spawn QA Engineers.
- User says "rethink X" → revise, present again. No QA Engineer spawns until
  the user signs off on the plan.
