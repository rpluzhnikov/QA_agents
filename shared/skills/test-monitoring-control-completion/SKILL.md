---
name: test-monitoring-control-completion
description: ISTQB CTFL §5.3 — the metric categories you can collect from a Kensa project (progress, product quality, defect, risk, coverage, cost), the structure of test progress reports (interim) vs test completion reports (final), and how to communicate status to stakeholders. Load when preparing the report-back to the user after `/new-feature` or `/update-feature`, and when the user asks for a coverage/progress summary.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 5 — Managing the Test Activities, §5.3 Test Monitoring, Test Control and Test Completion (§5.3.1 metrics, §5.3.2 reports, §5.3.3 status communication).
> Learning objectives: FL-5.3.1 (K1) recall metrics used for testing; FL-5.3.2 (K2) summarize purposes, content, and audiences for test reports; FL-5.3.3 (K2) exemplify how to communicate the status of testing.
> See also: §1.4.1 (monitoring/control as a test activity); §5.1.3 (exit criteria are what completion measures against); §5.2 (risk metrics).

# Test monitoring, control and completion

This is the Test Lead-only skill that governs how the `test-lead-agent`
reports back to the user. Every Kensa session ends in a test
completion report — a summary of what was done, what was found, and
what remains. Mid-session, for longer features, the Test Lead may also
emit a test progress report.

The ISTQB framing here is what separates a useful report ("here's
what's tested, here's what's not, here's the residual risk") from a
useless one ("I wrote 12 cases").

## The three activities (§5.3)

> "Test monitoring is concerned with gathering information about
> testing. … Test control uses the information from test monitoring
> to provide … guidance and the necessary corrective actions. … Test
> completion collects data from completed test activities to
> consolidate experience, testware, and any other relevant
> information."
> — CTFL 4.0 §5.3

| Activity | What | Kensa |
|---|---|---|
| **Test monitoring** | Gather info on progress | Test Lead tracks QA Engineer checklist/case status during session |
| **Test control** | Take corrective actions | Test Lead sends checklists back, escalates blockers to user |
| **Test completion** | Wrap up at milestones | Test Lead's final report-back at session end |

Examples of control directives (§5.3):

- Reprioritize tests when a risk becomes an issue.
- Re-evaluate entry/exit criteria due to rework.
- Adjust schedule for environment delays.
- Add new resources where needed (e.g., spawn an additional
  qa-engineer-agent for an under-scoped package).

## Metric categories (§5.3.1)

§5.3.1 lists seven common metric categories. For each, here's what
Kensa CAN and CAN'T provide.

### 1. Project progress metrics

> Task completion, resource usage, test effort.

Kensa can produce:
- Task completion: % of checklist items implemented as cases.
- Effort: rough time-to-completion per session (less precise).

### 2. Test progress metrics

> Test case implementation progress, test environment preparation,
> # of test cases run/not run, passed/failed, execution time.

Kensa can produce:
- Number of cases authored: `kensa-cli stats`.
- Number of cases by status (draft / ready / deprecated):
  `kensa-cli stats --by-status`.
- Pass/fail/run metrics: NOT directly — these require a test run,
  which lives downstream in `.tms/runs/` if the user is using runs.

### 3. Product quality metrics

> Availability, response time, mean time to failure.

Kensa CANNOT produce these — they require running the product. Out
of scope; tell the user this needs a different tool (APM, perf
testing).

### 4. Defect metrics

> # and priorities of defects found/fixed, defect density, defect
> detection percentage.

Kensa can produce (during static review):
- # of defects found in static review of the spec (AC ambiguities,
  missing coverage).
- # of testware defects found by lead review (cases sent back).

For dynamic-test defects: only if the user runs the cases and feeds
results back — usually out of session scope.

### 5. Risk metrics

> Residual risk level.

Kensa can produce:
- Risk register from `risk-based-testing` — initial assessment.
- Residual risks at session end (risks NOT mitigated by the cases
  authored): explicit in the report-back.

### 6. Coverage metrics

> Requirements coverage, code coverage.

Kensa can produce:
- Requirements coverage: `kensa-cli coverage --by-source LIN-89` shows
  which AC have cases. This is the most actionable Kensa metric.
- Code coverage: NOT producible — handed off to dev/automation tools.

### 7. Cost metrics

> Cost of testing, organizational cost of quality.

Kensa CANNOT produce these directly. The lead can report effort
(time, agent invocations) qualitatively.

## Kensa metric inventory — what to include in reports

When producing a completion report, include these where available:

| Metric | Command/source | Always include? |
|---|---|---|
| Cases authored | `kensa-cli stats` | Yes |
| Cases by suite | `kensa-cli stats --by-suite` | If multi-suite session |
| Cases by status | `kensa-cli stats --by-status` | Yes |
| Coverage by source | `kensa-cli coverage --by-source <SOT-ID>` | Yes |
| Coverage by risk | `kensa-cli coverage --by-risk <risk-id>` | If risk register has IDs |
| Lint warnings | `kensa-cli lint` | If any |
| Duplicate cases | `kensa-cli duplicates` | If any |
| Residual risks | From scope plan vs final cases | Yes |
| Open questions | Carried from scope plan | If any unresolved |

Cite these in the report so the user can verify or query later.

## Test progress reports (§5.3.2)

> "Test progress reports support the ongoing test control and must
> provide enough information to make modifications to the test
> schedule, resources, or test plan, when such changes are needed
> due to deviation from the plan or changed circumstances."
> — CTFL 4.0 §5.3.2

### When to produce one in Kensa

For most sessions: not needed. Sessions are short.

For long sessions or multi-day features: emit a progress report at
checkpoints. Examples:

- After scope plan approval, before first qa-engineer-agent spawns.
- After Stage 1 (checklist review) for each package.
- After Stage 2 (case review) for each package.

### Progress report template (per §5.3.2)

```markdown
## Progress report — Session for LIN-89 (2FA), checkpoint 2 of 3

**Testing period:** Stage 2 case writing for package P1

**Progress:**
- P1 (auth/2fa): 12 of 14 cases written, ready for review
- P2 (auth/2fa-recovery): blocked on user clarification (R5 in risk
  register)

**Impediments:**
- Spec ambiguity on recovery code reusability — awaiting user
  response before P2 can proceed.

**Metrics so far:**
- 12 cases authored
- 100% coverage of AC-1, AC-2, AC-4 (P1 scope)
- 0% coverage of AC-3, AC-5 (P2 scope, blocked)
- 1 testware defect found by lead review (resolved)

**New / changed risks:**
- None.

**Next period:**
- Awaiting user response on recovery code policy.
- Once unblocked, ~5 cases for P2.
```

This is the structure §5.3.2 mandates: testing period / progress /
impediments / metrics / new risks / next-period plan.

## Test completion reports (§5.3.2)

> "A test completion report is prepared during test completion, when
> a project, test level, or test type is complete and when, ideally,
> its exit criteria have been met."
> — CTFL 4.0 §5.3.2

This IS what the Test Lead's end-of-session report-back to the user
should aspire to. Less formal than the syllabus describes (Kensa is
async + lightweight), but with the same content slots.

### Completion report template (per §5.3.2)

```markdown
## Completion report — /new-feature LIN-89 (2FA)

**Summary**
14 cases authored across 1 package (auth/2fa). All AC covered.
Test Lead-reviewed; all passed `review-rubrics`. Ready for human
execution.

**Quality evaluation (vs scope plan)**
- ✅ All 6 in-scope AC have ≥1 case
- ✅ 3-value BVA applied to TOTP time window
- ✅ Decision table for login state combinations
- ✅ Negative paths for invalid codes, expired codes
- ✅ Re-auth flow for disable
- ⚠️ Recovery code reusability documented as assumption (per
  open question response)

**Deviations from plan**
- Estimated ~14 cases (3-point estimate); actual 14. Within range.
- No new risks emerged.

**Metrics**
- 14 cases authored (`kensa-cli stats`)
- 6/6 AC covered (`kensa-cli coverage --by-source LIN-89`)
- 0 lint warnings
- 0 duplicates

**Unmitigated risks**
- R5 (recovery code abuse): single-use assumption confirmed by user
  — covered.
- (Project risk) SMS-based 2FA: explicitly out of scope per spec;
  separate ticket recommended.

**Lessons learned (for `/save-memory`)**
- This team uses scenario-format AC consistently — pattern recorded.
- TOTP window not in spec — captured as a `glossary.md` clarification
  for future auth features.

**Ready for:**
- Human tester to execute cases.
- Or: future automation to translate to executable specs (ATDD
  pattern).
```

That's the §5.3.2 completion-report template, Kensa-fitted.

## Audience tailoring (§5.3.2, §5.3.3)

> "Different audiences require different information in the reports
> and influence the degree of formality and the frequency of test
> reporting."
> — CTFL 4.0 §5.3.2

The user is the primary audience for Kensa reports, but they may
forward to:

- **Engineers** — want the case IDs and what to run; metrics matter
  less.
- **PM / product manager** — want coverage of AC and residual risks;
  case count matters less.
- **Management / executive** — want one-line summary + risk status;
  want to know "are we shipping?".

Match the section emphasis to who'll read it. If the user clarifies
audience ("send this to the head of engineering"), shorten the
summary and elevate risks.

## Communicating status (§5.3.3)

§5.3.3 lists options:

- Verbal communication.
- Dashboards (CI/CD, task boards, burn-down charts).
- Electronic communication (email, chat).
- Online documentation.
- Formal test reports.

Kensa is asynchronous text — closest to "electronic communication"
+ "online documentation" (the `.tms/` git history). The lead's
report-back is the formal report.

> "More formal communication may be more appropriate for distributed
> teams where direct face-to-face communication is not always
> possible due to geographical distance or time differences."
> — CTFL 4.0 §5.3.3

Kensa serves distributed/async teams by default — that's why the
report needs to stand on its own.

## Worked example — short session completion report

User invokes `/new-feature` on a small profile-edit feature. 5
cases authored.

```markdown
## Completion — /new-feature LIN-42 (Edit profile name/email)

**Summary:** 5 cases for happy + key negatives. All AC covered.

**Coverage:** 3/3 AC (kensa-cli coverage --by-source LIN-42).

**Risks:** Low overall (no PII new, no auth change). 1 risk
accepted: deep i18n testing on name field (low likelihood, low
impact for English-only product).

**Metrics:** 5 cases, 0 lint, 0 duplicates.

**Ready for human execution.**
```

Short feature, short report. The structure is still §5.3.2-shaped.

## Worked example — when an exit criterion isn't met

Mid-session, the Test Lead discovers the user's spec contradicts itself
and needs revision. Session can't proceed.

```markdown
## Progress + escalation — LIN-89 paused

**Testing period:** scope-analysis phase only

**Progress:** Plan drafted but not approved. Scope-analysis halted
due to spec contradiction: description says "max 5 failed attempts"
but AC-4 says "max 3 failed attempts".

**Impediment:** Cannot proceed without authoritative source. This
violates entry criterion (DoR) — spec is not unambiguous.

**Recommended action:** User confirms which value applies, OR
PM updates the spec.

**Metrics:** 0 cases authored. 1 static defect found (the
contradiction itself).

**Pausing session.**
```

That's control + monitoring producing an actionable status to the
user.

## When to load this skill

- `test-lead-agent` at session end, before composing the
  report-back to the user.
- During long sessions when emitting a progress checkpoint.
- When the user asks "what's the coverage / status / metrics?" —
  use this skill to structure the answer.
- When the user asks for a report formatted for a specific audience
  (engineering vs PM vs exec).
- When a session is blocked and needs escalation — frame as a
  monitoring/control output.

## Anti-patterns

- Completion report = "I wrote N cases". Missing risk, missing
  coverage, missing residual issues. Violates §5.3.2 content
  requirements.
- Mid-session progress with no impediments and no risks ever
  identified — implies you didn't look.
- Citing metrics Kensa can't produce ("100% code coverage") —
  off-scope and misleading. Stick to requirements coverage.
- Burying residual risks at the end of a long report. They're
  the second most important section after the summary.
- One-size-fits-all reports — failing to tailor to audience when
  the user tells you who'll read it.
- Reporting in vague qualitative language ("we did well") when
  metrics are available. Use numbers when you have them.
