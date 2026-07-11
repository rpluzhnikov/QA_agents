---
description: Bootstrap kensa-qa project memory (.tms/memory/) and source-of-truth config for a Kensa TMS project.
argument-hint: (no args — interactive interview)
---

Act as the **test-lead-agent**. Run the kensa-qa project setup interview — a
multi-turn conversation, not a one-shot. Do not write anything until the user
confirms at the end.

1. **Discovery** — check whether `.tms/memory/` already exists (offer overwrite /
   update / cancel) and whether `.tms/suites/` has cases to learn style from.
2. **Project basics** — ask (a few at a time) for: project description, stack
   (web/mobile/backend/mixed), case language, testing types tracked.
3. **Source of truth** — which of Linear/Jira/Confluence/Notion/Figma they use and
   the default workspace/space to scope. Load the matching `sot-*` skill for
   guidance. On Codex, source MCPs are configured in `~/.codex/config.toml`
   `[mcp_servers.*]` (not `.mcp.json`) — offer to add the ones they want.
4. **Style learning** (if cases exist) — sample 10-20 cases, draft `conventions.md`,
   confirm with the user.
5. **Glossary** — extract frequent domain terms, build `glossary.md`.
6. **Commit** — show the tree, get confirmation, write `.tms/memory/*` from the
   templates. Also add `.tms/.pending-checkpoint` to the project `.gitignore`
   (create or append, never clobber) — it's the transient Stop-hook marker the
   authoring commands create and `/kensa-save-memory` deletes; never commit it.
   For a web project, optionally seed starter browser routines from the
   plugin `templates/routines/` into `.tms/routines/` (RT-001..003: smoke / form /
   visual baseline) — committable Markdown the user runs with `/kensa-run-routine`.

Use the bundled skills `scope-analysis`, `clarification-protocol`, and the `sot-*`
guides. Fill sensible defaults where the user has no answer, and mark them as
defaults.

End your final message with (adapt to what actually happened; only suggest commands
whose bundle is installed — otherwise name the bundle):

✅ **Done:** .tms/memory/ created (<files>), MCP config <added/skipped>, routines <seeded/skipped>
➡️ **Next:** restart Codex if MCP servers were added to `config.toml` — they start on restart · `/kensa-new-feature <ref>` — author cases for your first feature · `/kensa-run-routine RT-001` — if routines were seeded · migrating from another TMS? `/kensa-adapt-schema <samples>` first, import via Universal format, then re-run `/kensa-setup` (update mode).
