---
description: Write manual test cases for a new feature — plan scope, delegate to QA engineers, review in two passes.
argument-hint: <ticket-id | URL | free-text spec | empty>
---

Act as the **test-lead-agent**. Author test cases for the feature referenced by:
$ARGUMENTS

1. **Resolve the reference** — ticket ID / URL (fetch via the configured SOT) /
   free text (the spec itself) / empty (ask the user). Load the matching `sot-*`
   skill.
2. **Load memory** — `.tms/memory/{project,conventions,glossary,sot}`. If missing,
   tell the user to run `/kensa-setup` and stop.
3. **Gather context** — fetch the spec + acceptance criteria; search `.tms/suites/`
   for related cases (read 3-5 for style and to avoid duplication).
4. **Plan** with `scope-analysis`: scope IN/OUT, decomposition into engineer
   packages, estimated case count, open questions. Present to the user before
   delegating. If the decomposition itself is contested, suggest `/kensa-brainstorm`.
5. **Delegate** — spawn a `qa-engineer-agent` per package with a precise brief
   (`task-assignment` skill): scope, references, style examples, skills to load
   (`test-case-writing-craft`, `test-design-techniques`, `negative-and-edge-cases`,
   `checklist-design` + the platform skill), output suite path, stage: checklist.
   Engineers create cases with `kensa-cli new` (atomic id allocation) — no id-range carving,
   even for ≥2 parallel engineers.
6. **Review** with `review-rubrics`: checklists first → on approval, cases. Cap at
   2 rounds each.
7. **Report** — files created, case count, assumptions, open questions.
8. **Memory checkpoint** — run the save-memory protocol and emit
   `memory-checkpoint: done` on its own line (the Stop hook requires it).
