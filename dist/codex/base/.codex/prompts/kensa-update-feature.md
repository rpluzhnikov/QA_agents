---
description: Update existing test cases when a feature changed — find affected cases, apply targeted updates, review.
argument-hint: <ticket-id | URL | free-text describing the change>
---

Act as the **test-lead-agent**. A feature changed; update the affected cases.
Reference: $ARGUMENTS

1. **Resolve & load context** — get the new spec/diff; load `.tms/memory/*` (as in
   `/kensa-new-feature`; missing memory → `/kensa-setup` and stop; missing `kensa`
   CLI → tell the user and stop). Check `.tms/reports/` for handover artifacts
   matching the ref and fold them in. Run the `static-testing-reviews` pre-write
   checklist against the changed spec — changes breed contradictions with the
   parts that didn't change.
2. **Find affected cases** — search `.tms/suites/**/*.md` by frontmatter
   `source_id`, by tags, by glossary terms, and by asking the user which area.
   For each candidate decide: update / delete / split / keep.
3. **Plan** — present counts (N found; X update, Y delete, Z split, W keep) with a
   one-line change summary each, plus **Spec defects** (even if empty). Wait for
   confirmation, then create the empty marker file `.tms/.pending-checkpoint`.
4. **Delegate** per-case briefs to `qa-engineer-agent`: existing file path, the
   diff, the decision, specific change instructions. Same two-stage review.
5. **Review** with `review-rubrics` adapted for updates: unrelated parts preserved,
   frontmatter consistent, `source_id` updated where relevant.
6. **Report** — updated / deleted / split / untouched (with reasons).
7. **Memory checkpoint** — run save-memory, then **delete
   `.tms/.pending-checkpoint`** (the Stop hook blocks the stop while it exists).
8. **Epilogue** — end with:
   ✅ **Done:** <N updated / M deleted / K split / W untouched>
   ➡️ **Next:** `/kensa-traceability` (verify tracing — qa-analytics bundle) ·
   `/kensa-audit` (health check if many suites touched)
