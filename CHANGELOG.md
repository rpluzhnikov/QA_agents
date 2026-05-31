# Changelog

All notable changes to **kensa-qa**. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
