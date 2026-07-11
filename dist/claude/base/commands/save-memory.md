---
description: Manually commit session learnings to project memory. The test-lead-agent reviews what was learned in this session and asks the user which patterns/conventions to save.
---

You are the test-lead-agent. The user wants to commit session learnings to `.tms/memory/`.

If `.tms/memory/` does not exist, tell the user to run `/setup` first, delete
`.tms/.pending-checkpoint` if present, and stop.

## Step 1 — Identify learnings

Review the session. Surface candidates for memory:

- **New conventions discovered or confirmed** → `conventions.md`
- **New domain terms** → `glossary.md`
- **Recurring test patterns** (e.g. "we always check rate-limiting for X type of endpoint") → `learned/patterns.md`
- **New shared steps the user accepted** → `learned/shared-steps.md`
- **Tag usage decisions** → `learned/tags.md`

Also sweep the session for `ASSUMPTION:` and `GAP:` markers (from engineer
briefs, plans, and spec-defect blocks). If any exist, append them to
`.tms/reports/assumptions-<ref>-<date>.md` — a standing questions-to-PM ledger —
without asking per item (it's a report, not memory). Mention the file in Step 4.

## Step 2 — Propose

Present each candidate as a discrete proposal:

> "I'd like to save these to project memory. Tell me yes/no/edit for each:
> 1. **conventions.md**: 'Step descriptions use imperative form starting with a verb (Open, Click, Enter), not infinitive.' [yes/no/edit]
> 2. **glossary.md**: Add `KYC = Know Your Customer, refer to as 'верификация' in case text` [yes/no/edit]
> 3. **learned/patterns.md**: 'For any endpoint accepting user-controlled IDs, always include IDOR scenario.' [yes/no/edit]"

## Step 3 — Apply

For confirmed items, append to the relevant file with a timestamp comment:

```markdown
<!-- Added 2025-XX-XX from session: feature LIN-89 -->
- Step descriptions use imperative form...
```

This makes it easy to audit later what was learned when.

## Step 4 — Report

"Saved 3 items. Memory updated. To review, edit `.tms/memory/conventions.md` and friends directly."
If nothing was worth saving, say so in one line. If assumptions were swept,
name the ledger file.

## Step 5 — Release the checkpoint

Delete `.tms/.pending-checkpoint` if it exists. The `Stop` hook blocks the
session from ending while that marker file is present — deleting it is what
closes the checkpoint (there is no chat sentinel).

## Epilogue (required)

✅ **Done:** <N items saved to memory; assumptions ledger updated or "nothing to save">
➡️ **Next:** `/next` — see where the project stands and what's worth doing now
