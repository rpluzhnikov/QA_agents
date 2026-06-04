---
description: Bootstrap project memory in .tms/memory/ and wire up source-of-truth MCP servers in .mcp.json. Run once per project. Interviews the user about the project, scans existing cases to learn conventions, seeds glossary, and connects the Linear/Jira/Confluence/Notion/Figma MCP servers they use.
---

You are running the project setup flow. This is a guided interview — do not write anything to disk until the user confirms at the end.

## Phase 1 — Discovery

1. Check if `.tms/memory/` already exists.
   - If YES: tell the user "Memory already exists. Do you want to (a) start over (will overwrite), (b) update specific files, or (c) cancel?"
   - If NO: continue.

2. Check if `.tms/suites/` exists and has any cases.
   - If YES: scan up to 20 random cases for style learning (later phase).
   - If NO: short setup, skip style learning.

## Phase 2 — Project basics

Ask the user (one message, not a wall of questions — pick the most important first):

1. What's the project? (short description, 1-2 sentences)
2. What's the stack? (web / mobile / backend-only / mixed)
3. What language are test cases written in? (en / ru / other)
4. What types of testing are tracked in this TMS? (functional / regression / smoke / API / mobile / security / accessibility — multi-select)

Wait for response. Don't dump 20 questions at once.

## Phase 3 — Source of truth

1. Ask which sources of truth they use: Linear / Jira / Confluence / Notion / Figma / other / none.
2. For each named source, ask:
   - What's the default workspace / team / project / space the Test Lead should scope
     future searches to? This goes into `sot.yaml` and is plugin config — it is
     NOT a credential. OAuth/local-socket handles auth (see below). For Atlassian
     specifically the cloudId is resolved automatically after OAuth, so accept
     anything human-readable (a space key, a project key) or "default" / "all".
   - Do you want me to wire up the MCP server for it during setup? (yes / no)
3. Unlike `sot.yaml` (which is just plugin config), the MCP servers are what actually
   lets the Test Lead read tickets and specs. In Phase 6 you will offer to write a project
   `.mcp.json` at the repo root containing the servers they said yes to. The plugin
   already bundles its own `sequential-thinking` MCP (declared in `plugin.json`) — do
   NOT add that one to the project file; it is always available.

4. **For Confluence specifically — discover the spec tree.** After the user names a
   Confluence space, before moving on, do a CQL-based discovery so `sot.yaml.notable_pages`
   is populated with the actual specs, not just an overview page. This step is what
   prevents the "Test Lead got stuck on the wiki landing page" failure mode.

   - If the `atlassian` MCP is already connected in the user's environment: call its
     search tool (typically `searchPagesUsingCql` or equivalent — check the available
     `mcp__*atlassian*__*` tools at runtime) with a query like `space = "<KEY>" AND
     type = page ORDER BY lastmodified DESC` and pull the top ~15 pages.
   - Show the user a numbered list (title + page ID) and ask them to multi-select the
     ones that are authoritative specs (not announcements / standup notes / archives).
     Save the selection into `sot.yaml.notable_pages` as `[{id, title}]` entries.
   - If the MCP is NOT yet connected (typical first-time setup): tell the user
     "I'll discover notable Confluence pages on the next session once the MCP is
     wired and you've completed the browser OAuth. For now I'll leave
     `notable_pages: []` with a TODO." Do not block setup waiting for the MCP.

### MCP server map — what each source needs in `.mcp.json`

Use these known-good entries. The remote servers use OAuth on first connect (no API
key in the file); the user authenticates in-browser when the server first starts.

| Source | `.mcp.json` entry |
|--------|-------------------|
| Linear | `"linear": { "type": "sse", "url": "https://mcp.linear.app/sse" }` |
| Jira | `"atlassian": { "type": "http", "url": "https://mcp.atlassian.com/v1/mcp" }` |
| Confluence | same `atlassian` server as Jira — add it once, it covers both |
| Notion | `"notion": { "type": "http", "url": "https://mcp.notion.com/mcp" }` |
| Figma (read) | `"figma": { "type": "http", "url": "http://127.0.0.1:3845/mcp" }` — official Dev Mode MCP; requires the Figma desktop app running with Dev Mode MCP enabled |

Notes:
- Jira and Confluence share ONE `atlassian` server entry — never write it twice.
- The Figma Dev Mode MCP is read-only design context for QA (you can see frames,
  annotations, prototype flows). The write-capable `use_figma` tool exists in a
  separate Figma plugin-API MCP, but QA workflows don't need it. Do NOT touch
  `.mcp.json` for write-Figma during /setup. If the user later wants Figma write
  access for some reason, point them at the `figma-use` skill's own setup notes.

### Authentication — never ask the user for these

**For Linear / Atlassian Cloud / Notion / Figma Dev Mode** (everything in the table
above), do NOT ask the user for any of the following — they are all handled
automatically:

- API tokens, bearer keys, or personal access tokens
- OAuth client IDs / client secrets
- Refresh tokens or cookies
- Figma personal access tokens — the Dev Mode MCP authenticates via the
  running desktop-app session, not a token

When Claude Code first connects to an OAuth-based MCP it opens a browser tab and
the user signs in there. The local Figma Dev Mode MCP authenticates against the
running desktop app. Either way, `.mcp.json` for these four sources contains ONLY
`type` and `url` — no `headers`, no `env`, no `Authorization`.

Tell the user about this ONCE at the end of Phase 6 ("the browser will open the
first time each MCP connects — sign in there"). Do NOT surface it as a question
during the interview.

### Token fallback — for non-OAuth sources ONLY

This applies only when the user names a SOT that is NOT in the table above — for
example a self-hosted Jira behind a custom auth proxy, an internal Notion-clone,
or a bespoke REST tracker. **SKIP this entirely for Linear, Atlassian Cloud,
Notion, and Figma Dev Mode — those are OAuth/local and never need a token here.**

If a non-listed source genuinely needs an API key: write it as an env-var
placeholder (e.g. `"Authorization": "Bearer ${CUSTOM_TRACKER_TOKEN}"`), NEVER
the literal secret, and tell the user which variable to export from their shell
profile.

## Phase 4 — Style learning (only if existing cases were found)

1. Read 10-20 random cases from `.tms/suites/` (sample across suites, not all from one).
2. Form a DRAFT of `conventions.md` (use the template — see plugin templates).
3. Present the draft to the user:
   > "Here's what I learned about your style from existing cases. Review and tell me what to change."
4. List specifically:
   - Title style (imperative "Login with..." vs noun "Successful login")
   - Step granularity (atomic vs grouped)
   - Expected results format (one-liner vs list, where it lives — same step or next)
   - Frontmatter fields used (which are always present, which sometimes)
   - Tag taxonomy (list the tags found, ask which are canonical)
5. Wait for feedback. Iterate. Don't write to disk yet.

## Phase 5 — Glossary seeding

1. From the scanned cases, extract 10-20 frequent domain terms (proper nouns, feature names, abbreviations).
2. Present to the user:
   > "I found these terms in your cases. Translate or annotate the ones that matter; ignore the rest."
3. Build `glossary.md`.

## Phase 6 — Commit

1. Show the user the tree of what will be created:
   ```
   .mcp.json                  ← repo root: MCP servers for chosen sources (Phase 3)
   .tms/memory/
   ├── project.md
   ├── conventions.md
   ├── glossary.md
   ├── sot.yaml
   └── learned/
       ├── patterns.md  (empty for now)
       ├── shared-steps.md  (empty for now)
       └── tags.md  (auto-populated from scan)
   ```
2. Get explicit confirmation.
3. Create files using the templates (see plugin `templates/` directory). The plugin's templates live alongside `commands/` and `agents/`; copy them into the user's `.tms/memory/` and fill in the placeholders from interview answers.
4. **Wire up MCP servers** (only for the sources the user said yes to in Phase 3):
   - Target file: `.mcp.json` at the **repo root** (NOT inside `.tms/`). This is the
     standard Claude Code project-scope location and should be committed to git.
   - If `.mcp.json` already exists: read it, **merge** the new servers into the existing
     `mcpServers` object — never overwrite the file or clobber servers already there.
     If a server name already exists, leave the user's version untouched and tell them.
   - If it doesn't exist: create it with `{ "mcpServers": { ... } }`.
   - Use the entries from the Phase 3 MCP server map. Remember Jira+Confluence collapse
     to one `atlassian` entry.
   - Show the user the exact diff/content before writing, and get confirmation.
   - Make sure `sot.yaml` is written with a `notable_pages` field for Confluence
     (the Phase 3 discovery output, or an empty array with a TODO if discovery was
     deferred). Same applies symmetrically for Notion `relevant_database_ids` if
     the user picked Notion.
   - After writing, tell them: "MCP config written to `.mcp.json`. Restart Claude Code
     (or run `/reload-plugins`) so the servers start. For each of Linear / Atlassian /
     Notion a browser tab will open on first connect — sign in there. The Figma Dev
     Mode MCP needs the Figma desktop app running with Dev Mode MCP enabled — no
     browser step. No API tokens to configure for any of these four."
5. **Offer to seed starter browser routines** (optional). If the project is a web
   app and the user wants ready-to-run browser scenarios, copy the starter
   routines from the plugin `templates/routines/` into `.tms/routines/`
   (`RT-001`..`RT-003`: smoke tour, form submission, visual baseline). They are
   plain Markdown and committable; the user edits the target URL/selectors and runs
   them with `/run-routine RT-001`. See the `kensa-browser` skill for the verb set.
   Skip silently for non-web projects or if the user declines.
6. **Offer always-on kensa context** (optional). The plugin ships a `CLAUDE.md`
   operating manual at its root (`.claude/plugins/kensa-qa/CLAUDE.md`), but a
   plugin-folder `CLAUDE.md` is **not** auto-loaded — only a `CLAUDE.md` at the
   project root is. Offer to copy/merge it into `<project>/CLAUDE.md` so the QA team
   context is always in scope:
   - If the project has no root `CLAUDE.md`: offer to copy the plugin's verbatim.
   - If one exists: offer to append a fenced `<!-- kensa-qa -->` section (never
     clobber the user's content), or skip.
   - Show the diff and confirm before writing.
7. Tell the user how to use it: "Run `/new-feature <ref>` and I'll take it from here. Edit any file in `.tms/memory/` directly when conventions change — I re-read on every session. If I seeded routines, run `/run-routine <id>` to drive the browser."

## Notes for the agent running this command

- This is a long conversation, not a one-shot. Use multiple turns.
- Default to filling in sensible defaults when the user doesn't have an answer — but mark them as defaults in the file so the user knows to revisit.
- Never silently overwrite existing files.
- If the user says "skip this section" — honor it, mark the section as `TBD` in the resulting file.
