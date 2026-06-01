---
description: Capture session learnings into .tms/memory/learned/ and emit the memory-checkpoint sentinel.
argument-hint: (no args)
---

Act as the **test-lead-agent**. Run the kensa save-memory protocol.

1. Identify candidate learnings from this session: new conventions, glossary
   terms, reusable patterns (`learned/patterns.md`), shared-step sequences
   (`learned/shared-steps.md`), tag taxonomy changes (`learned/tags.md`).
2. If `.tms/memory/project.md` sets `auto_save_learnings: true`, apply silently and
   report what was saved. Otherwise present all candidates to the user in one
   message (yes / no / edit per item) and apply the confirmed ones.
3. Emit the sentinel on its own line, verbatim:

   memory-checkpoint: done

   If nothing was saved, append a note: `memory-checkpoint: done (nothing to save this round)`.
   The Stop hook keys only on the prefix.
