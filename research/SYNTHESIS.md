# kensa-qa — automation rebuild: target-state synthesis

Consolidates the 6 research reports (R1–R6) + the new **base + bundle** distribution
contract (`qa-agents-plugin.md`) into one buildable plan. This is the single source of
truth for the rebuild; the `compass_artifact_*.md` files are the underlying knowledge.

> **Core decisions (locked):**
> - **base = lean manual-QA core** that makes `/setup` → author/update cases work out of
>   the box. Everything else is opt-in, no bundle is `default:true`.
> - **Automation is bundled per combo** (`automation-<combo>` = `automation-test-lead` +
>   `automation-engineer` + that framework's skills, shipped together — pick the combo and
>   its skills arrive immediately). `automation-devops`, `codereviewer`, `git-operator` are
>   **separate optional layers** on top of automation.
> - **SOT connectors are a "which tools do you use?" checklist**, not a grab-bag bundle —
>   each of Linear / Jira / Confluence / Notion / Figma is independently selectable.
> - 5 of the 6 bundle agents **do not exist yet** and must be authored: `automation-test-lead`,
>   `automation-engineer`, `automation-devops`, `codereviewer`, `git-operator` (`strategist` exists).

---

## 1. The new distribution model (from `qa-agents-plugin.md`)

- **base** (`engine.source`) — always installed. The core plugin.
- **bundles** — optional, additive, user picks via checkboxes; add/remove later in
  Settings → Agents. A bundle mirrors the plugin's internal layout (`agents/ skills/
  commands/`) and merges into the installed plugin. **No dependency mechanism between
  bundles** — last-copied-wins on path conflict, so keep filenames unique.
- Contract = `engines.json` at repo root: `engines[].source` → base dir; `bundles[]` →
  catalog with `engineSources[engineId] → [dirs]`.

---

## 2. Current vs target (the structural delta)

| Aspect | Current (legacy) | Target |
|---|---|---|
| `engines.json` | `source: "dist/claude"`, **no** `bundles` key | `source: "dist/claude/base"` + `bundles[]` catalog |
| `dist/<engine>/` | flat (`agents/ commands/ skills/ hooks/`) | `base/…` + `bundles/<id>/…` |
| Source tree | `shared/` (skills/hooks/templates) + `engines/<engine>/` (agents/commands) | same + a **bundle split**: `shared/bundles/<id>/` + `engines/<engine>/bundles/<id>/` |
| Build | `scripts/build.{ps1,sh}` merges shared + engine → `dist/<engine>` | must emit `dist/<engine>/base` (current behavior) **and** `dist/<engine>/bundles/<id>` per bundle |
| Automation | none | self-contained `automation-<combo>` bundles + optional devops/codereview/git |

**The rebuild is primarily a repo-layout refactor + `engines.json` rewrite + build-script
change — content authoring comes after.**

---

## 3. Target catalog

### base (always installed) — manual-QA core (3 agents, 8 commands, 22 skills)
**Agents (3):** `test-lead-agent`, `qa-engineer-agent`, `schema-bootstrap-agent`.

**Skills (22):** the base carries the **full ISTQB author/review knowledge** (the skills
the base agents reference for the plan→author→review loop) + core `kensa-*` tooling —
`kensa`, `kensa-test-authoring`, `kensa-browser`, `kensa-blueprints`, `testing-fundamentals`,
`sdlc-and-test-lifecycle`, `test-design-techniques`, `negative-and-edge-cases`,
`checklist-design`, `collaboration-based-approaches`, `white-box-techniques-overview`,
`test-case-writing-craft`, `scope-analysis`, `test-planning`, `risk-based-testing`,
`review-rubrics`, `static-testing-reviews`, `test-monitoring-control-completion`,
`defect-management`, `test-tools-and-automation-overview`, `task-assignment`,
`clarification-protocol`.

> **DEVIATION (needs your OK):** the earlier split put management/static ISTQB skills in
> the `qa-analytics` bundle. But the base `test-lead-agent`/`qa-engineer-agent` *reference*
> those skills for the core loop — a base that points at unloadable skills is broken. So
> they were moved **back into base**, and `qa-analytics` is now a **commands-only** bundle
> (the 6 read-only commands reuse the base skills). If you want a stricter-lean base instead,
> we'd revert and make the base agents' skill-loads conditional ("if installed").

**Commands (8):** `/setup`, `/new-feature`, `/update-feature`, `/save-memory`, `/audit`,
`/adapt-schema`, `/run-routine`, `/blueprint`.

### bundles

| Bundle id | Category | Ships | Source | Status |
|---|---|---|---|---|
| `strategist` | strategy | `strategist` agent + `/brainstorm` + `sequential-thinking` | existing | relocate only |
| `qa-analytics` | analysis | **commands-only** — the 6 read-only commands (`/pull-context`, `/review-spec`, `/risk-assess`, `/test-plan`, `/analyze-cases`, `/traceability`); reuse the base ISTQB skills | existing | ✅ built |
| `platform-testing` | platform | platform skills (`web-testing`, `mobile-testing`, `backend-api-testing`, `security-testing`) | existing | ✅ built |
| `automation-playwright-ts` | automation | `automation-test-lead` + `automation-engineer` + 10 PW skills + 6 scaffold/de-flake commands | R2 (ready), R3, R5 | ✅ built (both engines) |
| `automation-pytest` | automation | lead + engineer + pytest/httpx skills | R2 (not run) | ❌ research pending |
| `automation-rest-assured` | automation | lead + engineer + REST Assured/Java skills | R2 (not run) | ❌ research pending |
| `automation-appium` | automation | lead + engineer + Appium skills | R2 (not run) | ❌ research pending |
| `automation-devops` | automation | `automation-devops` agent + 3 CI skills (`ci-runners-and-parallelism`, `ci-artifacts-and-reporting`, `ci-flake-gating-and-hygiene`) | R4 | ✅ built (both engines) |
| `automation-codereview` | automation | `codereviewer` agent + `test-code-review-standards`, `test-flakiness-governance` | R3 | ✅ built (both engines) |
| `automation-git` | automation | `git-operator` agent + `ken-traceability`, `case-test-sync` | R5 | ✅ built (both engines) |
| `api-contract` | api | API + contract-test agent/skills (Pact, can-i-deploy) | R3, R5 | partial knowledge |
| `manual-exploratory-sbtm` | skills | exploratory/SBTM charters, session sheets, debriefs | R6 | net-new |
| `manual-accessibility` | skills | WCAG manual checks, screen-reader passes, axe/WAVE/Lighthouse | R6 | net-new |
| `manual-pairwise` | skills | combinatorial/pairwise (PICT/AllPairs) | R6 | deepen |
| `manual-heuristics` | skills | SFDIPOT/FCC-CUTS-VIDS/touring heuristics & oracles | R6 | net-new |

**Tool connectors — "which tools do you use?" checklist** (category `sources`, each independently selectable):
`sot-linear`, `sot-jira`, `sot-confluence`, `sot-notion`, `sot-figma` (+ `figma-use` shipped with `sot-figma`).
Without any connector, `/new-feature <ref>` works on pasted text only — no tracker pull.

> **Automation packaging note:** `automation-test-lead` + `automation-engineer` ship inside
> *each* `automation-<combo>` bundle so picking a combo brings the agents + skills together
> (the lead/engineer agent files are identical across combos; last-copied-wins merge makes
> the duplication harmless). `automation-devops` / `codereview` / `git` stay separate so they
> are opt-in on top.
>
> R6 manual extras: exact split to be finalized from R6's prioritized `.tms/`-fit ranking.

### R2 combo coverage
R1 v1 shortlist = Playwright+TS, Playwright+Python, pytest+requests/httpx,
REST Assured+Java, Appium. **R2 run only for Playwright+TS so far** — the other 4 need
their own R2 pass before their bundles can be authored.

---

## 4. R2 → `automation-playwright-ts` skill decomposition (ready to build)

From R2 (`compass…1c0a375a`). Sub-skills (each `concept → rules → code → pitfalls`):
`playwright-typescript` (index), `playwright-locators`, `playwright-fixtures-and-pom`,
`playwright-waiting-and-assertions`, `playwright-auth-storagestate`,
`playwright-test-data`, `playwright-parallel-and-sharding`,
`playwright-reporting-and-traces`, `playwright-ci-docker`, `playwright-visual-and-a11y`.

Commands: `/kensa-scaffold-playwright`, `/kensa-add-page-object`, `/kensa-add-auth-setup`,
`/kensa-add-visual-test`, `/kensa-add-a11y-test`, `/kensa-fix-flake`.

---

## 5. Work plan (sequencing)

1. **Layout refactor** — introduce `shared/bundles/<id>/` + `engines/<engine>/bundles/<id>/`;
   update `scripts/build.{ps1,sh}` to emit `dist/<engine>/base` + `dist/<engine>/bundles/*`.
2. **Carve the base** — move the non-base existing skills/commands out of `base/` into their
   bundles: `strategist`, `qa-analytics` (management/static + 6 RO commands), `platform-testing`
   (web/mobile/api/security), and the `sot-*` connectors. Base keeps only the §3 base set.
   Pure relocation, no behavior change.
3. **Rewrite `engines.json`** — `source → dist/<engine>/base`, add `bundles[]` catalog from §3
   (no `default:true`). Connectors as `category: sources`.
4. **Build `automation-playwright-ts`** — author `automation-test-lead` + `automation-engineer`
   (R3/R5/R2) + the §4 skills + commands. First end-to-end automation bundle.
5. **Build the optional automation layers** — `automation-devops` (R4), `automation-codereview`,
   `automation-git` (R5).
6. **Validate install** — scratch project, both engines: base-only (uncheck all) works; then
   base + `automation-playwright-ts` produces a working engineer with its skills.
7. **Backlog** — R2 for the other 4 combos → their bundles; R6 manual bundles; `api-contract`.

---

## 6. Open items
- R2 not run for 4 of 5 shortlisted combos.
- R3/R4/R6 reports did not emit an explicit "How this maps to the plugin" section — their
  concrete artifact lists are derived above and need a confirmation pass against the reports.
- Final R6 manual-bundle split pending R6's prioritized `.tms/`-fit ranking.
- `automation-test-lead` + `automation-engineer` are duplicated across every `automation-<combo>`
  bundle (identical files). Acceptable via last-wins merge, but if it gets unwieldy, revisit a
  shared `automation-core` bundle later.
