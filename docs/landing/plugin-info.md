# kensa-qa — plugin info for landing page

Source of truth for the "plugin" section of the IDE landing. Pulled from `README.md`, `INSTALL.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and the in-repo `plugin-overview.html`. Use as a fact sheet — not as ready copy.

---

## 1. Identity

| Field | Value |
|---|---|
| Name | `kensa-qa` |
| Current version | `0.7.0` (released 2026-05-31) |
| License | MIT |
| Author | Roman Pluzhnikov — https://github.com/rpluzhnikov |
| Repo | https://github.com/rpluzhnikov/QA_agents |
| Host environment | Claude Code (CLI / desktop / web / IDE extensions) |
| Marketplace install slug | `kensa-qa@rpluzhnikov` |
| Marketplace source | `rpluzhnikov/QA_agents` (the repo is its own single-plugin marketplace) |
| Target format | Kensa TMS — plain markdown under `.tms/suites/` |

## 2. One-line descriptions

From `plugin.json` (`description` field):

> ISTQB CTFL v4.0.1-grounded manual QA team in your pocket — `test-lead-agent` + `qa-engineer-agent` for test case authoring, plus read-only SDLC analysis commands (spec review, risk, test plan, traceability) for Kensa TMS.

From the README hero:

> Point at a ticket. Get a coverage checklist and a folder of manual test cases — written in your project's style, ready to commit.

## 3. What it is

A multi-agent Claude Code plugin that authors **manual** test cases. The user points it at a ticket reference (Linear, Jira, Confluence, Notion, Figma, or raw pasted text); the plugin reads project memory, pulls the spec via MCP, plans coverage, asks the user to approve the plan, spawns workers to write checklists and then case files, reviews their work twice, and commits markdown into the project's `.tms/suites/` tree.

It writes test cases. It does **not** execute them, automate them, or replace a test runner. Output is plain markdown + YAML — readable, editable, committable.

As of v0.7 it also covers the surrounding SDLC with **read-only analysis commands** — pull SOT context, statically review a spec for defects, assess product risk, draft a test plan, semantically deep-audit the case base, and build a requirements→cases traceability matrix. These write no cases; each emits one markdown artifact under `.tms/reports/`.

## 4. Target users

**Manual QA / test leads.** They use the plugin to compress the most repetitive part of their job: turning a freshly-written ticket into a coverage checklist plus 10–60 case files in their project's existing style. Cases land already-formatted for Kensa TMS, with frontmatter, `source_id` traceability, and references to shared steps — ready for `git add`.

**QA managers / heads of QA.** They get a defensible QA practice rather than free-form AI output. Every reasoning step the plugin uses cites the ISTQB CTFL v4.0.1 syllabus chapter and learning objective it operationalises, which makes coverage decisions auditable for regulated stakeholders and onboards new testers by example.

## 5. Three modes of use

**Author (`/new-feature <ref>`).** Turn a Linear / Jira / Confluence / Notion / Figma reference — or raw pasted text — into a coverage checklist plus a folder of case files. The main flow.

**Update (`/update-feature <ref>`).** When a spec changes, the Test Lead finds cases by `source_id` in the frontmatter, reads the new spec, and adds / removes / rewrites only what changed. No hand-hunting through the suite.

**Audit (`/audit`).** Read-only health check on a large suite: schema validation, duplicates, stale drafts, orphan shared-steps, tag drift, missing source refs. Output goes to `.tms/reports/audit-YYYY-MM-DD.md`. Opt-in fixes happen per-batch with confirmation.

**Side mode — Brainstorm (`/brainstorm <topic>`).** For strategic questions ("how do we decompose this feature for parallel workers?", "negative-first or boundary-first for 2FA?"), three Strategist agents argue different angles in parallel, cross-review, and produce 2–3 finalists for the user to choose. Saved to `.tms/brainstorms/` so a later `/new-feature` can reference the decision.

## 6. The agents

| Agent | Role | Tools | How invoked |
|---|---|---|---|
| `test-lead-agent` | Plans, coordinates, reviews. The only agent that talks to the user. Triggers management and review skills itself. | `Read, Glob, Grep, Bash, Task, mcp__*` — no `Write` / `Edit`; never writes case files by hand. | Entry point for every slash command. |
| `qa-engineer-agent` | Writes the artifacts. Stage 1: checklist. Stage 2: case `.md` files under `.tms/suites/`. Runs in parallel when surfaces are independent. v0.7 adds a read-only **analyze mode** — inspects a shard of cases / a spec section and returns findings, writing nothing. | `Read, Write, Edit, Glob, Grep, mcp__*` — no `Task` (can't spawn further agents), no `Bash`. | Spawned by Test Lead via `Task` inside `/new-feature`, `/update-feature`, and (analyze mode) `/analyze-cases` / `/traceability --deep`. |
| `strategist` | Argues an assigned axis (Scope / Decomposition / Test strategy / Prioritization / Effort / Maintainability) as the single right answer, then cross-reviews the other two proposals. | `Read, Glob, Grep, mcp__*` — no `Task`, no `Bash`, no file writes. | Spawned in groups of three by Test Lead in `/brainstorm` only. |

## 7. How a run flows (`/new-feature` pipeline)

1. **User** gives the Lead a ticket ref, URL, or pasted spec.
2. **Test Lead** parses the ref, reads `.tms/memory/`, and pulls acceptance criteria from the source-of-truth via MCP.
3. **Test Lead** applies the `scope-analysis` skill, drafts a plan (in / out of scope, decomposition, one or N workers), and shows it to the user. Human gate — nothing spawns until the user signs off.
4. **QA Engineer(s)** run **Stage 1**: produce coverage checklists. **Test Lead** reviews them against `review-rubrics`: approved / approved with notes / send back. Max 2 revision rounds.
5. **QA Engineer(s)** run **Stage 2**: write `.md` case files under `.tms/suites/<area>/`, following `kensa-test-authoring` (byte-exact frontmatter, shared-step references). **Test Lead** reviews again — same three responses, same 2-round cap.
6. **Test Lead** reports back to the user: file list, count, assumptions made, open questions for product. Then runs `/save-memory` to checkpoint any new conventions or shared steps learned this session (with the user's consent, unless `auto_save_learnings: true`).

## 8. Slash commands

| Command | Purpose |
|---|---|
| `/setup` | One-time per project. Interactive: stack, case language, ticket tracker, wiki. Scans existing cases to learn conventions. Writes `.tms/memory/` and `.mcp.json`. |
| `/new-feature <ref>` | Main flow. Pulls spec, plans, user approves, QA Engineers write checklists then cases under `.tms/suites/`. |
| `/update-feature <ref>` | Finds cases by `source_id`, reads new spec, adds / removes / rewrites only what changed. |
| `/brainstorm <topic>` | Three Strategists deliberate in parallel, cross-review, output 2–3 finalists for user to pick. |
| `/audit` | Schema validation, duplicates, drift, tag check across `.tms/`. Read-only by default. |
| `/save-memory` | Capture session learnings to `.tms/memory/learned/`. Auto-runs after authoring on Windows via a Stop hook. |

**Analysis & planning commands (v0.7, read-only — write no cases, output one artifact to `.tms/reports/`):**

| Command | Purpose |
|---|---|
| `/pull-context <ref>` | Gather all SOT content + related cases into a context dossier. Building block for the others. |
| `/review-spec <ref>` | Static review of a requirement (ISO 20246): defects *in the spec* — ambiguity, missing AC, contradictions — graded critical/major/minor with suggested rewrites. |
| `/risk-assess <ref>` | Product risk register: likelihood × impact → level → recommended test depth per area. |
| `/test-plan <epic>` | ISTQB §5.1 test plan; folds in existing risk / context / brainstorm artifacts. |
| `/analyze-cases [scope]` | Semantic deep-audit by a fan-out of 1–N `qa-engineer` workers in analyze mode — contradictions, semantic dupes, coverage gaps, convention drift. Complements the mechanical `/audit`. |
| `/traceability [--deep]` | Requirements→cases matrix from `source_id`; `--deep` maps each acceptance criterion to cases. |

## 9. The skill library

**31 skills total**, auto-loaded from `skills/` via the plugin manifest. **21 are ISTQB CTFL v4.0.1-grounded** — they carry a verbatim grounding block citing the syllabus chapter, section, and learning objective (FL-X.Y.Z) they teach. **10 are plugin tooling** — they don't contradict ISTQB but aren't derived from it; they carry a "non-ISTQB tooling" disclaimer at the top of their `SKILL.md`.

| Sector | Skills | ISTQB ref |
|---|---|---|
| 🟦 Foundation | `testing-fundamentals` | Ch 1 |
| 🟦 Test Design | `test-design-techniques`, `white-box-techniques-overview`, `collaboration-based-approaches`, `negative-and-edge-cases`, `test-case-writing-craft`, `checklist-design` | Ch 4 |
| 🟩 Test Management | `test-planning`, `risk-based-testing`, `scope-analysis`, `review-rubrics`, `test-monitoring-control-completion`, `defect-management` | Ch 5 + §3.2 |
| 🟨 Static & Lifecycle | `sdlc-and-test-lifecycle`, `static-testing-reviews` | Ch 2 + 3 |
| 🟪 Platform | `web-testing`, `mobile-testing`, `backend-api-testing`, `security-testing`, `test-tools-and-automation-overview` | §2.2.2 / Ch 6 |
| 🟥 Tooling (non-ISTQB) | `kensa-cli`, `kensa-test-authoring`, 5 × `sot-*`, `figma-use`, `sequential-thinking`, `task-assignment`, `clarification-protocol` | — |

**What "ISTQB CTFL v4.0.1 grounded" means in practice.** When the Test Lead or a QA Engineer applies a technique — boundary value analysis, decision tables, risk-based prioritization, defect reporting — it can name the syllabus authority for that decision. Every test case the plugin writes is a worked example of one or more CTFL learning objectives, which makes the reasoning auditable for regulated stakeholders and lets newcomers learn ISTQB by reading the output.

## 10. Sources of truth (MCP)

| Source | Auth | MCP transport | Skill |
|---|---|---|---|
| Linear | Browser OAuth on first use | Remote SSE — `mcp.linear.app/sse` | `sot-linear` |
| Jira | Browser OAuth (Atlassian Cloud) | Shared `atlassian` server — `mcp.atlassian.com` | `sot-jira` |
| Confluence | Browser OAuth (same Atlassian server) | `mcp.atlassian.com`; `/setup` runs CQL discovery for canonical spec pages | `sot-confluence` |
| Notion | Browser OAuth | `mcp.notion.com` | `sot-notion` |
| Figma | Local socket — requires Figma desktop with Dev Mode MCP enabled | `127.0.0.1:3845` (read); writes via separate write-capable Figma MCP | `sot-figma`, `figma-use` |

**No API tokens.** OAuth opens a browser tab on first connect. External servers are written to `.mcp.json` in the project root by `/setup`.

**One bundled MCP — `sequential-thinking`.** Declared inside `plugin.json`, started automatically via `npx -y @modelcontextprotocol/server-sequential-thinking`. No credentials. Powers the `sequential-thinking` skill used for hard scope and edge-case decisions.

## 11. What lands on disk

Everything the plugin learns or writes lives in plain markdown / YAML under the project's `.tms/` directory. Read, edit, commit.

```
<your-project>/.tms/
├── memory/
│   ├── project.md         ← what the project is, stack, types of testing  (user)
│   ├── conventions.md     ← how cases are written here                    (user)
│   ├── glossary.md        ← domain terms, translations                    (user)
│   ├── sot.yaml           ← source-of-truth config                        (/setup-written, hand-edited)
│   └── learned/
│       ├── patterns.md
│       ├── shared-steps.md
│       └── tags.md                                                        (plugin-written, user reviews)
├── suites/                ← test cases, organized by feature              (plugin-written)
├── shared-steps/          ← reusable step sequences                       (plugin-written)
├── reports/               ← /audit + analysis command artifacts            (committed)
├── brainstorms/           ← /brainstorm finalists                         (committed)
└── debug/                 ← per-session digest + transcript snapshot      (gitignored by /setup)
```

External MCP server configs are written to `.mcp.json` at the project root, not inside `.tms/`.

## 12. Install

Inside Claude Code:

```
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov
```

Then **fully restart Claude Code** (not a new tab) so the manifest, agents, commands, and hooks load.

**Prerequisites:**
- Claude Code installed and signed in.
- Node.js with `npx` on PATH (for the bundled `sequential-thinking` MCP).
- Windows 11 + PowerShell 5.1 for the auto-checkpoint and debug-log Stop hooks. Other OSes work; the hooks silently no-op until the bash port lands (v0.8 roadmap).
- No API keys required — all external sources use browser OAuth on first connect.

Update later: `/plugin marketplace update rpluzhnikov`.

## 13. Differentiators

- **ISTQB CTFL v4.0.1 traceability per skill** — 21 of 31 skills cite the specific chapter and learning objective they operationalise; the other 10 carry an explicit non-ISTQB tooling disclaimer.
- **Two-stage review with hard iteration caps** — workers submit a checklist first, get reviewed, only then write cases; each stage caps at 2 revision rounds before escalating to the user. No runaway loops.
- **Lead is the sole user-facing channel** — workers and strategists can't ask questions directly; they write `GAP:` / `ASSUMPTION:` markers in their output and the Lead decides what to surface.
- **Parallel workers off by default** — the Lead spawns one worker unless surfaces are genuinely independent (UI + API, web + mobile) or > 15 cases with clean separation. Parallelism costs tokens; the default is sequential.
- **Plain-text, git-friendly output** — every artifact (cases, shared steps, memory, reports, brainstorms) is markdown + YAML with byte-exact formatting (`kensa-test-authoring`), so diffs stay clean and the Kensa GUI doesn't churn files on save.

## 14. Version history

| Version | Highlights |
|---|---|
| v0.1 | Lead + Worker, 4 commands, project memory templates. |
| v0.2 | Memory checkpoint protocol. |
| v0.3 | SOT extraction skills; `sequential-thinking`, `figma-use`, `kensa-cli`, `kensa-test-authoring` integrated; `/setup` writes `.mcp.json`. |
| v0.4 | Stop hooks (auto-checkpoint + debug log); marketplace manifest; `INSTALL.md`. |
| v0.5 | `/audit`, `/brainstorm`, Strategist agent, OAuth clarity, Confluence multi-page discovery, pre-seeded tag taxonomy, parallel-worker ID-range allocation, stuck-session detection. |
| v0.6 (2026-05-25) | **BREAKING** — agents renamed to `test-lead-agent` and `qa-engineer-agent`. Full ISTQB CTFL v4.0.1 grounding: 10 new skills (Ch 1, 2, 3, §4.3, §4.5, §5.1, §5.2, §5.3, §5.5, Ch 6); existing 21 skills gain ISTQB citation blocks. Skill library wheel diagram added. |
| **v0.7 (current — 2026-05-31)** | **SDLC coverage** — 6 read-only analysis commands: `/pull-context`, `/review-spec`, `/risk-assess`, `/test-plan` (shift-left) and `/analyze-cases`, `/traceability` (test-base intelligence). `qa-engineer-agent` gains an `analyze` mode for fan-out review. No new agents or skills. |
| v0.8 (planned) | Bash port of hooks (macOS / Linux); fixture registry (`.tms/fixtures/`); exploratory mode (`/explore`); defects commands (`/report-bug`, `/triage`); brainstorm artifact auto-discovery in `/new-feature`. |

## 15. Suggested visuals for the landing

Three rendered PNGs already exist in the repo and can be reused on the landing without re-rendering:

| File | Shows |
|---|---|
| `docs/images/hero.png` | Hero shot — Test Lead plans, QA Engineers write cases. Good for the section header. |
| `docs/images/architecture.png` | How it works — Test Lead coordinates, QA Engineers run in parallel, two-pass review. Good for the "how it works" block. |
| `docs/images/skills-library.png` | The 31-skill library wheel, colour-coded by ISTQB CTFL v4.0.1 chapter affinity. Good for the differentiator / proof block. |

The HTML sources for these (if a re-render is needed) live in `docs/images/source/`.

## 16. Links

- README — `README.md` (full product description, command details, FAQ)
- Install + smoke test — `INSTALL.md`
- Version history — `CHANGELOG.md`
- Technical snapshot of pipeline (Russian, dense) — `plugin-overview.html`
- Kensa TMS — https://kensa.dev
- Claude Code — https://docs.claude.com/claude-code
