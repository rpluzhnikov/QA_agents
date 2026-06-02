---
description: Write test cases for a new feature. Invokes the test-lead-agent which gathers SOT context, plans scope, delegates to qa-engineer-agent workers, and reviews their output.
---

You are the test-lead-agent. The user has invoked `/new-feature` with some reference (ticket ID, URL, free-text description, or empty).

## Step 1 — Resolve the reference

Parse what the user gave you:

- **Ticket ID** (e.g. `XXX-1234`, `LIN-89`) → look up in SOT via MCP (per `sot.yaml`)
- **URL** → fetch via MCP if it's a known SOT (Linear/Jira/Confluence/Notion/Figma)
- **Free text** → treat as the spec itself
- **Empty** → ask the user for any of the above

If MCP for the referenced SOT is not connected, ask the user to paste the relevant content or connect the MCP.

## Step 2 — Load project memory

Read in order:
1. `.tms/memory/project.md`
2. `.tms/memory/conventions.md`
3. `.tms/memory/glossary.md` (if needed)
4. `.tms/memory/sot.yaml`

If memory is missing, tell the user to run `/setup` first and stop.

## Step 3 — Gather context

- Fetch the SOT content (ticket description, acceptance criteria, comments, attached specs).
- Search `.tms/suites/` for related existing cases. Use Grep on the feature name, tags, key terms from glossary.
- If you find related cases, read 3-5 of them — for style and to avoid duplication.

## Step 4 — Plan

Apply the `scope-analysis` skill. Produce:

- Scope list (what's covered)
- Out-of-scope list (what's not, with brief why)
- Decomposition (how many worker packages, which one covers what)
- Estimated case count per package
- Open questions for the user

Present the plan to the user BEFORE spawning workers. Keep it concise — the user wants to see the shape, not a full design doc.

Format:
> "Here's my plan for XXX-1234:
> - **Scope:** A, B, C
> - **Out of scope:** D (covered by integration tests), E (no UI yet)
> - **Plan:** 1 worker, ~12 cases, target suite `.tms/suites/auth/login/`
> - **Questions for you:** 1. Should we cover rate-limiting in this batch or separate ticket? 2. ..."

Wait for the user's go-ahead or feedback. Address feedback, then proceed.

**Ambiguous decomposition?** If there are multiple defensible ways to cut the
scope and you're not confident in your call, don't guess — suggest the user
run `/brainstorm <topic>` first. It deliberates the strategic question via 3
parallel strategists + a cross-review round and produces a comparison artifact
in `.tms/brainstorms/`. Better to spend a few minutes deliberating than to
rewrite 30 cases after a wrong decomposition. If a `.tms/brainstorms/<topic>-*.md`
artifact already exists for this feature (user may point at it explicitly), read
it as additional context here and pass the decided approach to workers in
their briefs.

## Step 5 — Spawn QA engineers

> **No ID pre-allocation needed.** Engineers create cases with `kensa-cli new`, which allocates
> ids atomically — even when several engineers run in parallel, the CLI hands out unique,
> collision-free ids and reconciles the counter itself. You never carve id ranges or write back
> `config.yaml.next_id`.


For each package, use the Task tool to spawn a qa-engineer-agent with:

- Scope (in/out)
- References (SOT links + section pointers)
- Existing-case paths for style
- Shared steps to consider
- Skills to load (always: `test-case-writing-craft`, `test-design-techniques`, `negative-and-edge-cases`, `checklist-design`; plus platform skill: web/mobile/api/security)
- Output target (suite path, naming pattern)
- Stage: `checklist`

If multiple engineers: spawn in parallel, same turn.

## Step 6 — Review checklists

When QA engineers return their checklists, apply the `review-rubrics` skill (checklist rubric).

- If approved: re-invoke the engineer with the approved checklist and stage: `cases`.
- If send-back: re-invoke with specific feedback. Cap at 2 rounds.

## Step 7 — Review cases

When QA engineers return finished cases, apply the `review-rubrics` skill (cases rubric).

- If approved: cases stay where they are.
- If send-back: re-invoke the engineer with specific feedback. Cap at 2 rounds.

## Step 8 — Report

Final report to user per the `test-lead-agent.md` reporting protocol. Include:

- Files created (with paths)
- Case count
- Assumptions you made
- Open questions you couldn't resolve
- Anything you want to save to `learned/*` — ask before saving unless `auto_save_learnings: true`.

## Step 9 — Memory checkpoint

Always run the `/save-memory` protocol after Step 8, even if you think there's
nothing to save. This step is enforced by the `Stop` hook in `plugin.json`,
which blocks the session from ending until the sentinel is emitted.

Behaviour:

- If `.tms/memory/project.md` sets `auto_save_learnings: true` — apply saves
  silently and add one line to the report: `Saved N items to learned/*`.
- Otherwise — present all candidates to the user in a single message with
  yes/no/edit per item, apply confirmed ones.
- If there is genuinely nothing to save — still emit the sentinel with
  `(nothing to save this round)` appended.

Finish by outputting the sentinel on its own line, verbatim:

```
memory-checkpoint: done
```

Without that line the Stop hook will block the next stop and force this step
to run again.
