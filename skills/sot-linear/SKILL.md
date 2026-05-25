---
name: sot-linear
description: Extract test requirements from a Linear issue via the Linear MCP — issue body, acceptance criteria, comments, sub-issues, attached docs, and project/cycle context. Use when the Test Lead hands a QA Engineer a Linear reference (issue ID like ENG-123 or an issue URL). Tells you where AC live in Linear, which MCP tools to call, and how Linear's sub-issue/project/cycle model maps to coverage.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (Linear MCP server integration for extracting test requirements from Linear issues). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: operationalises CTFL §1.4.4 traceability between test basis and testware for Linear as the Source of Truth; surfaces acceptance criteria per §4.5.2 from Linear-native AC checklists.

# SOT — Linear

You mine a Linear issue for **what must be verifiably true when it's done**. Linear
issues are usually terser than Jira/Confluence — the body is Markdown, AC are often a
checklist, and important detail hides in comments and sub-issues.

## MCP tools

Linear is served by the **`linear`** MCP server (wired into `.mcp.json` by `/setup`,
official remote `https://mcp.linear.app/sse`, OAuth on first connect). List the
available `mcp__linear__*` tools and match by purpose:

- **Get an issue by ID** — body (Markdown), state, labels, priority, assignee, the
  parent issue, and project/cycle. Your primary call.
- **Search/list issues** — to fetch sub-issues (children of the parent) or sibling
  issues in the same project.
- **Get comments** — clarifications and amended AC after the body was written.

If the Linear MCP isn't connected, ask the user to run `/setup` or paste the issue.

## Where acceptance criteria live (check in this order)

1. **A checklist in the body** — `- [ ]` items under an "Acceptance Criteria" / "AC" /
   "Requirements" heading. The most common and most authoritative source in Linear.
2. **Body prose** — when there's no explicit checklist, the behavior is described in
   the description; extract the requirements from it.
3. **Comments** — late clarifications and edge cases. Latest clarification wins on
   conflict; flag the conflict as a `GAP:`.
4. **Linked docs / attachments** — Linear documents, Figma links, or attached specs.
   Follow them (`sot-figma` / `sot-confluence` / `sot-notion` as appropriate).

## Hierarchy and context → scope

- **Sub-issues** — Linear's decomposition unit. A parent issue with sub-issues is your
  scope map: each sub-issue is a candidate QA Engineer package or checklist section. Confirm
  with the Test Lead which sub-issues are in this run.
- **Parent issue** — gives the umbrella intent; cover the in-scope sub-issues under it.
- **Project** — groups issues toward a larger goal; useful for understanding adjacent
  features that interact, not a direct test target.
- **Cycle** — a time-box (sprint). Tells you what's shipping together, useful for
  prioritizing regression scope, not a source of AC.
- **Labels** — `bug`, `regression`, `needs-design` etc. signal coverage emphasis. A
  `bug` issue always needs a regression case reproducing the original report.

## Extraction workflow

1. Get the issue. Record: ID (e.g. `ENG-123`) as `source_id`, title, state, labels.
2. Locate AC using the priority list. Convert each checklist item into one or more
   verifiable conditions.
3. Pull sub-issues; decide scope with the Test Lead.
4. Follow linked Figma/docs and extract from there too.
5. Read comments for amendments. Anything vague ("make it snappy") is a `GAP:` — don't
   invent the threshold.

## Pitfalls

- Linear states (`Backlog/Todo/In Progress/Done`) describe workflow, not AC quality —
  trust the AC text.
- An empty or one-line body with everything in sub-issues is common — don't conclude
  "no requirements" before walking the children.
- Linear Markdown supports tables and toggles; make sure you fetched the full body.

If this team consistently structures Linear issues a certain way, record it in
`.tms/memory/learned/patterns.md`.
