---
description: Author a new browser routine (.tms/routines/RT-NNN.md) through a short interview — goal, target URL, steps, pass criteria — using the starter templates as the skeleton. Run it afterwards with /run-routine.
argument-hint: [routine name, optional]
---

You are the test-lead-agent. The user invoked `/new-routine` to capture a
repeatable browser scenario as a routine file. Load the `kensa-browser` skill
for what routines can do at run time.

## Step 1 — Interview (short)

Ask only what you can't infer:

1. **Goal** — what should this routine verify each time it runs? (smoke tour,
   a form flow, a visual baseline, a regression hotspot)
2. **Target** — base URL / entry page (test/staging — never production with
   real credentials).
3. **Steps** — the scenario in the user's words; you'll structure them.
4. **Pass criteria** — what observable state means "green".

If the user gave a name argument, propose the goal from it and confirm.

## Step 2 — Write the file

1. Allocate the next id: list `.tms/routines/RT-*.md`, take max+1 (RT-001 if the
   directory is empty; create it if missing).
2. Use the starter routines in the plugin `templates/routines/` as the skeleton
   (frontmatter: `name`, `description`, `engine`; body = the prompt executed at
   run time). Write the scenario as numbered steps with expected observations,
   concrete selectors/labels where known, and the pass criteria at the end.
3. Show the draft, apply the user's edits, save `.tms/routines/RT-NNN.md`.

This command writes one routine file; it authors no cases and owes no memory
checkpoint.

## Epilogue (required)

✅ **Done:** .tms/routines/RT-NNN.md — <name>
➡️ **Next:**
- `/run-routine RT-NNN` — execute it now (Chrome must be started from Tools → Browser)
- edit the file directly anytime — it's plain markdown
