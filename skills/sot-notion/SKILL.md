---
name: sot-notion
description: Extract test requirements from a Notion page or database via the Notion MCP — page blocks, database schema (including relation/rollup properties), sub-pages, and linked specs. Use when the Test Lead hands a QA Engineer a Notion page or database URL. Tells you how Notion's block + database model maps to extractable requirements, which MCP tools to call, and where AC tend to hide.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (Notion MCP server integration for extracting test requirements from Notion pages and databases). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: operationalises CTFL §1.4.4 traceability between test basis and testware for Notion as the Source of Truth; surfaces acceptance criteria per §4.5.2 from Notion blocks and database properties.

# SOT — Notion

Notion mixes two shapes: **pages** (block documents — like a spec) and **databases**
(structured rows with typed properties — like a requirements tracker). Extraction
differs for each. Your goal is the same: pull the normative, testable requirements.

## MCP tools

Notion is served by the **`notion`** MCP server (wired into `.mcp.json` by `/setup`,
remote `https://mcp.notion.com/mcp`, OAuth on first connect). List the available
`mcp__notion__*` tools and match by purpose:

- **Search** — resolve a title or keyword to a page/database when you don't have the URL.
- **Fetch / get page** — retrieve a page's blocks (the body). Notion paginates blocks
  and nests them (toggles, columns, sub-pages) — make sure you fetched children, not
  just the top level.
- **Query database** — retrieve rows with their properties, with filters/sorts.
- **Get database schema** — the property definitions (types, select options, relations).

If the Notion MCP isn't connected, ask the user to run `/setup` or paste the content.

## Pages — where requirements live

1. **AC / requirements headings** — `Acceptance Criteria`, `Requirements`, `Success
   Metrics`, or a to-do list (`[ ]` checkboxes) of behaviors.
2. **Callout and toggle blocks** — teams hide "Edge cases", "Error states", and "Out of
   scope" inside toggles; expand them — they're prime negative-case material.
3. **Tables** — inline tables of `Field | Rule | Message` map directly to validation
   cases. Preserve rows.
4. **Sub-pages** — a spec page often links to child pages per area. Walk them.
5. **Body prose** — extract embedded requirements when nothing is explicitly marked.

## Databases — schema is the spec

For a feature tracked as database rows, the **schema carries requirements**:

- **Select / multi-select** properties enumerate the valid states or categories — each
  option is an equivalence class to cover (and an invalid value to test).
- **Relation** properties link rows to other databases (e.g. a feature → its specs, or
  → linked Jira issues). Follow relations to find the detailed AC.
- **Rollup / formula** properties compute values from related rows — they encode rules
  (e.g. "status = Done only when all sub-tasks Done") that are themselves testable.
- **Status** properties tell you which rows are in scope for this release.

Query the database for the in-scope rows, read each row's properties AND its page body
(a Notion row is also a page — it can have a full spec inside).

## Extraction workflow

1. Resolve the reference. Record the page/row URL as `source_id`.
2. Determine page vs database and extract per the sections above.
3. Follow relations and sub-pages; decide scope with the Test Lead.
4. Convert each requirement into verifiable conditions; flag vague ones as `GAP:`.

## Pitfalls

- A database row looks empty if you only read its properties — open its page body too.
- Block pagination: a long page can return partial blocks; confirm you reached the end.
- Synced blocks and linked databases can show the same content in multiple places —
  don't double-count, and trace to the canonical source.
- Honor explicit "Out of scope" callouts; list them back to the Test Lead.

If this workspace uses a consistent spec/database structure, record it in
`.tms/memory/learned/patterns.md`.
