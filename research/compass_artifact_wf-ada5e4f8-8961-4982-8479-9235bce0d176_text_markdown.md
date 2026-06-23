# Designing kensa-qa: Automation Candidacy, `@KEN-<id>` Traceability, and Case↔Test Sync

## TL;DR
- **Automate the frequent, stable, high-risk, deterministic tests; keep manual the rare, volatile, judgment-heavy ones** — and make the cutoff explicit with the weighted rubric below (composite ≥70 = automate now, 40–69 = automate later, <40 or any hard veto = keep manual), grounded in the ROI break-even rule N = automation build cost ÷ (per-run manual cost − per-run automated cost).
- **Adopt a single canonical `@KEN-<id>` tag** that maps 1:1 to the `id` in each `.tms/*.md` file, expressed as a native tag/annotation in every framework, and ingest results by parsing that tag out of the test report — copying the proven Xray/Zephyr "test-case-key tag" pattern while avoiding TestRail's brittle name-matching and Allure's hash-based `testCaseId` drift.
- **Make the Markdown case the source of truth, with bi-directional drift detection in CI**: a `kensa` linter fails the build on orphaned tags (code references a deleted/unknown case) and reports uncovered cases (case with no `@KEN` tag), while a `test-first` generator scaffolds `.tms/` stubs from untagged tests so automation-first teams don't lose traceability.

## Key Findings

1. **There is no industry-standard published percentage-weighted automation rubric** — vendors publish factor lists and 1–5 scales but keep the actual weights in gated spreadsheets. The two fully-specified numeric models in the open literature are a 4-factor / 1–3-point / 4–12-total additive model and ZEISS's 100%-weighted utility-value analysis with a 0–4 fulfillment scale. This gives kensa-qa room to define an opinionated, defensible rubric.
2. **The classic ISTQB "suitability of tests for automation" criteria** (frequency of use, complexity to automate, tool-support compatibility, lifecycle stage, sustainability of the automated environment, controllability of the SUT) come from the **2016** CTAL-TAE syllabus — now formally retired (per istqb.org, "The sunset dates for the CT-TAE 2016 certification are as follows: English syllabus, exams, and accredited training June 12, 2025"). The 2024 v2.0 rewrite (authors Andrew Pollner (Chair), Péter Földházi, Patrick Quilter, Gergely Ágnecz, László Szikszai) moved strategy content to the separate CT-TAS v1.0 syllabus and reframes suitability as SUT/requirements analysis, explicitly calling out the "span and lifetime" of tests and "availability of test data and its quality."
3. **The dominant real-world traceability pattern is a project-scoped key embedded as a tag/annotation** — Xray (`@TEST_KEY-123` / `@TestCaseKey`), Zephyr Scale (`@TestCaseKey=ABC-T123`, `@TestCase(key=...)`), Qase (`qase.id(1)` / `@qase.id`), Allure (`@TmsLink`), and TestRail (`C1234` case IDs or an `automation_id`). kensa's `@KEN-<id>` convention is a direct generalization of this.
4. **Every shortlisted framework already supports the tag natively**: Playwright (`tag` option or `@`-token in title), Cypress (`@cypress/grep` tags), pytest (registered markers), JUnit5 (`@Tag` + custom composed annotations), and Cucumber/Gherkin (scenario tags with feature-level inheritance). No custom runner is required.
5. **The known failure modes are well-documented**: TestRail's own docs warn that changing a test's class/method name breaks the auto-generated `automation_id` and silently creates duplicate cases; Allure's TestOps Help Desk warns that "if the fullName changes, then md5 checksum changes, then testCaseId changes... the link between your test result and existing AllureID breaks and Allure TestOps creates a new test case. The previous test case with old AllureID gets abandoned" (the hash is `testCaseId = md5(fullName, sort(names(parameters)))`). kensa's explicit, human-authored `@KEN-<id>` avoids both because the link survives renames.

## Details

### 1. Automation candidacy: what to automate vs. keep manual

**The established criteria.** Mature teams converge on a recurring factor set: execution frequency, feature/UI stability, business value & risk, cost-to-automate, determinism/repeatability, data-setup complexity, expected test lifespan, and maintenance burden. Per Katalon's "Manual vs. Automation Decision Matrix" blog, teams should score each case "across five criteria — frequency, complexity, risk, ROI, and business priority. Use a consistent scale like 1 to 5," and Katalon's narrative singles out three as highest-impact: Risk/Business Criticality ("the why behind every automation choice"), Effort to Automate ("the invisible time sink"), and Maintenance Effort ("the silent ROI killer"). The retired ISTQB 2016 CTAL-TAE criteria add *controllability of the SUT* and *suitability for the lifecycle stage* — a test for a feature still in flux is a poor candidate.

**The governing economics — the ROI break-even rule.** Automation pays off only when it runs enough times to recoup its build cost. The closed-form break-even is:

> **N_break-even = automation development cost ÷ (per-run manual cost − per-run automated cost)**

Equivalently ROI = Savings ÷ Investment, where Savings = (manual run time − automated run time) × #tests × #runs and Investment = framework build + per-test coding + maintenance. A widely cited Slalom Build worked example reaches break-even at roughly 25 runs and ROI ~1.75 by the 50th run; if the same test only ever runs 10 times, ROI is ~0.45 and it never breaks even — manual would have been cheaper. Maintenance must be in the denominator: per QA Skills' "Test Automation ROI & Business Value: 2026 Framework," "A widely cited rule of thumb is that maintenance runs 15-30% of the build cost per year for a stable application, and far more for a fast-changing one" (corroborated by Quash, which notes industry estimates that "maintenance consumes 15–30% of the initial build cost annually"). The single most important lever: pushing a test *down* the pyramid (UI → service/integration) moves break-even sharply left.

**The supporting models.** Three authoritative models inform the rubric:
- **The Test Pyramid** (Mike Cohn, *Succeeding with Agile*, 2009; developed further by Martin Fowler's "The Practical Test Pyramid" post, authored by Ham Vocke of Thoughtworks and hosted on martinfowler.com). Vocke's summary of Cohn's two essential takeaways: "Write tests with different granularity / The more high-level you get the fewer tests you should have," adding "Having a low-level test is better than having a high-level test." This directly implies that a manual case is often best automated at a *lower* level than the UI.
- **Google's Small/Medium/Large taxonomy** (*Software Engineering at Google*): size is defined by *what a test may do*, not lines of code. Small = single process, no I/O/network/sleep; Medium = single machine, localhost only; Large = unrestricted. The prized qualities are speed and determinism — exactly the candidacy signals for automation. Google notes "the smaller the test, the more likely it is to be automated," and reserves exploratory, usability, and UAT for Large/manual.
- **The Agile Testing Quadrants** (Brian Marick; refined by Lisa Crispin & Janet Gregory): Q1 (tech-facing, support-team: unit/component) and Q2 (business-facing, support-team: functional/story tests) are automation-heavy; Q3 (business-facing, critique-product: exploratory, usability, UX) is human-centric; Q4 (tech-facing, critique-product: performance, security, load) is tool-assisted. The do-not-automate zone is squarely Q3.

#### Deliverable 1 — Automation-Candidacy Scoring Rubric

**Step A — Hard veto checklist (any one ⇒ keep manual, do not score).** This is the explicit do-NOT-automate list:
- Test requires human aesthetic/UX judgment (visual "does it look right", layout, copy tone).
- Test needs human-only interaction (CAPTCHA, biometric, physical device gesture).
- Exploratory / one-off / throwaway investigation.
- Feature is still in active flux (UI/contract changing sprint-to-sprint).
- Test will run only rarely (≈ below its ROI break-even N over its expected lifespan).
- Non-deterministic by nature and cannot be made repeatable (true randomness, un-stubable third party).

**Step B — Weighted score (only if no veto).** Score each factor 1–5, multiply by weight, sum to a 0–100 composite. Weights sum to 100 and front-load the economics (frequency, risk, stability, cost) per Katalon's "three columns that matter most" and the ROI rule:

| Factor | Weight | Score 1 (low) | Score 5 (high) |
|---|---|---|---|
| Execution frequency | 25 | Run yearly / ad hoc | Every commit / nightly regression |
| Business risk & criticality | 20 | Cosmetic, low impact | Revenue/safety/compliance-critical path |
| Feature & UI stability | 15 | Changing every sprint | Stable for many months |
| Determinism / repeatability | 15 | Flaky, timing-dependent | Fully deterministic, stubable |
| Cost-to-automate (inverse) | 10 | Days of effort, complex data | Hours, trivial setup |
| Expected test lifespan | 10 | Retired next release | Lives for years |
| Data-setup complexity (inverse) | 5 | Elaborate fixtures/state | Self-contained |

Composite = Σ(factor score × weight) ÷ 5, normalized to 0–100.

**Step C — Thresholds:**
- **≥ 70 → Automate now.** High-frequency, high-risk, stable, deterministic — clears break-even quickly.
- **40–69 → Automate later (backlog).** Worth automating but not urgent; revisit when frequency rises or the feature stabilizes. Keep as a manual case meanwhile.
- **< 40 → Keep manual.** Below the economic break-even for the foreseeable lifespan.

**Tie-break rule:** even a high composite should be pushed to the lowest pyramid level that still validates the intent (Cohn/Fowler — "having a low-level test is better than having a high-level test") before committing to a UI-level automated test; a service-level test changes the cost and stability scores favorably and should be re-scored at that level.

### 2. Traceability conventions in the wild (and their pitfalls)

| Tool | Link mechanism | Result ingestion | Brittleness |
|---|---|---|---|
| **TestRail** | `C1234` case ID in test name/refs, OR an `automation_id` (= classname+name) | `trcli parse_junit` parses JUnit XML; `--case-matcher name\|property\|auto`; specification-first (ID in test) vs code-first (auto-create) | TestRail's own docs warn: changing classname/test name breaks `automation_id` and **creates a duplicate case** rather than updating; name-matching is fragile |
| **Xray (Jira)** | Cucumber scenario tag `@TEST_KEY-123` / `@id:NN`; requirement tags above `Feature:` create "Tests" links; JUnit/TestNG import | Import JUnit/TestNG/Cucumber JSON via REST `/import/execution/*` or CI plugins | Requires exporting *Jira-tagged* feature files back to CI so result keys match; round-trip is heavyweight |
| **Zephyr Scale** | `@TestCaseKey=ABC-T123` Gherkin tag; `@TestCase(key="JQA-T1")` JUnit annotation | `automations/executions/junit?autoCreateTestCases=true` REST; JUnit listener emits keyed JSON | `autoCreateTestCases` silently mints new cases for unkeyed tests → orphan proliferation |
| **Qase** | `qase.id(1)` / `@qase.id(1)` / native annotation `{annotation:{type:'QaseID',description:'1'}}` | Per-framework reporters (playwright-qase-reporter, qase-pytest, etc.) post to TestOps API | Wrapper-in-title syntax deprecated; multiple competing syntaxes per framework cause drift |
| **Allure** | `@TmsLink("TMS-456")`, `@AllureId("123")`, `tms`/`testCaseId` labels; `allure.link.tms.pattern` builds URL | `allure-results` JSON → Allure/TestOps | Allure's docs warn the hash-based `testCaseId = md5(fullName, sort(names(parameters)))` **changes when the signature changes, abandoning the old case**; `@AllureId` is the explicit fix |
| **Cucumber/Gherkin** | Scenario- or feature-level `@`-tags; feature tags inherit to all scenarios | Cucumber JSON consumed by any TMS | Feature-level inheritance can over-apply a case ID to every scenario; copy-pasted tags drift |
| **JUnit5 / TestNG** | `@Tag("KEN-123")` or custom composed annotation; TestNG groups | JUnit XML / report properties | Tags are plain strings — typos silent unless enforced |
| **pytest** | Registered marker `@pytest.mark.ken("KEN-123")`; pytest-bdd reuses Gherkin tags as markers | JUnit XML / reporter plugin | Unregistered markers warn but don't fail unless `strict_markers`; ID inside marker arg needs custom collection hook |
| **Playwright** | `{tag:'@KEN-123'}` option or `@KEN-123` in title; `test.info().annotations`; available to reporters via `TestCase.tags` | Custom reporter or qase/allure reporter | Title tags duplicate into the HTML report label; newer object syntax preferred |
| **Cypress** | `@cypress/grep` / `cy-grep` tags `{tags:['@KEN-123']}` or in title | Custom reporter parsing test titles | No first-class metadata API; relies on plugin; tags in title only |

**The cross-cutting lesson:** every robust system uses a **stable, human-authored, project-scoped key** (Xray/Zephyr/Qase), and every brittle one relies on a **derived identifier** (TestRail's name-based `automation_id`, Allure's signature hash) that breaks on rename. kensa's `@KEN-<id>` must be the former.

### 3. Mapping granularity

Real suites are never 1:1. The convention must support:
- **1 case : N tests** — one manual case ("user can checkout") covered by several automated checks (happy path, declined card, inventory edge). All N tests carry the same `@KEN-<id>`; the case is "covered" if ≥1 linked test exists and "passing" only if all linked tests pass.
- **N cases : 1 test** — one automated test validating several cases. Allow multiple keys: `@KEN-12 @KEN-13`, Qase's `@qase.id([2,3])`, TestRail's comma-separated case IDs in one test (trcli explicitly supports updating multiple cases from one test).
- **Parameterized / data-driven** — one test definition, many rows maps to **one** case by default (Qase's reporter auto-parameterizes a single case rather than creating one per row); split into multiple `@KEN` keys only when rows represent genuinely distinct business cases.
- **Shared steps** — manual "shared steps" map to code helpers/page-objects/fixtures, which carry **no** `@KEN` tag (they aren't cases); only the test functions do. This mirrors Cucumber's step-definition reuse and keeps the case↔test mapping at the test level, not the helper level.

### 4. Sync / drift

**Ownership — who is the truth?** Two models:
- *Case-as-truth* (recommended default for kensa): `.tms/*.md` is authoritative; tests must point to a real case. Best for regulated/audited contexts and bi-directional traceability matrices.
- *Test-as-truth*: code is authoritative and cases are generated/auto-created (TestRail code-first, Zephyr `autoCreateTestCases`). Faster for automation-first teams but, as the vendor docs show, tends to spawn orphan and duplicate cases.

kensa resolves this by making the **Markdown case the truth** while providing a **test-first generator** so automation-first teams aren't penalized (see Deliverable 3).

**Detecting drift.** A requirements-traceability matrix exists precisely to expose **orphan tests** (no requirement) and **coverage gaps** (requirement with no test); bidirectional traceability is the recommended default. The measurable signals to track are coverage %, **orphan rate** (tests without cases), **gap rate** (cases without tests), and **update lag** (time between a case change and the test change). kensa operationalizes these as CI checks.

### 5. Greenfield / automation-first path

When automation is written first, traceability is preserved by **reverse-generation**: derive a case stub from the test's structure, name, and assertions. This pattern exists today — Zephyr/Qase/TestRail all *auto-create* cases from incoming results, and TMS tools like testomat.io import automated tests and convert them into (BDD) case definitions / living documentation. kensa's `kensa generate` does this deterministically into `.tms/` Markdown (Deliverable 3), assigning a fresh `id` and writing the tag back into the test, so the link is explicit rather than name-derived.

### 6. BDD as a bridge

Gherkin scenarios can be the single shared artifact: the scenario *is* the manual case (human-readable) and is executable. This collapses the manual/automated distinction cleanly **when** the audience is mixed (BA/QA/dev) and behavior is expressible in Given/When/Then. It works poorly for data-heavy, non-functional, or exploratory testing, and the indirection (feature file ↔ step definitions) is overhead when there is no business-stakeholder audience.

**Recommendation for kensa:** treat BDD as *optional*, not mandatory. The `@KEN-<id>` tag works identically whether the test is a Gherkin scenario tag or a code annotation, so kensa supports both without forcing teams onto Cucumber. Where a team already uses Gherkin, the scenario tag *is* the `@KEN-<id>` and the `.feature` body can be mirrored into the `.tms/*.md` body.

## Recommendations

#### Deliverable 2 — The `@KEN-<id>` tagging + bi-directional traceability design

**Frontmatter contract.** Each `.tms/<slug>.md` has YAML frontmatter:
```yaml
id: KEN-1042            # canonical, immutable, project-scoped
source_id: PROJ-87      # optional upstream requirement/story (Jira etc.)
title: User can checkout with a saved card
status: automated       # manual | automate-later | automated
automation:             # populated by CI, not by hand
  tags: [KEN-1042]
  last_run: 2026-06-21T02:14:00Z
  last_status: passed
```
The `id` is the join key. `source_id` ties the case *up* to a requirement; `@KEN-<id>` ties it *down* to code. This gives the full requirement → case → test → result chain a traceability matrix needs.

**The tag, per framework (all resolve to the literal string `KEN-1042`):**

- **Cucumber/Gherkin** — scenario-level tag (never feature-level, to avoid inheritance over-applying the ID):
  ```gherkin
  @KEN-1042
  Scenario: Checkout with saved card
  ```
- **Playwright** — object syntax (preferred over title tags to avoid HTML-report duplication):
  ```ts
  test('checkout with saved card', { tag: '@KEN-1042' }, async ({ page }) => { /* ... */ });
  ```
- **Cypress** (`@cypress/grep`):
  ```js
  it('checkout with saved card', { tags: ['@KEN-1042'] }, () => { /* ... */ });
  ```
- **pytest** — registered marker (registered in `pytest.ini` with `strict_markers` so typos fail):
  ```python
  @pytest.mark.ken("KEN-1042")
  def test_checkout_saved_card(): ...
  ```
- **JUnit5** — `@Tag` or a custom composed `@Ken` annotation:
  ```java
  @Test @Tag("KEN-1042") void checkoutSavedCard() { }
  ```
- **TestNG** — `@Test(groups = "KEN-1042")`.

**Ingestion — one parser, framework-agnostic.** Standardize on the JUnit XML report (or Cucumber JSON for BDD), which every framework above emits. A `kensa ingest` step:
1. Parses the report.
2. Extracts every `KEN-####` token from each test's tags/title/properties (regex `KEN-\d+`).
3. Maps results back to `.tms/` by `id`, writing `automation.last_run` / `last_status` into frontmatter (or a sidecar `.tms/.results.json` to keep cases diff-clean).
4. For a case with N linked tests, status = passed iff all pass; for a test with N keys, the result is recorded against each.

This deliberately copies the **Xray/Zephyr keyed-tag** model (stable, explicit) and **rejects** TestRail's name-based `automation_id` and Allure's signature-hash `testCaseId`, both of which their own docs say break on rename.

#### Deliverable 3 — Case↔test sync workflow

**Direction A — case-first (default):**
1. Author writes `.tms/checkout-saved-card.md` with `id: KEN-1042`.
2. Developer writes the automated test and adds `@KEN-1042`.
3. CI `kensa ingest` records per-`@KEN` pass/fail back to the case and flips `status: manual → automated` on first linked run.

**Direction B — test-first (automation-first / greenfield):**
1. Developer writes an untagged automated test.
2. `kensa generate` scans the report, finds tests with no `KEN-` tag, scaffolds a `.tms/*.md` stub per test — deriving `title` from the test name, populating a body skeleton from `describe`/`test.step`/assertion text — assigns the next free `id`, and **writes the `@KEN-<id>` tag back into the source file**. Traceability is now explicit, not name-derived.

**CI drift detection (`kensa lint`, runs every pipeline):**
- **Orphaned tag (hard fail):** code references `@KEN-9999` with no matching `.tms/` file → build fails. This is the check that catches deleted cases and copy-paste errors.
- **Uncovered case (warn/report):** a `.tms/` case with `status: automated` but no linked test in the latest report → reported in the coverage summary; a case with `status: manual` is expected to have none.
- **Stale/duplicate:** two cases sharing an `id`, or a tag pointing to a case whose `title` has materially diverged → flagged.
- **Metrics surfaced:** coverage %, orphan rate, gap rate, and update-lag — the four traceability KPIs.

**Staged rollout:**
1. *Phase 1 (week 1):* introduce frontmatter `id`/`source_id` and the `@KEN-<id>` convention; add `kensa lint` in **warn-only** mode.
2. *Phase 2:* turn orphaned-tag into a **hard CI failure**; wire `kensa ingest` to write last-run status.
3. *Phase 3:* run the candidacy rubric over the existing manual catalog; automate the ≥70 cases, backlog the 40–69, leave <40 manual; enable `kensa generate` for new automation-first work.

**Thresholds that change the plan:** if orphan rate climbs above a few percent, tighten generation discipline; if a manual case's frequency or risk score rises (e.g., it becomes part of nightly regression), re-score it — crossing 70 promotes it from "automate later" to "automate now."

## Caveats
- **No vendor publishes an authoritative percentage-weighted candidacy rubric**; the weights in Deliverable 1 are a synthesized, opinionated default derived from the named factor sets (Katalon's five criteria; the retired ISTQB 2016 syllabus) and the ROI break-even logic, not a single citable standard. Teams should calibrate weights to their context (e.g., regulated environments raise the risk weight).
- **The ISTQB "suitability" criteria are from the 2016 CTAL-TAE syllabus** (retired June 12, 2025), not the 2024 v2.0 rewrite, which reframes the topic as SUT/requirements analysis and split strategy content into the separate CT-TAS v1.0 syllabus. Cite accordingly.
- The Test Pyramid remains contested (Fowler's own caveats; the Cucumber "eviscerated pyramid" panel; testing-trophy/honeycomb variants); it is a heuristic, not a law. kensa's "push to the lowest level" tie-break rule reflects its sound core, not its disputed labels.
- ROI break-even figures (≈25 runs from the Slalom example; 15–30% annual maintenance) are illustrative practitioner numbers, not universal constants — they depend heavily on test level and flakiness.
- Auto-generation of cases from tests (Direction B) produces *skeletal* cases; their business intent still needs human review, exactly as the auto-create features in Zephyr/TestRail tend to spawn low-quality stubs if left unsupervised.