# The kensa-qa Bible

> The complete operating reference for the **kensa-qa** plugin — how every part
> works and why it is shaped that way. Audience: the plugin's maintainer and
> anyone extending it. User-facing quickstarts live in `README.md` /
> `INSTALL.md`; this document is the internal source of truth.
>
> Current as of **0.18.0**. When behavior and this document disagree, the code
> (commands / agents / skills / build) wins — then fix this document.

---

## 1. Philosophy and boundaries

kensa-qa is **a manual QA team in a box** for projects whose test cases live as
markdown in a Kensa TMS repository (`.tms/`). It:

- **writes and maintains manual test cases** (author → review → commit loop),
- **analyzes** specs, risk, coverage, and the health of the case base,
- **gathers live evidence** (browser / mobile device / HTTP API) and files
  defects back into `.tms/`,
- optionally **derives automated tests** from manual cases (automation bundles).

It does **not** execute manual test runs for you, replace a test runner, or
manage defects in an external tracker (it drafts them; filing conventions live
in `defect-management`).

Three design invariants shape everything:

1. **The user approves before anything expensive or destructive happens.**
   Plans are confirmed before engineers spawn; fixes are dry-run + per-batch
   confirmed; schema changes are previewed; writes to memory are opt-in.
2. **Nothing is cut silently.** Out-of-scope is always written down (scope
   plans, dimension tables, reports). A dropped negative case is a reviewable
   decision, not an accident.
3. **Every command tells you what to run next.** The epilogue contract
   (`✅ Done / ➡️ Next`) turns 25 commands into a small number of guided
   journeys. Lost? `/next` reads the project state and routes you.

## 2. Architecture

### 2.1 Monorepo layout

```
engines/claude/    Claude Code edition: .claude-plugin/plugin.json, CLAUDE.md,
                   agents/*.md, commands/*.md
engines/codex/     Codex edition: .codex-plugin/plugin.json, AGENTS.md,
                   .codex/agents/*.toml, .codex/prompts/kensa-*.md
shared/            engine-agnostic payload: skills/*/SKILL.md, hooks/, templates/
catalog.json       SOURCE OF TRUTH for base/bundle membership (logical names)
engines.json       the Kensa-app install contract (engine sources + bundle list)
scripts/build.ps1  assembles dist/<engine>/{base,bundles/<id>} + validates
scripts/build.sh   POSIX twin — keep in parity with build.ps1
dist/              committed build output; what installers actually copy
```

**Logical-name convention:** a command `x` = `engines/claude/commands/x.md` +
`engines/codex/.codex/prompts/kensa-x.md`; an agent `y` = `agents/y.md` +
`.codex/agents/y.toml`; a skill `s` = `shared/skills/s/`. Every capability
exists in BOTH engines or in neither.

### 2.2 Base + bundles

The **base** is always installed: 3 agents (test-lead, qa-engineer,
schema-bootstrap), 11 commands, 26 skills (ISTQB author/review loop + the
kensa-* tooling family), the Stop hook, and the bundled `sequential-thinking`
MCP declaration (Claude engine).

**12 optional bundles** add capability groups (all `default: false`):

| Bundle | Adds |
|---|---|
| `qa-analytics` | 6 read-only commands: pull-context, review-spec, risk-assess, test-plan, analyze-cases, traceability |
| `platform-testing` | web / mobile / backend-api / security ISO-25010 checklist skills |
| `strategist` | strategist agent + /brainstorm + sequential-thinking skill |
| `automation-playwright-ts` | automation-test-lead + automation-engineer, 10 playwright-* skills, 7 commands (incl. /automate-case) |
| `automation-devops` | automation-devops agent + 3 ci-* skills (no commands — reached via routing) |
| `automation-codereview` | codereviewer agent + 2 skills (reached via automation-test-lead routing) |
| `automation-git` | git-operator agent + 2 skills (same) |
| `sot-linear/jira/confluence/notion/figma` | one extractor skill each (figma also gets figma-use) |

Rule enforced across all prompts: **never assume a bundle is present**. If a
command/agent/skill from a bundle would help, either use it (installed) or name
the bundle for the user to add. Never improvise the capability.

### 2.3 Build pipeline

`pwsh scripts/build.ps1` (or `scripts/build.sh`):

1. wipes `dist/<engine>` and copies engine-specific base files (excluding the
   membership-filtered dirs),
2. copies base agents/commands/skills per `catalog.json`, plus `shared/hooks`
   and `shared/templates`,
3. deletes `hooks/hooks.json` from the **Claude** base (the Claude hook is
   registered inline in `plugin.json`; shipping hooks.json too would double-fire)
   — hooks.json is the **Codex** registration,
4. assembles each bundle directory,
5. **validates**: every shared skill mapped exactly once; manifests parse with
   a version; hook scripts present (`save-memory-stop.js`, `.sh`, `.ps1`);
   Claude manifest contains a Stop hook; codex `.toml` agents carry
   `name`/`description`/`developer_instructions`; every bundle produced a dir.

`dist/` is committed. The Kensa app installs `dist/<engine>/base` always and
each selected bundle on top (see `engines.json`).

## 3. The agents

### 3.1 Base team

**`test-lead-agent`** — the only agent that talks to the user; entry point for
every base and analytics command. Plans scope, spawns engineers, reviews in two
passes, reports. Hard rules: reads `.tms/memory/project.md` + `conventions.md`
at session start; **always** runs the `static-testing-reviews` pre-write
checklist against the spec and puts a quoted **Spec defects** block in the plan
(even when empty); never writes cases itself (beyond 1-2 trivial); never
accepts engineer output unreviewed; never cuts scope silently. Defaults to ONE
engineer; parallelizes only for genuinely independent surfaces / >15 cases /
explicit user ask. `kensa new` allocates ids atomically, so parallel engineers
need no id coordination.

**`qa-engineer-agent`** — writes checklists (Stage 1) then cases (Stage 2)
from a narrow brief; also has a read-only **analyze** mode (returns structured
findings, writes nothing) used by /analyze-cases, /traceability --deep, and
large /review-spec. Cannot talk to the user. Carries the **adversarial
mandate**: assume the spec author forgot the unhappy paths; ≥1-2 negatives per
positive flow (AC → 1 positive + 1-2 negatives); >70% happy-path needs written
justification; re-runs the error-guessing taxonomy as a final Stage-2 sweep.
Marks unknowns `ASSUMPTION:` / `GAP:` — silent guessing is a defect. Stage 2
creates every case via `kensa new` (never hand-written files/ids) and authors
bodies byte-exact per `kensa-test-authoring`.

**`schema-bootstrap-agent`** — one job: additively adapt `.tms/schema.yaml` to
a foreign TMS export (1-2 samples), preview before apply, signal
`kensa adapt ready`, hand off. Imports nothing — the user loads the export via
the GUI's Universal-format importer ("data follows schema, never the reverse").
Flags contradictions between samples with `GAP:` instead of silently
reconciling.

### 3.2 The two-pass review loop (the quality engine)

```
brief → engineer Stage 1 (checklist) → Lead review (checklist rubric)
      → approved → engineer Stage 2 (cases) → Lead review (case rubric)
      → approved → report to user
```

- Outcomes per pass: approve / approve-with-notes / send-back. **Cap: 2
  revision rounds**, then escalate to the user with a concrete question.
- **Checklist rubric critical criteria** (any ❌ = send-back): coverage, scope
  adherence, **negative scenarios**, **edge cases**, references, **the
  coverage-dimensions table**. A happy-path-only checklist is never approvable.
- **The Coverage Dimensions Gate**: every checklist ends with a fixed table —
  negative/validation · boundaries · state transitions · permissions/roles ·
  concurrency/idempotency · interruption/recovery · i18n/locale/timezone ·
  data lifecycle · non-functional flags — each row covered(refs) /
  out-of-scope(reason) / N/A(why). Blank row = automatic send-back.
  Out-of-scope rows are copied into the user report.
- Case rubric sends back on: checklist items not implemented, recurring
  anatomy/title/step defects, or approved negatives dropped.
- Priorities: a negative of a must-have flow inherits the flow's priority.

### 3.3 Automation team (bundles)

**`automation-test-lead`** — strategy: candidacy rubric (automate-or-not, with
explicit do-NOT-automate signals), layer selection (unit/integration/contract/
E2E — lowest faithful layer), `@KEN-<id>` traceability governance, anti-flake
policy. Briefs carry **negative/edge parity** (which negative rows of the case
must be automated); review checks **coverage adequacy vs the case's steps**.
Routes to sibling bundles when installed: review pass → `codereviewer`;
landed work → `git-operator`; CI → `automation-devops`.

**`automation-engineer`** — writes the code. Derives scenarios BEFORE code
(greenfield happy-path-only spec files must justify themselves); tags with the
structured `{ tag: '@KEN-<id>' }` form; **runs what it wrote** and reports real
output — unverified green is forbidden.

**`automation-devops` / `codereviewer` / `git-operator`** — agent-only bundles
reached through routing and epilogues (no commands of their own): CI wiring,
test-code review (reliability > traceability > maintainability > isolation),
atomic conventional commits (never push, never commit failing/unreviewed work).

**`strategist`** (strategist bundle) — one of three parallel debaters in
/brainstorm; argues ONE assigned axis hard (hedging wastes the slot), grounds
numbers via read-only `kensa stats/coverage/list`, then a cross-review round;
the Lead synthesizes.

## 4. Commands — the journey map

### 4.1 Catalog

**Base (11):** `/next` · `/setup` · `/new-feature <ref>` · `/update-feature
<ref>` · `/audit [scope]` · `/run-routine [RT-id]` · `/new-routine [name]` ·
`/blueprint [sub]` · `/adapt-schema [samples]` · `/import-results <report>` ·
`/save-memory`

**qa-analytics (6):** `/pull-context` · `/review-spec` · `/risk-assess` ·
`/test-plan` · `/analyze-cases` · `/traceability [--deep]`

**strategist (1):** `/brainstorm <topic>`

**automation-playwright-ts (7):** `/automate-case <id>` ·
`/scaffold-playwright` · `/add-auth-setup` · `/add-page-object` ·
`/add-visual-test` · `/add-a11y-test` · `/fix-flake <spec>`

(Codex engine: same set, prefixed `/kensa-`.)

### 4.2 The routing table (who points where)

Every command ends with the epilogue block; these are the canonical routes:

```
setup ─────────────→ new-feature · run-routine · (adapt-schema for migrations)
adapt-schema ──────→ GUI Universal import → setup(update) → audit
new-feature ───────→ traceability · audit · automate-case
update-feature ────→ traceability · audit
audit ─────────────→ analyze-cases · update-feature · traceability
analyze-cases ─────→ update-feature / new-feature · re-audit
pull-context ──────→ review-spec · risk-assess · new-feature · update-feature(supersedes)
review-spec ───────→ risk-assess / new-feature (pass) · product (needs-rework)
risk-assess ───────→ new-feature (depth applied) · test-plan
test-plan ─────────→ new-feature × N
traceability ──────→ new-feature (gaps) · update-feature (dangling refs)
brainstorm ────────→ new-feature (points at the artifact)
run-routine ───────→ re-run · new-routine · save-memory
new-routine ───────→ run-routine
blueprint ─────────→ new → validate → run → .tms/runs/
import-results ────→ @KEN write-backs · traceability · automate-case
scaffold-playwright→ add-auth-setup → add-page-object → automate-case; CI → @automation-devops
add-page-object ───→ automate-case · add-visual-test
add-auth-setup ────→ add-page-object · automate-case
add-visual/a11y ───→ fix-flake · automate-case
fix-flake ─────────→ @automation-devops (gating) · @codereviewer (systemic)
automate-case ─────→ next case · visual/a11y · import-results; @codereviewer/@git-operator
save-memory ───────→ next
next ──────────────→ (the router itself)
```

**The handover contract:** analysis commands write artifacts to
`.tms/reports/` (`context-<ref>-<date>.md`, `spec-review-…`, `risk-…`,
`test-plan-…`) and `/brainstorm` to `.tms/brainstorms/`; **`/new-feature` and
`/update-feature` read them automatically** for their ref (newest wins) instead
of re-gathering, and say which artifacts they used. This is what makes the
shift-left pipeline an actual pipeline.

### 4.3 Preflight contracts

Uniform checks, fail-fast with a pointer:

- memory missing → "run `/setup` first", stop (exceptions: `/setup` itself;
  `/adapt-schema`, which legitimately runs pre-setup on migrations; `/next`,
  which reports it as a finding).
- `kensa` CLI missing → stop, in every command that drives it (authoring,
  audit/analytics, blueprint, run-routine, import-results, automate-case).
- `/audit` and `/analyze-cases`: <20 cases → too small, stop (validate/lint
  cover the basics).
- automation commands: no Playwright project → "run `/scaffold-playwright`
  first", stop.
- browser work: Chrome not reachable (exit 2) → "Tools → Browser → Start",
  stop; agents never launch their own browser.

### 4.4 Human gates & read-only matrix

Gates (wait for explicit user confirmation): plan approval before spawning
engineers (new/update-feature); per-batch dry-run confirmation for every fix
phase (audit, analyze-cases); scaffold overwrite; `.mcp.json` writes and
CLAUDE.md merges in /setup; defect-case creation from live evidence;
`--allow-scripts` on blueprint runs; memory writes (unless
`auto_save_learnings: true`); `automated` tag application.

Read-only by contract: next, pull-context, review-spec, risk-assess, test-plan,
brainstorm, traceability; audit/analyze-cases read-only by default with the
opt-in fix phase. Writers: new/update-feature (cases), save-memory (memory +
ledger), setup (memory, .mcp.json, routines), adapt-schema (schema.yaml only),
run-routine (evidence + optional defect cases), import-results (runs + optional
cases + tags), blueprint (BP files, runs), the automation commands (project
code), new-routine (one RT file).

## 5. Skills — the knowledge base

54 skills in `shared/skills/`. Load-on-demand, never front-load. Groups:

- **ISTQB reasoning (base)** — testing-fundamentals, sdlc-and-test-lifecycle,
  test-design-techniques (EP/BVA/decision tables/state transitions/pairwise/
  CRUD×roles×states), negative-and-edge-cases (taxonomy error guessing),
  exploratory-testing (charters + tours), checklist-design (incl. the
  dimensions gate), collaboration-based-approaches, white-box-overview,
  test-case-writing-craft (incl. test oracles), scope-analysis, test-planning,
  risk-based-testing, review-rubrics, static-testing-reviews,
  test-monitoring-control-completion, defect-management,
  test-tools-and-automation-overview. Every one carries an ISTQB CTFL v4.0.1
  grounding block (chapter + FL-x.y.z learning objectives).
- **Process glue (base, non-ISTQB)** — task-assignment (brief schemas),
  clarification-protocol (ask vs assume).
- **kensa tooling (base)** — kensa (CLI reference), kensa-test-authoring
  (byte-exact on-disk format — the authority for file writing),
  kensa-browser / kensa-mobile / kensa-http (live evidence, observe→act,
  write-back loop), kensa-results (report ingestion, match chain,
  `@KEN` write-back), kensa-blueprints (node graphs, validate-before-run).
- **Bundles** — platform checklists (web/mobile/api/security), sot-* extractors
  (+ figma-use), sequential-thinking, the playwright-* family (hub:
  playwright-typescript; spokes: locators, fixtures-and-pom,
  waiting-and-assertions, auth-storagestate, test-data, parallel-and-sharding,
  reporting-and-traces, ci-docker, visual-and-a11y), ci-* devops trio,
  test-code-review-standards + test-flakiness-governance, ken-traceability +
  case-test-sync.

Conventions that keep the library coherent:

- `source_id` = **external** tracker ref only; internal case cross-links use a
  `related-<case-id>` tag.
- The case↔test link is the structured `{ tag: '@KEN-<id>' }` — never a title
  token.
- Memory paths are always written in full (`.tms/memory/learned/patterns.md`).
- Filter DSL: `tag=x` (never `tag:x`), `modified` (never `mtime`).
- `generated_by: kensa-qa@<plugin version>` — placeholder, not a pinned number.

## 6. Memory and the Stop hook

### 6.1 Project memory (`.tms/memory/`)

`project.md` (facts + `auto_save_learnings` flag) · `conventions.md` (how cases
are written here) · `glossary.md` · `sot.yaml` (which SOT, which workspaces,
`on_unresolved_ref`) · `learned/{patterns,shared-steps,tags}.md` (appended by
save-memory with dated comments). Lead reads project+conventions every session.
Templates in `shared/templates/`, instantiated by `/setup`.

### 6.2 The memory-checkpoint protocol (marker file, since 0.17.0)

```
/new-feature | /update-feature
   plan approved → CREATE .tms/.pending-checkpoint  (empty file)
   …work…
   Step 9/7: run save-memory protocol → DELETE the marker
Stop hook (every turn end):
   stop_hook_active? → allow      (anti-loop; CC force-stops after 8 blocks)
   marker absent?    → allow      (the normal case — hook is silent)
   marker present    → block once with a reason instructing save-memory + delete
```

- Claude registration: inline in `.claude-plugin/plugin.json`, exec form —
  `node ${CLAUDE_PLUGIN_ROOT}/hooks/save-memory-stop.js` (node is already a
  plugin dependency via the npx-launched MCP). Codex registration:
  `shared/hooks/hooks.json` → `.sh` (POSIX) / `.ps1` (`commandWindows`).
- There is **no chat sentinel** and **no transcript scanning** — mentioning
  command names (e.g. in epilogues) can never re-arm the hook.
- `save-memory` also sweeps `ASSUMPTION:`/`GAP:` markers into
  `.tms/reports/assumptions-<ref>-<date>.md` — the standing questions-to-PM
  ledger.
- `/setup` gitignores the marker. If the hook ever misbehaves, deleting the
  marker always releases it; the hook fails open on any internal error.

## 7. The `kensa` CLI surface (what agents actually call)

| Area | Verbs |
|---|---|
| Orient | `list [--tree]`, `find`, `stats`, `show <id>` |
| Author | `new --suite … --title … [--priority --status --tag… --source-id]` (atomic ids), `update <id> --set/--add-tag/--remove-tag`, `bulk update/add-tag/remove-tag/move/delete --filter … --dry-run/--yes` |
| Health | `validate` (exit 3 = violations), `lint`, `doctor`, `duplicates --threshold`, `stale --days`, `gaps --against source|shared-steps`, `coverage --by-tag|--by-source|--by-suite [--uncovered]`, `sync --quiet` |
| Filter DSL | `tag=x`, `status = draft`, `modified > 30d`, `suite=auth`, `source_id != ""` — used by filter/bulk/context/export |
| Context | `context bundle --filter …` (token-budgeted case reading), `shared-step list/usage/orphan` |
| Schema | `schema show/preview/apply/migrate`, `adapt ready` (writes the GUI sentinel) |
| Evidence | `browser …` (CDP into Kensa-launched Chrome), `mobile …` (ui→tap/type/swipe, re-ui after transitions), `http …` (collections, envs, `{{var}}`) |
| Results | `results ingest <report> [--report-format] [--match]` → matched/orphaned, run in `.tms/automation-runs/` |
| Blueprints | `blueprint list/show/new/validate/run [--allow-scripts]` — always validate before run |
| Export/Import | `export` (profiles), `import --dry-run` (mapping report) |

Exit-code convention (browser/mobile/http): `0` ok · `1` runtime failure
(retry once / report state) · `2` usage-config error (fix the invocation, don't
retry verbatim). `validate` exit `3` = violations (a signal, not an abort).

## 8. Journeys end-to-end

1. **First-time setup → first feature**: install → `/setup` (interview, memory,
   .mcp.json, optional routines, optional CLAUDE.md merge) → restart for MCP →
   `/new-feature <ref>` (spec attack → plan+gate → engineers → 2-pass review →
   report → auto save-memory) → `/traceability` → periodic `/audit`.
2. **Shift-left pipeline** (qa-analytics): `/pull-context` → `/review-spec` →
   `/risk-assess` → `/test-plan` → `/new-feature` × N (reads all artifacts) →
   `/traceability`. Every hop suggested by the previous epilogue.
3. **Spec changed**: `/pull-context` flags *supersedes* → `/update-feature`
   (finds by source_id/tags/glossary; update/delete/split/keep per case).
4. **Base health**: `/audit` (mechanical) → `/analyze-cases` (semantic fan-out)
   → fixes via `/update-feature` / opt-in batch phase → re-`/audit`.
5. **TMS migration**: `/adapt-schema samples...` (additive schema fit,
   `adapt ready`) → GUI Universal import → `/setup` update-mode (learn
   conventions from imported cases) → `/audit` baseline.
6. **Live evidence**: `/run-routine RT-001` (or exploratory charter via the
   `exploratory-testing` skill) → evidence to `.tms/attachments/` → defect
   cases with `related-<id>` tags → `/new-routine` to capture new scenarios.
7. **Automation adoption**: `/scaffold-playwright` → `/add-auth-setup` →
   `/add-page-object` → `/automate-case <KEN-id>` × N → `/add-visual-test` /
   `/add-a11y-test` → `/fix-flake` when needed → CI via `@automation-devops` →
   `/import-results <report>` each CI run to keep case↔test sync.
8. **Contested strategy**: `/brainstorm <topic>` (3 strategists × 2 rounds →
   comparison artifact) → user decides → `/new-feature` pointing at it.
9. **Coming back cold**: `/next`.

**Troubleshooting quick refs:** hook blocks unexpectedly → delete
`.tms/.pending-checkpoint`. MCP tools absent after /setup → restart Claude Code
(servers start on launch). `kensa` exit 2 → invocation/config wrong, don't
retry verbatim. Bundle command "not found" → the bundle isn't installed.
Browser unreachable → start Chrome from Kensa Tools → Browser.

## 9. Contributor conventions (how to extend without breaking the shape)

**Adding a command** — checklist:
1. `engines/claude/commands/<name>.md` — frontmatter (`description`,
   `argument-hint`), preflight block, human gates where writes happen,
   the memory-checkpoint stance (owes one? almost certainly not), an
   **Epilogue (required)** section with routes from §4.2.
2. `engines/codex/.codex/prompts/kensa-<name>.md` — compact mirror, `/kensa-`
   prefixed routes.
3. `catalog.json` — add to `base.commands` or a bundle's `commands`.
4. Update `engines.json` verify text if base, `CLAUDE.md` + `AGENTS.md`
   command maps, README table, this file's §4.
5. `pwsh scripts/build.ps1` must pass.

**Adding an agent**: `.md` + `.toml` (with `name`/`description`/
`developer_instructions`), catalog entry, and — critically — a **door**:
either a command entry point or a routing note in the agent that spawns it.
Agent files without doors are dead weight (the 0.16 codereviewer/git-operator
lesson).

**Adding a skill**: `shared/skills/<name>/SKILL.md`; `name:` matches the dir;
description carries concrete "load when…" triggers; ISTQB grounding block for
reasoning skills, the "Non-ISTQB tooling" block otherwise; add to exactly one
place in catalog.json; cross-link siblings both ways; obey the conventions in
§5 (paths, tags, filter DSL, no version pins, no engine-specific file paths in
shared skills).

**Prompt style rules** (learned the hard way): bundle references always
carry an "if installed" guard; worker spawns name the agent exactly
(`qa-engineer-agent`, not `qa-engineer`); CLI examples must use flags that
exist (check `shared/skills/kensa/SKILL.md` first); no raw control characters
in skill files (`\x00` as text, not a NUL byte); rubric changes must keep
negatives/edges/dimensions **critical** — that is the plugin's spine.

**Release**: bump version in both engine manifests + `engines.json` →
CHANGELOG entry → build → verify dist smoke checks (hook = node js; zero
`memory-checkpoint: done` matches; new files present) → commit source + dist.
