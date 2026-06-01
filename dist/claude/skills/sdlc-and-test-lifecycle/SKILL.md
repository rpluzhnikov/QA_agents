---
name: sdlc-and-test-lifecycle
description: ISTQB CTFL Chapter 2 — how the SDLC choice (sequential/iterative/Agile/DevOps) shapes test activities; the five test levels (component / component integration / system / system integration / acceptance); the four test types (functional / non-functional / black-box / white-box); confirmation vs regression; and maintenance testing triggers. Use to label every test case with the level + type it belongs to and to choose the right scope when a feature is being modified vs newly added.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 2 — Testing Throughout the SDLC, §2.1 SDLC context, §2.2 Test levels and types, §2.3 Maintenance testing.
> Learning objectives: FL-2.1.1 (K2) explain SDLC impact on testing; FL-2.1.3 (K1) recall test-first approaches; FL-2.1.5 (K2) explain shift left; FL-2.2.1 (K2) distinguish test levels; FL-2.2.2 (K2) distinguish test types; FL-2.2.3 (K2) distinguish confirmation testing from regression testing; FL-2.3.1 (K2) summarize maintenance testing and its triggers.
> See also: §1.4 for the test activities that run inside each level; §5.2 for risk-based scope decisions per level/type.

# SDLC and the test lifecycle

Chapter 2 answers two big questions for every case you write:

1. **Which level is this case targeting?** (component / component
   integration / system / system integration / acceptance)
2. **Which type is it?** (functional / non-functional / black-box /
   white-box — and which non-functional quality characteristic if
   non-functional)

Get those labels right and the rest of the metadata falls out
naturally. Get them wrong and the case looks misplaced — a "system"
case in an "acceptance" suite confuses everyone reading the suite.

This skill also covers maintenance testing (when a feature changes vs
when it's new) and the SDLC patterns the user team probably operates
in (Agile/DevOps/iterative), which determines how lightweight your
testware should be.

## The SDLC shapes everything (§2.1.1)

> "The choice of the SDLC impacts on the scope and timing of test
> activities, level of detail of test documentation, choice of test
> techniques and test approach, extent of test automation, and role
> and responsibilities of a tester."
> — CTFL 4.0 §2.1.1

For Kensa, the implications:

| SDLC | Implication for test cases |
|---|---|
| Sequential (waterfall, V-model) | More detailed cases, more documentation, formal hand-offs. Long-lived testware. |
| Iterative / incremental | Cases evolve per iteration; expect frequent `/update-feature`. |
| Agile | Lightweight cases tied to user stories; AC-driven. Heavy use of experience-based techniques. |
| DevOps | Automation-friendly; manual cases shrink to what humans must still verify (exploratory, validation, UX). |

The Kensa default assumption is Agile/iterative — that's what
`project.md` typically captures. If the user is in a regulated
sequential context (finance, medical, aerospace), the
`test-lead-agent` should ask before assuming.

## Test-first approaches (§2.1.3) — recognize them

You need to recognize these terms when the user uses them:

- **TDD (Test-Driven Development)** — developer-facing: tests first,
  then code, then refactor. Kensa cases are NOT TDD output (those are
  component-level dev tests). But the user's dev team may already
  produce them.
- **ATDD (Acceptance Test-Driven Development)** — tester +
  developer + customer write acceptance tests *before* implementation;
  see `collaboration-based-approaches`. **Kensa connection:**
  `/new-feature` invoked on a spec that doesn't yet have an
  implementation IS an ATDD pattern. Your output (the test cases) is
  the executable spec.
- **BDD (Behavior-Driven Development)** — Given/When/Then format. If
  your project uses BDD-style ACs (see `kensa-test-authoring`), keep
  the same vocabulary in case steps for consistency.

## Shift left (§2.1.5)

> "Shift left basically suggests that testing should be done earlier
> (e.g., not waiting for code to be implemented or for components to
> be integrated)."
> — CTFL 4.0 §2.1.5

Concrete Kensa applications:

- The `test-lead-agent` reviewing a spec during scope-analysis and
  flagging "AC-3 is ambiguous" is shift-left. Cheaper to fix the spec
  now than after code is written.
- Writing cases against a spec before code exists (ATDD) is shift-left
  at the test-design level.
- Using `static-testing-reviews` against the user's spec before any
  case is written is shift-left for test analysis.

## The five test levels (§2.2.1)

Memorize these. Every Kensa case lives at one of them; if the
frontmatter doesn't say which, the level should be obvious from the
suite path.

### 1. Component testing (unit testing)

- **Test object:** individual functions, methods, classes.
- **Who:** developers in their dev environment.
- **Kensa cases here:** rarely. If they exist, they're usually
  dev-authored, not Kensa-authored.

### 2. Component integration testing (unit integration testing)

- **Test object:** interactions between components.
- **Who:** developers; sometimes test engineers.
- **Kensa cases here:** uncommon. API-level integration tests may
  fit if Kensa is being used for those (see `backend-api-testing`).

### 3. System testing

- **Test object:** the whole system end-to-end.
- **Who:** an independent test team (or a Kensa session).
- **Kensa cases here:** **default for most web/mobile features.**
  This is where most cases land. End-to-end flows, business logic
  across modules.

### 4. System integration testing

- **Test object:** the system + its external services (payment
  provider, identity provider, third-party APIs).
- **Who:** test team with environment access.
- **Kensa cases here:** cases that exercise external integrations
  explicitly. Often paired with stub/mock data because real third
  parties can't be tested freely.

### 5. Acceptance testing

- **Test object:** the system from the user's perspective; readiness
  for deployment.
- **Who:** ideally the intended users. UAT, operational AT,
  contractual AT, regulatory AT, alpha, beta.
- **Kensa cases here:** scenario-based cases derived directly from
  user stories' AC; often the basis for UAT scripts handed to
  business users.

### How to choose the right level

For a Kensa session, default to **system** unless:

- The spec explicitly calls out an external integration → **system
  integration**.
- The spec is a user story with AC and the goal is "user can sign
  off" → **acceptance**.
- The case verifies an isolated API contract → consider
  **component integration** (see `backend-api-testing`).

Tag in frontmatter (project convention) — example:

```yaml
---
id: checkout.payment.flow-001
level: system_integration   # uses external payment provider
type: functional
---
```

If `project.md` doesn't define a `level` field, the suite path usually
implies it (e.g., `.tms/suites/acceptance/...` vs
`.tms/suites/system/...`). When in doubt, ask the user.

## The four test types (§2.2.2)

These cut across levels — a single feature can have functional,
non-functional, black-box and white-box tests at the same level.

### Functional testing

> "Functional testing evaluates the functions that a component or
> system should perform. … The main objective is checking the
> functional completeness, functional correctness and functional
> appropriateness."
> — CTFL 4.0 §2.2.2

Kensa default. Most cases are functional system tests.

### Non-functional testing

Per ISO/IEC 25010, the non-functional quality characteristics are:

- Performance efficiency
- Compatibility
- Usability (interaction capability)
- Reliability
- Security
- Maintainability
- Portability (flexibility)
- Safety

**Kensa rule:** when a non-functional aspect needs testing, name the
characteristic in the tag (`tags: [non-functional, usability]` or
`tags: [non-functional, security]`). This makes the case
discoverable and signals what platform skill should be loaded —
e.g., `security-testing`, mobile-only checks in `mobile-testing`.

> "The late discovery of non-functional defects can pose a serious
> threat to the success of a project."
> — CTFL 4.0 §2.2.2

If the user's spec only describes "what" (functional) and never
"how well" (non-functional), the test-lead-agent should flag this
during scope-analysis.

### Black-box testing

Specification-based. Derives tests from documentation (AC, specs,
user stories). **Kensa default** — agents only have access to the
spec, not the implementation source.

### White-box testing

Structure-based. Derives tests from implementation (code, control
flow). **Kensa typically can't do white-box authoring** — agents
don't read source. They can RECOGNIZE white-box concepts when
talking to devs (see `white-box-techniques-overview`).

## Confirmation vs regression (§2.2.3)

**These two are distinct. Confirmation ≠ regression.**

### Confirmation testing

> "Confirmation testing confirms that an original defect has been
> successfully fixed."
> — CTFL 4.0 §2.2.3

For a bug fix:

- Re-run the tests that previously failed.
- Optionally add new tests for the changes made during the fix.

In Kensa: when the user says "we fixed bug LIN-203, write a
confirmation test", the case targets the exact failure conditions
described in the original bug report.

### Regression testing

> "Regression testing confirms that no adverse consequences have
> been caused by a change, including a fix that has already been
> confirmation tested."
> — CTFL 4.0 §2.2.3

For *any* change (fix or new feature), re-run a broader set of cases
to make sure nothing else broke. Regression suites grow with time;
they're a strong candidate for automation.

In Kensa: `/update-feature` is the workflow that produces *both*
confirmation tests (for the change itself) and updated regression
coverage (cases adjacent to the change that need re-verification).

### Distinction in tagging

```yaml
tags: [confirmation, bug-fix:LIN-203]   # confirmation case
tags: [regression]                       # regression-pack case
```

Don't tag every case as "regression" — by definition, every passing
case becomes a regression case after the next change. Reserve the
tag for cases that are explicitly part of the regression sweep.

## Maintenance testing (§2.3)

The three categories of maintenance trigger:

### Modifications

Planned enhancements, corrective changes, hot fixes. **This is what
`/update-feature` is built for.** When a feature changes, the Test Lead:

1. Identifies affected existing cases (`source_id` and tags help).
2. Categorizes: update / remove / leave as-is / add new.
3. Delegates targeted update packages to qa-engineer-agents.

### Upgrades or migrations

Platform changes (one OS to another), data migrations, dependency
upgrades. **Out of scope for default Kensa workflows** but the Test Lead
should recognize the trigger and ask the user whether they want
migration-focused regression coverage.

### Retirement

End-of-life: data archiving, restore/retrieval. **Explicitly out of
scope for Kensa** — retirement testing is a specialty topic; tell the
user to engage a different process if it comes up.

> "The scope of maintenance testing typically depends on the degree of
> risk of the change, the size of the existing system, and the size
> of the change."
> — CTFL 4.0 §2.3

So when a user says "we changed login", the scope of maintenance
testing depends on: how risky is auth (high), how big is the system
(only the Test Lead can estimate from the suite tree), how big the change
(read the diff/spec). Use this to scope `/update-feature`.

## Worked example — labelling cases for a 2FA feature

| Test purpose | Level | Type | Tags |
|---|---|---|---|
| User enables 2FA from Settings (happy path) | system | functional | `[functional, auth, 2fa]` |
| 2FA secret is encrypted in DB | component integration | non-functional, security | `[non-functional, security, 2fa]` |
| User completes 2FA via authenticator app end-to-end | acceptance | functional | `[acceptance, functional, 2fa]` |
| TOTP code window is ±30s | system | non-functional, reliability | `[non-functional, reliability, 2fa]` |
| Login with 2FA against external IdP | system integration | functional | `[integration, idp, 2fa]` |
| All 2FA cases re-run after fixing a typo in error string | (same as original level) | functional | `[regression, 2fa]` |
| Test that the exact reported lockout bug LIN-203 is fixed | system | functional | `[confirmation, bug-fix:LIN-203]` |

Two distinct cases for the same surface are fine if level/type
differ — that's how the syllabus expects it.

## Worked example — picking a scope for an update

User: "We changed the 2FA setup flow — now we send a verification
email before showing the QR code. Please update the tests."

The test-lead-agent's reasoning using §2.3:

1. **Trigger:** modification (planned enhancement).
2. **Affected scope:** `grep source_id LIN-89` in `.tms/suites/`
   → returns 14 cases.
3. **Categorize:**
   - **Update:** setup-001, setup-002 (the QR-code flow is now
     gated by email verification).
   - **Add new:** "email verification step rejects expired token",
     "resend email rate-limit".
   - **Leave as-is:** login-with-2FA cases (unchanged downstream
     behaviour).
   - **Confirmation:** ensure the original setup-001 still passes
     after the change (modified flow).
   - **Regression:** entire `auth/2fa/` folder gets re-run as part
     of next release.
4. **Delegate** 1 package to one qa-engineer-agent (small scope).

This is `/update-feature` operationalising §2.3 maintenance testing.

## Retrospectives (§2.1.6) — Kensa application

> "Retrospectives are critical for the successful implementation of
> continuous improvement, and it is important that any recommended
> improvements are followed up."
> — CTFL 4.0 §2.1.6

Kensa's `/save-memory` command IS a lightweight retrospective. After
a session, the Test Lead asks the user what worked, what didn't, and
records project-level learnings in `learned/patterns.md`. This is
how the plugin embodies §2.1.6.

## When to load this skill

- Session start, alongside `testing-fundamentals`, for any Kensa
  pipeline — both the Test Lead and the qa-engineer-agent need it.
- Before writing the frontmatter `level` and `type` (or `tags`) on
  cases — use this skill to choose the right values.
- When the user requests an update to existing cases — match the
  scenario to a maintenance trigger.
- When the user mentions TDD/ATDD/BDD/CI/CD/DevOps — use this skill
  to recognize the context and adapt your output accordingly.
- When you want to defend a scope decision ("this is system testing,
  not integration testing because we're stubbing the third party") —
  cite §2.2.1.

## Anti-patterns

- Tagging everything as "system" because you don't want to think
  about levels — wrong-level tagging confuses the suite reader.
- Tagging functional cases as "regression" preemptively — the
  regression tag belongs to a case that's *in the regression pack*,
  not every case ever written.
- Treating confirmation and regression as synonyms — they're
  different activities with different inputs.
- Authoring "white-box" cases — Kensa agents don't read source. If
  you find yourself trying, you've drifted; see
  `white-box-techniques-overview`.
- Recommending retirement testing or migration testing without
  flagging it's a specialty effort the user may not want to scope
  into the current session.
