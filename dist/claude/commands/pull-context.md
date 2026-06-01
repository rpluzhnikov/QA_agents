---
description: Pull maximum context about a task or bug from all available sources of truth into one dossier. Read-only — gathers SOT content + related existing cases, surfaces gaps, writes a context dossier to .tms/reports/. A building block you run before /new-feature, /review-spec, or /risk-assess.
---

You are the test-lead-agent. The user invoked `/pull-context` with a reference
(ticket ID, URL, free-text, or empty). Your job is to gather everything known
about that work item from the sources of truth and the existing test base into
a single dossier — so the next step (planning, review, risk, or case-writing)
starts from full context instead of a cold ticket.

This command is **read-only**. It writes NO test cases, modifies NO cases, and
does NOT emit `memory-checkpoint: done` — the Stop hook only enforces
checkpoints for `/new-feature` and `/update-feature`.

## Step 1 — Resolve the reference

Parse what the user gave you (same rules as `/new-feature`):

- **Ticket ID** (e.g. `LIN-89`, `KAN-456`) → look up in SOT via MCP (per `sot.yaml`, using `primary_tracker` to disambiguate a bare key)
- **URL** → fetch via MCP if it's a known SOT (Linear/Jira/Confluence/Notion/Figma)
- **Free text** → treat as the spec itself; dossier is thin but still useful
- **Empty** → ask the user for any of the above, then stop until they answer

If MCP for the referenced SOT is not connected, tell the user honestly and offer
to work from pasted content (per `on_unresolved_ref` in `sot.yaml`).

## Step 2 — Load project memory

Read in order: `.tms/memory/project.md`, `conventions.md`, `glossary.md` (when
terms are unfamiliar), `sot.yaml`. If memory is missing → tell the user to run
`/setup` first and stop.

## Step 3 — Gather (the core of this command)

Load the matching SOT skill (`sot-linear`, `sot-jira`, `sot-confluence`,
`sot-notion`, `sot-figma`) — it tells you where AC live and which MCP tools to
call. Then pull, as available:

- Description / requirement body
- Acceptance criteria (in whatever form: checklist, Gherkin, table, prose)
- Comments and decision threads
- Linked / child items (sub-issues, linked Confluence pages, linked Figma frames)
- Attached specs and design references

Follow the links one hop out — a ticket that links a spec page and a Figma flow
means you read all three. Note the canonical source vs WIP explorations
(especially in Figma, per `sot-figma`).

## Step 4 — Cross-link with the existing test base

- `kensa-cli filter 'source_id = <ref>' --format json` → cases already traced to this ref.
- Grep `.tms/suites/` on the feature name, glossary terms, and key nouns → related cases under a different or missing `source_id`.
- If you find related cases, note their paths and whether the new work overlaps,
  extends, or supersedes them (informational — do not modify them).

## Step 5 — Surface gaps (light-touch only)

Flag what the source is *missing* so the reader knows the context isn't complete:
no acceptance criteria, undefined glossary terms, two statements that look
contradictory, no error/empty-state handling described. List them plainly.

Do **not** do a full static review here — that's `/review-spec`. This is a
"here's what's thin" pointer, not a graded findings report. If the gaps look
serious, recommend the user run `/review-spec <ref>` next.

## Step 6 — Write the dossier

Get today's date. Write `.tms/reports/context-<ref>-<YYYY-MM-DD>.md` (create
`.tms/reports/` if absent; it is committable — not in `.gitignore`). Slugify the
ref for the filename (e.g. `LIN-89` → `lin-89`; a URL → a short kebab slug). If
the file already exists for today, overwrite it.

Structure, in order:

```markdown
# Context dossier — <ref>

**Date:** YYYY-MM-DD
**Source(s):** <list with URLs>
**Primary tracker:** <linear|jira|...>

## Summary
<2-4 sentences: what this work item is, in plain language>

## Requirements & acceptance criteria
<distilled AC, with a pointer to the exact source section for each>

## Linked material
<sub-issues, spec pages, figma flows — each with URL and one-line relevance>

## Related existing cases
<paths/ids from Step 4 + overlap note (extends / duplicates / supersedes)>

## Open gaps
<bullets from Step 5 — what the source doesn't say>

## Handover
- For test cases → run `/new-feature <ref>` (point it at this dossier).
- If the spec looks shaky → run `/review-spec <ref>` first.
- For coverage-depth decisions → run `/risk-assess <ref>`.
```

## Step 7 — Report

Terminal: a ~10-line summary (sources pulled, # of AC, # of related cases,
# of gaps) and the file path. Do not paste the dossier into the terminal —
point at the file.

## Anti-patterns — do not do these

- **Don't write or modify test cases.** This is gather-only; case-writing is `/new-feature`.
- **Don't do a full spec review.** Light gap-flagging only; grading is `/review-spec`.
- **Don't emit `memory-checkpoint: done`.** The Stop hook doesn't require it here.
- **Don't guess past missing MCP.** If a source isn't connected, say so and ask for pasted content.
