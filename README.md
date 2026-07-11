# Kensa-QA — a Manual QA Team Inside Claude Code

<p align="center">
  <img src="docs/images/hero.png" alt="Kensa-QA in action: Test Lead plans, QA Engineers write cases" />
</p>

<p align="center">
  <b>Point at a ticket. Get a coverage checklist and a folder of manual test cases — written in your project's style, ready to commit.</b>
</p>

<p align="center">
  Built for the <a href="https://kensa.dev">Kensa</a> TMS format (plain markdown under <code>.tms/suites/</code>), works on any project where test cases live in markdown.
</p>

<p align="center">
  📘 <b>ISTQB CTFL v4.0.1 grounded</b> — every reasoning skill cites the syllabus chapter and learning objective it teaches.
</p>

---

## What it does

<table>
<tr>
<td width="33%" valign="top">

### 📝 Author
Turn a Linear / Jira / Confluence / Notion / Figma ref — or raw pasted text — into a checklist plus 10–60 case files.

</td>
<td width="33%" valign="top">

### 🔄 Update
When a spec changes, find affected cases by source ref and rewrite only what changed. No hand-hunting.

</td>
<td width="33%" valign="top">

### 🔎 Audit
On large suites: flag stale drafts, duplicates, orphan steps, tag drift, missing source refs. Read-only by default.

</td>
</tr>
</table>

The base writes manual test cases — it does **not** replace a test runner. Optional bundles take it further across the SDLC: the `qa-analytics` bundle adds **read-only analysis commands** — pull context from your trackers, statically review a spec for defects before any code, assess product risk, draft a test plan, deep-audit the whole case base by a fan-out of reviewers, and build a requirements→cases traceability matrix — and the automation bundles derive `@KEN`-tagged **Playwright tests** from your manual cases. See [Base + bundles](#base--bundles) and [SDLC coverage](#sdlc-coverage) below.

And you never have to guess the next step: **every command ends with a `✅ Done / ➡️ Next` epilogue** naming the logical follow-up commands. Lost mid-project? Run `/next` — a read-only situation router that inspects `.tms/` state and recommends what's worth running now.

---

## How it works

<p align="center">
  <img src="docs/images/architecture.png" alt="How the plugin works: Test Lead coordinates, QA Engineers run in parallel and have their work reviewed in two passes" />
</p>

1. **`test-lead-agent`** reads your project memory, pulls the spec via MCP, and proposes a coverage plan.
2. **You approve** the plan. (Human gate — nothing spawns until you sign off.)
3. **`qa-engineer-agent`** workers run in parallel. Each writes its slice in two stages — checklist, then cases — with the Test Lead reviewing after each stage (up to 2 revision rounds per stage).
4. **Output**: new or updated `.md` cases, a project-memory checkpoint, and a report (files, gaps, open questions).

Rigor is enforced, not suggested. The spec is **statically reviewed before any case is written** — every plan carries a quoted *Spec defects* block (contradictions, ambiguities, missing unhappy paths), even when empty. The review rubric treats missing negatives or edge cases as an **automatic send-back**, never "approve with notes". Every checklist must end with a **Coverage-dimensions table** — negatives, boundaries, state transitions, permissions, concurrency, interruption/recovery, i18n, data lifecycle, non-functional — each row marked covered, out-of-scope (with reason), or N/A; nothing is cut silently. The pipeline also **chains**: the analysis commands' artifacts (context dossier, spec review, risk register, brainstorm) are read automatically by `/new-feature` instead of re-gathering. And for what scripted cases can't catch, the **exploratory-testing** skill runs charter- and tour-based sessions.

For strategic decisions ("how do we split this feature?", "negative-first or boundary-first?"), `/brainstorm` (the `strategist` bundle) spawns three **strategists** in parallel for a deliberation round instead of writing cases.

Onboarding an export from another TMS? `/adapt-schema` reads a couple of your real case files and fits the project **schema** to them (via the `schema-bootstrap-agent`), then you import the full export through Kensa's Universal format — **data follows schema, never the reverse**. And `/blueprint` builds **node-graph automations** (`.tms/blueprints/`) with a first-class agent step that runs `claude`/`codex` inside the flow.

---

## Base + bundles

The plugin installs as an always-on **base** plus **12 optional bundles** you pick at install time (checkboxes in the IDE; by hand, see [INSTALL.md](INSTALL.md)) and can change later. Uncheck everything and you still get a fully working manual-QA team. [`catalog.json`](catalog.json) is the single source of truth for the split.

**Base** (always installed): the 3 core agents (`test-lead-agent`, `qa-engineer-agent`, `schema-bootstrap-agent`), **11 commands**, **26 skills** (the full ISTQB author/review loop plus the `kensa` CLI / browser / mobile / HTTP / results / Blueprints tooling), the memory-checkpoint Stop hook, and the bundled `sequential-thinking` MCP.

| Bundle | What it adds |
|---|---|
| `qa-analytics` | 6 read-only commands — context dossiers, static spec review, risk registers, test plans, deep base audit, traceability |
| `platform-testing` | Web / mobile / API / security testing knowledge skills (ISO 25010 non-functional checklists) |
| `strategist` | `/brainstorm` — three strategists debate approaches in parallel, return 2–3 finalists |
| `automation-playwright-ts` | Write `@KEN`-tagged Playwright + TypeScript tests — `automation-test-lead` + `automation-engineer` agents, 10 framework skills, `/automate-case` + scaffold/de-flake commands |
| `automation-devops` | Wire automated tests into CI/CD — runner choice, matrix/sharding, artifacts, flake handling, merge-gating |
| `automation-codereview` | Review automated test code for reliability, maintainability, and `@KEN-<id>` traceability |
| `automation-git` | Commit `@KEN`-tagged tests atomically; keep `.tms/` cases ↔ tests in sync (drift detection) |
| `sot-linear` · `sot-jira` · `sot-confluence` · `sot-notion` · `sot-figma` | Source-of-truth connectors — where specs / acceptance criteria live in each tool and how to pull them |

Bundle commands and agents exist **only when their bundle is installed**. If the Test Lead suggests a step you don't have, it names the bundle to add instead of improvising the capability.

---

## The skill library

Every reasoning step is backed by an explicit skill — **54 skills** in all: 26 always-installed base skills plus 28 across the 12 optional bundles. Every **reasoning skill carries an ISTQB CTFL v4.0.1 grounding block** citing the chapter and learning objective it operationalises (21 skills, counting the `platform-testing` bundle's ISO 25010 checklists). The other 33 are **tooling skills** — the `kensa` CLI family, browser/mobile/HTTP-driven QA, schema adaptation, Blueprints, SOT extractors, agent communication, and the 17 automation-family skills — which complement ISTQB without being derived from it.

<p align="center">
  <img src="docs/images/skills-library.png" alt="Skill library: 54 skills organized into Foundation, Test Design, Test Management, Static & Lifecycle, Platform, Tooling, and Automation sectors — colour-coded by ISTQB CTFL v4.0.1 chapter" />
</p>

| Sector | Skills | ISTQB ref |
|---|---|---|
| 🟦 **Foundation** | `testing-fundamentals` | Ch 1 |
| 🟦 **Test Design** | `test-design-techniques`, `white-box-techniques`, `collaboration-based-approaches`, `negative-and-edge-cases`, `exploratory-testing`, `test-case-writing-craft`, `checklist-design` | Ch 4 |
| 🟩 **Test Management** | `test-planning`, `risk-based-testing`, `scope-analysis`, `review-rubrics`, `test-monitoring-control-completion`, `defect-management` | Ch 5 + §3.2 |
| 🟨 **Static & Lifecycle** | `sdlc-and-test-lifecycle`, `static-testing-reviews` | Ch 2 + 3 |
| 🟪 **Platform** *(bundle: `platform-testing`)* | `web-testing`, `mobile-testing`, `backend-api-testing`, `security-testing` — plus base `test-tools-and-automation-overview` | §2.2.2 / Ch 6 |
| 🟥 **Tooling** (base) | `kensa`, `kensa-test-authoring`, `kensa-browser`, `kensa-mobile`, `kensa-http`, `kensa-results`, `kensa-blueprints`, `task-assignment`, `clarification-protocol` | non-ISTQB |
| 🟥 **Tooling** (bundles) | 5 × `sot-*` + `figma-use` (connector bundles), `sequential-thinking` (`strategist`) | non-ISTQB |
| 🟧 **Automation** *(bundles: `automation-*`)* | the 10-skill `playwright-*` family, 3 CI/CD skills, `test-code-review-standards`, `test-flakiness-governance`, `ken-traceability`, `case-test-sync` | non-ISTQB |

The Test Lead loads the management & static skills on demand. Every QA Engineer brief always loads `testing-fundamentals`, `test-design-techniques`, `negative-and-edge-cases`, `test-case-writing-craft` — plus one platform skill (with the `platform-testing` bundle) and the matching SOT extractor for the ticket source (its connector bundle).

---

## Install

kensa-qa ships **two clean engine builds from one monorepo** — one for Claude Code,
one for OpenAI Codex. No installer script. The built, ready-to-use folders live
under [`dist/claude/`](dist/claude) and [`dist/codex/`](dist/codex) — each an
always-installed **`base/`** (self-contained: agents, commands, skills, hooks,
manifest) plus optional **`bundles/<id>/`** add-ons.

| Engine | What runs the team | Installed into |
|---|---|---|
| **Claude Code** | Claude | `<project>/.claude/plugins/kensa-qa/` |
| **Codex** | OpenAI Codex CLI | `<project>/` — `.codex/agents/*.toml`, `.codex/prompts/`, `AGENTS.md`, `skills/`, `hooks/` |

**By hand (no IDE) — see [INSTALL.md](INSTALL.md):**

```
# Claude Code (complete, one-liner)
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov

# Codex (copy the build into your project root)
git clone https://github.com/rpluzhnikov/QA_agents.git
cp -R QA_agents/dist/codex/. /path/to/your-project/
```

Both by-hand routes install the **base**. To add a bundle by hand, copy
`dist/<engine>/bundles/<id>/` contents on top — see [INSTALL.md](INSTALL.md).

**Via an IDE:** the IDE reads [`engines.json`](engines.json), offers the engine
picker plus the bundle checkboxes, and copies base + selected bundles into the
project (change the selection later in Settings → Agents).

After install, run `/setup` (Claude) or `/kensa-setup` (Codex) to bootstrap
`.tms/memory/` and wire your source-of-truth MCP servers.

### Building from source

Sources are split so the **54 skills have a single home** and never drift between engines:

```
shared/skills · shared/hooks · shared/templates   # one source, copied into both engines
engines/claude · engines/codex                     # engine-specific manifest + agents/prompts
scripts/build.ps1 · scripts/build.sh               # assemble + validate dist/<engine>
```

Edit a skill once under `shared/skills/`, then rebuild both engines:

```powershell
.\scripts\build.ps1     # Windows
```
```bash
sh scripts/build.sh     # macOS / Linux
```

The build reads [`catalog.json`](catalog.json) (the base/bundle membership), assembles
`dist/<engine>/base/` + `dist/<engine>/bundles/<id>/`, generates the per-engine drop
README, and validates that all 54 skills are mapped exactly once and each manifest is valid.

<details>
<summary><b>Prerequisites</b></summary>

- [Claude Code](https://docs.claude.com/claude-code/install) and/or the [OpenAI Codex CLI](https://developers.openai.com/codex), installed and signed in.
- Node.js on PATH (for the bundled `sequential-thinking` MCP via `npx`, and for the memory-checkpoint Stop hook, which Claude runs via `node`).
- The Stop hook is cross-platform: the Claude engine runs `hooks/save-memory-stop.js` (node) on every OS; the Codex engine keeps `save-memory-stop.sh` / `.ps1`, dispatched per OS by `hooks/hooks.json`.
- No API keys: Linear / Atlassian / Notion / Figma all use browser OAuth on first connect.
</details>

---

## Verify

After the drop, in the project:

| Check | Expected |
|---|---|
| `/help` | The 11 **base** commands: `setup`, `new-feature`, `update-feature`, `save-memory`, `audit`, `adapt-schema`, `run-routine`, `new-routine`, `blueprint`, `next`, `import-results` |
| Type `@` (Claude) | Base agents: `test-lead-agent`, `qa-engineer-agent`, `schema-bootstrap-agent` |
| `/hooks` | One **Stop** hook (memory checkpoint) |

Bundle commands and agents (`/brainstorm` + `strategist`, the six `qa-analytics` commands, `/automate-case` + the automation agents, …) appear **only if their bundle is installed**. Anything missing that should be there → restart the host fully so it reloads the dropped files.

---

## First-time setup

```
/setup
```

Interactive: asks about your stack, case language, ticket tracker, wiki. Scans existing cases under `.tms/suites/` to learn your style.

Writes:
- `.tms/memory/` — conventions, glossary, SOT config (edit by hand any time)
- `.mcp.json` — MCP servers for your sources (restart Claude Code after this to connect)

---

## Commands

**Every command ends with a standard epilogue** — `✅ Done: …` + `➡️ Next: …` naming the 1–3 logical follow-ups (bundle-aware: it only suggests what you have installed). The plugin always tells you what to run next; if you're ever lost, run `/next`.

### Base (always installed)

| Command | What it does |
|---|---|
| `/next` | Read-only situation router — probes `.tms/` state (base size, pending checkpoint, fresh reports, stale audits) and recommends the 2–3 most useful next commands. "I'm back, where were we?" |
| `/setup` | Bootstraps `.tms/memory/` and `.mcp.json`. Re-run to add a new SOT |
| `/new-feature <ref>` | Pulls spec, plans, you approve, QA Engineers write cases under `.tms/suites/<suite>/` |
| `/update-feature <ref>` | Finds cases by `source_id`, reads new spec, adds/removes/rewrites only what changed |
| `/audit [scope]` | Schema validation, duplicates, drift, tag check on the whole `.tms/`. Read-only by default |
| `/run-routine [RT-id]` | Executes a saved browser routine against the live app via the Kensa-launched Chrome |
| `/new-routine [name]` | Authors a browser routine (`.tms/routines/RT-*.md`) through a short interview — goal, target, steps, pass criteria |
| `/adapt-schema [samples]` | Fits the project schema (additively) to an export from another TMS, via the `schema-bootstrap-agent` |
| `/blueprint [verb]` | Designs / validates / runs a Blueprint node-graph automation (`.tms/blueprints/`) |
| `/import-results <report>` | Ingests a CI report (JUnit / Playwright / Allure + 8 more) via `kensa results`, walks the matched/orphaned split, and closes the traceability loop |
| `/save-memory` | Captures session learnings to `.tms/memory/learned/` and closes the memory checkpoint |

### Analysis & planning (read-only) — `qa-analytics` bundle

These six write **no** test cases — each produces one committable markdown artifact in `.tms/reports/` and never owes a memory checkpoint. Their artifacts are picked up automatically by `/new-feature` / `/update-feature`.

| Command | What it does |
|---|---|
| `/pull-context <ref>` | Gathers all SOT content + related cases into a dossier. Building block for the rest |
| `/review-spec <ref>` | Static review of a requirement (ISO 20246) — finds defects *in the spec* before any case is written |
| `/risk-assess <ref>` | Product risk register (likelihood × impact → level → recommended test depth) |
| `/test-plan <epic>` | ISTQB §5.1 test plan; folds in existing risk / context / brainstorm artifacts |
| `/analyze-cases [scope]` | Semantic deep-audit of the case base by a fan-out of 1–N reviewers — contradictions, semantic dupes, coverage gaps, convention drift. Complements the mechanical `/audit` |
| `/traceability [--deep]` | Requirements→cases matrix from `source_id`; `--deep` maps each acceptance criterion to cases |

### Strategy — `strategist` bundle

| Command | What it does |
|---|---|
| `/brainstorm <topic>` | Three strategists deliberate in parallel, output 2–3 finalists you pick from |

### Automation — `automation-playwright-ts` bundle

| Command | What it does |
|---|---|
| `/automate-case <KEN-id>` | **The core verb**: derives a `@KEN-<id>`-tagged Playwright test from a manual case — candidacy check, negative-parity brief, run-verified spec, case tagged `automated` |
| `/scaffold-playwright` | Scaffolds a Playwright + TypeScript E2E project from zero — config, fixtures/pages/utils/tests layout |
| `/add-page-object <name>` | Generates a Page Object Model class and registers it as a fixture — resilient locators, no assertions in POMs |
| `/add-auth-setup` | Log-in-once auth via `storageState` wired into `playwright.config.ts` (multi-role supported) |
| `/add-visual-test <target>` | Stabilized visual-regression test (`toHaveScreenshot`) with masked dynamic content |
| `/add-a11y-test <url>` | Accessibility test with `@axe-core/playwright`, scoped to WCAG A+AA |
| `/fix-flake <spec>` | Diagnoses and de-flakes a spec — web-first assertions, resilient locators, re-run to confirm |

<details>
<summary><b>Command details and examples</b></summary>

#### `/new-feature <ref>`
```
/new-feature LIN-42
/new-feature https://yourcompany.atlassian.net/wiki/spaces/...
/new-feature "Free-text spec pasted here"
```
The Test Lead pulls the spec, plans coverage, gets your sign-off, spawns QA Engineers for checklists, reviews, then has QA Engineers write the case files. Reports total case count, assumptions made, open questions for product.

#### `/update-feature <ref>`
```
/update-feature LIN-42
```
The Test Lead finds cases referencing the changed source (via `source_id` in frontmatter), reads the new spec, decides what to add/remove/rewrite. Same review + report flow as `/new-feature`.

#### `/brainstorm <topic>` — `strategist` bundle
```
/brainstorm how to split the Discount Engine for parallel QA engineers?
/brainstorm should 2FA cases be negative-first or boundary-first?
```
The Test Lead picks three angles (scope, decomposition strategy, test technique), three strategists each argue one angle in parallel, cross-review round, then a comparison view with 2–3 finalists. Saved to `.tms/brainstorms/`, referenceable from `/new-feature` later.

#### `/audit`
Walks `.tms/` via the `kensa` CLI: schema validation, duplicates, stale drafts, orphan shared-steps, tag drift, qualitative sampling. Output to terminal + `.tms/reports/audit-YYYY-MM-DD.md`. Opt-in fixes per-batch with confirmation.

#### `/save-memory`
`/new-feature` and `/update-feature` create a `.tms/.pending-checkpoint` marker when you approve the plan; the cross-platform Stop hook won't let the session end until the `/save-memory` protocol runs and deletes it. Run manually mid-session to capture a new convention before more work happens.

#### `/next`
```
/next
```
Read-only, writes nothing, owes no checkpoint. Probes the CLI, `.tms/` presence, pending checkpoint, base size and coverage, fresh analysis/brainstorm artifacts, and audit age — then reports a short status snapshot plus the 2–3 most useful next commands with reasons (only ones whose bundle is installed).
</details>

---

## SDLC coverage

The commands map onto the QA side of the software lifecycle — shift-left first, authoring in the middle, repo intelligence and automation feedback across the whole base:

| SDLC stage | Command(s) | ISTQB skill surfaced |
|---|---|---|
| Requirements / static testing | `/pull-context`, `/review-spec` (`qa-analytics`) — and every `/new-feature` plan carries a *Spec defects* block regardless | `static-testing-reviews` (Ch 3) |
| Risk analysis & planning | `/risk-assess`, `/test-plan` (`qa-analytics`), `/brainstorm` (`strategist`) | `risk-based-testing` (§5.2), `test-planning` (§5.1) |
| Test design / authoring | `/new-feature`, `/update-feature` (base) | `test-design-techniques` (Ch 4) |
| Exploratory sessions | charter + tour sessions via the `exploratory-testing` skill (base) | `exploratory-testing` (§4.4.2) |
| Test-base health & coverage | `/audit` (base), `/analyze-cases`, `/traceability` (`qa-analytics`) | `review-rubrics` (§3.2) |
| Automation & results feedback | `/automate-case` (`automation-playwright-ts`), `/import-results` (base) | `kensa-results`, the `playwright-*` family |

Analysis is read-only, authoring writes manual cases, and the automation bundles are the only place the plugin writes executable test code — always traceably tagged `@KEN-<id>` back to a case.

---

## Sources of truth

| Source | Auth | Notes |
|---|---|---|
| Linear | Browser OAuth | |
| Jira | Browser OAuth | Atlassian Cloud |
| Confluence | Browser OAuth | Same Atlassian server as Jira; `/setup` runs CQL discovery for canonical spec pages |
| Notion | Browser OAuth | |
| Figma | Local socket | Requires Figma desktop with Dev Mode MCP enabled |

No API tokens. OAuth opens a tab on first use. Each source has a dedicated extraction skill (`sot-linear`, `sot-jira`, `sot-confluence`, `sot-notion`, `sot-figma`) that tells the agents where acceptance criteria typically live.

---

## Project memory — the `.tms/` directory

Everything the plugin learns lives in plain markdown / YAML. Read, edit, commit.

```
<your-project>/.tms/
├── memory/
│   ├── project.md         ← what this project is, stack, testing types
│   ├── conventions.md     ← how cases are written here
│   ├── glossary.md        ← domain terms and translations
│   ├── sot.yaml           ← source-of-truth config
│   └── learned/
│       ├── patterns.md
│       ├── shared-steps.md
│       └── tags.md
├── suites/                ← test cases, organized by feature
├── shared-steps/          ← reusable step sequences
├── reports/               ← /audit + analysis + exploratory-session output (commit)
├── brainstorms/           ← /brainstorm output (commit)
├── routines/              ← browser routines RT-*.md (commit)
├── blueprints/            ← /blueprint node-graphs BP-*.json (commit)
└── automation-runs/       ← normalized runs ingested by /import-results
```

`project.md`, `conventions.md`, `glossary.md` are human-written, plugin reads only. `sot.yaml` is `/setup`-written, hand-edited later. `learned/*` is plugin-written; you review during memory checkpoint. One transient file lives at the top: `.tms/.pending-checkpoint`, the memory-checkpoint marker (`/setup` adds it to `.gitignore`).

Byte-exact case file format: see `skills/kensa-test-authoring/`.

---

## FAQ

<details>
<summary><b>macOS / Linux — do the hooks work?</b></summary>

Yes, everywhere. As of v0.17 the Claude engine registers a single
cross-platform Stop hook, `hooks/save-memory-stop.js`, run via `node`
on Windows, macOS, and Linux alike. The `.sh` / `.ps1` variants remain
for the Codex engine, whose `hooks/hooks.json` dispatches the right
one per OS.
</details>

<details>
<summary><b>I ran <code>/setup</code> but Linear / Jira / Notion isn't reading anything.</b></summary>

You skipped the restart after `/setup`. MCP servers connect at session start — fully quit Claude Code and reopen. On first connect, a browser tab opens for OAuth. Still failing → run `/hooks` and `/help` to confirm the plugin loaded.
</details>

<details>
<summary><b><code>.tms/suites/</code> is empty. The plugin says "no cases yet".</b></summary>

Normal on a fresh project. `/new-feature` creates suite directories on first write. Already have cases from another tool? Drop them under `.tms/suites/<suite>/<id>.md` matching the `kensa-test-authoring` format and `/setup` will learn from them.
</details>

<details>
<summary><b>How do I disable the plugin in one project only?</b></summary>

Inside that project: `/plugin disable kensa-qa@rpluzhnikov`. Stays installed globally; just doesn't load there.
</details>

<details>
<summary><b>Can I edit <code>conventions.md</code> directly?</b></summary>

Yes, that's the intended workflow. The plugin re-reads memory at session start so changes take effect immediately. Want the plugin to *learn* from cases you wrote by hand? Re-run `/setup` and pick "update specific files".
</details>

<details>
<summary><b>QA Engineers vs Strategists — what's the difference?</b></summary>

`qa-engineer-agent` workers (spawned by `/new-feature`, `/update-feature`) *write* test cases. `strategist` agents (spawned by `/brainstorm`) *deliberate* — they argue strategic angles to help you decide on an approach, never write cases themselves.
</details>

<details>
<summary><b>What does "ISTQB CTFL v4.0.1 grounded" mean here?</b></summary>

Every reasoning skill in the plugin cites the specific ISTQB CTFL chapter, section, and learning objective it operationalises. When the Test Lead or a QA Engineer applies a technique (boundary value analysis, decision tables, risk-based prioritization, defect reporting…), it can name the syllabus authority for that decision. This makes the reasoning auditable for teams that need to justify their QA practice to regulated stakeholders, and it lets newcomers learn ISTQB by example: every test case the plugin writes is a worked example of one or more CTFL learning objectives.

The claim is scoped to the reasoning skills: the base's 17 reasoning skills (plus the `platform-testing` bundle's four ISO 25010 checklists) carry ISTQB grounding blocks. The other 33 skills are tooling — the `kensa` / `kensa-test-authoring` / browser / mobile / HTTP / results / Blueprints family, the `sot-*` connectors, `figma-use`, `sequential-thinking`, `task-assignment`, `clarification-protocol`, and the 17 automation-family skills (`playwright-*`, CI/CD, test-code review, traceability). They don't contradict ISTQB but aren't derived from it either; they carry a "non-ISTQB tooling" disclaimer at the top of their SKILL.md.
</details>

<details>
<summary><b>The session won't end — something about a memory checkpoint.</b></summary>

`/new-feature` and `/update-feature` create a marker file `.tms/.pending-checkpoint` when you approve the plan; the save-memory protocol deletes it at the end, and the Stop hook blocks the session only while the marker exists. Wait for the Lead to finish, or — if it's stuck — delete `.tms/.pending-checkpoint` yourself to unblock (the hook fails open; nothing else keys on that file).
</details>

---

<details>
<summary><b>Under the hood</b> (for the curious / plugin developers)</summary>

### Auto memory checkpoint
`/new-feature` and `/update-feature` create the marker file `.tms/.pending-checkpoint` on plan approval; the save-memory protocol deletes it as its final step. A `Stop` hook (`hooks/save-memory-stop.js`, run via `node` on every platform) blocks the session from ending only while the marker exists — no transcript scanning, no chat sentinel, so merely *mentioning* a command never re-arms it. Behavior is controlled by `auto_save_learnings` in `.tms/memory/project.md`:
- `true` — silent saves, one-line report
- `false` (default) — yes/no/edit per candidate

If nothing to save, the Lead says so in one line and deletes the marker anyway. Save-memory also sweeps the session's `ASSUMPTION:`/`GAP:` markers into `.tms/reports/assumptions-<ref>-<date>.md` — a standing questions-to-PM ledger. (The `.sh`/`.ps1` hook scripts remain for the Codex engine's `hooks.json`.)

### Bundled MCP
`sequential-thinking` ships with the plugin (declared in `plugin.json`, started automatically — no credentials). Powers the reasoning skill Lead and Workers use for hard scope and edge-case decisions.

### Skills
54 skills under `shared/skills/` — 26 in the base, 28 across the 12 optional bundles. See the skill library section above for the full taxonomy. Highlights:

**ISTQB CTFL v4.0.1-grounded (21 — 17 base + the 4 `platform-testing` checklists):**
- **Foundation:** `testing-fundamentals` (Ch 1)
- **Test design (Ch 4):** `test-design-techniques`, `white-box-techniques-overview`, `collaboration-based-approaches`, `negative-and-edge-cases`, `exploratory-testing`, `test-case-writing-craft`, `checklist-design`
- **Test management (Ch 5 + §3.2):** `test-planning`, `risk-based-testing`, `scope-analysis`, `review-rubrics`, `test-monitoring-control-completion`, `defect-management`
- **Static & lifecycle (Ch 2 + 3):** `sdlc-and-test-lifecycle`, `static-testing-reviews`
- **Platform / non-functional (§2.2.2 + Ch 6):** `web-testing`, `mobile-testing`, `backend-api-testing`, `security-testing`, `test-tools-and-automation-overview`

**Non-ISTQB tooling (33):**
- `kensa-test-authoring` — byte-exact `.tms/` on-disk format
- `kensa` — drive the `kensa` CLI (queries, bulk edits, context bundling, audit, schema adaptation)
- `kensa-browser` / `kensa-mobile` / `kensa-http` — live evidence (Chrome via CDP, Android/iOS devices, HTTP collections)
- `kensa-results` — ingest CI reports (11 formats), match tests to cases
- `kensa-blueprints` — design/validate/run node-graph automations (`kensa blueprint …`) with an agent step
- `sequential-thinking` — structured reasoning
- `figma-use` — programmatic Figma access for deep node inspection
- `sot-linear` / `sot-jira` / `sot-confluence` / `sot-notion` / `sot-figma` — extraction guides per source
- `task-assignment` — `test-lead-agent` → `qa-engineer-agent` delegation contract
- `clarification-protocol` — Test Lead ↔ user dialogue rules
- the 17 automation-family skills — `playwright-typescript` + 9 focused sub-skills, the `ci-*` devops trio, `test-code-review-standards`, `test-flakiness-governance`, `ken-traceability`, `case-test-sync`

</details>

---

## Roadmap

| Version | Highlights |
|---|---|
| v0.1 | Lead + Worker, 4 commands, project memory templates |
| v0.2 | Memory checkpoint protocol |
| v0.3 | SOT extraction skills; `sequential-thinking`, `figma-use`, `kensa`, `kensa-test-authoring` integrated; `.mcp.json` writer |
| v0.4 | Stop hooks (auto-checkpoint + debug log); marketplace manifest; `INSTALL.md` |
| v0.5 | `/audit`, `/brainstorm`, `strategist` agent, OAuth clarity, Confluence multi-page discovery, pre-seeded tag taxonomy, parallel-worker ID-range allocation, stuck-session detection |
| v0.6 | **BREAKING** — agents renamed to `test-lead-agent` and `qa-engineer-agent`. Full ISTQB CTFL v4.0.1 grounding: 10 new skills covering Chapters 1, 2, 3, §4.3, §4.5, §5.1, §5.2, §5.3, §5.5, Ch 6; existing 21 skills carry ISTQB citation blocks. Skill library wheel diagram. |
| v0.7 | **SDLC coverage** — 6 read-only analysis commands: `/pull-context`, `/review-spec`, `/risk-assess`, `/test-plan` (shift-left) and `/analyze-cases`, `/traceability` (test-base intelligence). `qa-engineer-agent` gains an `analyze` mode for fan-out review. No new agents or skills. |
| v0.8 | **Multi-engine + installer** (superseded by v0.9). Three install modes (Claude / native Codex / hybrid Claude→Codex worker) via an interactive `install.ps1` / `install.sh`; bash port of the hooks. |
| v0.9 | **Two clean engines, one monorepo.** Removed the hybrid delegation and the interactive installer. Skills now have a single home under `shared/`; `scripts/build.{ps1,sh}` assemble self-contained `dist/claude/` and `dist/codex/` builds an IDE drops straight into a project. Claude = standard plugin; Codex = project-scoped `.codex/agents/*.toml` + `AGENTS.md` + skills. |
| v0.11 | Migrated to **`kensa-cli` v0.15** commands; QA Engineers create cases with atomic `kensa-cli new` (id-range carving gone); removed the PostToolUse `kensa-sync` hook. |
| v0.12 | **Browser QA & routines.** New `kensa-browser` skill + `/run-routine` command + starter routine templates (smoke / form / visual baseline) driving the Kensa-launched Chrome via `kensa-cli browser`. Full `kensa-cli` rename pass; removed the `debug-log` Stop hook and trimmed the memory-checkpoint message. |
| v0.13 | **Schema adaptation & Blueprints.** New `schema-bootstrap-agent` + `/adapt-schema` fit the project schema to a user's existing TMS export (additive; data follows schema, never the reverse), handing off to Kensa's Universal-format importer. New `kensa-blueprints` skill + `/blueprint` command for node-graph automations (`.tms/blueprints/`) with a first-class agent (`prompt`) node that runs `claude`/`codex` inside the flow. |
| v0.14 | **CLI renamed `kensa-cli` → `kensa`.** Dropped the `-cli` suffix across every skill, command, agent, prompt, template, and doc; the `kensa-cli` skill is now the `kensa` skill. Reverts the v0.12 rename. |
| v0.15 | **Base + bundles architecture.** Always-installed base + 12 optional bundles picked at install (analytics, platform knowledge, strategist, source connectors, four automation bundles with `automation-test-lead` / `automation-engineer` / `automation-devops` / `codereviewer` / `git-operator` agents and the `playwright-*` skill family). |
| v0.16 | **Full `kensa` CLI coverage.** New `kensa-mobile` / `kensa-http` / `kensa-results` skills (device, API, automation-result ingestion), export/import documented, core-CLI accuracy fixes. |
| **v0.17 (current)** | **Flow chaining & rigor.** Every command ends with a `✅ Done / ➡️ Next` epilogue; `/next` situation router; `/automate-case`, `/import-results`, `/new-routine`; analysis artifacts consumed automatically by `/new-feature`; Stop hook redesigned (marker file, cross-platform via node, no chat sentinel); review rubric hardened (happy-path-only = send-back, coverage-dimensions gate); unconditional spec review; `exploratory-testing` skill (covers the planned `/explore` ground via charters + tours); test oracles; assumptions ledger. |
| v1.0 (planned) | Fixture registry (`.tms/fixtures/`); defects commands (`/report-bug`, `/triage`) |

---

## License

MIT — see [LICENSE](LICENSE).

## Links

- [INSTALL.md](INSTALL.md) — install by hand (no IDE): Claude marketplace, Codex copy
- [CHANGELOG.md](CHANGELOG.md) — version history
- [Kensa](https://kensa.dev) — the TMS format this plugin targets
- [Claude Code](https://docs.claude.com/claude-code) — the host environment
