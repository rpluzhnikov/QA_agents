# Test-Automation Framework + Language Combos for `kensa-qa`: Ranked Support Roadmap (2025–2026)

## TL;DR
- **Build `automation-playwright-ts` first.** Playwright + TypeScript is the single best default for a team starting from scratch and the clear momentum leader: it overtook Cypress in npm downloads in mid-2024 (per Checkly's analysis) and by June 2026 the `@playwright/test` package pulls **38,641,569 weekly npm downloads** (the base `playwright` package: 57,637,599) versus Cypress's **7,320,054**, while topping the State of JS 2025 survey on satisfaction (**91% vs Cypress 72%**, the widest gap ever, per the survey released January 2026).
- **A v1 shortlist of ~5 first-class bundles covers most real teams:** Playwright/TypeScript and Playwright/Python (web E2E), pytest+requests/httpx (Python API), REST Assured/Java (enterprise JVM API), and Appium (mobile) — with Postman/Newman a near-tie for the API slot given it is "used by more than 40 million developers and 500,000 organizations, including 98% of the Fortune 500" (Postman State of the API Report, October 8, 2025).
- **Keep functional and performance axes separate.** Performance is adjacent; if `kensa-qa` supports one load tool first, make it **k6** (JavaScript, cloud-native, fastest-rising), with JMeter as the enterprise-legacy backlog item.

## Key Findings

1. **Playwright has decisively won the "new project" decision across every public adoption signal**, while Selenium retains the largest *installed* base (especially Java/Python enterprises) and Cypress holds a stable but no-longer-growing JavaScript niche. This is the central tension: vendor marketing pushes Playwright hard, but practitioner data (downloads, surveys, GitHub) genuinely corroborates it for greenfield work.
2. **Language follows niche.** TypeScript/JavaScript dominates web E2E; Python is the fastest-growing cross-cutting QA language and the most-used Selenium binding by telemetry; Java/C# dominate enterprise API and legacy suites; Swift/Kotlin own native mobile.
3. **API testing is bifurcated**: GUI-first collection tools (Postman, 40M+ developers) for exploration vs. code-first libraries (REST Assured in Java, pytest+requests/httpx in Python, supertest in Node) for CI pipelines. Playwright's built-in APIRequest is an increasingly attractive "one framework for UI + API" option.
4. **Mobile is fragmented and shifting**: Appium remains the cross-platform de facto standard, but Maestro is rising fast and native tools (Espresso, XCUITest) win on speed/stability for single-platform teams.
5. **BDD is a separate layer, not a runner** — and the .NET BDD landscape just had a forced migration: SpecFlow reached end-of-life on December 31, 2024 (Tricentis deleted the GitHub projects on January 1, 2025), and the community has moved to Reqnroll, which reported more than 5,000 projects using it by the beginning of 2025.
6. **AI-codegen friendliness now matters as a first-class selection criterion**, and Playwright leads it: huge volume of idiomatic public training data, stable role-based locators, official codegen, and the Playwright MCP server + Test Agents (Planner/Generator/Healer, 2025–2026).

## Details

### Axis 1 — Web E2E / UI

**Adoption signals (dated):**
- **Playwright** weekly npm downloads (npm trends, June 2026): `@playwright/test` 38,641,569; base `playwright` 57,637,599 — up from under 1M in 2021. TestDino (May 2026) cites "52 million weekly npm downloads." Surpassed Cypress in mid-2024 (Checkly). GitHub stars ~83,940 (Feb 2026) rising to ~89,800 (mid-2026, getpanto.ai), with v1.60.0 released May 11, 2026.
- **Cypress**: 7,320,054 weekly npm downloads (npm trends, June 2026, v15.16.0); ~49,600 GitHub stars. Downloads plateaued around 6.5–7.4M.
- **Selenium**: ~22.1% adoption among QA professionals (Vervali benchmark, 2026), down from ~39% in 2022; `selenium-webdriver` npm ~2M weekly; Python `selenium` ~52.8M downloads/month (pypistats, 2026); 31,000+ companies report usage (LinkedIn data, 2025). Python is the most-used Selenium binding per Selenium Manager (Plausible) telemetry, ahead of C# and Java — even though a 2025 academic survey of QA pros (Journal of Information and Software Technology, 88 respondents) found Java dominant (>70%) in established teams. This divergence is sampling bias: surveys over-sample mature Java QA teams; telemetry captures all bindings.
- **WebdriverIO**: ~2,810,343 weekly npm downloads, ~9,758 stars. **Puppeteer**: ~8,857,390 weekly downloads (mostly scraping, not E2E). **Nightwatch**: ~130,903 weekly downloads, ~11,950 stars. **TestCafe**: declining.
- **State of JS 2025** (released January 2026): "The prize for largest relative usage increase goes to Vitest and Playwright, which both gained 14 percentage points year-over-year." Playwright satisfaction 91% vs Cypress 72%.
- **State of JS 2024**: Playwright used at work by 3,674 respondents (just ahead of Cypress's 3,603), Puppeteer 1,865, Selenium 1,130; Playwright 94% retention.

**Use cases / maturity / learning curve / AI-friendliness:**
- **Playwright/TypeScript**: best all-rounder; native parallelism, auto-wait, cross-browser (Chromium/Firefox/WebKit), own test runner, trace viewer. Richest ecosystem and best AI-codegen story (codegen, MCP, Test Agents). Moderate learning curve, easiest greenfield setup. **Rising.**
- **Playwright/Python**: same engine, pytest-playwright plugin; pytest-playwright ~4.5M downloads/month (pypistats 2026). Slightly fewer runner features than the JS binding (no built-in config.ts parity, sharding). **Rising.** Best for Python-shop teams and data/AI-adjacent orgs.
- **Cypress/JS-TS**: best-in-class time-travel debugging and component testing for front-end SPA teams; limited to Chromium/Firefox, no multi-tab, paid parallelization (Cypress Cloud). **Stable/plateaued.**
- **Selenium (Java/Python/C#)**: unmatched language + legacy-browser breadth; the enterprise default in banking/insurance/government. More setup (drivers/grid), slower, more flake. Massive AI training corpus but brittle selectors. **Declining for new projects, stable installed base.**
- **WebdriverIO/JS-TS**: flexible WebDriver + DevTools, strong for teams wanting one tool for web + Appium mobile. **Stable.**

### Axis 2 — API / Integration

- **Postman/Newman**: "used by more than 40 million developers and 500,000 organizations, including 98% of the Fortune 500" (Postman State of the API Report, October 8, 2025); user base grew from ~25M to 40M+ across 2024–2025. GUI-first; Newman is the CLI runner for CI. Best for collaboration/exploration; weaker for complex code-level logic and JVM-grade matchers.
- **pytest + requests/httpx (Python)**: the pragmatic code-first default for Python shops; reuses pytest fixtures; pairs naturally with Playwright/Python.
- **REST Assured (Java)**: the established JVM API DSL; ~7,100 GitHub stars, listed as "Used By 3,233 artifacts" on mvnrepository (note: that figure is from a 2016 version page and is almost certainly understated today); v6.0.0 shipped December 2025. **Stable** in JVM enterprises.
- **Karate (Java/Gherkin)**: unifies API + mocks + perf + UI in a Gherkin DSL; ~8,900 GitHub stars; vendor claims ~400,000 monthly downloads and use by 76 of the Fortune 500 (self-reported, unverified). **Rising** within JVM/BDD-leaning teams.
- **supertest (Node)**: ~11,986,881 weekly npm downloads; the default for Express/Node API tests.
- **RestSharp (.NET)** and **Playwright APIRequest**: RestSharp for .NET HTTP testing; Playwright's APIRequest lets teams run API + browser tests in one framework/report — increasingly compelling.

### Axis 3 — Mobile

- **Appium**: cross-platform de facto standard; WebDriver-compatible, multi-language (Java/Python/JS/C#/Ruby), black-box, no app-code changes. Heavier setup, slower (WebDriver overhead; Espresso reportedly 3–5x faster, XCUITest up to 50% faster). **Stable, dominant.**
- **Espresso (Android)**: Google's native in-process framework; trusted by 50,000+ teams; Android-only, Kotlin/Java; auto-syncs with UI thread. **Stable.**
- **XCUITest (iOS)**: Apple's native framework; Swift/Objective-C, Xcode-integrated; iOS-only. **Stable.**
- **Maestro**: YAML-based, one-line install, low flakiness (<1%), ~10,000+ GitHub stars (early 2025); adopted by Microsoft, Meta (for React Native itself), DoorDash. **Rising fast.**
- **Detox**: React Native gray-box, JS; ~573,226 weekly npm downloads, ~11,925 stars; healthy maintenance but narrower scope and effectively plateaued vs Maestro.
- **Flutter integration_test**: the native Dart path for Flutter apps.

### Axis 4 — Performance (RANK SEPARATELY — adjacent, not functional)

- **k6 (JavaScript/Go engine)**: ~29.9k GitHub stars; CLI/test-as-code, Grafana ecosystem, low resource use, k6 Operator v1.0 GA September 2025. **Rising; modern default.**
- **JMeter (Java/XML+GUI)**: widest protocol coverage (HTTP, JDBC, LDAP, JMS, FTP), huge enterprise install base, but heavy (thread-per-user OS threads), XML hostile to code review. **Legacy-stable.**
- **Gatling (Scala/Java/Kotlin DSL)**: best-in-class HTML reports, async non-blocking engine, compile-time checks; steeper learning curve. **Stable niche.**
- **Locust (Python)**: 24,000+ GitHub stars; pure-Python user behavior, gevent concurrency; the obvious pick for Python teams. **Stable.**

### BDD layers (explicitly a separate axis layered on a runner)
BDD is *not* a runner — it is a Gherkin layer glued on top of one:
- **Cucumber** (Java/JS/Ruby; cucumber-jvm ~2,800 stars, "Used By 612 artifacts" on mvnrepository, latest 7.33.0 December 2025).
- **SpecFlow (.NET)**: end-of-life December 31, 2024; GitHub projects deleted January 1, 2025. Do **not** target for new work.
- **Reqnroll (.NET)**: the actively-maintained SpecFlow fork and successor; 1:1 migration; 5,000+ projects using it by early 2025.
- **Behave (Python)**: Gherkin, no native parallel execution (needs BehaveX).
- **pytest-bdd (Python)**: piggybacks on pytest; better for teams already using pytest fixtures/parallelism.

### Language ecosystem summary (where teams actually are)
- **TypeScript/JavaScript**: owns web E2E (Playwright, Cypress) and Node API (supertest); TypeScript now used by ~67–78% of JS developers (State of JS 2024).
- **Python**: fastest-growing general + QA language (Stack Overflow 2025: +7pp adoption YoY); strongest for pytest-based API, Playwright/Python, Selenium (most-used binding by telemetry), Locust.
- **Java**: enterprise/legacy backbone — Selenium, REST Assured, Karate, Cucumber-JVM, Gatling; JUnit dominates the JVM runner slot (junit accumulated ~150,000 Maven usages 2005–2024 vs TestNG's ~11,900, per arXiv:2502.02879, February 2025), though TestNG retains a strong Selenium-QA niche.
- **C#/.NET**: Microsoft-stack shops — Playwright/.NET, Selenium/C#, RestSharp, Reqnroll (post-SpecFlow).
- **Ruby**: shrinking in test automation; Selenium-Ruby and Capybara persist in legacy Rails shops only.

## Ranked Support Tiers

| Tier | Combo | Axis | Signal & trend |
|------|-------|------|----------------|
| **S (v1)** | Playwright + TypeScript | Web E2E | `@playwright/test` 38.6M weekly npm dl (June 2026); +14pp StateOfJS'25; 91% satisfaction — **rising** |
| **S (v1)** | Playwright + Python | Web E2E | pytest-playwright ~4.5M/mo PyPI — **rising** |
| **A (v1)** | pytest + requests/httpx | API | Python code-first default — **stable/rising** |
| **A (v1)** | REST Assured + Java | API | ~7.1k stars, JVM enterprise standard — **stable** |
| **A (v1)** | Appium (Java/Python/JS) | Mobile | cross-platform de facto standard — **stable** |
| **B (v2)** | Postman / Newman | API | 40M+ developers (Oct 2025), GUI-first — **stable** (CLI-only integration) |
| **B (v2)** | Cypress + JS/TS | Web E2E | 7.3M weekly dl (June 2026) — **plateaued** |
| **B (v2)** | Selenium + Java/Python/C# | Web E2E | ~22% share, huge legacy base — **declining (new), stable (legacy)** |
| **B (v2)** | k6 (JavaScript) | Performance | ~29.9k stars — **rising** (separate axis) |
| **B (v2)** | Maestro (YAML) | Mobile | ~10k stars, Meta/DoorDash — **rising** |
| **C (v2)** | Playwright APIRequest | API | one-framework UI+API — **rising** |
| **C (v2)** | supertest (Node) | API | ~11.9M weekly dl — **stable** (Node shops) |
| **C (v2)** | WebdriverIO + JS/TS | Web E2E | ~2.8M weekly dl — **stable** |
| **C (v2)** | Espresso / XCUITest | Mobile | native, fast — **stable** (single-platform) |
| **C (v2)** | Locust (Python) / Gatling (JVM) / JMeter | Performance | per-language perf — **stable/legacy** |
| **C (v2)** | Reqnroll (.NET) / Cucumber / pytest-bdd | BDD layer | layered on a runner — **stable** |
| **D (skip)** | SpecFlow (.NET) | BDD | EOL 31 Dec 2024 — **do not support** |
| **D (skip)** | Nightwatch, TestCafe, Puppeteer-as-E2E | Web E2E | low/declining E2E usage |

## v1 SHORTLIST (build these `automation-<combo>` bundles first)

1. **`automation-playwright-ts`** — *The default.* Highest adoption momentum (38.6M weekly npm downloads, June 2026), best AI-codegen ergonomics, cross-browser, batteries-included runner. Start here.
2. **`automation-playwright-python`** — Same engine for the large and fast-growing Python QA population; serves data/AI-adjacent teams who won't adopt TS.
3. **`automation-pytest-api`** (pytest + requests/httpx) — Python code-first API testing that composes with bundle #2; minimal new surface area.
4. **`automation-restassured-java`** — Covers the enterprise JVM API niche that Playwright/pytest do not; REST Assured is the established standard there.
5. **`automation-appium`** — The only credible cross-platform mobile entry; one bundle reaches Android + iOS across multiple languages.

*(Optional 6th if budget allows: `automation-postman-newman` — with 40M+ developers it has the broadest raw reach, but it integrates as a CLI/collection runner rather than a code framework, so it sits at the v1/v2 boundary.)*

## v2 BACKLOG (with one-line rationales)

- **`automation-cypress-ts`** — Still beloved by front-end SPA teams for component testing and time-travel debugging; large existing base worth supporting second.
- **`automation-selenium`** (Java/Python/C#) — Enormous legacy install base; support to capture migration/maintenance users, not greenfield.
- **`automation-postman-newman`** — If not promoted to v1; dominant API collaboration tool, CLI-runnable in CI.
- **`automation-playwright-apirequest`** — Lets Playwright shops unify UI + API in one report; low marginal effort once #1 exists.
- **`automation-k6`** — First-class *performance* bundle (kept separate from functional); modern cloud-native default.
- **`automation-maestro`** — Fastest-rising mobile option; YAML simplicity suits developer-led mobile testing.
- **`automation-webdriverio`** — For JS/TS teams wanting unified web + Appium mobile.
- **`automation-supertest`** — Node/Express API default.
- **`automation-espresso` / `automation-xcuitest`** — Native single-platform mobile speed/stability.
- **`automation-locust` / `automation-gatling` / `automation-jmeter`** — Per-ecosystem performance (Python / JVM / enterprise-legacy).
- **BDD adapters** — `automation-reqnroll` (.NET, the SpecFlow successor), `automation-cucumber`, `automation-pytest-bdd`: implement as a *layer* toggle on top of existing runner bundles, not standalone runners.

## Recommendations

**Stage 1 (ship now):** Build `automation-playwright-ts` as the flagship and recommend it as the universal default for any team with no existing automation. Pair it immediately with `automation-playwright-python` since they share an engine and documentation burden is low.

**Stage 2 (next):** Add `automation-pytest-api` and `automation-restassured-java` to cover the two dominant API niches (Python code-first; JVM enterprise), then `automation-appium` for mobile. This completes a v1 that spans web + API + mobile.

**Stage 3 (backlog):** Add Cypress and Selenium bundles to capture migration/legacy users, a dedicated `automation-k6` performance bundle, and `automation-maestro` for modern mobile. Implement BDD (Reqnroll/Cucumber/pytest-bdd) as a layered toggle.

**Decision thresholds that would change this ranking:**
- If your telemetry shows >30% of `kensa-qa` users are on .NET, promote `automation-playwright-dotnet` and `automation-reqnroll` from C-tier into v1.
- If mobile-first teams exceed web teams in your user base, promote Maestro alongside Appium in v1.
- If Cypress weekly npm downloads recover above ~10M or Selenium new-project share rises back above ~30%, re-tier them upward.
- If Postman/Newman shows up in >40% of user CI configs, promote it firmly into v1.
- Re-evaluate the whole web axis if Playwright's State of JS satisfaction drops below ~80% or its download lead over Cypress narrows to under 3x (it is currently ~5x on `@playwright/test`).

## Caveats
- **Vendor vs practitioner data:** Many cited percentages (e.g., "45.1% Playwright adoption," "22.1% Selenium") come from testing-vendor blogs (Vervali, ContextQA, TestDino) that sell competing AI-testing products; treat exact figures as directional. The cleaner signals are npm/PyPI download counts and the independent State of JS survey.
- **npm/GitHub structurally undercount Selenium and JVM tools**, whose users are Java/Python/C# developers who don't install via npm or star JS-ecosystem repos. Selenium's true footprint is larger than its npm/stars suggest; fork counts and Maven usage are better JVM proxies.
- **State of JS surveys only sample JavaScript developers**, so they overstate JS-native tools (Playwright, Cypress) and understate Selenium/Appium's polyglot reality.
- **Some figures are dated or self-reported:** REST Assured's "3,233 artifacts" is a 2016 mvnrepository snapshot; Karate's "400,000 monthly downloads / 76 of Fortune 500" are unverified vendor marketing claims; Maestro's adopter list (Microsoft/Meta/DoorDash) is from Maestro's own blog.
- **Forward-looking claims flagged:** statements such as Playwright "surpassing Selenium in overall market share by late 2027" are predictions, not facts.
- **AI-codegen is moving fast:** the Playwright MCP / Test Agents ecosystem (Planner/Generator/Healer) is new (2025–2026) and evolving; productivity figures (e.g., "3–5x faster authoring," Sauce Labs State of Test Automation 2026) come from vendor/practitioner reports, not controlled studies, and the MCP spec itself is still changing.