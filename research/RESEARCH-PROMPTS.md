# kensa-qa — research prompts

Briefs for the modernization research (manual → automation + manual enablement).
Each block below is a self-contained prompt — paste it into the deep-research skill
(`/deep-research`) or any research agent. Drop each result next to this file as
`R1-landscape.md`, `R2-<combo>.md`, `R3-strategy.md`, etc.

**Shared context** (prepend mentally to every brief — the research agent should
assume it):

> `kensa-qa` is a QA plugin for AI coding agents (Claude Code + OpenAI Codex). Today
> it is a **manual** QA team: it authors human-executed test cases as markdown in a
> `.tms/` repo driven by the `kensa` CLI, grounded in ISTQB CTFL v4.0.1. We are adding
> **test automation** capability. The plugin ships **agents** (orchestrators/workers),
> **skills** (on-demand knowledge docs, ~one concept each), and **slash commands**
> (workflows). Automation will have two equal entry modes: *downstream* (derive a
> `@KEN-<id>`-tagged automated test from an existing `.tms/` case, closing Kensa's
> traceability loop) and *greenfield* (write tests from a feature/spec directly,
> optionally back-filling `.tms/` case stubs). Agent model: one `test-automation-lead`
> (architecture/strategy) + one `automation-engineer` (writes code; framework/language
> variance lives in **skills**) + one `automation-devops` (CI/infra). Each research
> result must end with a **"How this maps to the plugin"** section listing concrete
> skills / agent-knowledge / commands / bundles it should produce.

**Recency:** prioritize 2025–2026 sources. Note version numbers. Flag anything in flux.

**Dependency:** R1 gates R2 (R2 is instantiated per combo R1 selects). R3–R6 are
independent and can run in parallel with R1.

---

## R1 — Automation framework + language landscape (2026)

**Objective:** decide which framework+language combos `kensa-qa` should support as
first-class `automation-<combo>` bundles, ranked by real-world adoption, with a v1
shortlist and a v2 backlog.

**Core question:** Which test-automation framework + language combinations are most
widely used in industry right now, and which deserve dedicated support first?

**Cover, with evidence (surveys, npm/PyPI/Maven downloads, GitHub activity, job
postings, State-of-JS / Stack Overflow / testing-tool surveys — cite numbers and
dates):**
- **Web E2E/UI:** Playwright, Cypress, Selenium, WebdriverIO, Puppeteer, TestCafe, Nightwatch — across TS/JS, Python, Java, C#, Ruby.
- **API/integration:** Postman/Newman, REST Assured (Java), Karate, pytest+requests/httpx, supertest, RestSharp, Playwright APIRequest.
- **Mobile:** Appium, Espresso, XCUITest, Detox, Maestro, Flutter integration_test.
- **BDD layers:** Cucumber/SpecFlow/Reqnroll/Behave/pytest-bdd — note when BDD is a separate axis vs. baked into a runner.
- **Performance (adjacent, flag separately):** k6, Gatling, JMeter, Locust.
- **Language ecosystems:** which languages dominate which testing niches, and where teams actually are (not where vendors push).

**For each strong candidate report:** adoption signal + trend (rising/stable/declining),
typical use case, ecosystem maturity, learning curve, AI-codegen friendliness (how well
an LLM can author tests for it).

**Deliverable:** a ranked table of combos → **v1 shortlist (≈4–6)** + **v2 backlog**,
each with a one-line rationale. Separate the web / API / mobile / perf axes. Call out
the single best "default" combo for a team with no existing automation.

---

## R2 — Best practices per combo  *(run once per combo R1 selects — templated)*

**Objective:** produce skill-ready best-practice knowledge for a specific
framework+language combo so `automation-engineer` writes idiomatic, low-flake,
maintainable tests for it.

**Instantiate this brief for combo:** `<FRAMEWORK + LANGUAGE>` (e.g. "Playwright +
TypeScript"). Run R2 separately per shortlisted combo.

**Cover (current idiomatic practice, with code patterns and canonical references):**
- Recommended **project structure** and config; how to scaffold from zero.
- **Design patterns:** Page Object Model vs Screenplay vs fixture-based — what this
  ecosystem actually favors in 2025–2026, with tradeoffs.
- **Locator/selector strategy** (resilient selectors, test ids, role-based queries).
- **Waiting / synchronization** — auto-wait behavior and the anti-flake idioms; what
  causes flakiness in *this* framework specifically and how to avoid it.
- **Test data** setup/teardown, fixtures, factories, isolation between tests.
- **Parallelization / sharding** model and its gotchas.
- **Reporting / traces / artifacts** (built-in + common add-ons).
- **Retries**, soft assertions, and when each is appropriate.
- **CI integration** specifics unique to this combo (defer general CI to R4).
- **Accessibility / visual** hooks if idiomatic (axe, screenshot diffing).
- **Top pitfalls** and a short list of authoritative references / exemplar repos.

**Deliverable:** a single best-practices document structured as a plugin **skill**
(concept → rules → code snippets → pitfalls), plus a minimal canonical example test
showing the recommended pattern end-to-end.

---

## R3 — Test automation strategy & architecture

**Objective:** give the `test-automation-lead` agent the decision frameworks it needs
to architect a test suite and decide *what* to automate at *which* layer.

**Core question:** How should a modern QA lead design and govern an automated test
suite for maintainability, low flakiness, and ROI?

**Cover:**
- **Test distribution models:** pyramid vs testing trophy vs honeycomb vs ice-cream-cone
  (anti-pattern) — when each applies; how to decide layer boundaries (unit/integration/
  E2E/contract).
- **Contract testing** (Pact, consumer-driven) — when it replaces heavy E2E.
- **Test data management** strategies at scale (factories, seeding, synthetic data,
  data isolation, prod-like data + privacy).
- **Environment strategy:** shared vs ephemeral/on-demand environments, service
  virtualization / mocking boundaries.
- **Maintainability:** abstraction layers, DRY vs DAMP in tests, dealing with churn,
  test-code review standards.
- **Flakiness** — systemic root causes and organizational mitigation (not per-framework;
  that's R2). Quarantine policy, flake budgets.
- **Test selection / impact analysis** (run-what-changed), risk-based automation depth.
- **Metrics that matter** vs vanity metrics: coverage's real meaning, flake rate,
  mean-time-to-detect/repair, escape rate.

**Deliverable:** a set of **decision frameworks / rubrics** the lead applies (e.g. "pick
the layer," "automate-or-not," "stabilize-or-delete"), each compact enough to become
agent knowledge or a skill.

---

## R4 — CI/CD & automation infrastructure

**Objective:** equip the `automation-devops` agent to wire automated tests into CI/CD
across stacks and runners.

**Core question:** What are the current best practices for running automated test
suites in CI/CD — fast, parallel, stable, and observable?

**Cover (with concrete config patterns where useful):**
- **Runners:** GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps — common
  patterns and differences for test workloads.
- **Parallelization / sharding** at the CI layer; matrix builds; balancing.
- **Containerization:** Docker images for browsers/drivers, Selenium Grid, Testcontainers,
  Playwright/Cypress official containers; self-hosted vs cloud device farms
  (BrowserStack / Sauce Labs / LambdaTest) — tradeoffs and when each.
- **Artifacts & reporting:** traces, videos, screenshots, JUnit XML; report tooling
  (Allure, ReportPortal, Currents, Allure TestOps, native HTML); dashboards/observability.
- **Flaky handling in CI:** auto-retry, quarantine lanes, flake detection services.
- **Gating policy:** required checks, merge gates, smoke-vs-full split, scheduled/nightly
  full runs, sharded PR runs.
- **Hygiene:** caching deps/browsers, secrets handling, run-time budgets, cost control.

**Deliverable:** CI patterns + a **decision guide** (which runner/parallelism/reporting
choice for which team size & stack), plus reusable config snippets per major runner.

---

## R5 — Manual ↔ automation bridge & traceability

**Objective:** define `kensa-qa`'s candidacy rubric and the `@KEN-<id>` tagging /
traceability convention that links `.tms/` cases to automated tests — informed by how
the industry already does this.

**Core question:** How do mature teams decide what to automate and keep manual test
cases and automated tests traceable and in sync?

**Cover:**
- **Automation candidacy:** criteria for what to automate vs keep manual (frequency,
  stability, value, risk, cost-to-automate, determinism) and explicit
  **do-NOT-automate** signals. Provide a scoring rubric.
- **Traceability conventions in the wild:** how TestRail / Xray / Zephyr / qase link
  automated tests to cases; annotation patterns (`@TmsLink`, Allure `tms`/`testCaseId`,
  Cucumber tags, JUnit metadata). What works, what's brittle.
- **Mapping granularity:** 1 case : N tests, parameterized cases, shared steps ↔ helpers.
- **Sync / drift:** keeping cases and code aligned as either changes; who owns the truth;
  CI feeding results back to the case (pass/fail per `@KEN-<id>`).
- **Greenfield path:** generating `.tms/` case stubs *from* tests so traceability isn't
  lost when automation comes first.
- **BDD as a bridge:** Gherkin scenarios as the shared artifact between manual intent and
  executable test — pros/cons vs separate case + tagged test.

**Deliverable:** (1) an automation-candidacy scoring rubric; (2) a concrete design for
the `@KEN-<id>` tagging + bi-directional traceability convention across the shortlisted
frameworks; (3) the case↔test sync workflow (both directions).

---

## R6 — Manual tester enablement beyond ISTQB CTFL

**Objective:** find high-value capabilities for *manual* testers that go beyond what the
plugin's CTFL-grounded skills already cover, to package as new manual bundles.

**Core question:** Beyond ISTQB Foundation, what knowledge and tooling most improves a
manual/exploratory tester's effectiveness, and which of it can a plugin operationalize?

**Cover:**
- **Exploratory testing & SBTM:** session-based test management — charters, session
  sheets, time-boxing, debriefs; how to structure and review exploratory work.
- **Heuristics & oracles:** SFDIPOT, FCC CUTS VIDS, touring heuristics, consistency
  oracles; RST/BBST schools — what's worth borrowing.
- **Test data management** for manual testing (realistic data, edge data, privacy).
- **Accessibility testing:** WCAG-based manual checks, screen-reader passes, tooling
  (axe, WAVE, Lighthouse) the tester can drive.
- **Cross-browser / device matrices:** how to choose a sane matrix; data-driven device
  selection.
- **Bug advocacy & report quality:** what makes a report get fixed; severity vs priority;
  reproduction quality.
- **Combinatorial / pairwise testing:** tools (PICT, Hexawise, AllPairs) and when they
  beat manual case explosion.
- **Worth-borrowing from CTAL/Advanced** topics for a manual context.

**Deliverable:** a prioritized list of candidate **skills / commands** (each with the
concept it teaches and the artifact it would produce), flagged by how well it fits an
AI-agent + `.tms/` workflow.
