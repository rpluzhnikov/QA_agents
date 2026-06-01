---
name: sot-confluence
description: Extract test requirements from a Confluence spec via the Atlassian MCP — heading hierarchy, requirement tables, Gherkin/AC sections, decision logs, embedded designs, and child pages. Use when the Test Lead hands a QA Engineer a Confluence page URL (or a Jira issue links to one). Tells you how to walk a long spec for the testable parts, find the authoritative version among drafts, and read requirement tables without losing structure.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (Atlassian MCP server integration for extracting test requirements from Confluence specs). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: operationalises CTFL §1.4.4 traceability between test basis and testware for Confluence as the Source of Truth; surfaces acceptance criteria per §4.5.2 from requirement tables and Gherkin/AC sections.

# SOT — Confluence

Confluence pages are long and mixed: background, decisions, requirements, open
questions, and out-of-scope notes all share one document. Your job is to separate the
**normative requirements** (what the system must do) from everything else, and turn
those into test scope.

## MCP tools

Confluence is served by the **`atlassian`** MCP server (same server as Jira — wired
into `.mcp.json` by `/setup`). List the available `mcp__atlassian__*` tools and match
by purpose:

- **Get a page by ID/URL** — fetches the page body (storage/ADF), title, version, and
  space. Your primary call.
- **Get page children/descendants** — specs are often split across a parent page and
  child pages (one per area). Walk them.
- **Search by CQL** — to find related pages in the same space (`space = ENG and title ~
  "checkout"`) or the latest version of a spec when several drafts exist.

If the Atlassian MCP isn't connected, ask the user to run `/setup` or paste the page.

## Find the authoritative version first

Specs rot. Before extracting, confirm you're reading the live one:

- Prefer the page explicitly linked from the in-scope Jira issue.
- Check the title/labels for `DRAFT`, `WIP`, `Archived`, `Superseded`, or a version
  suffix. A page labelled `Archived` is not the spec.
- If several candidates exist, surface them to the Test Lead and ask which is canonical —
  don't guess.

## Where requirements live in a page

1. **Requirement tables** — rows of `Requirement | Description | Priority` or
   `Field | Validation | Error message`. The richest, most testable source. Preserve
   the row structure; each row is usually one or more cases.
2. **AC / Gherkin sections** — `Given/When/Then`, or a "Acceptance Criteria" /
   "Success Criteria" heading.
3. **Numbered/headed requirement sections** — walk the heading hierarchy; the leaf
   sections under "Requirements"/"Functional spec" carry the testable detail.
4. **Validation and error-handling sections** — explicit error messages and limits are
   gold for negative cases. Quote them verbatim into expected results.
5. **Decision logs / ADRs** — tell you *why* something is the way it is; useful for
   resolving ambiguity, not usually a direct source of cases.

## Read with structure intact

- Confluence body comes through as storage format or flattened text. A requirements
  table that flattens into a paragraph loses its rows — re-impose the structure when
  you extract, and if you can't tell where a row ends, flag a `GAP:`.
- Status macros (`/status` lozenges: TODO / IN PROGRESS / DONE) often mark which
  requirements are actually in this release. Respect them.
- Expand/collapse and panel macros can hide requirements — make sure you fetched the
  full body, not a truncated preview.

## Boundaries

- Honor explicit **"Out of scope" / "Non-goals"** sections — list them back to the Test Lead
  so cut scope is visible, never silently tested or skipped.
- **Embedded/linked designs** (Figma) carry visual and state requirements the prose
  omits — follow them and switch to `sot-figma`.
- **Open questions** sections mean the spec isn't settled. Each open question that
  touches in-scope behavior is a `GAP:` for the Test Lead to resolve with the user.

Record the `source_id` as the page URL/ID so QA Engineers can stamp it on cases. If this
space has a consistent spec template, note it in `.tms/memory/learned/patterns.md`.
