# Changelog

All notable changes to **kensa-qa**. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.14.0 -- 2026-06-19

CLI renamed back to **`kensa`** — the `-cli` suffix is dropped everywhere, reverting the
v0.12 rename to `kensa-cli`.

### Changed

- **`kensa-cli` → `kensa` everywhere.** Every CLI invocation across all skills, slash
  commands, agents, Codex prompts, routine templates, and docs now reads `kensa` (e.g.
  `kensa new`, `kensa filter`, `kensa browser`). No behavior change — pure rename.
- **The `kensa-cli` skill is now the `kensa` skill** (`shared/skills/kensa-cli/` →
  `shared/skills/kensa/`, `name: kensa`). All "the `kensa-cli` skill" cross-references in
  other skills, agents, and docs updated to "the `kensa` skill".
- Bumped version to `0.14.0` in `engines.json`, both engine `plugin.json` manifests, and
  the marketplace manifest; `generated_by` stamps now read `kensa-qa@0.14.0`.

### Fixed

- **Claude Stop hook double-firing / `No such file` error.** The Claude build shipped
  both the inline `plugin.json` Stop hook (correct, `${CLAUDE_PLUGIN_ROOT}`) **and** the
  shared `hooks/hooks.json` (Codex-only, `$PLUGIN_ROOT`). Claude Code auto-discovered the
  latter and ran the hook twice — the second with an unset `$PLUGIN_ROOT`, failing with
  `sh: /hooks/save-memory-stop.sh: No such file or directory`. The build (`build.sh` +
  `build.ps1`) now drops `hooks/hooks.json` from the Claude artifact (Claude registers the
  hook inline; only the scripts ship), and validation guards against the stray file
  reappearing. Codex is unchanged — it still registers via `hooks/hooks.json`.

## 0.13.0 -- 2026-06-15

Schema adaptation for onboarding foreign TMS exports, and **Blueprints** — node-graph
automations with a first-class agent node. Integrates `SCHEMA-ADAPTATION-AND-BLUEPRINTS.md`.

### Added — schema adaptation (Part A)

- **New `schema-bootstrap-agent`** (Claude `agents/schema-bootstrap-agent.md` + Codex
  `.codex/agents/schema-bootstrap-agent.toml`): reads 1–2 of the user's real case files
  from a foreign TMS export and adapts the project schema *additively* to fit them, then
  hands off. Principle: **data follows schema, never the reverse** — it imports no cases
  and never deletes/rewrites existing fields unless asked.
- **New `/adapt-schema` command** (Claude `commands/adapt-schema.md` + Codex
  `kensa-adapt-schema.md`): resolves sample files, delegates to the bootstrap agent,
  reviews the proposed mapping, and points the user at Kensa's **Universal format**
  importer for the actual (deterministic, schema-preserving) import.
- **Extended the `kensa-cli` skill** with the schema surface: `schema show`,
  `schema preview`, `schema apply`, `schema migrate`, and `adapt ready`, plus the
  adapt-with-AI flow, the agent contract, and an `/adapt-schema` recipe.

### Added — Blueprints (Part B)

- **New `kensa-blueprints` skill** (skill #33): node-graph automations at
  `.tms/blueprints/BP-NNN.json` run by the Rust engine — exec/data pins, the node-family
  catalog, `${...}` context references, the agent (`prompt`) node two-file handshake, the
  `kensa-cli blueprint new/list/show/validate/run` CLI, the frozen validation codes, and
  the security model (engine/shell allow-lists, project-root confinement, secret handles).
- **New `/blueprint` command** (Claude `commands/blueprint.md` + Codex
  `kensa-blueprint.md`): `list | show | new | validate | run` over project blueprints,
  always validating before a run and respecting the consent gate on script/agent nodes.

### Changed — wiring

- Wired both new capabilities into the operating manuals (Claude `CLAUDE.md` + Codex
  `AGENTS.md`) and the `test-lead-agent` (Claude `.md` + Codex `.toml`): the Lead routes
  `/adapt-schema` to the bootstrap agent and drives `/blueprint`.
- All new CLI commands documented as `kensa-cli <verb>` (the canonical name), not bare `kensa`.

### Bumped

- All manifests (`engines.json`, both `plugin.json`, `marketplace.json`) to `0.13.0`;
  `generated_by` stamp to `kensa-qa@0.13.0`. Counts updated: **15** commands/prompts,
  **33** skills, **4** agents (added `schema-bootstrap-agent`).

## 0.12.0 -- 2026-06-04

Browser-driven QA + routines, a full `kensa-cli` rename pass, and a quieter hook setup.

### Added — browser QA & routines

- **New `kensa-browser` skill** (skill #32): the `kensa-cli browser` verb set
  (navigate / interact / capture / inspect / eval / wait / diagnostics), the
  connect→act→disconnect CDP model, loopback-only + throw-away-profile guardrails,
  exit-code branching (`1` retry/report, `2` fix/launch), and the loop that writes
  browser findings back into `.tms/` cases.
- **New `/run-routine` command** (Claude `commands/run-routine.md` + Codex
  `kensa-run-routine.md`): resolves an `RT-*` routine from `.tms/routines/`,
  preflights the browser, executes the scenario, and reports evidence / files
  defect cases.
- **Starter routine templates** under `templates/routines/` (`RT-001` smoke tour,
  `RT-002` form submission, `RT-003` visual baseline). `/setup` can seed them into
  `.tms/routines/` for web projects.
- Wired the skill into both agents (Claude `.md` + Codex `.toml`) and the Codex
  `AGENTS.md`: the Test Lead assigns browser QA / runs `/run-routine`; the QA
  Engineer drives the browser and writes findings back.

### Changed — `kensa-cli` is the one canonical CLI name

- Every bare `kensa <verb>` CLI invocation across docs, skills, agents, and the new
  browser content now reads `kensa-cli`. `BROWSER_AND_ROUTINES.md` §1 was rewritten:
  the agents always call `kensa-cli` (the in-app `kensa` PATH alias is noted but not
  relied on, since agents run in the host process).

### Removed — the `debug-log` Stop hook

- Dropped the per-session `debug-log` hook (entry + `debug-log.{ps1,sh}`) that wrote
  `.tms/debug/` digests and transcript snapshots. The lone remaining Stop hook is the
  memory checkpoint; its block message was trimmed from ~20 lines to a 3-line
  reminder so it no longer dumps a wall of text on stop. Removed from both
  `engines/claude/.claude-plugin/plugin.json` and `shared/hooks/hooks.json`.

### Bumped

- All manifests (`engines.json`, both `plugin.json`, `marketplace.json`) to `0.12.0`;
  the `generated_by` case stamp to `kensa-qa@0.12.0`. Skill count 31 → 32, slash
  commands 12 → 13.

## 0.11.0 -- 2026-06-02

Migrated the plugin to the new `kensa-cli` (v0.15.0 workspace) commands.

### Added — `kensa-cli new` atomic case creation

- **QA Engineers now create cases with `kensa-cli new`** (`--suite … --title … --priority …
  --tag … --source-id … --format json`) instead of hand-writing `.md` files and hand-allocating
  ids. `new` atomically allocates the next id (reconciles the counter like `sync`, formats per
  `id_format`) and returns `{id, path, suite, status}`; the engineer then edits the returned file
  to author the `## Steps` body. Documented in the `kensa-cli` and `kensa-test-authoring` skills.
- Because allocation is atomic, **id-range carving is gone**: `/new-feature` Step 4.5, the
  `id_range` brief field (`task-assignment` skill), and the "Test Lead writes back `next_id`"
  bookkeeping were removed. Parallel engineers can no longer collide. The Claude
  `qa-engineer-agent` gained the `Bash` tool so it can invoke `kensa-cli` directly.

### Added — new traceability / coverage axes

- `/traceability` and `/audit` now list **untraced cases** via `kensa-cli gaps --against source`
  (absent/empty `source_id`) instead of a hand-rolled `filter 'source_id = ""'`.
- `/audit` now flags **empty suites** via `kensa-cli coverage --by-suite --uncovered`.
- Documented that `kensa-cli find` now searches **step/notes/section bodies** (not just
  title/tags) and returns a `match_field`, and that `bulk update --set` is **repeatable**.

### Removed — the PostToolUse `kensa-sync` hook

- The auto-sync hook existed only to repair the id counter after agent-authored case files.
  With atomic `kensa-cli new`, that is unnecessary — the hook was removed from
  `engines/claude/.claude-plugin/plugin.json` and `shared/hooks/hooks.json`, and
  `shared/hooks/kensa-sync.{ps1,sh}` were deleted. `kensa-cli sync` is now a **periodic
  safety/repair** step, run as a preflight by `/audit` and `/traceability` (and by hand after
  editing a tree outside the CLI). The two `Stop` hooks (memory checkpoint, debug log) are unchanged.

### Bumped

- All manifests (`engines.json`, both `plugin.json`, `marketplace.json`) to `0.11.0`; the
  `generated_by` case stamp to `kensa-qa@0.11.0`.

## 0.10.0 -- 2026-06-01

### Added — auto-sync of `.tms/` id counters

- **PostToolUse hook (`kensa-sync`).** After an agent writes/edits a case file under
  `suites/` or `.tms/`, the plugin runs `kensa-cli sync --quiet` to recompute the id
  counters in `.tms/config.yaml` (`project.next_id`, `next_shared_step_id`,
  `next_plan_id`) from disk, then a non-fatal `kensa-cli doctor --quiet` advisory
  check. Idempotent and near-instant. Ships as `shared/hooks/kensa-sync.{ps1,sh}`,
  registered for both engines (`engines/claude/.claude-plugin/plugin.json` +
  `shared/hooks/hooks.json`) with the `Write|Edit|MultiEdit` matcher.
- Requires `kensa-cli` on PATH (the hook runs in the agent host process, not Kensa's
  embedded terminal). If absent, the hook no-ops; it also does nothing outside a Kensa
  project (no `.tms/config.yaml`). Documented in `INSTALL.md`.

### Changed

- **CLI renamed to `kensa-cli` in all docs.** Every CLI invocation in the skills,
  commands, and README now uses the real binary name `kensa-cli` (was `kensa`).
  Product/plugin/skill names are unchanged.
- Documented the new `kensa-cli sync` subcommand in the `kensa-cli` skill.

### Bumped

- All manifests (`engines.json`, both `plugin.json`, `marketplace.json`) to `0.10.0`.

## 0.9.0 -- 2026-06-01

### Changed — two clean engines, one monorepo

The plugin is now two focused, self-contained builds (Claude + Codex) assembled
from a single source tree. Distribution is by IDE drop-into-project — there is no
installer and no marketplace step.

- **Repo restructure.** Skills, hooks, and `.tms` templates moved to `shared/`
  (one source of truth, copied into both engines). Engine-specific files moved to
  `engines/claude/` (`.claude-plugin/`, `agents/`, `commands/`) and
  `engines/codex/` (`.codex-plugin/`, `.codex/agents/*.toml`, `.codex/prompts/`,
  `AGENTS.md`).
- **Build step.** `scripts/build.ps1` and `scripts/build.sh` assemble self-contained
  `dist/claude/` and `dist/codex/` (skills materialized inside each), generate a
  per-engine drop README, and validate skill counts + manifests. `dist/` is the
  IDE's download target.

### Removed

- **Hybrid Claude→Codex delegation** — `hooks/codex-detect.{ps1,sh}`,
  `codex/prompts/codex-{worker-package,reviewer,consult}.md`, `templates/codex.yaml`,
  the `codex_role`/`codex_review` logic in the Test Lead, `/new-feature`,
  `/update-feature`, `/setup` (Phase 3.5), and `task-assignment`. `CODEX_INTEGRATION.md`
  deleted.
- **Interactive installer** — `install.ps1`, `install.sh`.

### Distribution

- **Claude marketplace kept** — `.claude-plugin/marketplace.json` now points at
  `./dist/claude`, so the one-liner `/plugin marketplace add rpluzhnikov/QA_agents`
  + `/plugin install` still works (complete: Claude bundles agents+commands+skills+hooks+MCP).
- **Codex install is a file copy** of `dist/codex` into the project (the Codex
  plugin format can't bundle subagents). New concise `INSTALL.md` documents both;
  `engines.json` is the machine-readable contract for IDE drop-in.

### Bumped

- Both `plugin.json` manifests to `0.9.0`.

## 0.8.0 -- 2026-05-31

### Added — multi-engine support + an interactive installer

kensa-qa now runs in three modes, wired up by a cross-platform installer.

- **Installer** — `install.ps1` (Windows / PowerShell) and `install.sh`
  (macOS / Linux). Interactive menu or flags (`-Claude`/`--claude`, `-Codex`,
  `-Both`, `-Hybrid`, `-Marketplace`); detects which engines are present, offers
  copy or symlink, idempotent.
- **Mode B — native Codex plugin.** `.codex-plugin/plugin.json` reuses the 31
  `skills/` **verbatim** (identical `SKILL.md` format) and bundles the Stop hooks
  via `hooks/hooks.json`. The 3 agents ship as Codex subagents
  (`.codex/agents/*.toml` → `~/.codex/agents/`) and the 12 commands as `/kensa-*`
  slash prompts (`prompts/kensa-*.md` → `~/.codex/prompts/`). `AGENTS.md` is the
  Codex operating manual. Installed via the Codex plugin system
  (`codex plugin marketplace add` + `codex plugin add`), staged by the installer.
- **Mode C — hybrid.** `/setup` Phase 3.5 detects Codex and asks `worker` /
  `reviewer` / `off` (persisted to `.tms/memory/codex.yaml`). As **worker** the
  Test Lead offloads test-case packages to `codex exec` (Codex drafts, Claude
  writes + reviews); as **reviewer** Codex gives a second-opinion review. Templates
  in `codex/prompts/`. Detection helper `hooks/codex-detect.{sh,ps1}` (cached to
  `.tms/.codex-availability`). Everything **fail-closed** — any Codex error falls
  back to internal agents silently.

### Added — cross-platform hooks (the long-promised bash port)

- `hooks/save-memory-stop.sh` and `hooks/debug-log.sh` — POSIX twins of the
  PowerShell Stop hooks, identical stdin/stdout contract. macOS/Linux Claude Code
  and native Codex now get auto-checkpoint + debug logging. `.gitattributes`
  forces LF on `*.sh`.

### Changed

- `commands/setup.md`, `agents/test-lead-agent.md`, `agents/qa-engineer-agent.md`,
  `commands/new-feature.md`, `commands/update-feature.md` gained the Codex
  delegation paths. `CODEX_INTEGRATION.md` rewritten (the old "no native plugin"
  premise is obsolete). Version bumped to 0.8.0; fixed the marketplace manifest
  version drift (was pinned at 0.6.0).

## 0.7.0 -- 2026-05-31

### Added — SDLC coverage (6 read-only commands)

The plugin now spans the test side of the SDLC beyond authoring. Every new
command is **read-only**: it writes NO test cases, produces one committable
markdown artifact in `.tms/reports/`, and does NOT emit
`memory-checkpoint: done` (the Stop hook still only enforces checkpoints for
`/new-feature` and `/update-feature`). No new agents, no new skills — these
surface ISTQB skills that previously had no entry point.

**Shift-left (before cases exist):**

- `/pull-context <ref>` (`commands/pull-context.md`) — gathers all SOT content
  + related existing cases into a context dossier. A building block the others
  reuse. Surfaces `scope-analysis`, `sot-*`, `collaboration-based-approaches`.
- `/review-spec <ref>` (`commands/review-spec.md`) — static review of a
  requirement (ISTQB Ch 3 / ISO 20246): finds defects *in the spec* —
  ambiguity, untestable statements, missing AC, contradictions — graded
  critical/major/minor with suggested rewrites. Surfaces
  `static-testing-reviews`, `collaboration-based-approaches`, `review-rubrics`.
- `/risk-assess <ref>` (`commands/risk-assess.md`) — product risk register
  (likelihood × impact → level → recommended test depth per area). Surfaces
  `risk-based-testing` (§5.2).
- `/test-plan <epic>` (`commands/test-plan.md`) — ISTQB §5.1 test plan; folds
  in existing `risk-*` / `context-*` / brainstorm artifacts. Surfaces
  `test-planning`. Routes to `/brainstorm` when the strategy itself is contested.

**Test-base intelligence (over existing cases):**

- `/analyze-cases [scope]` (`commands/analyze-cases.md`) — semantic deep-audit
  by a **fan-out** of 1–N `qa-engineer` workers in analyze mode. Finds what the
  mechanical `/audit` can't: cross-case contradictions, semantic duplicates,
  coverage gaps, convention drift, mis-prioritization. Test Lead shards, workers
  return findings, Test Lead synthesizes one report. Optional per-batch fixes at
  the end. Built for large projects.
- `/traceability [--deep]` (`commands/traceability.md`) — requirements→cases
  matrix from `source_id`. Light mode is mechanical (kensa + `sot.yaml`
  cross-reference); `--deep` fans out analyze-mode workers to map each
  acceptance criterion to cases and find uncovered AC.

### Changed

- `agents/qa-engineer-agent.md` — new **`analyze` mode** (read-only): given a
  shard of cases, a spec section + lens, or a source's AC, it returns structured
  findings in its message and writes nothing. Stage 1 (checklist) and Stage 2
  (cases) are unchanged and backward-compatible.
- `agents/test-lead-agent.md` — `description` updated with the new entry points;
  new "Analysis & planning commands" section documenting the read-only
  contract and which command may fan out (only `/analyze-cases` and
  `/traceability --deep`).
- `README.md` — new "Analysis & planning" command table and "SDLC coverage"
  section; `/help` verify row and `.tms/` tree updated.
- Plugin version bumped to `0.7.0`.

## 0.6.0 -- 2026-05-25

### BREAKING

- **Agents renamed** for clarity to non-technical readers:
  - `lead` → **`test-lead-agent`** (file: `agents/test-lead-agent.md`)
  - `worker` → **`qa-engineer-agent`** (file: `agents/qa-engineer-agent.md`)
  - `strategist` — unchanged.
  - Any references in your `.tms/memory/project.md`, scripts, hooks, or
    @-mentions need updating. Re-run `/setup` if your project memory captured
    the old names.

### Added — ISTQB CTFL v4.0.1 grounding

- **10 new skills** covering ISTQB chapters previously implicit or missing
  in the plugin's reasoning surface. Each skill carries a verbatim ISTQB
  grounding block citing the syllabus chapter, section, and learning
  objective (FL-X.Y.Z) it teaches:
  - `testing-fundamentals` — Ch 1 (objectives, debugging, principles,
    activities, testware, traceability, roles)
  - `sdlc-and-test-lifecycle` — Ch 2 (SDLC impact, levels, types,
    confirmation vs regression, maintenance)
  - `static-testing-reviews` — Ch 3 (ISO 20246 review process, types, roles)
  - `white-box-techniques-overview` — §4.3 (statement & branch coverage,
    recognition level for manual QA)
  - `collaboration-based-approaches` — §4.5 (3 C's + INVEST, AC formats,
    ATDD)
  - `test-planning` — §5.1 (plan content, entry/exit criteria, estimation,
    prioritization, pyramid, quadrants)
  - `risk-based-testing` — §5.2 (project vs product risk, analysis, control)
  - `test-monitoring-control-completion` — §5.3 (metrics, test progress &
    completion reports, audience tailoring)
  - `defect-management` — §5.5 (defect lifecycle, ISO 29119-3 fields,
    severity vs priority)
  - `test-tools-and-automation-overview` — Ch 6 (tool categories, benefits
    & risks of automation)
- **ISTQB grounding blocks** added to the 11 existing ISTQB-aligned skills.
- **Non-ISTQB tooling disclaimer blocks** added to the 10 plugin
  infrastructure skills (`kensa-cli`, `kensa-test-authoring`, all `sot-*`,
  `figma-use`, `sequential-thinking`, `task-assignment`,
  `clarification-protocol`) — they remain in the library because they don't
  contradict ISTQB and they operationalise specific ISTQB concepts (e.g.,
  traceability per §1.4.4 via `source_id`).
- **Skill library wheel diagram** (`docs/images/skills-library.png`)
  visualising the 31 skills grouped into 6 sectors colour-coded by ISTQB
  chapter affinity.
- `README.md` gains a "Skill library" section with the diagram and a
  per-sector skill table.

### Changed

- **Architecture diagram** (`docs/images/architecture.png`) regenerated:
  - Clean SVG arrows for the "plan / feedback loop" exchange between Test
    Lead and Human gate (was: misaligned CSS-border arrows).
  - Each QA Engineer column now shows two explicit "Test Lead reviews"
    blocks (between Stage 1 → Stage 2, and after Stage 2) instead of the
    inline "Lead · ≤ 2" pill that read as a token-budget hint.
  - All agent labels updated to the new names.
- 8 of the existing 21 skills REFRAMED to cite ISTQB explicitly in their
  description and headers, without changing operational content:
  `negative-and-edge-cases`, `checklist-design`, `review-rubrics`,
  `scope-analysis`, `web-testing`, `mobile-testing`, `backend-api-testing`,
  `security-testing`.
- All `commands/*.md`, `templates/*`, `agents/strategist.md`, `INSTALL.md`,
  `.claude-plugin/marketplace.json`, and the `plugin-overview.html` updated
  to the new agent names.

### Migration

- Re-install the plugin (`/plugin update`) or pull and restart Claude Code.
- If your project memory or any local scripts reference `lead` or `worker`
  agent names, update them to `test-lead-agent` and `qa-engineer-agent`.
- Old `agents/lead.md` and `agents/worker.md` files are removed — their
  contents live in the new files with the same role definitions.

## 0.4.0 -- 2026-05-23

### Added

- **Marketplace manifest** (`.claude-plugin/marketplace.json`). The repo
  now doubles as a single-plugin marketplace named `rpluzhnikov`; users
  install with `/plugin marketplace add rpluzhnikov/QA_agents` then
  `/plugin install kensa-qa@rpluzhnikov`. Symlink/clone install still
  works for plugin development.
- **Auto memory checkpoint.** A `Stop` hook in `plugin.json`
  (`hooks/save-memory-stop.ps1`) blocks session stop after `/new-feature` or
  `/update-feature` until the Lead emits the sentinel line
  `memory-checkpoint: done`. The Lead runs the `/save-memory` protocol
  automatically; UX is controlled by `auto_save_learnings` in
  `.tms/memory/project.md`.
- **Per-session debug log.** A second `Stop` hook
  (`hooks/debug-log.ps1`) writes a readable digest at
  `.tms/debug/session-<id>.md` plus a transcript snapshot
  `session-<id>.jsonl`, but only when the cwd has `.tms/memory/` (i.e. it is
  a Kensa project). `/setup` adds `.tms/debug/` to the project's
  `.gitignore`.
- `INSTALL.md` -- step-by-step install, restart, smoke-test, and diagnostic
  recipe for the hooks.
- `CHANGELOG.md`.
- Top-level `.gitignore` for this repo (local Claude state, debug output if
  hooks ever run here while developing the plugin, OS junk).

### Changed

- `commands/new-feature.md` gains a Step 9 (memory checkpoint).
- `commands/update-feature.md` gains a Step 7 (memory checkpoint).
- `commands/save-memory.md` gains a Step 5 (emit sentinel) -- without it,
  the Stop hook would re-block.
- `commands/setup.md` Phase 6 now writes `.tms/debug/` into the project's
  `.gitignore`.
- `agents/lead.md` documents the memory-checkpoint contract and how the
  Stop hook enforces it.
- Plugin version bumped to `0.4.0`.

### Known limitations

- Hooks are Windows + PowerShell 5.1 only. macOS/Linux: hooks fail silently,
  rest of the plugin works as before. Bash port tracked for v0.5.
- Plugin-defined hooks in `plugin.json` depend on the Claude Code version
  supporting that field. If yours doesn't, copy the `hooks` block manually
  into your project's `.claude/settings.json` as a fallback.

## 0.3.0

- SOT-specific extraction skills (`sot-linear`, `sot-jira`, `sot-confluence`,
  `sot-notion`, `sot-figma`).
- `sequential-thinking`, `figma-use`, `kensa-cli`, `kensa-test-authoring`
  skills integrated.
- `/setup` writes MCP servers into a project `.mcp.json`.

## 0.2.0

- Memory keeper protocol for session logging and pattern promotion.

## 0.1.0

- Initial release: Lead + Worker agents, 4 slash commands, project memory
  templates.
