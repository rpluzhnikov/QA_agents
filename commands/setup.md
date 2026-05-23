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
   - What's the workspace/team/project ID they want me to use as default? (goes into `sot.yaml`)
   - Do you want me to wire up the MCP server for it during setup? (yes / no)
3. Unlike `sot.yaml` (which is just plugin config), the MCP servers are what actually
   lets the Lead read tickets and specs. In Phase 6 you will offer to write a project
   `.mcp.json` at the repo root containing the servers they said yes to. The plugin
   already bundles its own `sequential-thinking` MCP (declared in `plugin.json`) — do
   NOT add that one to the project file; it is always available.

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
- The Figma Dev Mode MCP is read-only design context. The write-capable `use_figma`
  tool (used by the `figma-use` skill) comes from a separate Figma plugin-API MCP; if
  the user wants that, ask them for its command/url rather than guessing — leave a
  commented placeholder in `.mcp.json` and tell them to fill it.
- If a source needs an API key/token instead of OAuth, write it as an env-var
  placeholder (`"Authorization": "Bearer ${SOURCE_API_KEY}"`), never the literal
  secret, and tell the user which variable to export.

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
   - After writing, tell them: "MCP config written to `.mcp.json`. Restart Claude Code
     (or run `/reload-plugins`) so the servers start, then approve them when prompted.
     The first connect to a remote server opens a browser for OAuth."
5. **Update `.gitignore`** at repo root to keep `.tms/debug/` out of git
   (the Stop hook in `plugin.json` writes per-session digests and transcript
   snapshots there; not safe to commit -- transcripts may contain ticket text,
   internal URLs, or secrets the user pasted into prompts):
   - If `.gitignore` exists and already has a `.tms/debug/` line: skip.
   - If `.gitignore` exists without it: append a comment + the rule.
   - If `.gitignore` doesn't exist: create it with the rule.
   - Show the user the diff before writing and confirm.
6. Tell the user how to use it: "Run `/new-feature <ref>` and I'll take it from here. Edit any file in `.tms/memory/` directly when conventions change — I re-read on every session. Per-session debug logs land in `.tms/debug/` if you ever need to share what happened."

## Notes for the agent running this command

- This is a long conversation, not a one-shot. Use multiple turns.
- Default to filling in sensible defaults when the user doesn't have an answer — but mark them as defaults in the file so the user knows to revisit.
- Never silently overwrite existing files.
- If the user says "skip this section" — honor it, mark the section as `TBD` in the resulting file.
