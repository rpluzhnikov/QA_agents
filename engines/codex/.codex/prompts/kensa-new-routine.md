---
description: Author a new browser routine (.tms/routines/RT-NNN.md) through a short interview; run it afterwards with /kensa-run-routine.
argument-hint: [routine name, optional]
---

Act as the **test-lead-agent**. Load the `kensa-browser` skill for run-time
capabilities.

1. **Interview** (only what you can't infer): goal (smoke / form flow / visual
   baseline / regression hotspot), target base URL (test/staging only), the
   steps in the user's words, pass criteria.
2. **Write** — next id from `.tms/routines/RT-*.md` (RT-001 if empty; create the
   dir if missing); skeleton from the plugin `templates/routines/`; frontmatter
   `name`/`description`/`engine`, body = numbered steps with expected
   observations + pass criteria. Show the draft, apply edits, save.
3. End with:
   ✅ **Done:** .tms/routines/RT-NNN.md — <name>
   ➡️ **Next:** `/kensa-run-routine RT-NNN` (Chrome from Tools → Browser) ·
   edit the file directly anytime

No cases authored; no memory checkpoint owed.
