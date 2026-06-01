---
name: testing-fundamentals
description: ISTQB CTFL Chapter 1 foundation — test objectives, the testing/debugging distinction, root-cause vs error vs defect vs failure, the seven testing principles, the seven test activities (planning → completion), testware taxonomy, and traceability. Load when reasoning about why a test exists or what artefact it produces, and any time you need to name an activity correctly (analysis vs design vs implementation vs execution).
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 1 — Fundamentals of Testing, §1.1 What is Testing?, §1.2 Why is Testing Necessary?, §1.3 Testing Principles, §1.4 Test Activities/Testware/Roles, §1.5 Skills and Good Practices.
> Learning objectives: FL-1.1.1 (K1) identify test objectives; FL-1.1.2 (K2) differentiate testing from debugging; FL-1.2.3 (K2) distinguish root cause, error, defect, failure; FL-1.3.1 (K2) explain the seven testing principles; FL-1.4.1 (K2) explain test activities and tasks; FL-1.4.3 (K2) differentiate testware; FL-1.4.4 (K2) explain the value of traceability; FL-1.4.5 (K2) compare roles in testing.
> See also: §5.5 for defect management (which builds on §1.2.3); §4 for the techniques used inside the "test design" activity.

# Testing fundamentals

This skill is the conceptual floor every other skill stands on. If you
can't name the difference between an error, a defect and a failure, or
between test analysis and test design, you'll write fuzzy plans and
mis-tag everything. Read this once per session before you do real work.

Five things to get right from Chapter 1:

1. **Testing is a set of activities, not just execution.** It includes
   static testing (reviews), dynamic testing, planning, analysis,
   design, implementation, execution and completion. Skipping any of
   these is a process anti-pattern, not a shortcut.
2. **Testing and debugging are separate.** Testing finds or triggers
   defects; debugging removes them. The QA Engineer tests; the
   developer debugs. Confirmation testing (§2.2.3) is the bridge.
3. **Verification and validation are both in scope.** Verification
   = does it meet the spec? Validation = does it meet the user's
   actual need? You owe the user both.
4. **Test objectives are plural.** The CTFL lists nine. Pick the ones
   that apply to your context, name them, and let them drive what you
   write.
5. **Traceability is non-negotiable.** Every case ties back to a test
   basis element (an AC, a requirement, a risk). In Kensa, that's the
   `source_id` frontmatter field.

## The seven testing principles (verbatim, §1.3)

These are the principles. Cite them as `per ISTQB CTFL 4.0 §1.3` when
you need to defend a decision.

1. **Testing shows the presence, not the absence of defects** (Buxton
   1970). Testing reduces the probability of undiscovered defects but
   never proves correctness. *Kensa application:* never tell the user
   "this feature is tested and bug-free" — tell them "X test cases
   passed against acceptance criteria Y; residual risk Z remains."
2. **Exhaustive testing is impossible** (Manna 1978). Use techniques
   (Ch 4), prioritization (§5.1.5), and risk-based testing (§5.2) to
   focus. *Kensa application:* a checklist with 200 items for a small
   form means you skipped technique selection. Use EP/BVA instead.
3. **Early testing saves time and money** (Boehm 1981). Defects caught
   early don't cascade. *Kensa application:* the test-lead-agent's
   spec review during scope-analysis IS early testing — it's where you
   find AC ambiguities before any case is written.
4. **Defects cluster together** (Enders 1975, Pareto). A small set of
   components contains most of the defects. *Kensa application:* if
   `learned/patterns.md` shows the auth module has produced 60% of
   recent bugs, allocate more cases there.
5. **Tests wear out** (Beizer 1990). Repeating the same tests stops
   finding new defects. *Kensa application:* `/update-feature` is the
   antidote — change the case set when the feature changes; don't just
   re-run the old ones.
6. **Testing is context dependent** (Kaner 2011). No universal
   approach. *Kensa application:* `project.md` exists precisely to
   capture this context per project so workers don't apply a generic
   template.
7. **Absence-of-defects fallacy** (Boehm 1981). Passing every test
   doesn't mean users will be happy. *Kensa application:* validation
   cases (against user needs) belong alongside verification cases
   (against spec) — see `collaboration-based-approaches`.

## Error → defect → failure → root cause (§1.2.3)

Get this chain right or your defect reports are sloppy.

| Term | Definition | Example |
|---|---|---|
| **Error** (mistake) | The human mistake | Developer mis-reads spec: "min length 8" as "max length 8" |
| **Defect** (fault, bug) | The flaw in the artefact that resulted | The validation regex rejects passwords > 8 chars |
| **Failure** | The observable wrong behaviour | User can't sign up with a 12-char password |
| **Root cause** | The fundamental reason for the error | Spec was ambiguous; reviewer missed it; no AC for max-length boundary |

Why this matters for Kensa:

- A defect report's **failure description** is the observable thing
  ("user cannot submit form when password length = 12"). The
  **defect** is the underlying flaw, often only knowable after dev
  diagnosis. Don't conflate them in the report.
- **Root cause analysis** belongs in the test completion report
  (`test-monitoring-control-completion`) and feeds retrospectives —
  not in the defect report itself.
- Failures can come from sources other than defects (environmental:
  radiation, network flake). If your test fails and you suspect
  environment, mark the result as INCONCLUSIVE rather than FAIL.

See `defect-management` for the full defect-report schema.

## Verification vs validation

- **Verification** — are we building the product right? (Conforms to
  the spec.) Most functional test cases.
- **Validation** — are we building the right product? (Meets actual
  user need.) Acceptance testing, usability testing, exploratory
  testing.

A spec can be wrong. A product that perfectly implements a wrong spec
will pass verification and fail validation. When the user says "this
isn't what I meant", that's a validation failure caught by the user
acting as final validator.

## The seven test activities (§1.4.1)

These are sequential in name but interleaved in practice. Know the
names — they're how the syllabus and every QA conversation references
work.

1. **Test planning** — defining objectives and approach. Output: test
   plan, schedule, risk register, entry/exit criteria. See
   `test-planning`.
2. **Test monitoring and test control** — checking progress vs plan;
   taking corrective action. Output: progress reports, control
   directives. See `test-monitoring-control-completion`.
3. **Test analysis** — analysing the test basis to identify *what* to
   test. Output: prioritized test conditions (= acceptance criteria,
   coverage items). This is "what to test?". In Kensa: the **checklist**
   stage of the `qa-engineer-agent` IS test analysis.
4. **Test design** — elaborating test conditions into test cases. This
   is "how to test?". Output: prioritized test cases. In Kensa: the
   **case-writing** stage is test design + implementation.
5. **Test implementation** — creating the testware needed for
   execution (test data, environment, scripts). Output: procedures,
   suites, scripts. In Kensa: writing the steps and expected results.
6. **Test execution** — running the tests, comparing actual to
   expected, logging results. Output: test logs, defect reports. In
   Kensa: this is the human tester running the cases later.
7. **Test completion** — wrapping up at milestones. Output: completion
   report, archived testware, lessons learned. In Kensa: the
   test-lead-agent's final report-back to the user IS test completion.

**Anti-pattern:** the qa-engineer-agent saying "I've finished test
design" when only the checklist is done. The checklist is test
*analysis*. Case writing is test design.

## Test activities mapped to Kensa agents

| Activity | Led by | Other involvement | Output in Kensa |
|---|---|---|---|
| Test planning | test-lead-agent | — | scope plan, decomposition, estimates |
| Monitoring & control | test-lead-agent | — | review checkpoints, send-back decisions |
| Test analysis | qa-engineer-agent | — | checklist `.md` per package |
| Test design | qa-engineer-agent | — | case `.md` files in `.tms/suites/` |
| Test implementation | qa-engineer-agent | — | shared steps, test data references |
| Test execution | (human tester or downstream automation) | — | runs in `.tms/runs/` |
| Test completion | test-lead-agent | — | final report message to user |

When you're inside an agent and unsure what to call your output, look
this table up.

## Testware taxonomy (§1.4.3)

These are the output work products. Knowing which produces what stops
confusion when you say "send me your testware":

- **Test planning work products** — test plan, schedule, risk
  register, entry/exit criteria.
- **Test monitoring/control work products** — test progress reports,
  control directives, risk updates.
- **Test analysis work products** — prioritized test conditions
  (= acceptance criteria), defect reports on the test basis itself
  (e.g., AC is ambiguous).
- **Test design work products** — prioritized test cases, test
  charters, coverage items, test data requirements, environment
  requirements.
- **Test implementation work products** — test procedures, manual and
  automated scripts, test suites, test data, execution schedule, test
  environment items (stubs, drivers, simulators).
- **Test execution work products** — test logs, defect reports on
  observed failures.
- **Test completion work products** — completion report, action
  items, lessons learned, change requests.

In Kensa: case `.md` files are test design work products; shared steps
are test implementation; the Test Lead's final report is a (lightweight)
test completion report.

## Traceability (§1.4.4)

> "To implement effective test monitoring and test control, it is
> important to establish and maintain traceability throughout the test
> process between the test basis elements, testware associated with
> these elements (e.g., test conditions, risks, test cases), test
> results, and defects."
> — CTFL 4.0 §1.4.4

In Kensa, traceability is operationalised through frontmatter:

```yaml
---
id: auth.2fa.setup-001
title: User enables TOTP from Security settings
source_id: LIN-89          # links to test basis (Linear issue)
source_ac: AC-1            # specific acceptance criterion (test condition)
risk_refs: [risk-2fa-bypass]  # links to risk register
priority: high
status: ready
---
```

The `source_id` field IS the test basis → testware link of §1.4.4.
This is what powers coverage queries:

- `kensa-cli coverage --by-source LIN-89` — which AC have cases?
- `kensa-cli coverage --by-risk risk-2fa-bypass` — what mitigates this risk?
- Reverse: when an AC changes, `grep source_ac: AC-1` finds every
  affected case.

Without traceability you cannot answer "are we covered?" — see
`test-monitoring-control-completion`.

## Roles in testing (§1.4.5)

The syllabus identifies two principal roles:

- **Test management role** — overall responsibility for the test
  process, team, leadership; focuses on planning, monitoring,
  control, completion. *Kensa mapping:* `test-lead-agent`.
- **Testing role** — engineering/technical aspects; focuses on
  analysis, design, implementation, execution. *Kensa mapping:*
  `qa-engineer-agent`.

> "Different people may take on these roles at different times. … It
> is also possible for one person to take on the roles of testing and
> test management at the same time."
> — CTFL 4.0 §1.4.5

The user is implicitly the **manager** (provides resources, decides
scope; see review roles in §3.2.3) and often the **author** of the
test basis (the spec being tested).

## Configuration management as part of fundamentals (§5.4 context)

§5.4 covers configuration management briefly. For Kensa, the relevant
points fold in here:

- All testware is version-controlled. `.tms/` is git-tracked; that IS
  configuration management.
- Configuration items are uniquely identified — every case has an
  `id`; every shared step has an `id`.
- Changes are traceable — `git log` over `.tms/` is the audit trail.
- The user is responsible for promoting cases to baseline by merging.
  The agents do not branch or merge on their own.

## Whole team approach and independence (§1.5.2, §1.5.3)

> "Independent testers are likely to recognize different kinds of
> failures and defects compared to developers because of their
> different backgrounds, technical perspectives, and biases."
> — CTFL 4.0 §1.5.3

The Kensa plugin sits at "high independence" (a separate agent team
from whoever wrote the code/spec). Benefits: catches what the author
missed. Drawbacks: less context. Mitigations the Test Lead should apply:

- Read the SOT thoroughly to build context (`reading-existing-codebase`
  pattern from sibling skills).
- Engage the user when something is unclear — don't write cases
  against assumptions.
- Use existing cases (`.tms/suites/`) as a source of project
  context.

## Worked example — a 2FA feature, mapped to Chapter 1

User: "Write tests for the new TOTP 2FA in LIN-89."

1. **Test planning** (lead) — read LIN-89, identify scope, decompose,
   estimate. Output: scope plan to user. **Test objective applied:**
   "Reducing the risk level of inadequate software quality" — auth is
   high-risk.
2. **Test analysis** (qa-engineer-agent) — read the AC, identify
   testable claims. Output: checklist with items mapped to AC and
   risks. **Principle applied:** #2 exhaustive testing impossible —
   pick BVA on the 6-digit code, EP on the secret format.
3. **Test design** (qa-engineer-agent) — write 14 cases in
   `.tms/suites/auth/2fa/`, each with `source_id: LIN-89` and
   `source_ac: AC-N` for traceability.
4. **Test completion** (lead) — report to user: "14 cases, all AC
   covered, residual risk: SMS fallback not tested (out of scope per
   spec). Recommend separate ticket."

Notice how the activity names show up in the work breakdown. If you
can't name your current activity, you're not in control of the
process.

## When to load this skill

- Session start in any Kensa pipeline — `test-lead-agent` loads it
  first, `qa-engineer-agent` loads it before checklist work.
- Any time you're about to label an activity ("Is this analysis or
  design?") and want to be right.
- When the user asks "why" — why is a case needed, why is something
  out of scope, why traceability — you'll cite a principle or
  objective.
- When writing a defect report and you need to separate failure from
  defect from root cause.
- Before delegating: the Test Lead names the activity in the QA Engineer brief
  ("perform test analysis for package P1") using §1.4.1 vocabulary.

## Anti-patterns

- Conflating testing with debugging in conversation with the user
  ("we'll test and fix it") — these are different activities done by
  different roles.
- Calling the checklist "test cases" — it's test conditions
  (analysis output), not test cases (design output).
- Skipping `source_id` in frontmatter — you've broken traceability;
  no §5.3 coverage metrics possible.
- Treating principles as decoration. They're load-bearing — if your
  plan violates principle #2 (200 items because "we want to be
  thorough"), reread #2.
- Claiming "tested = bug-free" — violates principle #1. Always
  qualify in the report-back.
