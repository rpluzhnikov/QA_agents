---
name: risk-based-testing
description: ISTQB CTFL §5.2 — identifying product risks (likelihood × impact), distinguishing them from project risks, analyzing risks to influence test scope and depth, and controlling risks via mitigation (testing, review, acceptance, transfer, contingency). Load whenever you need to justify why you're allocating MORE testing to one area and LESS to another, or when the user asks for risk-based prioritization.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 5 — Managing the Test Activities, §5.2 Risk Management (§5.2.1 risk definition, §5.2.2 project vs product risks, §5.2.3 product risk analysis, §5.2.4 product risk control).
> Learning objectives: FL-5.2.1 (K1) identify risk level by likelihood and impact; FL-5.2.2 (K2) distinguish project risks from product risks; FL-5.2.3 (K2) explain how product risk analysis influences thoroughness and test scope; FL-5.2.4 (K2) explain measures taken in response to analyzed product risks.
> See also: §5.1.5 (risk-based prioritization); §1.5.3 (independence of testing as a risk-mitigation lever); `negative-and-edge-cases` for the four-dimension walk that complements risk analysis.

# Risk-based testing

Risk-based testing IS the default approach for any non-trivial Kensa
session. Without explicit risk thinking, you'll either over-test
low-risk areas (waste) or under-test high-risk areas (missed
defects). This skill gives you the framework for both.

> "The test approach, in which test activities are selected,
> prioritized, and managed based on risk analysis and risk control,
> is called risk-based testing."
> — CTFL 4.0 §5.2

Two main activities:

1. **Risk analysis** = risk identification + risk assessment.
2. **Risk control** = risk mitigation + risk monitoring.

The `test-lead-agent` does the analysis during scope-analysis; both
agents apply mitigation throughout the session.

## Risk definition (§5.2.1)

> "Risk is a potential event, hazard, threat, or situation whose
> occurrence causes an adverse effect. A risk can be characterized
> by two factors:
> - Risk likelihood — the probability of the risk occurrence
>   (greater than zero and less than one)
> - Risk impact (harm) — the consequences of this occurrence."
> — CTFL 4.0 §5.2.1

**Risk level = likelihood × impact** (or some qualitative
combination). Higher risk level = more important to treat.

## Project risks vs product risks (§5.2.2)

The distinction matters because the agents handle them differently.

### Project risks

Related to management and control of the project. Examples per §5.2.2:

- **Organizational:** delays in deliveries, inaccurate estimates,
  cost cutting.
- **People:** insufficient skills, conflicts, communication problems,
  shortage of staff.
- **Technical:** scope creep, poor tool support.
- **Supplier:** third-party delivery failure, vendor bankruptcy.

**Kensa handling:** project risks affect *whether the testing
happens*, not what gets tested. The lead can surface project risks
to the user (e.g., "this Linear story is missing AC and the PM is
out for a week — project risk: blocked scope"), but mitigation is
the user's call.

### Product risks

Related to product quality characteristics (per ISO 25010). Examples
per §5.2.2:

- Missing or wrong functionality
- Incorrect calculations
- Runtime errors
- Poor architecture
- Inefficient algorithms
- Inadequate response time
- Poor user experience
- Security vulnerabilities

Consequences when product risks occur:

- User dissatisfaction
- Loss of revenue, trust, reputation
- Damage to third parties
- High maintenance costs, help-desk overload
- Criminal penalties
- (Extreme) physical damage, injuries, or death

**Kensa handling:** product risks ARE the primary input to test
scoping. They drive what cases get written, what depth, and what
techniques.

## Risk identification techniques (§5.2.3)

> "Stakeholders can identify risks by using various techniques and
> tools, e.g., brainstorming, workshops, interviews, or cause-effect
> diagrams."
> — CTFL 4.0 §5.2.3

For Kensa, the Test Lead's primary techniques:

1. **Read the spec critically** for known risk categories (auth,
   payments, data, perf).
2. **Walk the four dimensions** from `negative-and-edge-cases`
   (input / action / state / environment) — each dimension surfaces
   risk areas.
3. **Check `learned/patterns.md`** for past defect clusters in this
   project (per §1.3 principle 4: defects cluster).
4. **Ask the user** when something is opaque ("Is this auth-adjacent?
   Does it touch payment data?").

## Risk assessment — quantitative vs qualitative (§5.2.3)

> "Risk assessment can use a quantitative or qualitative approach,
> or a mix of them. In the quantitative approach the risk level is
> calculated as the multiplication of risk likelihood and risk
> impact. In the qualitative approach the risk level can be
> determined using a risk matrix."
> — CTFL 4.0 §5.2.3

### Quantitative (multiplication)

- Likelihood: 1-5 (1 = very unlikely, 5 = very likely)
- Impact: 1-5 (1 = trivial, 5 = catastrophic)
- Risk level = L × I (range 1-25)

Use when stakeholders care about ranked numbers.

### Qualitative (risk matrix)

A 3×3 matrix is the Kensa default. Each axis: Low / Medium / High.

|  | Low impact | Medium impact | High impact |
|---|---|---|---|
| **High likelihood** | Medium | High | **Critical** |
| **Medium likelihood** | Low | Medium | High |
| **Low likelihood** | Low | Low | Medium |

Map each identified product risk into a cell. The cell determines
test depth:

- **Critical / High** — many cases, including BVA + decision-table +
  negative paths + non-functional checks.
- **Medium** — cases for happy + key negatives + at least one BVA
  group.
- **Low** — smoke coverage only; document why deeper testing isn't
  worth the cost.

## Product risk catalog — common categories

When scoping a Kensa session, walk this catalog for the feature
under test:

| Category | Typical likelihood | Typical impact | Notes |
|---|---|---|---|
| **Authentication / Authorization** | Medium | Critical | Almost always high risk; cross-link `security-testing` |
| **Payments / Financial** | Low-Medium | Critical | Off-by-one + currency edge cases |
| **Personal data (PII)** | Medium | High | Cross-link `security-testing`; GDPR/privacy |
| **Data integrity (storage, sync)** | Medium | High | Concurrent writes, partial failures |
| **Performance (latency, throughput)** | Variable | Variable | Often misunderstood as functional |
| **External integrations** | High | Medium-High | Third-party flake; stub data realistic? |
| **Concurrency / race conditions** | Low | High | Hard to test manually; flag if relevant |
| **Internationalisation** | Medium | Medium | Locale/encoding bugs |
| **Accessibility** | Medium | Medium-High | Legal in some jurisdictions; cross-link a11y tests |
| **Browser / device compatibility** | Medium | Medium | Cross-link `web-testing` / `mobile-testing` |
| **Backwards compatibility** | Medium | High | API contract changes break clients |

For each, decide if the feature touches it. If yes, allocate cases
proportional to the risk level.

## Combining risk analysis with the four-dimension walk

`negative-and-edge-cases` provides four dimensions: input, action,
state, environment. Cross these with the risk catalog:

| Dimension | Risk lens |
|---|---|
| **Input** | What inputs could cause a security failure? a payment miscalculation? a data corruption? |
| **Action** | What user actions could trigger a race condition? bypass authorization? |
| **State** | What states expose authentication holes? What state transitions could leak PII? |
| **Environment** | Which environments are riskiest (offline, slow network, multiple tabs)? |

The product of (dimension × risk category) is your case-count budget
per area.

## Risk control measures (§5.2.4)

Once risks are analysed, what do you DO about them? §5.2.4 lists
response options:

- **Risk mitigation by testing** — most common; design and run cases
  to reduce the probability the risk causes a failure in production.
- **Risk acceptance** — explicitly decide not to test (residual risk
  is acceptable).
- **Risk transfer** — pass the risk to another party (e.g.,
  third-party warranty).
- **Contingency plan** — define a response if the risk materialises
  (rollback procedure).

The lead's job is to surface these options. The user decides.

### Mitigation by testing — actions per §5.2.4

When mitigating product risks by testing, you can:

1. **Select testers with the right experience and skills.** Kensa
   delegates to qa-engineer-agents loaded with platform-specific
   skills (`security-testing`, `mobile-testing`, etc.).
2. **Apply appropriate independence.** Kensa is high-independence
   (separate from dev). Good for catching what authors miss.
3. **Perform reviews and static analysis.** See
   `static-testing-reviews` — spec review before case writing.
4. **Apply appropriate test techniques and coverage.** Higher risk
   → BVA + decision tables + state transitions, not just smoke.
5. **Apply the appropriate test types.** Auth feature → add
   non-functional security cases, not just functional.
6. **Perform dynamic testing, including regression.** When the
   feature changes, regression-test adjacent areas (per §2.2.3).

## Risk register template (for Kensa scope-analysis output)

Slot this into the `scope-analysis` "Risk" section:

```markdown
## Risk register

| ID | Risk | Likelihood | Impact | Level | Mitigation |
|---|---|---|---|---|---|
| R1 | 2FA bypass via recovery code abuse | M | High | High | 3 cases for recovery-code single-use enforcement; cross-link security-testing |
| R2 | Account lockout interacts with 2FA failures unpredictably | M | High | High | 2 cases for "2FA failure + bad password" interaction; flag to user — spec ambiguous |
| R3 | TOTP window misconfigured (too narrow → false negatives) | L | M | M | 3-value BVA on time window (±30s) |
| R4 | UI clarity on the setup page | M | L | L | 1 acceptance case for happy-path UX; defer deeper UX to manual exploratory |
| R5 | (Project risk) Spec missing recovery-code reusability | M | M | M | Open question to user; assume single-use unless told otherwise |
```

Cite this register in the report-back so the user can see what was
mitigated and what wasn't.

## Risk-based prioritization (link to §5.1.5)

Once cases exist, use the risk register to order execution:

- Critical / High risk cases run first.
- Smoke-only on Low risk cases.
- If time runs out, document which risk-tier cases didn't run.

The lead can suggest this order to the user when handing off cases
to a human tester.

## Worked example — risk analysis for a payments feature

User: "Add a one-click checkout."

Test Lead's risk analysis:

**Identification (per §5.2.3):**

- Brainstorm + spec read: PII, payment fraud, double-charging,
  currency, refund, network failure mid-transaction, race
  conditions on inventory.
- Check `learned/patterns.md`: this team had 2 payment bugs in the
  past 6 months. Defect cluster signal (per §1.3 principle 4).

**Assessment (qualitative matrix):**

| Risk | L | I | Level |
|---|---|---|---|
| Double-charge on retry | M | Critical | **Critical** |
| Payment data leaked in logs | L | Critical | High |
| Currency mismatch (USD/EUR) | M | High | High |
| Network failure mid-transaction → ambiguous state | H | High | **Critical** |
| Inventory race (two users buy last item) | L | High | Medium |
| Refund flow correctness | M | High | High |

**Control (per §5.2.4):**

- Critical → many cases, EP + BVA on amounts, decision tables on
  state, state transitions on retry flow.
- High → 3-5 cases each.
- Medium → 1-2 cases + flag to user.
- Independence: Kensa is fine (high-independence).
- Apply reviews: spec must explicitly state retry semantics; flag
  if not.
- Non-functional: add cases tagged `[non-functional, security]` for
  PII handling.

**Output:** ~25 cases instead of "~10 cases for a checkout feature"
that a non-risk-based approach would estimate. Justification in the
plan: "Payments are critical-risk per §5.2; extra depth on retry
and currency."

## Worked example — risk acceptance

User: "We have 30 minutes to ship tests for the 'change profile
picture' feature."

Test Lead's reasoning:

- Identify: profile picture is low-risk (no PII beyond what's
  already shown; no payment; no auth changes).
- Risk matrix: Medium likelihood, Low impact = **Low**.
- Decision: **risk acceptance** for deep coverage. Smoke cases only:
  upload happy path, file-type rejection, size limit, image visible
  after upload.
- Report: "5 smoke cases covering happy path + 2 negatives. Deeper
  edge cases (corrupted images, EXIF metadata, racy uploads) not
  covered due to time — risk accepted."

This is per §5.2.4: risk acceptance is a valid control measure.
Document the residual risk.

## Worked example — risk transfer

User: "Add Stripe checkout integration."

Test Lead's reasoning:

- Identify: card-data security risk.
- Note: Stripe handles card data on their side; merchant uses
  Stripe.js / Checkout to avoid PCI scope.
- **Risk transfer:** card-data security is transferred to Stripe.
  Kensa doesn't test Stripe's PCI compliance.
- What's left for Kensa to test: the merchant-side integration
  (correct customer ID passed, webhook signature verification,
  error handling on Stripe failures).
- Report: "Card-data risk transferred to Stripe. Cases focus on
  integration boundaries: webhooks, error paths, idempotency."

Per §5.2.4 risk transfer is valid; document it explicitly.

## When to load this skill

- Test Lead during scope-analysis on any non-trivial feature — build the
  risk register before estimating case count.
- When the user asks "why so many cases for X and so few for Y?" —
  cite the risk register.
- When the user asks "what about Z?" — check if Z is in the risk
  register; if yes explain coverage; if no, was it identified and
  accepted/transferred?
- When time is constrained — use the risk register to choose what to
  test vs accept.
- When a qa-engineer-agent's brief flags "risk-heavy scope" — QA Engineer
  loads this skill to align their checklist with the Test Lead's risk
  assessment.

## Anti-patterns

- "We'll test everything equally" — implicit risk-blind approach.
  Violates §5.2 entirely.
- Risk register that's just risk names without likelihood × impact —
  no way to prioritize.
- Treating project risks and product risks as the same — they need
  different responses.
- Silent risk acceptance (deciding not to test something without
  telling the user). Always document accepted risks.
- Over-testing low-risk areas to look thorough. Cite §1.3 principle
  2 (exhaustive testing impossible) and reallocate.
- Ignoring `learned/patterns.md` defect history — that's free
  likelihood data per principle 4 (defects cluster).
