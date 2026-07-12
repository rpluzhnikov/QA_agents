# QA_agents plugin — authoring & contract guide

How the **`kensa-ide/QA_agents`** repository is structured so that Kensa can install it
into a user's project, offer a selectable bundle catalog, and update it later.

This is the contract between Kensa (the IDE) and the QA_agents repo (the content). Kensa
reads `engines.json` from the repo root, clones the repo into an app-cache, and copies the
declared directories into the open project. **All the agent / skill / command content lives
in QA_agents — Kensa only copies what a bundle declares.**

---

## 1. Mental model

- An **engine** is a target AI tool: `claude` (Claude Code) or `codex` (OpenAI Codex). Each
  engine has its own on-disk layout and its own content.
- The **base** of an engine (`engine.source`) is **always installed** when the user installs
  that engine — the core agents / commands / skills that make the plugin useful out of the box.
- A **bundle** is an **optional, additive add-on** on top of the base: an automation pack, an
  extra agent, an extra skill set, etc. The user picks bundles with checkboxes at install time
  and can add/remove them later in **Settings → Agents**.

> **Base is always on; bundles are the extras.** The base is NOT a bundle and never shows up as
> a checkbox. If the user unchecks every bundle, the base alone is still installed.

---

## 2. Repository layout

```
QA_agents/
  engines.json                      # the contract (repo root)
  dist/
    claude/
      base/                         # engine.source for claude — ALWAYS installed
        .claude-plugin/plugin.json  # the plugin manifest (name, version, etc.)
        agents/                     # core agents (*.md)
        commands/                   # core slash-commands (*.md)
        skills/                     # core skills (<skill>/SKILL.md)
        hooks/                      # optional hooks (use ${CLAUDE_PLUGIN_ROOT} for paths)
      bundles/                      # one folder per optional bundle
        automation-playwright-ts/
          agents/                   #   files here MERGE into the plugin's agents/
          skills/
        automation-pytest/
          agents/
        api-contract/
          agents/
          skills/
        extra-agents-perf/
          agents/
    codex/
      base/                         # engine.source for codex — ALWAYS installed
        .codex/
          agents/                   # *.toml agent definitions
        AGENTS.md
      bundles/
        automation-playwright-ts/
          .codex/agents/playwright-ts.toml
        api-contract/
          .codex/agents/api.toml
```

**Rules**

1. **`base/` and every `bundles/<id>/` directory are disjoint.** Kensa copies the *contents* of
   the base and of each selected bundle into one destination, merging them. A bundle therefore
   mirrors the plugin's internal structure (`agents/`, `skills/`, `commands/`) so its files land
   in the right place — it does NOT re-declare the base.
2. On a path conflict between two selected sources, **the last one copied wins** (overwrite).
   Keep bundle filenames unique to avoid surprises.
3. Author **per-engine content separately**: the same logical bundle (e.g. "Playwright (TS)")
   has a `claude` source (md agents / skills) and a `codex` source (`.toml`). Declare each under
   the bundle's `engineSources` map. If a bundle isn't meant for an engine, simply omit that
   engine's key — Kensa silently skips it for that engine.

---

## 3. `engines.json` reference

```json
{
  "version": "1.0.0",
  "engines": [
    {
      "id": "claude",
      "displayName": "Claude Code",
      "source": "dist/claude/base",
      "target": ".claude/marketplace/kensa-qa",
      "copy": "contents",
      "postInstall": ["Reload Claude Code so it loads the plugin"],
      "verify": ["@ lists the kensa-qa agents"]
    },
    {
      "id": "codex",
      "displayName": "Codex",
      "source": "dist/codex/base",
      "target": ".",
      "copy": "contents",
      "postInstall": ["Start a new Codex session to activate the plugin"],
      "verify": []
    }
  ],
  "bundles": [
    {
      "id": "automation-playwright-ts",
      "displayName": "Playwright (TS)",
      "summary": "Writes @KEN-tagged Playwright tests",
      "category": "automation",
      "tags": ["playwright", "typescript"],
      "default": false,
      "engineSources": {
        "claude": ["dist/claude/bundles/automation-playwright-ts"],
        "codex":  ["dist/codex/bundles/automation-playwright-ts"]
      }
    },
    {
      "id": "automation-pytest",
      "displayName": "pytest",
      "summary": "Writes @KEN-tagged pytest tests",
      "category": "automation",
      "default": false,
      "engineSources": {
        "claude": ["dist/claude/bundles/automation-pytest"]
      }
    },
    {
      "id": "api-contract",
      "displayName": "API / contract",
      "summary": "API and contract-test agent",
      "category": "api",
      "default": false,
      "engineSources": {
        "claude": ["dist/claude/bundles/api-contract"],
        "codex":  ["dist/codex/bundles/api-contract"]
      }
    },
    {
      "id": "extra-agents-perf",
      "displayName": "Performance agent",
      "category": "agents",
      "default": false,
      "engineSources": {
        "claude": ["dist/claude/bundles/extra-agents-perf"]
      }
    }
  ]
}
```

### Engine fields

| Field | Required | Meaning |
|-------|----------|---------|
| `id` | yes | Engine id. Kensa only activates `claude` and `codex` today. |
| `displayName` | yes | Shown in the install dialog + Settings. |
| `source` | yes | **The base** — directory (relative to the repo root) copied **on every install** of this engine. |
| `target` | yes | Where the build is copied inside the user's project (relative to project root). Claude: `.claude/marketplace/kensa-qa`. Codex: `.` (project root). |
| `copy` | yes | Must be `"contents"` (copy the directory's contents, not the folder itself). |
| `postInstall` | no | Lines shown to the user after a successful install. |
| `verify` | no | Hint lines for verifying the install. |

### Bundle fields

| Field | Required | Meaning |
|-------|----------|---------|
| `id` | yes | Unique id. **It is a catalog key, never a path** — use stable ASCII (e.g. `automation-playwright-ts`). An id Kensa doesn't recognise is rejected. |
| `displayName` | yes | Checkbox label. |
| `summary` | no | Secondary line under the checkbox. |
| `category` | no | Group heading in the UI (e.g. `automation`, `api`, `agents`, `skills`). Bundles with the same category are grouped together; catalog order is preserved. |
| `tags` | no | Free-form tags (not shown yet; reserved). |
| `default` | no (default `false`) | If `true`, the checkbox is **pre-checked** in the install dialog on a fresh install. |
| `engineSources` | yes | Map `engineId → [relative dir, …]`. The directories (relative to the repo root) copied when this bundle is selected for that engine. Omit an engine key to make the bundle unavailable for that engine. |

> **Backward compatibility:** an `engines.json` with **no `bundles` key at all** installs exactly
> like the pre-catalog version (the whole `engine.source` is copied, and no marker file is written).
> You can ship the catalog incrementally.

---

## 4. How install resolves (so you can predict the result)

For an install of engine *E* with a selection:

```
if engines.json has no "bundles":
    copy  engine.source                          # legacy, unchanged
else:
    copy  engine.source                          # the BASE — always
    + for each selected bundle offered for E:     # the EXTRAS
          copy  bundle.engineSources[E]
```

Selection semantics:

| Selection passed by the UI | Result |
|----------------------------|--------|
| fresh dialog open | base + every `default:true` bundle (pre-checked) |
| user's chosen set | base + exactly those bundles |
| user unchecks everything | **base only** (no extras) |

Every copied directory is validated and confined under the project root (see §7).

---

## 5. Per-engine authoring notes

### Claude Code
- The base is a real Claude **plugin**: it needs `.claude-plugin/plugin.json` plus the standard
  `agents/`, `commands/`, `skills/`, optional `hooks/` and MCP config.
- Kensa copies base + selected bundles into `<project>/.claude/marketplace/kensa-qa/`, writes a
  local **directory marketplace** catalog there, and registers + enables it in
  `<project>/.claude/settings.json`. It also appends a qa-agents section to `<project>/CLAUDE.md`.
- Because everything lands in one plugin folder, **bundle files merge into the base's structure**
  — a bundle's `agents/foo.md` simply becomes another agent in the same plugin.
- In hooks, reference files via `${CLAUDE_PLUGIN_ROOT}` (the plugin loads in-place from the project).

### Codex
- The base is `.codex/agents/*.toml` + `AGENTS.md`, copied into the project root (`target: "."`).
  Codex auto-loads these.
- Bundles add more `.codex/agents/*.toml`. They merge into `.codex/agents/`.
- **No-prune:** removing a Codex bundle later stops it being copied on the next install but does
  NOT delete files already copied (the IDE shows a note). Claude clean-mirrors its plugin folder,
  so Claude removals take effect automatically.

---

## 6. What the user sees in Kensa

- **New project / install dialog:** pick `claude` / `codex` / empty. With a catalog present, a
  grouped checkbox list of bundles appears (defaults pre-checked). Install copies base + checked
  bundles.
- **Settings → Agents:** per-engine list of bundles with checkboxes, an **Apply** button (re-runs
  the install with the current selection), and an **Update** button that appears **only when the
  QA_agents repo has moved past the installed revision** (Kensa compares the recorded checkout SHA
  with the current `HEAD`).
- Selection + checkout SHA are persisted per engine in a small marker file inside the project
  (`.claude/marketplace/kensa-qa/.kensa-bundles.json` for Claude, `.codex/.kensa-bundles.json` for
  Codex). You don't author these — Kensa writes them.

---

## 7. Constraints & gotchas (authoring)

- **Paths are confined.** Every `source`/`engineSources` path is resolved relative to the repo
  checkout and must stay inside it — no absolute paths, no `..`, no symlinked escapes. A path that
  tries to escape is rejected and the install fails.
- **Bundle ids are keys, not paths.** They never become path segments; keep them stable and ASCII.
- **Keep base and bundles disjoint** (see §2 rule 1). Don't put a bundle's files inside `base/`.
- **`copy` must be `"contents"`.** Other modes are rejected.
- **No new engines beyond `claude`/`codex`** are activated by Kensa today (you can list others for
  forward-compat; they're skipped).
- The catalog **data** is entirely yours; Kensa ships no bundle content. Test changes by pointing a
  local checkout's `engines.json` at your new layout.

---

## 8. Authoring checklist

- [ ] `engines.json` validates as JSON; `engines[]` non-empty; each engine has `source`/`target`/`copy:"contents"`.
- [ ] `dist/<engine>/base/` contains the core plugin (Claude: `.claude-plugin/plugin.json` + agents/commands/skills; Codex: `.codex/agents/*.toml` + `AGENTS.md`).
- [ ] Each bundle has a unique `id`, a `displayName`, a `category`, and an `engineSources` entry per supported engine.
- [ ] Bundle directories exist at the declared paths and are disjoint from `base/` and from each other.
- [ ] `default:true` only on bundles you want pre-checked on a fresh install.
- [ ] No path uses `..` / absolute / symlink escape.
- [ ] Install once per engine into a scratch project and confirm base-only (uncheck all) and base+extras both produce the expected files.
