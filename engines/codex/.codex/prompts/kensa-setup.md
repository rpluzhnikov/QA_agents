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
   templates, and add `.tms/debug/` to `.gitignore`.

Use the bundled skills `scope-analysis`, `clarification-protocol`, and the `sot-*`
guides. Fill sensible defaults where the user has no answer, and mark them as
defaults.
