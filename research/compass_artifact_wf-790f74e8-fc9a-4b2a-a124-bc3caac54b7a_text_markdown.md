# Beyond ISTQB Foundation: High-Value Manual/Exploratory Testing Capabilities to Operationalize as `.tms/` Skills & Commands

## TL;DR
- The highest-leverage net-new additions are the ones that turn a *named, structured practitioner method* into a deterministic markdown artifact: an **exploratory charter** ("Explore X with Y to discover Z"), an **SBTM session sheet** (TBS metrics + PROOF debrief), a **pairwise/PICT matrix**, a **RIMGEN bug report**, a **WCAG 2.2 manual accessibility checklist**, and a **data-driven device/browser matrix** — each maps cleanly to a committable file under `.tms/` and each sits squarely in one of your known thin zones.
- Rank by `.tms/`-fit: **pairwise (`/pairwise`)**, **bug-report RIMGEN (`/bug`)**, **accessibility checklist (`/a11y`)**, **device matrix (`/matrix`)**, **exploratory charter (`/charter`)** and **SBTM session sheet (`/session`)** are the strongest because their outputs are tabular/checklist artifacts with little ambiguity; PICT can even be shelled out via `kensa-cli`.
- The most defensible *differentiation* vs. TestRail/Xray/Zephyr/Qase is that these are git-committable, reviewable-in-PR, plain-markdown artifacts authored by an agent that pulls live specs — hosted TMS competitors treat charters, oracles, pairwise models and a11y checklists as at best loose attachments, not first-class versioned design artifacts.

## Key Findings
1. **Exploratory testing & SBTM are the single biggest gap** relative to CTFL v4.0, which mentions exploratory and checklist-based testing only as experience-based techniques. The practitioner canon (Satisfice SBTM, Hendrickson's *Explore It!*, RST) supplies ready-made artifact structures — charters, session sheets, debriefs — that are essentially begging to be markdown templates.
2. **Heuristics/oracles (SFDIPOT, FEW HICCUPPS, FCC CUTS VIDS) are "thinking tools" that become artifacts** when rendered as a product-coverage outline or an oracle checklist. They deepen test-design and negative-testing skills rather than replace them.
3. **Pairwise is mentioned but not operationalized** in your current set — and it is the most mechanizable of all: a parameter model in, a minimized matrix out. PICT is free, CLI-driven, supports constraints/seeding/weights, and can be invoked by `kensa-cli`. Its value rests on the NIST "Interaction Rule": in the NIST/NASA study, 67% of failures were triggered by a single parameter value, 93% by 2-way combinations, and 98% by 3-way combinations, reaching 100% detection only at 4-to-6-way (NIST SP 800-142, *Practical Combinatorial Testing*); a medical-device study found 66% triggered by a single variable value and 97% by one or two variables interacting.
4. **Accessibility and device matrices are real thin zones** that are highly artifact-friendly: WCAG 2.2 AA gives an authoritative checklist spine (POUR), and device/browser selection has a defensible data-driven method (analytics + market share + risk tiers).
5. **Bug advocacy depth (RIMGEN) is the natural extension of defect-management** and is unusually high-value because better reports directly raise fix rates. As Cem Kaner put it in *Testing Computer Software*: "The best tester is not the one who finds the most bugs or who embarrasses the most developers. The best tester is the one who gets the most bugs fixed."
6. **Worth borrowing from CTAL Advanced Test Analyst:** classification trees, cause-effect graphing, defect taxonomies, and ISO 25010 quality characteristics for non-functional manual testing — all of which can be operationalized as design or checklist artifacts.

## Details — The Source Basis

### Exploratory testing & SBTM
Session-Based Test Management was created in 2000 by Jonathan and James Bach and first presented by Jonathan Bach at STAR West 2000 ("How to Measure Ad Hoc Testing"); the canonical reference is his STQE magazine article (sbtm.pdf). The **session sheet** has a fixed structure, verbatim from the article's example sheet: CHARTER, #AREAS, START, TESTER, TASK BREAKDOWN (#DURATION; #TEST DESIGN AND EXECUTION; #BUG INVESTIGATION AND REPORTING; #SESSION SETUP; #CHARTER VS. OPPORTUNITY), DATA FILES, TEST NOTES, BUGS, ISSUES. Sessions are ~90 minutes ("normal"), ~45 min ("short"), ~120 min ("long"); a tester does no more than ~3 a day. The **TBS metrics** (Test/Bug/Setup) capture where on-charter time went: "Test design and execution means scanning the product and looking for problems"; "Bug investigation and reporting is what happens once the tester stumbles into behavior that looks like it might be a problem"; "Session setup is anything else testers do that makes the first two tasks possible." The **PROOF** debrief structure (Past, Results, Obstacles, Outlook, Feelings) is Jonathan Bach's. Satisfice also publishes an "SBTM Session Report Checklist."

Elisabeth Hendrickson's *Explore It!* gives the **charter template**: "Explore (target) With (resources) To discover (information)," plus the Test Heuristics Cheat Sheet (with James Lyndsay and Dale Emery) of variation heuristics (Zero/One/Many, Some/None/All, Beginning/Middle/End, CRUD, Goldilocks, etc.).

### Heuristics & oracles
James Bach's **Heuristic Test Strategy Model (HTSM)**, currently v6.x (v6.0 dated 2/8/2024; satisfice.com lists v6.3 with minor state-based/boundary edits), contains the **SFDIPOT** ("San Francisco Depot") Product Elements guidewords (Structure, Function, Data, Interfaces, Platform, Operations, Time) and the Quality Criteria categories (Capability, Reliability, Usability, Charisma, Security, Scalability, Compatibility, Performance, Installability, Development). SFDPO was originally James Bach's; Michael Bolton added "Time" (and later "Interfaces"). **FEW HICCUPPS** (Familiarity, Explainability, World, History, Image, Comparable products, Claims, User expectations, Product, Purpose, Standards, Statutes) are Bolton/Bach's consistency oracles, rooted in Kaner/Bach/Pettichord's *Lessons Learned in Software Testing*. **FCC CUTS VIDS** is Michael Kelly's touring mnemonic (Feature, Complexity, Claims, Configuration, User, Testability, Scenario, Variability, Interoperability, Data, Structure tours), built on James Bach's touring heuristic. These are required/recommended readings in BBST Test Design.

### Test data management
Practitioner and vendor guidance converges on: synthetic data for privacy-regulated contexts (GDPR/HIPAA/CCPA) and for rare/edge cases that don't appear in production; masking/anonymization of production copies; subsetting; and deliberate edge/boundary data (very long names, Unicode, malformed emails, boundary numerics). A tester can drive all of this without a runner by *specifying* the data sets and generation rules.

### Accessibility (manual)
WCAG 2.2 (W3C Recommendation, Oct 5 2023; updated Dec 2024) is the authoritative standard, structured by the **POUR** principles (Perceivable, Operable, Understandable, Robust), with conformance levels A/AA/AAA; AA is the legal baseline (ADA, Section 508, EN 301 549). WCAG 2.2 added nine success criteria — including 2.4.11 Focus Not Obscured (Minimum), 2.5.7 Dragging Movements, 2.5.8 Target Size (Minimum), 3.2.6 Consistent Help, 3.3.7 Redundant Entry, and 3.3.8 Accessible Authentication (Minimum) — and obsoleted/removed 4.1.1 Parsing. The WebAIM WCAG 2 Checklist is the canonical condensed checklist.

Automated tools (axe DevTools, WAVE, Lighthouse, Accessibility Insights — all built on axe-core) have a hard coverage ceiling. Deque's *Automated Accessibility Coverage Report* found axe-core completely covers 57.38% of accessibility issues by volume ("on average, 57 percent of accessibility issues were completely covered by this automated testing" — Dylan Barrell, CTO, Deque), drawn from 2,000+ audits across 13,000+ pages and ~300,000 issues; the older, more conservative ~30–40% figure is based on counting WCAG success criteria rather than issue volume. Either way, the remainder requires manual keyboard, screen-reader (NVDA/JAWS/VoiceOver), and reflow/zoom passes — Focus Order and Focus Visible are not automatable. Deque has stated automated WCAG 2.2 coverage is intentionally narrow: target-size (2.5.8) is likely the only new WCAG 2.2 rule axe-core will add, because automating the rest "produces too many false positives"; Focus Appearance and Focus Not Obscured live in axe Pro guided tests, not the engine.

The scale of the problem is rising, which strengthens the case for prioritizing this skill: the WebAIM Million 2026 report (data from February 2026, published late March 2026) found 95.9% of the top one million home pages had detected WCAG 2 failures (up from 94.8% in 2025), totaling 56,114,377 distinct accessibility errors — an average of 56.1 errors per page, a 10.1% one-year rise that reverses six years of improvement and is attributed to a 22.5% jump in page complexity.

### Cross-browser / device matrices
The defensible method: start analytics/traffic-weighted (your own GA/Firebase/Mixpanel data), layer market-share data (StatCounter, Statista, DeviceAtlas) for coverage you can't see in your own traffic, then adjust by risk (crash data, regulated flows). Build tiered matrices (primary/secondary/long-tail). BrowserStack and others publish guidance; a common rule of thumb is to prioritize any browser-OS combination driving >5% of key business metrics.

### Bug advocacy & report quality
Cem Kaner's BBST Bug Advocacy frames a bug report as a *persuasive document* whose goal is to get the right bugs fixed. The **RIMGEN/RIMGEA** heuristic: Replicate, Isolate (minimal repro), Maximize (follow-up testing for a harsher failure), Generalize (de-corner the corner case), Externalize (who is affected, impact), and Neutral tone / say it clearly. Severity vs. priority distinction and the defect lifecycle are already covered by your defect-management skill; advocacy depth and reproduction quality are not.

### Combinatorial / pairwise
Because most failures are triggered by one or two parameters (the NIST Interaction Rule, above), pairwise (2-way) coverage is a high-value reduction of the full Cartesian explosion. Tools: Microsoft **PICT** (free, CLI, model file with constraints, weights, sub-models, n-wise order), NIST **ACTS** (2–6-way, constraint validation, GUI+CLI), **Hexawise** (commercial, visual modeling), plus AllPairs, Jenny, IBM FoCuS. PICT is the most "agent-friendly": a plain-text model in, a compact test set out.

### Worth-borrowing from CTAL Advanced
The ISTQB Advanced Test Analyst syllabus adds, beyond Foundation: classification tree method, cause-effect graphing, orthogonal arrays/pairwise, domain analysis, defect-based techniques and **defect taxonomies**, plus testing of quality characteristics (functional correctness/suitability/interoperability; usability and accessibility) — and a defect-prevention chapter unique to the TA path. ISO/IEC 25010:2023 gives the product-quality model (functional suitability, performance efficiency, compatibility, interaction capability/usability, reliability, security, maintainability, flexibility/portability, safety) usable as a non-functional manual-test checklist spine.

---

## The Prioritized Candidate List

Sorted by **`.tms/`-fit** (how cleanly it produces a committable markdown artifact as an AI-agent skill/command). NET-NEW and DEEPEN are flagged per row; the two groupings are then summarized separately.

### Tier 1 — Highest `.tms/`-fit (deterministic, tabular/checklist outputs)

**1. `pairwise-combinatorial` — slash: `/pairwise`** *(NET-NEW; thin zone)*
- **Concept/source:** Pairwise/n-wise combinatorial test design; NIST combinatorial testing research (SP 800-142); Microsoft PICT, NIST ACTS, Hexawise. Generate a minimized set covering all parameter pairs, with constraints, seeding, and weighting.
- **Artifact:** `.tms/suites/<feature>/pairwise-<name>.md` containing the parameter model, constraints, and the generated matrix table; optionally a committed `*.pict` model file alongside. Could also emit reusable fragments to `shared-steps/`.
- **`.tms/`-fit:** Very high. Fully deterministic; `kensa-cli` can shell out to PICT and capture the table. The agent's value-add is deriving parameters/values (often via equivalence partitioning) and constraints from the spec.
- **vs. existing:** NET-NEW; the existing `test-design-techniques` skill *mentions* pairwise but does not generate matrices.
- **TMS differentiation:** TestRail documents pairwise conceptually but doesn't generate/commit the matrix; here the model + matrix live in git and regenerate on change.

**2. `bug-report-rimgen` — slash: `/bug`** *(DEEPEN: defect-management; thin zone)*
- **Concept/source:** Cem Kaner's BBST Bug Advocacy; RIMGEN/RIMGEA (Replicate, Isolate, Maximize, Generalize, Externalize, Neutral tone). Bug report as persuasive document; minimal repro; follow-up testing to maximize severity.
- **Artifact:** `.tms/reports/bugs/BUG-<id>.md` (or a reusable bug-report template skill) with sections: Summary, Environment, Minimal Repro Steps, Expected vs. Actual, Maximize/Generalize notes, Impact/Who's affected, Severity vs. Priority, Oracle (why it's a bug, via FEW HICCUPPS).
- **`.tms/`-fit:** Very high. A structured template the agent fills; the RIMGEN checklist doubles as a review rubric.
- **vs. existing:** DEEPEN — current `defect-management` covers severity/priority and lifecycle but not advocacy, reproduction quality, or minimization.
- **TMS differentiation:** TMS tools give a bug *form*; none enforce RIMGEN investigation discipline or tie the report to an oracle.

**3. `accessibility-wcag-manual` — slash: `/a11y`** *(DEEPEN: web-testing; thin zone)*
- **Concept/source:** WCAG 2.1/2.2 A/AA, POUR principles; WebAIM checklist; manual keyboard, screen-reader (NVDA/JAWS/VoiceOver), reflow/zoom passes; tool-assist via axe DevTools/WAVE/Lighthouse/Accessibility Insights (note the ~57% axe-core / ~30–40% criteria-based automated-coverage ceiling).
- **Artifact:** `.tms/suites/<feature>/a11y-checklist.md` — per-criterion rows (criterion, level, manual test method, common failure, pass/fail, notes), plus a "manual-only" section (Focus Order, Focus Visible, target size, dragging alternatives) the scanners can't cover. Optionally an RT-*.md browser-QA routine for the keyboard/screen-reader pass.
- **`.tms/`-fit:** Very high. WCAG provides a fixed criterion spine, so the checklist is reproducible and reviewable.
- **vs. existing:** DEEPEN — accessibility is only touched inside `web-testing`.
- **TMS differentiation:** Hosted TMS treat a11y as ordinary test cases; a versioned WCAG-mapped checklist that distinguishes automatable vs. manual criteria is distinctive.

**4. `device-browser-matrix` — slash: `/matrix`** *(DEEPEN: web-/mobile-testing; thin zone)*
- **Concept/source:** Data-driven selection — analytics/traffic-weighted first, market-share (StatCounter/Statista/DeviceAtlas), then risk-adjusted; tiered matrices; ">5% of key business metric" threshold rule of thumb.
- **Artifact:** `.tms/reports/device-matrix.md` — tiered table (Tier 1 primary / Tier 2 secondary / long-tail) of browser/OS/device combos with the rationale (traffic %, market share, risk note) and review cadence.
- **`.tms/`-fit:** High. The agent can pull analytics context and emit a defensible, dated matrix; pure markdown table.
- **vs. existing:** DEEPEN — only touched inside web-/mobile-testing.
- **TMS differentiation:** TMS tools store configurations but don't *derive* a defensible matrix from usage data.

### Tier 2 — High `.tms/`-fit (structured artifacts with more tester judgment)

**5. `exploratory-charter` — slash: `/charter`** *(NET-NEW; thin zone)*
- **Concept/source:** Hendrickson *Explore It!* charter template "Explore (target) With (resources) To discover (information)"; RST chartering.
- **Artifact:** `.tms/suites/<area>/charters/CH-<id>.md` (or a dedicated `charters/` area) — target, resources, information goal, risk/priority, time-box size (S/M/L), linked spec.
- **`.tms/`-fit:** Very high. Tiny, well-defined template; the agent generates a set of charters from a spec or risk analysis.
- **vs. existing:** NET-NEW; complements `scope-analysis`/`risk-based-testing` by turning risks into explorable missions.
- **TMS differentiation:** Qase et al. blog about charters but don't make them first-class committable artifacts.

**6. `sbtm-session-sheet` — slash: `/session`** *(NET-NEW; thin zone)*
- **Concept/source:** Satisfice SBTM session sheet; TBS metrics; Jonathan Bach STQE article; Satisfice SBTM Session Report Checklist.
- **Artifact:** `.tms/reports/sessions/SESSION-<id>.md` with the canonical fields (Charter, #Areas, Start, Tester, Task Breakdown w/ Duration + Test/Bug/Setup % + Charter-vs-Opportunity, Data Files, Test Notes, Bugs, Issues).
- **`.tms/`-fit:** High. Fixed template; the agent scaffolds it and, post-session, helps the tester record notes and compute TBS.
- **vs. existing:** NET-NEW.
- **TMS differentiation:** Only specialized add-ons (e.g., historic Bonfire) did session sheets; committable markdown session logs are distinctive.

**7. `sbtm-debrief-and-metrics` — slash: `/debrief`** *(NET-NEW; thin zone)*
- **Concept/source:** PROOF debrief (Past/Results/Obstacles/Outlook/Feelings); SBTM aggregate metrics (sessions completed, coverage by charter, TBS breakdown).
- **Artifact:** appends a PROOF block to the session sheet and/or emits `.tms/reports/sbtm-summary.md` aggregating session sheets into coverage/TBS metrics.
- **`.tms/`-fit:** High. Aggregation over existing markdown session files is deterministic and a great fit for a Blueprint (BP-NNN.json) automation.
- **vs. existing:** NET-NEW; extends `test-monitoring-control-completion` with exploratory-specific metrics.
- **TMS differentiation:** Exploratory coverage/TBS reporting is rare in file-based form.

**8. `product-coverage-outline` (SFDIPOT/HTSM) — slash: `/coverage-outline`** *(NET-NEW, partial DEEPEN of scope-analysis)*
- **Concept/source:** James Bach HTSM — SFDIPOT Product Elements + Quality Criteria categories.
- **Artifact:** `.tms/reports/coverage-outline.md` — a structured inventory of the product mapped to SFDIPOT and the quality criteria, with risk notes and gaps, used to seed charters and test ideas.
- **`.tms/`-fit:** High. Guideword-driven outline is naturally a nested markdown list.
- **vs. existing:** Mostly NET-NEW; deepens `scope-analysis` by adding a coverage model.
- **TMS differentiation:** No hosted TMS produces an HTSM coverage outline.

**9. `oracle-heuristics` (FEW HICCUPPS) — slash: `/oracles`** *(DEEPEN: negative-and-edge-cases / test-case-writing-craft)*
- **Concept/source:** Bolton/Bach consistency oracles FEW HICCUPPS; "all oracles are heuristic."
- **Artifact:** an oracle checklist fragment in `.tms/shared-steps/oracles.md`, and inline "why is this a bug?" oracle tags reusable in charters, bug reports, and test cases.
- **`.tms/`-fit:** Medium-high. Best as a reusable shared-step fragment and as a rubric injected into other skills (notably `/bug`).
- **vs. existing:** DEEPEN — strengthens expected-result reasoning in test-case-writing and negative testing.
- **TMS differentiation:** Conceptual depth competitors don't encode.

**10. `test-data-plan` — slash: `/test-data`** *(NET-NEW)*
- **Concept/source:** TDM practice — synthetic vs. masked vs. subset data; privacy (GDPR/HIPAA/CCPA); deliberate edge/boundary data (Unicode, very long, malformed, boundary numerics). Tester drives by *specifying* data, not executing.
- **Artifact:** `.tms/suites/<feature>/test-data.md` — required fields, valid/invalid/boundary/edge values per field, sensitive-data handling, generation rules, and (optionally) seed snippets.
- **`.tms/`-fit:** High. A specification artifact, no runner needed; pairs naturally with `/pairwise` and BVA/EP.
- **vs. existing:** NET-NEW; complements `test-design-techniques`.
- **TMS differentiation:** TMS tools assume data lives elsewhere; a committed data spec is distinctive.

### Tier 3 — Medium `.tms/`-fit (valuable, more design-judgment-heavy)

**11. `touring-charters` (FCC CUTS VIDS) — slash: `/tour`** *(NET-NEW / DEEPEN exploratory)*
- **Concept/source:** Michael Kelly's touring heuristics on James Bach's touring concept.
- **Artifact:** a set of tour-based charters (one per applicable tour) appended into the `charters/` area.
- **`.tms/`-fit:** Medium-high. Generates multiple charters; overlaps with `/charter` (could be a mode of it).
- **vs. existing:** NET-NEW; consider folding into `exploratory-charter`.

**12. `classification-tree` & `cause-effect-graphing` — slash: `/ctree`, `/cause-effect`** *(DEEPEN: test-design-techniques; CTAL)*
- **Concept/source:** ISTQB Advanced Test Analyst — classification tree method (hierarchical EP), cause-effect graphing (→ decision tables).
- **Artifact:** `.tms/suites/<feature>/classification-tree.md` (nested tree + selected combinations) or a cause-effect/decision-table markdown.
- **`.tms/`-fit:** Medium. Trees render acceptably as nested lists/tables; cause-effect graphs are awkward as pure markdown (decision-table output is the practical artifact).
- **vs. existing:** DEEPEN — extends `test-design-techniques` (which has decision tables) and connects to `/pairwise`.

**13. `quality-characteristics` (ISO 25010) — slash: `/quality-attributes`** *(NET-NEW for non-functional manual)*
- **Concept/source:** ISO/IEC 25010:2023 product-quality model.
- **Artifact:** `.tms/reports/quality-characteristics.md` — per-characteristic manual-test ideas/checklist (usability, compatibility, reliability, performance-as-observed, security-as-observed), scoped to what a manual tester can assess without tooling.
- **`.tms/`-fit:** Medium-high. Checklist spine from the standard; some overlap with HTSM Quality Criteria — pick one canonical model to avoid duplication.
- **vs. existing:** NET-NEW; complements `security-testing`/`web-testing` for non-functional manual coverage.

**14. `defect-taxonomy` — slash: `/defect-taxonomy`** *(DEEPEN: defect-management; CTAL)*
- **Concept/source:** ISTQB Advanced Test Analyst defect/anomaly taxonomies; defect-based test design.
- **Artifact:** `.tms/reports/defect-taxonomy.md` — a project-tailored taxonomy used to drive defect-based test ideas and to classify found defects for trend analysis.
- **`.tms/`-fit:** Medium. Useful but more of a living reference doc than a per-feature artifact.
- **vs. existing:** DEEPEN — extends `defect-management` (classification/trends) and feeds `risk-based-testing`.

---

## NET-NEW vs. DEEPEN — Summary Split

**NET-NEW (fills uncovered ground):** `pairwise-combinatorial`, `exploratory-charter`, `sbtm-session-sheet`, `sbtm-debrief-and-metrics`, `product-coverage-outline` (SFDIPOT), `test-data-plan`, `touring-charters`, `quality-characteristics` (ISO 25010).

**DEEPEN-EXISTING (extends a thin area of a shipped skill):** `bug-report-rimgen` (defect-management), `accessibility-wcag-manual` (web-testing), `device-browser-matrix` (web-/mobile-testing), `oracle-heuristics` (negative-and-edge-cases / test-case-writing-craft), `classification-tree`/`cause-effect-graphing` (test-design-techniques), `defect-taxonomy` (defect-management).

**Thin-zone coverage (explicit):** exploratory/SBTM → candidates 5, 6, 7, 11; pairwise → candidate 1; accessibility → candidate 3; device matrices → candidate 4; bug advocacy → candidate 2 (with oracle support from 9).

## Recommendations
1. **Ship Tier 1 first (one sprint):** `/pairwise`, `/bug` (RIMGEN), `/a11y`, `/matrix`. These four hit four of the five named thin zones, produce the most deterministic artifacts, and have the clearest differentiation from hosted TMS. `/pairwise` should bundle a `kensa-cli` PICT invocation; `/a11y` should ship the WebAIM/WCAG 2.2 AA criterion spine with the automatable-vs-manual split baked in.
2. **Then ship the exploratory bundle:** `/charter`, `/session`, `/debrief` as a coherent SBTM workflow (charter → session sheet → PROOF debrief → aggregated TBS/coverage report). Implement the debrief aggregation as a Blueprint (BP-NNN.json) so metrics regenerate from committed session files.
3. **Then the design-depth layer:** `/coverage-outline` (SFDIPOT), `/test-data`, `/oracles`, and the CTAL borrowings (`/ctree`, `/cause-effect`, `/quality-attributes`, `/defect-taxonomy`).
4. **Avoid duplication:** consolidate `touring-charters` into `/charter` as a mode; choose ONE quality model (HTSM Quality Criteria vs. ISO 25010) as canonical to avoid two overlapping checklists; have `/oracles` feed `/bug` rather than stand fully alone.
5. **Benchmarks that change the plan:** if PICT integration via `kensa-cli` proves brittle, fall back to an embedded pairwise generator or ship the model-file-only artifact and defer matrix generation. If users rarely run full SBTM sessions, demote `/session`/`/debrief` and keep `/charter` (charters are useful even without session management). Given the WebAIM Million 2026 finding that 95.9% of home pages fail WCAG and errors rose 10.1% year-over-year, if accessibility legal exposure (EAA/ADA) is a stated user need, promote `/a11y` to the very top and add an EN 301 549 mapping.

## Caveats
- **Premise corrections from primary sources:** the original SBTM article uses **short ≈45 / normal ≈90 / long ≈120 min**, not 60/90/120; and the HTSM "CRUSSPIC STMP" mnemonic is partly reorganized in the current v6.x document (the old STMP grouping — Supportability, Testability, Maintainability, Portability, Localizability — is now folded under a "Development" category, with Scalability/Performance/Installability as standalone categories). Build templates against the current HTSM if you want them to match the live Satisfice doc.
- **Automated a11y coverage is limited:** Deque's issue-volume study puts axe-core coverage at 57.38%, while the older WCAG-success-criteria baseline is ~30–40%; the `/a11y` artifact must foreground the manual-only criteria (Focus Order, Focus Visible, target size, dragging alternatives) rather than implying a clean scan equals conformance. Deque has said target-size is likely the only new WCAG 2.2 rule axe-core will add to the engine.
- **Pairwise is not a silver bullet:** NIST and others warn against blindly applying 2-way coverage to safety-critical or higher-order-interaction systems (the NIST data shows 2-way catches ~93% but 100% detection needed up to 6-way); the skill should support n-wise and constraints, and flag when pairwise is inappropriate.
- **Some artifacts are reference docs, not per-feature outputs** (defect taxonomy, quality model), so their `.tms/`-fit is lower even though their knowledge value is high.
- **Source mix:** practitioner sources (Satisfice, BBST/Kaner, Hendrickson, Ministry of Testing, Michael Kelly) are authoritative for exploratory/heuristics/bug-advocacy but are not formal standards; WCAG and ISO 25010/29119/20246 are the standards-grade anchors. A few device-matrix and a11y-tooling figures come from vendor blogs (BrowserStack, Deque) and should be treated as guidance, not independent measurement.