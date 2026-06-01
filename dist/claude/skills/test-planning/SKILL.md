---
name: test-planning
description: ISTQB CTFL §5.1 — how to plan testing for a feature batch — the seven test-plan ingredients (context / assumptions / stakeholders / communication / risk register / approach / budget+schedule), entry & exit criteria (DoR / DoD in Agile), four estimation techniques, three prioritization strategies, and the test pyramid + testing quadrants as mental models. Load when planning a new feature batch — `scope-analysis` builds on this skill.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 5 — Managing the Test Activities, §5.1 Test Planning (§5.1.1 plan content, §5.1.2 iteration/release planning, §5.1.3 entry/exit criteria, §5.1.4 estimation, §5.1.5 prioritization, §5.1.6 test pyramid, §5.1.7 testing quadrants).
> Learning objectives: FL-5.1.1 (K2) exemplify the purpose and content of a test plan; FL-5.1.2 (K1) recognize how a tester adds value to iteration and release planning; FL-5.1.3 (K2) compare and contrast entry criteria and exit criteria; FL-5.1.4 (K3) use estimation techniques; FL-5.1.5 (K3) apply test case prioritization; FL-5.1.6 (K1) recall test pyramid concepts; FL-5.1.7 (K2) summarize testing quadrants.
> See also: §5.2 (risk-based testing feeds prioritization); §1.4.1 (planning is a test activity); the `scope-analysis` skill for the Kensa operationalisation.

# Test planning

Test planning is the first of the seven test activities (§1.4.1).
For Kensa, it happens at session start whenever the user invokes
`/new-feature` or `/update-feature`. The output is a scope plan that
goes to the user for approval before any case writing begins.

This skill gives you the ISTQB-grounded ingredients of a plan; the
existing `scope-analysis` skill gives you the Kensa-specific output
template. Use both.

## What a test plan is for (§5.1.1)

> "Test planning guides the testers' thinking and forces the testers
> to confront the future challenges related to risks, schedules,
> people, tools, costs, effort, etc. The process of preparing a test
> plan is a useful way to think through the efforts needed to achieve
> the test objectives."
> — CTFL 4.0 §5.1.1

A test plan:

- Documents the means and schedule for achieving test objectives.
- Helps ensure the activities will meet established criteria.
- Communicates with team members and stakeholders.
- Demonstrates adherence to test policy and strategy (or explains
  deviation).

In Kensa, the scope plan the `test-lead-agent` sends to the user IS
the test plan for that session — a lightweight one, but it serves
the same purpose.

## The seven test-plan ingredients (§5.1.1)

The CTFL lists seven content areas. Each one maps to something the
`scope-analysis` output already covers (or should).

| # | Ingredient | What it contains | Kensa mapping |
|---|---|---|---|
| 1 | **Context of testing** | Test scope, objectives, test basis | "In scope" + "Out of scope" sections |
| 2 | **Assumptions and constraints** | What you're assuming, what limits you | "Assumptions I'll make unless you say otherwise" section |
| 3 | **Stakeholders** | Roles, responsibilities, training needs | Usually implicit — user + lead + qa-engineer-agent |
| 4 | **Communication** | Forms and frequency of communication | Kensa is async via files + user messages; mention if non-default |
| 5 | **Risk register** | Product risks, project risks | "Risk" section; cross-reference `risk-based-testing` |
| 6 | **Test approach** | Levels, types, techniques, deliverables, entry/exit, independence, metrics, environment | "Decomposition" + techniques applied per package |
| 7 | **Budget and schedule** | Effort estimates, milestones | "Estimated case count" + (optionally) wall-clock estimate |

If any of these are missing from your scope plan and they're not
trivially defaulted, add them. Don't omit risks silently.

> "More details about the test plan and its content can be found in
> the ISO/IEC/IEEE 29119-3 standard."
> — CTFL 4.0 §5.1.1

For high-formality projects (audit, regulatory, contractual), refer
the user to ISO 29119-3 — Kensa's lightweight format isn't enough.

## Iteration and release planning (§5.1.2)

Two planning horizons:

- **Release planning** — looks ahead to a product release; defines
  and refines the product backlog; basis for the test approach
  across iterations.
- **Iteration planning** — looks ahead to the end of one iteration;
  iteration backlog.

What testers contribute at each level (per §5.1.2):

- **Release:** writing testable user stories and AC, project/quality
  risk analyses, estimating test effort, determining test approach.
- **Iteration:** detailed risk analysis per story, testability
  assessment, breaking stories into testing tasks, estimating per
  task, identifying functional and non-functional aspects.

**Kensa connection:** the Test Lead's `scope-analysis` for one feature is
iteration-planning-level work. If the user is planning a larger
release across many features, that's release-planning-level and
typically out of Kensa's per-session scope — but the Test Lead can
contribute risk and effort thinking on individual features.

## Entry and exit criteria (§5.1.3)

> "Entry criteria define the preconditions for undertaking a given
> activity. … Exit criteria define what must be achieved to declare
> an activity completed."
> — CTFL 4.0 §5.1.3

### Typical entry criteria

- Availability of resources (people, tools, environments, test data,
  budget, time).
- Availability of testware (test basis, testable requirements, user
  stories, test cases).
- Initial quality level of test object (e.g., smoke tests pass).

### Typical exit criteria

- Thoroughness measures (coverage achieved, unresolved defect count,
  defect density, failed-test count).
- Binary yes/no criteria (planned tests executed, static testing
  performed, all defects reported).
- Running out of time or budget can be valid exit criteria if
  stakeholders accept the residual risk.

### Agile vocabulary

> "In Agile software development, exit criteria are often called
> Definition of Done, defining the team's objective metrics for a
> releasable item. Entry criteria that a user story must fulfill to
> start the development and/or testing activities are called
> Definition of Ready."
> — CTFL 4.0 §5.1.3

For a Kensa session:

**Definition of Ready (entry criteria for the session):**

- SOT reference provided by user (Jira/Linear/Confluence/etc.).
- AC present in the SOT (or user agrees to draft AC with the Test Lead).
- The right MCP server is configured to read the SOT (see
  `kensa-setup` and `sot-*` skills).
- `project.md` exists or this is the first session.

**Definition of Done (exit criteria for the session):**

- All approved checklist items have ≥1 case.
- All cases pass Test Lead review per `review-rubrics`.
- Frontmatter complete on every case (`source_id` for traceability).
- Final report-back delivered to user.
- Open questions or residual risks explicitly stated.

If the user asks "are we done?", check this list.

## Estimation techniques (§5.1.4)

The syllabus describes four. Use these as appropriate.

### 1. Estimation based on ratios

Use historical project ratios. "If past dev:test was 3:2 and current
dev is 600 person-days, test = 400 person-days."

**Kensa application:** if `learned/patterns.md` records "average 8
cases per AC for this team", use that ratio for the new feature.

### 2. Extrapolation

Measure early in the current project, extrapolate from there. Best
for iterative SDLCs. "The forthcoming iteration's test effort is the
average of the last three iterations."

**Kensa application:** the Test Lead can extrapolate from the previous
2-3 sessions' case counts on similar features in this same project.

### 3. Wideband Delphi

Iterative, expert-based. Each expert estimates in isolation; results
shared; experts discuss; re-estimate; repeat until consensus.
Planning Poker is a variant.

**Kensa application:** rare in a single-agent context. But if multiple
qa-engineer-agents are spawned, the Test Lead could ask each to estimate
their package before delegating; outliers prompt discussion.

### 4. Three-point estimation

> "Three estimations are made by the experts: the most optimistic
> estimation (a), the most likely estimation (m) and the most
> pessimistic estimation (b). The final estimate (E) is their
> weighted arithmetic mean. In the most popular version of this
> technique, the estimate is calculated as E = (a + 4*m + b) / 6."
> — CTFL 4.0 §5.1.4

Standard deviation: `SD = (b - a) / 6`.

**Kensa application: THIS IS THE RECOMMENDED DEFAULT.** When the
lead estimates a package size, think three values:

- a (optimistic) = 5 cases
- m (most likely) = 8 cases
- b (pessimistic) = 14 cases
- E = (5 + 4*8 + 14) / 6 = (5 + 32 + 14) / 6 ≈ 8.5 cases
- SD = (14 - 5) / 6 = 1.5 cases
- Reported: "~8-10 cases" (E ± SD)

Three-point gives the user a range, not a false-precision single
number. Mark estimates as `~` in the plan output.

## Test case prioritization (§5.1.5)

Once cases exist, in what order should they be executed? Three
strategies:

### 1. Risk-based prioritization

Based on risk analysis (§5.2). Cases covering the most important
risks run first.

**Kensa application:** when handing cases off to a human tester, the
lead can recommend a run order. Cases tagged with high-risk
attributes go first.

### 2. Coverage-based prioritization

Based on coverage (statement, requirements, etc.). Highest-coverage
cases first. Variant: additional coverage prioritization (each next
case adds the most new coverage).

**Kensa application:** less common for manual cases. Used when the
human tester has limited time and wants to maximise breadth quickly.

### 3. Requirements-based prioritization

Based on the priorities of the requirements (set by stakeholders).
Cases tracing to the most important requirements first.

**Kensa application:** if AC are prioritized in the SOT (must-have,
should-have, nice-to-have), the Test Lead inherits that ordering. The
`review-rubrics` skill includes prioritization as a checklist
criterion.

### Dependencies and resources

> "If a test case with a higher priority is dependent on a test case
> with a lower priority, the lower priority test case must be
> executed first."
> — CTFL 4.0 §5.1.5

Also account for resource availability (tools, environment, people
windows). If the staging environment is only up Mon-Wed, schedule
environment-dependent cases then.

## Test pyramid (§5.1.6)

> "The test pyramid is a model showing that different tests may have
> different granularity. … The pyramid layers represent groups of
> tests. The higher the layer, the lower the test granularity, the
> lower the test isolation … and the higher the test execution time."
> — CTFL 4.0 §5.1.6

Classic three-layer model (Cohn 2009):

```
        /\         end-to-end / UI tests (few, slow, brittle)
       /  \
      /----\       service / integration tests (medium)
     /      \
    /--------\     unit / component tests (many, fast, isolated)
```

**Kensa positioning:** Kensa cases are typically at the top of the
pyramid (E2E / acceptance). The user is responsible for the bottom
layers (unit/integration tests written by devs). When the user asks
"should we have more tests?", the answer depends on where the gap is
— often the bottom of the pyramid is where to add coverage cheaply,
not the top.

If the user is over-relying on Kensa-style E2E cases for everything,
gently raise the pyramid model: "Some of these checks would be better
as unit tests for the dev team."

## Testing quadrants (§5.1.7)

> "The testing quadrants, defined by Brian Marick … group the test
> levels with the appropriate test types, activities, test techniques
> and work products in the Agile software development."
> — CTFL 4.0 §5.1.7

Two axes: business-facing vs technology-facing × support the team vs
critique the product.

| | Support the team | Critique the product |
|---|---|---|
| **Business-facing** | **Q2:** functional tests, user-story tests, examples, prototypes, simulations | **Q3:** exploratory testing, usability testing, UAT |
| **Technology-facing** | **Q1:** component tests, component integration tests | **Q4:** smoke tests, non-functional tests (perf, security, reliability) |

**Where Kensa cases live:**

- **Q2 (business-facing, support the team):** most Kensa cases. They
  derive from AC, they support the team by clarifying acceptance.
- **Q3 (business-facing, critique the product):** exploratory and
  UAT-style cases. Kensa can write the scripts; humans run them.
- **Q1 and Q4:** typically NOT Kensa (Q1 = dev tests; Q4 = automation).

Use the quadrants to explain to the user what kinds of testing
Kensa contributes to — and what's missing from their overall test
strategy if only Q2/Q3 are covered.

## Worked example — applying §5.1 to a Kensa scope plan

Feature: "Add 2FA via TOTP" (LIN-89). Test Lead's planning reasoning:

### 1. Context (ingredient 1)
- **Scope:** TOTP-based 2FA enable, login, disable, recovery codes.
- **Test basis:** LIN-89 description + AC + design link.
- **Objectives applied:** reduce risk level (auth is high-risk);
  validate user need (user-friendly setup).

### 2. Assumptions and constraints (ingredient 2)
- TOTP window: ±30s (industry default; spec silent).
- Recovery codes shown once at setup (industry default).
- No mobile-specific behaviour testing in this batch (web only).

### 3. Stakeholders (ingredient 3)
- User (manager + author of spec).
- test-lead-agent + 1 qa-engineer-agent.

### 4. Communication (ingredient 4)
- Async via Kensa session messages; final report on completion.

### 5. Risk register (ingredient 5)
See `risk-based-testing`. Key risks: 2FA bypass, lockout
interaction, recovery code abuse.

### 6. Test approach (ingredient 6)
- **Levels:** mostly system; some acceptance (UAT flow).
- **Types:** functional + non-functional (security).
- **Techniques:** EP on TOTP format, 3-value BVA on time window,
  decision-table on login states.
- **Independence:** high (Kensa is independent of dev team).
- **Entry criteria (DoR):** AC present, design final.
- **Exit criteria (DoD):** all cases reviewed, source_id traceability
  intact, residual risks documented.

### 7. Budget and schedule (ingredient 7)
- Estimate via 3-point: a=10, m=14, b=20. E = (10 + 56 + 20) / 6
  ≈ 14 cases. SD ≈ 1.7.
- Reported: "~14 cases, range 12-16."

That's a §5.1-grounded test plan, expressed in the `scope-analysis`
output format.

## Worked example — applying 3-point estimation

User asks "how many cases will this need?"

Test Lead reasoning:

> If everything's straightforward: 5 cases (a).
> Most likely given the AC and edge cases I see: 8 cases (m).
> If the AC ambiguities turn out to be more complex than I think
> and need extra coverage: 14 cases (b).
>
> E = (5 + 32 + 14) / 6 ≈ 8.5
> SD = (14 - 5) / 6 = 1.5
>
> Tell user: ~8 cases, range 7-10. I'll confirm after writing the
> checklist.

Don't promise an exact number you can't deliver. Three-point gives
you honest uncertainty.

## When to load this skill

- `test-lead-agent` at session start before producing the
  `scope-analysis` output — use the seven ingredients as a
  completeness check on the plan.
- When estimating session size — use 3-point estimation.
- When the user asks "what's the priority order to run these?" —
  apply §5.1.5 strategies.
- When the user asks about the test pyramid or quadrants — answer
  in §5.1.6/§5.1.7 vocabulary.
- When setting up entry/exit criteria for a session, especially in
  Agile contexts (DoR / DoD).

## Anti-patterns

- Single-number estimates with false precision ("13 cases") — use
  3-point and report a range.
- Skipping the risk register because "this is a small feature" —
  even small features should have at least 1-2 lines on risk; see
  `risk-based-testing`.
- Treating exit criteria as suggestions. If the user says "skip the
  review", flag that you're deviating from the DoD before doing it.
- Authoring cases that should be unit tests (push them down the
  pyramid) instead of suggesting to the user that the dev team owns
  them.
- Conflating release planning with iteration planning. Most Kensa
  sessions are iteration-scoped; large multi-feature releases need
  the user to scope explicitly.
