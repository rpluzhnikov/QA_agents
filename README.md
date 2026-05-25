# Kensa-QA — a Manual QA Team Inside Claude Code

![Kensa-QA in action — Lead planning, Workers writing cases](docs/images/hero.png)

A plugin for [Claude Code](https://docs.claude.com/claude-code) that turns
your editor into a small QA team. You write a ticket reference or paste a
spec, and the plugin produces a coverage checklist and a folder full of
manual test cases — written in your project's style, traced back to the
source of truth, and ready to commit.

It is built for the [Kensa](https://kensa.dev) test case management format
(plain markdown files under `.tms/suites/`), but you can use it on any
project where test cases live in markdown.

## What this does for you as a QA tester

- **Turns tickets and specs into manual test cases.** Point it at a Linear
  issue, a Confluence spec, a Figma frame, a Jira story, or paste raw text
  — and within minutes you have a coverage checklist plus 10–60 test-case
  files, written to your project's conventions.
- **Keeps cases in sync with the spec.** When a feature changes, the plugin
  finds the affected cases (by source-of-truth reference) and updates only
  what changed instead of asking you to hunt them down by hand.
- **Audits the repository for drift.** When the test suite gets large
  (hundreds of cases), it flags stale drafts, duplicates, orphan
  shared-steps, tag drift against your taxonomy, and missing source
  references — so the suite stays maintainable as it grows.

It does **not** execute tests, automate them, or replace a test runner.
It writes the manual test cases that a human (or, separately, an automation
engineer) will run.

## How it works

![How the plugin works — Lead coordinates, Workers write in parallel](docs/images/architecture.png)

When you invoke a command like `/new-feature LIN-42`, three things happen:

1. The **Lead** (a coordinator agent — Claude Code's term for a focused
   sub-AI) reads your project's conventions, fetches the spec from your
   ticket tracker / wiki, and plans how to cover it.
2. The Lead spawns one or more **Workers** (subagents that write the actual
   test-case files) in parallel. Each Worker gets a precise scope and
   writes its assigned slice.
3. The Lead reviews what came back, runs a memory checkpoint to capture
   any new conventions you've established, and reports the final list of
   files to you.

For complex strategic questions — "should we split this feature in two?",
"what coverage strategy fits this risk?" — there's also `/brainstorm`,
which spawns three **Strategists** in parallel plus a cross-review round
to deliberate before any cases are written.

You stay in the loop. The Lead asks you to confirm the plan before
spawning anything, and you review the final output at the end.

## Prerequisites

- **Claude Code** installed and signed in. ([Install Claude Code](https://docs.claude.com/claude-code/install))
- **Node.js** with `npx` on your PATH. The plugin ships a bundled
  reasoning MCP server (`sequential-thinking`) that auto-installs on first
  run via `npx -y`.
- **Windows 11 with PowerShell 5.1** if you want the auto-checkpoint and
  debug-log hooks. On macOS / Linux the rest of the plugin works fine; the
  hooks silently no-op. A bash port is on the roadmap.

You do **not** need API keys for Linear / Atlassian / Notion / Figma.
The MCP servers for these handle auth through your browser the first time
they connect.

## Install

Inside Claude Code, run:

```
/plugin marketplace add rpluzhnikov/QA_agents
/plugin install kensa-qa@rpluzhnikov
```

The first line registers this repo as a single-plugin marketplace (Claude
Code clones it into its plugin cache). The second line enables the plugin
from it.

**Then fully restart Claude Code** — not just a new tab. Plugin manifest,
agents, commands, and hooks all load at session start.

To update later: `/plugin marketplace update rpluzhnikov`.

<details>
<summary><b>Other install paths (for plugin developers)</b></summary>

If you're hacking on the plugin source itself, you can symlink your local
checkout into Claude Code's plugin directory instead of going through the
marketplace.

**Symlink (Windows, admin PowerShell or with Developer Mode enabled):**

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.claude\plugins\kensa-qa" `
  -Target "C:\path\to\your\QA_agents"
```

**Symlink (macOS / Linux):**

```bash
ln -s /path/to/QA_agents ~/.claude/plugins/kensa-qa
```

**Direct git clone into the plugins dir:**

```bash
git clone https://github.com/rpluzhnikov/QA_agents.git \
  ~/.claude/plugins/kensa-qa
```

You'll `git pull` manually for updates with this approach.

See [INSTALL.md](INSTALL.md) for deeper diagnostics if something doesn't
load.

</details>

## Verify the plugin loaded

After restart, in any project:

- Run `/help` — you should see `setup`, `new-feature`, `update-feature`,
  `save-memory`, `audit`, `brainstorm` in the slash-command list.
- Type `@` — `lead`, `worker`, and `strategist` should appear as agents.
- Run `/hooks` (Windows only) — two **Stop** hooks should show up:
  `kensa-qa: writing debug log` and `kensa-qa: checking memory checkpoint`.

If anything's missing, the usual culprit is "Claude Code wasn't fully
restarted". See [INSTALL.md §2](INSTALL.md) for deeper diagnostics.

## First-time setup

Open any project where you want to write QA cases. Run:

```
/setup
```

This is an interactive flow — answer questions about your stack, the
language your test cases are written in (English / Russian / other), which
ticket tracker and wiki you use, and so on. The plugin will also scan any
existing test cases under `.tms/suites/` to learn your conventions
(naming style, step granularity, expected-result format) so future cases
match.

When `/setup` finishes, it writes:

- `.tms/memory/` — your project's conventions, glossary, and source-of-truth
  config. **Edit any of these by hand later** — the plugin re-reads them
  every session.
- `.mcp.json` at the repo root — the MCP servers for your chosen sources.
  Restart Claude Code one more time after `/setup` so these connect; a
  browser tab will open for the first OAuth sign-in to each.

You're now ready to write cases.

## Commands

### Authoring

#### `/new-feature <ref>` — write cases for a new feature

```
/new-feature LIN-42
/new-feature https://yourcompany.atlassian.net/wiki/spaces/...
/new-feature "Free-text spec pasted here"
```

The Lead pulls the spec, plans coverage, gets your sign-off on the plan,
spawns Workers to write checklists, reviews them, then has Workers write
the test-case files. You'll see new `.md` files appear under
`.tms/suites/<suite>/`. At the end the Lead reports total case count, any
assumptions it made, and any open questions for product.

#### `/update-feature <ref>` — update cases when a feature changes

```
/update-feature LIN-42
```

The Lead finds cases that reference the changed source (via the `source_id`
field in their frontmatter), reads the new version of the spec, and works
out what needs to be added, removed, or rewritten. Reviews and reports the
same way as `/new-feature`.

#### `/brainstorm <topic>` — deliberate a complex decision

```
/brainstorm how to split the Discount Engine feature for parallel workers?
/brainstorm should 2FA cases be negative-first or boundary-first?
```

Use this before `/new-feature` when the right approach isn't obvious.
The Lead picks three angles (scope conservative vs. aggressive,
decomposition strategy, test technique, etc.), spawns three Strategists
in parallel — each argues one angle — then a cross-review round, then
synthesizes a comparison-view with 2–3 finalists for you to pick. The
result is saved to `.tms/brainstorms/` and can be referenced from a later
`/new-feature` for the decided approach.

### Maintenance

#### `/audit` — health check on the test repository

```
/audit
```

When the suite has grown to hundreds of cases and you suspect drift:
the Lead walks the entire `.tms/` via the `kensa` CLI, runs schema
validation, finds duplicates, stale drafts, orphan shared-steps, and tags
outside your taxonomy, plus samples a few cases for qualitative checks
(title style, vague expected results). Output goes to terminal +
`.tms/reports/audit-YYYY-MM-DD.md`. Read-only by default; at the end you
can opt-in to apply fixes per-batch with confirmation.

#### `/save-memory` — manually capture session learnings

```
/save-memory
```

Mostly runs automatically at the end of `/new-feature` and
`/update-feature` (enforced by the auto-checkpoint hook). Run it
explicitly when you've established a new convention mid-session and want
to capture it before more work happens.

### Setup

#### `/setup` — bootstrap a project (one-time)

Already covered above. Re-run if you add a new source of truth or want
to re-learn conventions from updated cases.

## Sources of truth

The plugin reads tickets and specs through MCP — the protocol Claude
Code uses to talk to external systems. You choose which ones to wire up
during `/setup`:

| Source        | Auth                           |
|---------------|--------------------------------|
| **Linear**    | Browser OAuth on first connect |
| **Jira**      | Browser OAuth (Atlassian Cloud)|
| **Confluence**| Browser OAuth (same Atlassian server as Jira) |
| **Notion**    | Browser OAuth                  |
| **Figma**     | Local socket (requires Figma desktop app with Dev Mode MCP enabled) |

**No API tokens to manage.** OAuth opens a tab on first use; the Figma
Dev Mode MCP authenticates against whatever's signed-in in your desktop
app.

For Confluence, `/setup` also runs a CQL discovery to find authoritative
spec pages within your space — so the Lead doesn't get stuck on an
overview page and miss the actual specs underneath. You'll be asked to
multi-select which pages count as the source of truth.

Each source has a dedicated extraction skill (`sot-linear`, `sot-jira`,
`sot-confluence`, `sot-notion`, `sot-figma`) that tells the agents where
acceptance criteria typically live for that source.

## Project memory — the `.tms/` directory

Everything the plugin learns about your project is stored as plain
markdown / YAML files. Read them, edit them, commit them.

```
<your-project>/.tms/
├── memory/
│   ├── project.md         ← what this project is, stack, testing types
│   ├── conventions.md     ← how cases are written here
│   ├── glossary.md        ← domain terms and translations
│   ├── sot.yaml           ← source-of-truth config
│   └── learned/
│       ├── patterns.md    ← reusable patterns spotted in cases
│       ├── shared-steps.md
│       └── tags.md        ← the tag taxonomy
├── suites/                ← your test cases live here, organized by feature
├── shared-steps/          ← reusable step sequences
├── reports/               ← /audit output (commit these)
├── brainstorms/           ← /brainstorm output (commit these)
└── debug/                 ← per-session logs (gitignored)
```

`project.md`, `conventions.md`, `glossary.md` are human-written — the
plugin only reads them. `sot.yaml` is written during `/setup` and edited
by hand later. `learned/*` is plugin-written; you review and accept
during the memory checkpoint.

For the byte-exact case file format, see the `kensa-test-authoring` skill
under `skills/kensa-test-authoring/`.

## FAQ / Troubleshooting

**Q: I'm on macOS / Linux. Do the hooks work?**
No, the auto-checkpoint and debug-log hooks are Windows + PowerShell only
in v0.5. The rest of the plugin works normally; you just don't get
auto-checkpoint enforcement or per-session debug logs. A bash port is on
the roadmap. As a workaround, you can run `/save-memory` manually at the
end of each `/new-feature` session.

**Q: I ran `/setup` but Linear / Jira / Notion isn't reading anything.**
You probably skipped the restart after `/setup`. MCP servers connect at
session start — fully quit Claude Code and reopen. On first connect a
browser tab opens for OAuth; complete that. If it still fails, run
`/hooks` and `/help` to confirm the plugin loaded; if not, see
[INSTALL.md](INSTALL.md).

**Q: Where's `.tms/suites/`? The plugin says "no cases yet".**
That's normal on a fresh project. `/new-feature` will create the suite
directories the first time it writes cases. If you already have cases
from another tool, drop them in `.tms/suites/<suite>/<id>.md` matching
the `kensa-test-authoring` format and `/setup` will learn from them.

**Q: How do I disable the plugin in one specific project?**
Use `/plugin disable kensa-qa@rpluzhnikov` while inside that project.
This keeps it installed globally; the project just won't load it.

**Q: Can I edit `conventions.md` directly?**
Yes — that's the intended workflow. The plugin re-reads memory at the
start of every session, so changes take effect immediately. If you want
the plugin to *learn* new conventions from cases you wrote by hand, run
`/setup` again and pick "update specific files".

**Q: What's the difference between the Workers and the Strategists?**
Workers (used by `/new-feature` and `/update-feature`) *write* test cases.
Strategists (used by `/brainstorm`) *deliberate* — they argue strategic
angles to help you decide on an approach, and never write cases
themselves.

**Q: The session won't end — something about a memory checkpoint.**
The auto-checkpoint hook (Windows only) requires the Lead to run
`/save-memory` after `/new-feature` or `/update-feature` before the
session can stop. Wait for the Lead to finish the checkpoint, or, if the
Lead got stuck, type the sentinel line `memory-checkpoint: done` yourself
to unblock. See [INSTALL.md §5](INSTALL.md) for deeper diagnostics.

---

## Under the hood

Everything below is for the curious or for plugin developers — you don't
need it to use the plugin.

### Auto memory checkpoint

After every `/new-feature` and `/update-feature`, a `Stop` hook
(`hooks/save-memory-stop.ps1`) blocks the session from ending until the
Lead runs the `/save-memory` protocol and emits a sentinel line:
`memory-checkpoint: done`.

The flow is controlled by `auto_save_learnings` in
`.tms/memory/project.md`:
- `true` — Lead applies saves silently and adds one line to its report.
- `false` (default) — Lead presents all candidates with yes/no/edit per
  item.

If there's nothing to save, the sentinel is still emitted with
`(nothing to save this round)` appended.

### Per-session debug log

A second `Stop` hook (`hooks/debug-log.ps1`) writes a debug digest for
every session that runs inside a Kensa project (detected by the presence
of `.tms/memory/`):

```
.tms/debug/
├── session-<id>.md     ← readable digest (commands invoked, files written,
│                         worker spawns, stuck-session warnings)
└── session-<id>.jsonl  ← full transcript snapshot
```

When `/setup` runs, it adds `.tms/debug/` to your project's `.gitignore`
automatically — transcripts may contain ticket text or secrets the user
pasted into prompts, so they're not safe to commit. If the digest shows
3+ `/new-feature` invocations with 0 files written, a "STUCK SESSION"
banner is added at the top.

The debug-log hook never blocks the stop; on failure it exits silently.

### Bundled MCP server

The plugin ships its own `sequential-thinking` MCP (declared in
`plugin.json`, started automatically — no credentials). It powers the
`sequential-thinking` reasoning skill that Lead and Workers use for hard
scope and edge-case decisions.

### Skills

~22 skills under `skills/`, auto-loaded via the plugin manifest.
Highlights:
- `kensa-test-authoring` — byte-exact `.tms/` on-disk format
- `kensa-cli` — drive the `kensa` CLI for queries, bulk edits, context
  bundling, and the audit workflow
- `sequential-thinking` — structured reasoning for hard decisions
- `figma-use` — programmatic Figma access for inspecting deep node
  structure
- `sot-linear` / `sot-jira` / `sot-confluence` / `sot-notion` /
  `sot-figma` — source-specific extraction guidance
- `checklist-design`, `test-design-techniques`,
  `test-case-writing-craft`, `negative-and-edge-cases`,
  `web-testing` / `mobile-testing` / `backend-api-testing` /
  `security-testing` — the QA-craft skills the Workers load

## Roadmap

- **v0.1** — Lead + Worker, 4 commands, project memory templates.
- **v0.2** — Memory checkpoint protocol.
- **v0.3** — SOT-specific extraction skills; `sequential-thinking`,
  `figma-use`, `kensa-cli`, `kensa-test-authoring` integrated;
  `/setup` writes MCP servers into `.mcp.json`.
- **v0.4** — Stop hooks for auto-checkpoint and debug log; marketplace
  manifest; `INSTALL.md` smoke-test guide.
- **v0.5 (current)** — `/audit` (repository health check),
  `/brainstorm` (multi-strategist deliberation), `strategist` agent,
  MCP-setup OAuth clarity, Confluence multi-page discovery,
  pre-seeded tag taxonomy (`negative`, `tbd`, `smoke`, `regression`),
  parallel-worker ID-range allocation, stuck-session detection in
  debug log.
- **v0.6** — Bash port of the hooks (macOS / Linux);
  fixture registry (`.tms/fixtures/` with `kensa fixtures --extract`);
  exploratory testing mode (`/explore`); auto-discovery of brainstorm
  artifacts in `/new-feature`.

## License

MIT — see [LICENSE](LICENSE).

## Links

- [INSTALL.md](INSTALL.md) — install, smoke-test, diagnostic recipes
- [CHANGELOG.md](CHANGELOG.md) — version history
- [Kensa](https://kensa.dev) — the test-case management format this plugin targets
- [Claude Code](https://docs.claude.com/claude-code) — the host environment
