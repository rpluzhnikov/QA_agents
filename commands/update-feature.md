---
description: Update existing test cases when a feature has changed. test-lead-agent finds affected cases, fetches the diff/new spec, and delegates targeted updates to qa-engineer-agent workers.
---

You are the test-lead-agent. The user invoked `/update-feature` with a reference to something that changed.

## Step 1 — Resolve and load context

Same as `/new-feature` Steps 1-2. Get the new spec, load project memory.

## Step 2 — Find affected cases

This is the key difference from `/new-feature`. You need to find cases that may need updating.

Strategies (use as many as apply):

1. **By `source_id`** — search `.tms/suites/**/*.md` for frontmatter `source_id: <ticket>` matching the changed feature.
2. **By tags** — if the feature has a known tag, search for cases with it.
3. **By glossary terms** — search for cases mentioning key terms.
4. **By user hint** — ask: "Which suite or area was this feature in? It helps me narrow the search."

Read the candidates and decide for each:

- **Update** — case is still valid in concept, needs specific changes
- **Delete** — case is now obsolete
- **Split** — case covered something now done by multiple cases
- **Keep** — case wasn't actually affected (false positive in search)

## Step 3 — Plan

Present to the user:

- Found N candidate cases.
- Of those: X to update, Y to delete, Z to split, W kept as-is.
- For each update: a one-line summary of what needs to change.
- QA engineer packages — usually one engineer per suite or per related cluster.

Wait for user confirmation, then proceed.

## Step 4 — Spawn QA engineers (per-case briefs)

QA engineers get a different brief shape than in `/new-feature`. For each case:

- Path to the existing case file
- The diff (what changed in the spec)
- The decision (update / delete / split into N)
- Specific change instructions

Same two-stage review (checklist of changes → applied changes).

## Step 5 — Review

Apply `review-rubrics` adapted for updates:

- Did the engineer preserve unrelated parts?
- Did frontmatter stay consistent?
- Did `source_id` get updated to the new ticket if relevant?

## Step 6 — Report

Same as `/new-feature` step 8. Also include:

- Cases updated / deleted / split
- Cases left untouched (with reason)

## Step 7 — Memory checkpoint

Same as `/new-feature` step 9 — run the save-memory protocol and emit the
sentinel `memory-checkpoint: done` on its own line. Enforced by the `Stop`
hook in `plugin.json`; without it the next stop will block.
