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

## Step 4.5 — Allocate ID ranges (only if spawning ≥2 workers)

When the plan calls for one QA engineer, skip this step — the engineer just reads
`.tms/config.yaml` `project.next_id` and increments from there.

When the plan calls for two or more QA engineers spawned in the same turn, you MUST
hand each engineer a non-overlapping ID range, otherwise two engineers will both
claim id 1 and produce filename collisions.

1. Read `.tms/config.yaml` and note `project.next_id` (call it `START`).
2. For each engineer package, use its estimated case count from Step 4 as the size
   (round up — better to over-allocate than collide). Carve contiguous ranges,
   leaving no gaps and no overlap.
3. Embed the assigned range in the brief as `id_range: NNN-MMM` (zero-padded to
   3 digits to match the filename convention). The engineer uses NNN as its first
   case ID and increments locally; if it produces fewer cases than the range, the
   tail of the range is wasted and that's fine.

Example: `next_id: 1`, three engineers estimated at 19 / 19 / 17 cases
→ engineer A: `id_range: 001-019`, engineer B: `id_range: 020-038`, engineer C: `id_range: 039-055`.

After the engineers report back, the actual highest ID used across all engineers is
what gets written back to `config.yaml.next_id` (the Test Lead does this, not the
QA engineers — they don't touch config).


## Step 5 — Spawn QA engineers

**First, pick the engine.** Read `.tms/memory/codex.yaml`. If `codex_role: worker`
AND the detection helper prints `codex` (see `test-lead-agent.md` → "Codex
delegation"), you may delegate packages to Codex instead of the internal agent;
otherwise (missing file, `off`, `reviewer`, or detection `internal`) use the
internal `qa-engineer-agent` exactly as below. The choice is per-package and
fail-closed — any Codex error drops that package back to internal.

**Internal path (default).** For each package, use the Task tool to spawn a
qa-engineer-agent with:

- Scope (in/out)
- References (SOT links + section pointers)
- Existing-case paths for style
- Shared steps to consider
- Skills to load (always: `test-case-writing-craft`, `test-design-techniques`, `negative-and-edge-cases`, `checklist-design`; plus platform skill: web/mobile/api/security)
- Output target (suite path, naming pattern)
- Stage: `checklist`

If multiple engineers: spawn in parallel, same turn.

**Codex worker path (`codex_role: worker`).** For each package handed to Codex,
fill `codex/prompts/codex-worker-package.md` and run `codex exec` read-only,
capturing the final message — per the procedure in `test-lead-agent.md` → "Codex
delegation → `codex_role: worker`". Key points: paste the SOT content and the
distilled authoring rules into the brief (Codex has no skills and no MCP); reuse
the Step 4.5 `id_range` carving for parallel packages; Codex **returns** content,
**you write** the files; then run the same Step 6/7 two-pass review on the
result. If a package fails (non-zero exit, empty/garbled output, `CODEX_ERROR`,
`400`), silently fall back to an internal `qa-engineer-agent` for it.

## Step 6 — Review checklists

When QA engineers return their checklists, apply the `review-rubrics` skill (checklist rubric).

- If approved: re-invoke the engineer with the approved checklist and stage: `cases`.
- If send-back: re-invoke with specific feedback. Cap at 2 rounds.

## Step 7 — Review cases

When QA engineers return finished cases, apply the `review-rubrics` skill (cases rubric).

- If approved: cases stay where they are.
- If send-back: re-invoke the engineer with specific feedback. Cap at 2 rounds.

**Codex second opinion (`codex_role: reviewer`, or `codex_review: on`/`auto`
with Codex available).** After your own cases-rubric pass, fill
`codex/prompts/codex-reviewer.md` and pipe it to `codex exec` read-only for an
independent verdict, then fold it into your decision — see `test-lead-agent.md` →
"Codex delegation → `codex_role: reviewer`". Advisory only; surface genuine
disagreements to the user. Fail-closed: no verdict ⇒ your review stands alone.

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
