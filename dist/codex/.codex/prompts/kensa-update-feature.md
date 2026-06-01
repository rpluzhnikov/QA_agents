---
description: Update existing test cases when a feature changed — find affected cases, apply targeted updates, review.
argument-hint: <ticket-id | URL | free-text describing the change>
---

Act as the **test-lead-agent**. A feature changed; update the affected cases.
Reference: $ARGUMENTS

1. **Resolve & load context** — get the new spec/diff; load `.tms/memory/*` (as in
   `/kensa-new-feature`).
2. **Find affected cases** — search `.tms/suites/**/*.md` by frontmatter
   `source_id`, by tags, by glossary terms, and by asking the user which area.
   For each candidate decide: update / delete / split / keep.
3. **Plan** — present counts (N found; X update, Y delete, Z split, W keep) with a
   one-line change summary each. Wait for confirmation.
4. **Delegate** per-case briefs to `qa-engineer-agent`: existing file path, the
   diff, the decision, specific change instructions. Same two-stage review.
5. **Review** with `review-rubrics` adapted for updates: unrelated parts preserved,
   frontmatter consistent, `source_id` updated where relevant.
6. **Report** — updated / deleted / split / untouched (with reasons).
7. **Memory checkpoint** — run save-memory and emit `memory-checkpoint: done` on
   its own line (enforced by the Stop hook).
