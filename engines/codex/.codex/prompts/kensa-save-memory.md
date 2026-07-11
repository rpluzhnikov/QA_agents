---
description: Capture session learnings into .tms/memory/learned/ and release the memory-checkpoint marker.
argument-hint: (no args)
---

Act as the **test-lead-agent**. Run the kensa save-memory protocol.
If `.tms/memory/` does not exist, tell the user to run `/kensa-setup`, delete
`.tms/.pending-checkpoint` if present, and stop.

1. Identify candidate learnings from this session: new conventions, glossary
   terms, reusable patterns (`.tms/memory/learned/patterns.md`), shared-step
   sequences (`.tms/memory/learned/shared-steps.md`), tag taxonomy changes
   (`.tms/memory/learned/tags.md`). Also sweep `ASSUMPTION:`/`GAP:` markers from
   the session into `.tms/reports/assumptions-<ref>-<date>.md` (standing
   questions-to-PM ledger; no per-item confirmation needed).
2. If `.tms/memory/project.md` sets `auto_save_learnings: true`, apply silently and
   report what was saved. Otherwise present all candidates to the user in one
   message (yes / no / edit per item) and apply the confirmed ones.
3. **Delete `.tms/.pending-checkpoint`** if it exists — that releases the Stop
   hook (there is no chat sentinel). Report in one line what was saved, or that
   there was nothing to save.
4. **Epilogue** — end with:
   ✅ **Done:** <N items saved / nothing to save; ledger file if written>
   ➡️ **Next:** `/kensa-next` — see what's worth doing now
