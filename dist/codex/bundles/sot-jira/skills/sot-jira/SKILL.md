---
name: sot-jira
description: Extract test requirements from a Jira issue via the Atlassian MCP — description, acceptance criteria (custom field or templated section), comments, sub-tasks, and linked Confluence specs. Use when the Test Lead hands a QA Engineer a Jira reference (issue key like ABC-123 or an issue URL) and you need to turn it into testable scope. Tells you where AC actually live in Jira, which MCP tools to call, and how the epic→story→sub-task hierarchy maps to coverage.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (Atlassian MCP server integration for extracting test requirements from Jira issues). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: operationalises CTFL §1.4.4 traceability between test basis and testware for Jira as the Source of Truth; surfaces acceptance criteria per §4.5.2 from Jira custom fields and templated AC sections.

# SOT — Jira

You read Jira to answer one question: **what must be true for this work to be
"done", and how do I verify each of those things?** You are not triaging or creating
issues — you are mining an existing issue for acceptance criteria and turning them
into test scope.

## MCP tools

Jira is served by the **`atlassian`** MCP server (wired into `.mcp.json` by `/setup`,
remote `https://mcp.atlassian.com/v1/mcp`, OAuth on first connect). The same server
covers Confluence — see `sot-confluence`.

Exact tool names depend on the connected server version, so **list the available
`mcp__atlassian__*` tools first** and match by purpose. You will typically need:

- **Get an issue by key** — fetches summary, description, status, issue type, custom
  fields, and the parent/epic link. Your primary call.
- **Search by JQL** — to find sub-tasks, linked issues, or sibling stories under an
  epic (e.g. `parent = ABC-123` or `"Epic Link" = ABC-100`).
- **Get comments** — AC are often clarified or amended in comments after the
  description was written.
- **Get remote/issue links** — to discover linked Confluence specs and related issues.

If the Atlassian MCP is not connected, say so and ask the user to run `/setup` or paste
the issue text.

## Where acceptance criteria actually live (check in this order)

1. **A dedicated "Acceptance Criteria" custom field.** Many teams have one. It is the
   most authoritative source when present. Read the issue's custom fields.
2. **A templated section in the description** — headings like `## Acceptance Criteria`,
   `## AC`, a Gherkin `Given/When/Then` block, or a checklist of `[ ]` items.
3. **The description prose itself** — when there's no explicit AC, the behavioral
   requirements are embedded in the narrative. Extract them.
4. **Comments** — late clarifications, edge cases raised in review, "also make sure X".
   Treat the *latest* clarification as authoritative when it conflicts with the body.
5. **Linked Confluence spec** — the issue may delegate detail to a page. Follow the
   link and switch to `sot-confluence`.

When sources conflict, the order of authority is usually: dedicated AC field >
latest comment clarification > description. Surface the conflict as a `GAP:` rather
than silently picking one.

## Hierarchy → scope

- **Epic** — too coarse to test directly. Get its child stories (JQL on Epic Link) and
  ask the Test Lead which story is in scope. Don't write cases against a whole epic.
- **Story** — the normal unit. One story usually maps to one QA Engineer package.
- **Sub-task** — a slice of a story. Cover it within the story's scope; don't treat
  each sub-task as a separate suite unless it represents an independently testable
  surface (e.g. an API sub-task vs a UI sub-task).
- **Bug** — the AC is "the reported behavior no longer happens AND the correct behavior
  does". Always produce a regression case that reproduces the original bug steps.

## Extraction workflow

1. Get the issue. Record: key, type, summary, status, `source_id` (the key, e.g.
   `ABC-123`) — QA Engineers stamp this on every case's frontmatter.
2. Locate AC using the priority list above.
3. Pull sub-tasks and linked issues; decide with the Test Lead whether they're in scope.
4. Follow Confluence/spec links and extract from there too (`sot-confluence`).
5. Convert each AC into one or more verifiable conditions. Anything vague
   ("works correctly", "is fast") is a `GAP:` — flag it; don't invent the threshold.
6. Note attachments (mockups, error screenshots) — they often encode untyped
   requirements (states, validation messages, empty/error views).

## Pitfalls

- Status ≠ readiness. A "Done" issue can still have stale AC; trust the AC text, not
  the workflow column.
- Jira renders ADF (Atlassian Document Format); tables and panels may come through as
  flattened text — don't lose the structure of a requirements table.
- "Definition of Done" (team-wide checklist) is not the same as this issue's AC. Use it
  for cross-cutting coverage (a11y, i18n) but don't mistake it for the feature spec.

When you keep extracting the same shape from this team's Jira (e.g. AC always in a
specific field), record it in `.tms/memory/learned/patterns.md` so the next run is
faster.
