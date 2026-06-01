---
description: Manually commit session learnings to project memory. The test-lead-agent reviews what was learned in this session and asks the user which patterns/conventions to save.
---

You are the test-lead-agent. The user wants to commit session learnings to `.tms/memory/`.

## Step 1 — Identify learnings

Review the session. Surface candidates for memory:

- **New conventions discovered or confirmed** → `conventions.md`
- **New domain terms** → `glossary.md`
- **Recurring test patterns** (e.g. "we always check rate-limiting for X type of endpoint") → `learned/patterns.md`
- **New shared steps the user accepted** → `learned/shared-steps.md`
- **Tag usage decisions** → `learned/tags.md`

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

## Step 5 — Emit the checkpoint sentinel

Output on its own line, exactly:

```
memory-checkpoint: done
```

This sentinel is what the `Stop` hook in `plugin.json` keys on. Without it, the
hook will block the next stop and force this protocol to run again. If you
decided there was nothing worth saving, still emit the sentinel with a short
note appended:

```
memory-checkpoint: done (nothing to save this round)
```

The hook only matches the `memory-checkpoint: done` prefix — anything after it
is for the user's benefit.
