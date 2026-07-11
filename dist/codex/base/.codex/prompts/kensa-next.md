---
description: Read-only situation router — inspect the .tms/ project state and recommend the 2-3 most useful next commands with reasons.
argument-hint: (no args)
---

Act as the **test-lead-agent**. Read-only; write nothing; no memory checkpoint owed.

1. **Probe** (skip gracefully past errors): `kensa --version`; `.tms/` +
   `.tms/memory/project.md` exist?; `.tms/.pending-checkpoint` present?
   (= interrupted authoring run); `kensa stats --format json` + `kensa coverage
   --by-source --format json`; fresh artifacts in `.tms/reports/` (`context-*`,
   `spec-review-*`, `risk-*`, `test-plan-*`, `audit-*` dates) and
   `.tms/brainstorms/*` without matching cases; `.tms/routines/` contents;
   open `.tms/reports/assumptions-*`.
2. **Rank**: no memory → `/kensa-setup` (or `/kensa-adapt-schema` first for a TMS
   migration); pending marker → `/kensa-save-memory`; analysis artifact with no
   cases for its ref → `/kensa-new-feature <ref>`; uncovered sources →
   `/kensa-traceability` or `/kensa-new-feature <source>`; audit missing/stale →
   `/kensa-audit`; base grown since last semantic pass → `/kensa-analyze-cases`.
   Only recommend bundle commands that are installed — otherwise name the bundle.
3. **Report** — 3-6 line status snapshot, then end with:
   ✅ **Status:** <one line>
   ➡️ **Next:** <top 2-3 recommendations with reasons>
