---
name: test-design-techniques
description: ISTQB-grounded test design techniques applicable to manual test cases — equivalence partitioning, boundary value analysis (2-value and 3-value), decision tables, state transitions (0-switch, 1-switch, round-trip), use case / scenario testing, checklist-based testing, error guessing. Use whenever designing what to cover in a test, especially when justifying coverage to QA stakeholders. Cite ISTQB section numbers to defend your choices ("per ISTQB CTFL 4.0 §4.2.3").
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 4 — Test Analysis and Design, §4.1 Test Techniques Overview, §4.2 Black-Box Test Techniques (§4.2.1 EP, §4.2.2 BVA, §4.2.3 decision tables, §4.2.4 state transitions), §4.4 Experience-Based Test Techniques (§4.4.1 error guessing, §4.4.3 checklist-based).
> Learning objectives: FL-4.1.1 (K2) distinguish black-box / white-box / experience-based; FL-4.2.1 (K3) use EP to derive test cases; FL-4.2.2 (K3) use BVA (2-value + 3-value) to derive test cases; FL-4.2.3 (K3) use decision tables; FL-4.2.4 (K3) use state transitions; FL-4.4.1 (K2) explain error guessing; FL-4.4.3 (K2) explain checklist-based testing.
> See also: CTAL-TA v4.0 §3.1–§3.4 for advanced extensions (1-switch / round-trip / scenario-based); §1.4.1 for where techniques fit in test analysis & design activities.

# Test design techniques

This skill is your toolbox for deciding **what** to test, grounded in
the two ISTQB syllabi that matter for manual test-case authoring: CTFL
v4.0.1 (Foundation Level, September 2024) and CTAL-TA v4.0 (Advanced
Test Analyst, May 2025).

Five things to know going in:

1. **CTFL 4.0 covers four black-box techniques in depth** — equivalence
   partitioning, boundary value analysis, decision tables, state
   transitions — plus three experience-based ones: error guessing,
   exploratory testing, checklist-based.
2. **Boundary Value Analysis has two distinct variants** the syllabus
   explicitly distinguishes — 2-value and 3-value. Mixing them is the
   #1 source of incorrect test cases at this level.
3. **Coverage is always measured the same way** — items exercised ÷
   items identified. Every technique has its own definition of "item".
4. **CTAL-TA v4.0 dropped use-case testing as a standalone technique**
   and replaced it with the broader scenario-based testing (§3.2.3).
   We keep the classical main/alternative/exception framing because
   it's the clearest treatment and still widely cited.
5. **Classification trees were deprecated as a standalone technique in
   CTAL-TA v4.0.** They survive only as an informal visualisation aid
   for pairwise / combinatorial testing. Skip them as a first-class
   technique.

Coverage formula across all techniques: `items_exercised ÷
items_identified × 100 %`. The summary table at the bottom of this
skill lists the per-technique "item" definition.

Cite techniques in your checklist as `per ISTQB CTFL 4.0 §X.Y.Z` —
that's what gives the QA Engineer (and the senior QA reading the cases) the
audit trail.

---

## Equivalence Partitioning (EP)

### Mechanics

Divide each input, output, or internal data element into groups —
**partitions** — where every value in a group is expected to be handled
identically. Pick **one representative value per partition**. The
underlying assumption: any defect detected by one value in a partition
would be detected by any other value in the same partition. Partitions
must be non-empty and non-overlapping.

Always identify both **valid partitions** (values the spec says should
be processed) and **invalid partitions** (values that should be
rejected).

### Worked example — age field on a sign-up form (must be 18–120)

- Invalid partition: age < 18 → representative value `15`
- Valid partition: 18 ≤ age ≤ 120 → representative value `42`
- Invalid partition: age > 120 → representative value `200`
- Invalid partition: non-integer / non-numeric → representative value `"abc"`

Four test cases cover all four partitions = 100 % EP coverage.

### When to use

Default first technique for almost any form field, dropdown,
configuration option, or output category. If the spec implies any
category-based behaviour, start here.

### When NOT to use

When values within an apparent partition actually have **different
processing** (e.g., positive vs. negative numbers may need separate
partitions even if "all numbers" looks like one group). Also weak when
interactions between parameters matter — combine with decision tables
or pairwise there.

### Coverage criteria

`partitions_covered ÷ partitions_identified × 100 %`. Each Choice
coverage (CTFL 4.0 §4.2.1) requires every partition from every
parameter exercised at least once; it does NOT require combinations.

### When this applies to your checklist

Use EP to justify why you have N test cases for an input. List the
partitions explicitly as a `[EP]` annotated group:

```markdown
### Age field [EP]
- [ ] Age = 42 (valid partition: 18..120)
- [ ] Age = 15 (invalid: below)
- [ ] Age = 200 (invalid: above)
- [ ] Age = "abc" (invalid: non-numeric)
```

### Source

ISTQB CTFL v4.0.1 §4.2.1 ("Equivalence Partitioning"); ISTQB Glossary
"equivalence partitioning"; CTAL-TA v4.0 §3.1 (data-based techniques).

---

## Boundary Value Analysis — 2-Value Variant

### Mechanics

Applies only to **ordered** partitions (numeric ranges, lengths,
counts, dates). For each boundary, write **two** test values: the
boundary value itself, and its closest neighbour in the adjacent
partition (offset by the smallest meaningful precision). The lighter
form of BVA — use when risk is low to moderate.

### Worked example — password length validator (8–64 characters)

Boundaries: 8 (lower) and 64 (upper). 2-value coverage items:

- `7` — should reject (just below lower boundary)
- `8` — should accept (lower boundary)
- `64` — should accept (upper boundary)
- `65` — should reject (just above upper boundary)

Four values = 100 % 2-value BVA coverage.

### When to use

Smoke tests, lower-risk numeric ranges, fields where 3-value BVA's
extra test would not be justified by the cost.

### When NOT to use

Safety-critical / financial / regulatory contexts where an off-by-one
defect would be catastrophic — use 3-value instead. Useless on
unordered enumerations (use EP).

### Coverage criteria

Per CTFL 4.0 §4.2.2: "for each boundary value there are two coverage
items: this boundary value and its closest neighbor belonging to the
adjacent partition." Coverage = `boundary_values_exercised ÷
total_boundary_values × 100 %`.

### When this applies to your checklist

Annotate the group `[2-value BVA]` and list both items per boundary:

```markdown
### Password length [2-value BVA]
- [ ] Length 7 → rejected
- [ ] Length 8 → accepted
- [ ] Length 64 → accepted
- [ ] Length 65 → rejected
```

### Source

ISTQB CTFL v4.0.1 §4.2.2 (cites Craig 2002, Myers 2011).

---

## Boundary Value Analysis — 3-Value Variant

### Mechanics

For each boundary value, write **three** test values: the boundary
itself, the value just inside the partition, and the value just
outside.

3-value catches a defect class 2-value misses — specifically the case
where `if (x ≤ 10)` is mistakenly implemented as `if (x = 10)`, which
2-value (testing 10 and 11) would miss but 3-value (testing 9, 10, 11)
catches.

### The most common 3-value BVA mistake — read this carefully

Per CTFL 4.0 §4.2.2: "In 3-value BVA, for each boundary value there
are three coverage items: this boundary value and **both its
neighbors**."

If the spec gives a range 8–64, there are two boundary values (8 and
64); 3-value BVA produces coverage items `{7, 8, 9}` for the lower
boundary and `{63, 64, 65}` for the upper — **8 coverage items, not 6**.

Many practitioners get this wrong by writing only `{7, 8, 64, 65}`,
which is 2-value BVA mislabeled. If you mark a group `[3-value BVA]`
in the checklist and the Test Lead counts only six items per simple range,
the Test Lead will send it back.

### Worked example — discount eligibility (order total $50–$500)

Two boundaries: $50 and $500. 3-value coverage items:

- Lower boundary: `$49`, `$50`, `$51` → eligibility flips correctly
- Upper boundary: `$499`, `$500`, `$501` → eligibility flips correctly

(Plus typically a "just outside the just-outside" probe — but the
literal CTFL 4.0 rule is the boundary plus both neighbours.)

### When to use

High-risk numeric logic: financial calculations, age/eligibility
gates, performance thresholds (concurrent-user limits), regulatory
limits.

### When NOT to use

Quick smoke runs and low-risk fields — the extra test cases per
boundary are not free.

### Coverage criteria

`(boundary_values_and_neighbours_exercised) ÷
(total_boundary_values_and_neighbours) × 100 %`.

### When this applies to your checklist

Annotate `[3-value BVA]` and list all neighbours explicitly per
boundary:

```markdown
### Discount eligibility [3-value BVA]
- [ ] Order $49 → no discount
- [ ] Order $50 → discount applies
- [ ] Order $51 → discount applies
- [ ] Order $499 → discount applies
- [ ] Order $500 → discount applies
- [ ] Order $501 → no discount
```

### Source

ISTQB CTFL v4.0.1 §4.2.2 (cites Koomen 2006, O'Regan 2019).

---

## Decision Table Testing

### Mechanics

Tabulate combinations of input conditions and the actions the system
should take. Conditions in the top rows, actions in the bottom rows;
each column is a **rule**.

Notation per CTFL 4.0 §4.2.3:
- `T` = true, `F` = false
- `–` = don't care (irrelevant to outcome)
- `N/A` = infeasible combination
- `X` = action occurs, blank = action does not occur

Start with a **full decision table** (2ⁿ rules for n binary
conditions), then **collapse** by merging rules that produce identical
actions and differ in only one condition (replace the differing
condition with `–`), and by deleting infeasible columns.

### Worked example — e-commerce checkout discount rules

Conditions:
- C1: Customer is logged in (T/F)
- C2: Cart total ≥ $100 (T/F)
- C3: Has valid coupon (T/F)

Actions:
- A1: Apply 10 % loyalty discount
- A2: Apply 15 % coupon discount
- A3: Show "log in for discounts" prompt

After collapse:

| Rule | C1 Logged in | C2 Total ≥ $100 | C3 Valid coupon | A1 10 % | A2 15 % | A3 Prompt |
|---|---|---|---|---|---|---|
| R1 | F | – | – |  |  | X |
| R2 | T | T | F | X |  |  |
| R3 | T | F | F |  |  |  |
| R4 | T | – | T |  | X |  |

Four test cases (one per rule) = 100 % decision-table coverage.

### When to use

Business-rule features: pricing, eligibility, permissions,
insurance/finance calculations — anything specified as "if X and Y but
not Z then do W". Decision tables make spec ambiguities visible —
a missing rule = a missing requirement.

### When NOT to use

Stateful / sequence-dependent behaviour (use state transitions).
Also poor when conditions explode beyond ~6–8 — switch to pairwise.

### Coverage criteria

Per CTFL 4.0 §4.2.3: "Coverage is measured as the number of exercised
columns, divided by the total number of feasible columns." Minimum =
one test case per feasible rule.

### When this applies to your checklist

Build the table, then write the checklist as one item per rule:

```markdown
### Discount rules [decision table — 4 rules]
- [ ] R1: not logged in → prompt to log in
- [ ] R2: logged in, $100+, no coupon → 10% loyalty discount
- [ ] R3: logged in, <$100, no coupon → no discount
- [ ] R4: logged in, valid coupon → 15% coupon discount
```

### Source

ISTQB CTFL v4.0.1 §4.2.3 ("Decision Table Testing"); CTAL-TA v4.0
§3.3.1 (advanced — minimisation algorithm; review criteria:
consistency, feasibility, completeness, correctness; warning about
overlapping rules).

---

## State Transition Testing

### Mechanics

Model the system as a finite set of **states** (e.g., "Logged out",
"Logged in", "Locked"), with **events** that cause **transitions**
between states, optionally subject to **guard conditions** (e.g., "if
failed attempts < 3"). Build a state transition diagram or table that
includes both valid and invalid (impossible per spec) transitions.

CTAL-TA v4.0 §3.2.2 adds an **N-switch hierarchy**:
- **0-switch** — a single transition
- **1-switch** — a pair of consecutive transitions
- **N-switch** — N+1 consecutive transitions
- **Round-trip coverage** — every loop from a state back to itself

### Worked example — login flow with account lockout

States: `LoggedOut → LoggingIn → LoggedIn`, with a `Locked` trap state
after 3 failed attempts.

Test cases for 100 % all-transitions coverage:

1. LoggedOut → (submit valid) → LoggedIn → (logout) → LoggedOut
2. LoggedOut → (submit invalid) → LoggedOut [fail count = 1]
3. From fail count = 2: (submit invalid) → Locked
4. From Locked: (submit valid) → still Locked (invalid transition attempt)
5. From Locked: (admin reset) → LoggedOut

For **1-switch coverage**, add sequences like "invalid then valid"
(fail-count = 1, then success) and "valid then logout then invalid"
to exercise transition pairs.

### When to use

Any system with explicit modes: login/session flows, order states
(cart → placed → shipped → delivered), media-player controls,
embedded controllers, wizard UIs, document/ticket workflows.

### When NOT to use

Stateless functions (use EP / decision tables). When states are
implicit and ill-defined, the modelling cost dominates.

### Coverage criteria

- **All states coverage** — every state visited. Weakest.
- **Valid transitions coverage (0-switch)** — every valid transition
  traversed. Most widely used in practice.
- **All transitions coverage** — both valid and invalid transitions
  exercised / attempted. Per CTFL 4.0: minimum requirement for mission
  and safety-critical software.
- **N-switch coverage (N ≥ 1)** — sequences of N+1 consecutive
  transitions. Use 1-switch for stateful business logic; 2+ only for
  very-high-risk systems.
- **Round-trip coverage** — every loop from a state back to itself.

### When this applies to your checklist

Use a state-machine block in the checklist:

```markdown
### Login state machine [state transitions — all valid + invalid attempts]
- [ ] LoggedOut → submit valid → LoggedIn
- [ ] LoggedOut → submit invalid → LoggedOut (fail count + 1)
- [ ] Fail count = 2, submit invalid → Locked
- [ ] Locked, submit valid → stays Locked (invalid transition attempted)
- [ ] Locked, admin reset → LoggedOut
```

### Source

ISTQB CTFL v4.0.1 §4.2.4 ("State Transition Testing"); ISTQB CTAL-TA
v4.0 §3.2.2 (cites Chow 1978 for N-switch, Antoniol et al. 2002 for
round-trip effectiveness).

---

## Use Case / Scenario-Based Testing

### Mechanics

Treat the test object as a participant in an end-to-end user
workflow. A use case has:

- **Main scenario** ("happy path") — the typical expected sequence
- **Alternative scenario(s)** — other sequences that still achieve
  the goal
- **Exception scenario(s)** — sequences that do not achieve the goal
  because of an unexpected event, invalid input, or abnormal use

Derive **at least one test case per scenario**. When the model
contains loops, apply **simple loop coverage** — zero iterations, one,
typical, maximum (CTAL-TA v4.0 §3.2.3).

### Worked example — e-commerce checkout use case

- Main: select items → add to cart → enter shipping → enter payment
  → confirm → order placed.
- Alternative A: guest checkout (skip account creation).
- Alternative B: apply coupon code (extra step before confirm).
- Exception 1: payment declined → show retry prompt → user re-enters
  card → succeeds.
- Exception 2: out-of-stock item discovered at confirmation → remove
  from cart → re-confirm.
- Exception 3: session timeout mid-checkout → save cart → require
  re-login.

Six test cases give one-per-scenario coverage.

### When to use

System and acceptance testing of user-facing workflows. Strong for
cross-functional reviews because non-engineers can read scenarios.
Also good source for performance test workloads.

### When NOT to use

Component-level testing of pure functions (use EP / decision tables).
When use cases are vague or aspirational rather than actual user
behaviour, they generate misleading tests.

### Coverage criteria

CTAL-TA v3.1.2 §3.2.7: minimum coverage = one test case for the main
scenario + one for each alternative + one for each exception. Higher
diagnostic coverage = one test case per alternative branch (no
amalgamation).

### When this applies to your checklist

Group by scenario role:

```markdown
### Checkout flow [scenario-based]
**Main**
- [ ] Logged-in user with card → order placed

**Alternative**
- [ ] Guest checkout
- [ ] Coupon code applied before confirm

**Exception**
- [ ] Card declined → retry succeeds
- [ ] Item goes out of stock at confirmation
- [ ] Session times out mid-checkout, cart preserved
```

### Source

ISTQB CTAL-TA v3.1.2 §3.2.7 ("Use Case Testing") — superseded but
still the clearest treatment of main/alternative/exception structure.
The current CTAL-TA v4.0 §3.2.3 generalises to "Scenario-Based
Testing" with activity diagrams, BPMN, etc. Cite v4.0 §3.2.3 for the
broader scenario framing; cite v3.1.2 §3.2.7 for the canonical
structure.

---

## Checklist-Based Testing

### Mechanics

Maintain a high-level list of items, rules, or quality criteria to
verify against the test object. The checklist is NOT a sequence of
detailed test steps — it is a **list of things to remember to check**,
derived from standards (e.g., WCAG accessibility), past experience,
defect taxonomies, UI conventions, or acceptance criteria from a user
story (CTFL 4.0 §4.4.3).

### Worked example — login-form checklist

- [ ] Required-field validation fires before submit
- [ ] Password field masks input by default
- [ ] "Show password" toggle reveals plaintext only on demand
- [ ] Caps-Lock indicator appears when active
- [ ] Tab order is logical (email → password → submit)
- [ ] Enter key submits the form
- [ ] Error messages are accessible to screen readers (`aria-live`)
- [ ] Failed-login response time is constant (timing-attack hygiene)
- [ ] Rate-limiting kicks in after N failed attempts
- [ ] Password reset link is visible and reachable by keyboard

A tester executes each item against the actual product and records
pass/fail per row.

### When to use

- Regression sweeps where the product changes faster than detailed
  cases can be maintained
- Smoke tests across many releases
- Cross-cutting concerns (accessibility, security hygiene, UX
  consistency) not tied to specific features
- When "high-level test cases" suffice and step-level repeatability
  is not required

### When NOT to use

Safety-critical / audited contexts where evidence of specific test
data and steps is mandatory — checklists lack the repeatability
detail. Also poor when the team lacks the experience to fill the gaps
the checklist leaves.

### Coverage criteria

CTFL 4.0 §4.4.3: experience-based techniques have **no formal
coverage criteria**; in practice, count `items_verified ÷
items_in_checklist` as a proxy. CTAL-TA v4.0 §3.4.2 provides a
method for building the checklist from defect libraries, taxonomies,
prior incidents, risk analysis, and personas.

### When this applies to your checklist

Use it as the primary technique for cross-cutting concerns sections.
The Kensa `negative-and-edge-cases` skill already walks four
dimensions in checklist style — that's checklist-based testing
applied to negative paths.

### Source

ISTQB CTFL v4.0.1 §4.4.3 ("Checklist-Based Testing"); ISTQB CTAL-TA
v4.0 §3.4.2 ("Checklists Supporting Experience-Based Test
Techniques"); ISTQB Glossary "checklist-based testing".

---

## Error Guessing (Structured ISTQB Framing)

### Mechanics — NOT "tester intuition"

ISTQB's framing (CTFL 4.0 §4.4.1) is explicit: **anticipate the
errors a developer or designer is likely to have made**, then design
tests to expose the resulting defects. The structured form uses a
**defect taxonomy** or **defect list** as input — a catalogue of
error types that have historically caused failures in this kind of
software — and walks the taxonomy item by item.

If you ever hear "I just have a feeling about this" framed as error
guessing — it isn't. Error guessing without a taxonomy is
unmeasurable, unrepeatable, and unauditable.

Typical inputs for the guessing:

- Past defects in the same product or product family
- Known weak spots (form validation, concurrency, integer overflow,
  null/empty inputs, encoding)
- Developer mistakes the tester has seen before
- Defect taxonomies from literature — Beizer 1990, Whittaker 2009,
  Kaner & Falk 1999

### Fault attack framing (Whittaker 2003)

The technique called **fault attack** is the disciplined application
of error guessing: take a category of likely fault, design an attack
to expose it, execute the attack. Canonical reference: James A.
Whittaker, *How to Break Software: A Practical Guide to Testing*,
Addison-Wesley, 2003.

A fault attack is NOT "poke around looking for bugs". It's a planned
campaign against a named class of defect with explicit pass/fail
criteria.

### Worked example — error guessing a payment input field

Taxonomy items applied:

- Numeric overflow → enter `$999,999,999,999.99`
- Negative amount → enter `-50.00`
- Zero amount → enter `0.00`
- Excess precision → enter `$10.005`
- Locale confusion → enter `10,50` (European decimal separator)
- Empty submission → submit blank
- Whitespace only → submit ` `
- Currency mismatch → submit `€50` to a USD field
- Unicode / RTL injection → submit `‮$100`
- SQL/script injection → submit `'; DROP TABLE orders; --`

Each taxonomy item generates one or more test cases; coverage =
`taxonomy_items_exercised ÷ taxonomy_items_total`.

### When to use

- Augmenting black-box-derived test suites to catch defects systematic
  techniques miss
- Smoke testing new releases for known historical weaknesses
- Pre-release destructive sweeps where the tester is encouraged to
  break things

### When NOT to use

- As a substitute for systematic techniques — error guessing
  *supplements*, never *replaces*, EP / BVA / decision tables
- In auditable / regulated contexts without a documented taxonomy,
  because results are not repeatable

### Coverage criteria

Per CTFL 4.0 §4.4.1: when a defect taxonomy is used, coverage =
`taxonomy_items_tested ÷ total_taxonomy_items`. Without a taxonomy,
coverage is unmeasurable.

### When this applies to your checklist

Annotate `[error guessing — taxonomy]` and list one item per fault
category. The Kensa `negative-and-edge-cases` skill already provides
a default taxonomy organised by input / action / state / environment.

### Source

ISTQB CTFL v4.0.1 §4.4.1 ("Error Guessing"); ISTQB CTAL-TA v3.1.2
§3.3.1 (cites Myers 2011 for the original framing); Whittaker, *How
to Break Software* (2003).

---

## Classification Tree — deprecated

CTAL-TA v4.0 removed the standalone Classification Tree section that
existed in v3.1.2 §3.2.5. The technique survives only as an informal
visualisation aid for combinatorial / pairwise test design. If your
feature is genuinely a configuration matrix (browser × locale ×
payment method × user role), draw a tree on paper or in Miro to see
the combinations, then pick **pairwise** coverage with a tool (PICT,
PairwiseTester) — that's the modern guidance. Don't cite
"classification tree coverage" in a checklist; cite "pairwise" or
"each-choice" instead.

---

## Coverage Criteria — Summary Table

All percentages are `items_exercised ÷ items_identified × 100 %`.

| Technique | Coverage item | 100 % means | Source |
|---|---|---|---|
| Equivalence partitioning | Each partition (valid + invalid) | Every partition exercised ≥ 1 time | CTFL 4.0 §4.2.1 |
| 2-value BVA | Boundary value + closest neighbour in adjacent partition | Every boundary value tested with its single closest off-partition neighbour | CTFL 4.0 §4.2.2 |
| 3-value BVA | Boundary value + both neighbours | Every boundary tested with both its neighbours (4 values per simple range) | CTFL 4.0 §4.2.2 |
| Decision table | Each feasible rule (column) | Every feasible rule covered by ≥ 1 test case | CTFL 4.0 §4.2.3 |
| State transition — all states | Each state | Every state visited | CTFL 4.0 §4.2.4 |
| State transition — valid transitions (0-switch) | Each valid transition | Every valid transition traversed | CTFL 4.0 §4.2.4 |
| State transition — all transitions | Every valid + invalid transition | Every valid traversed, every invalid attempted | CTFL 4.0 §4.2.4 |
| State transition — 1-switch | Each pair of consecutive valid transitions | Every transition pair exercised | CTAL-TA v4.0 §3.2.2 |
| State transition — round-trip | Each loop returning to its start state | Every loop exercised once | CTAL-TA v4.0 §3.2.2 |
| Use case / scenario | Each scenario (main / alt / exception) | 1 test case for main + 1 per alt + 1 per exception | CTAL-TA v3.1.2 §3.2.7 |
| Pairwise (combinatorial) | Each pair of parameter-value pairs | Every parameter-value pair combined with every other parameter's values | CTAL-TA v4.0 §3.1.2 |
| Checklist | Each checklist item | Every item verified against the test object | CTFL 4.0 §4.4.3 (informal) |
| Error guessing w/ taxonomy | Each taxonomy entry | Every taxonomy item tested ≥ once | CTFL 4.0 §4.4.1 |

---

## Caveats on versioning

- **CTFL v4.0.1 vs. v4.0** — v4.0.1 (15 Sept 2024) is a clerical
  errata. Technical content is identical. Cite as "ISTQB CTFL 4.0".
- **CTAL-TA v3.1.2 vs. v4.0** — v4.0 was released 2 May 2025; v3.1.2
  (Jan 2022) remains valid in non-English markets until 16 Nov 2026.
  Use-case testing as a named technique is gone in v4.0; cite v3.1.2
  §3.2.7 only when v4.0 §3.2.3 lacks the specific framing you need.
- **Glossary versioning** — the ISTQB Glossary updates continuously.
  When wording matters for citation, prefer the verbatim quote from
  the syllabus PDF rather than a glossary mirror.
