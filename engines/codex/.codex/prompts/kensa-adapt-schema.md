---
description: Adapt the Kensa project schema to a user's existing TMS export (CSV / JSON / YAML / XML) — additively add/rename fields to fit their case structure via kensa schema, then signal `adapt ready` and hand off. Imports nothing; the user loads the full export via Universal format afterwards.
argument-hint: [path(s) to 1-2 sample case files] (optional)
---

Act as the **test-lead-agent**. Adapt the project schema to the user's existing
test-case export before importing it. The argument is $ARGUMENTS — paths to one or two
representative sample files (or empty).

Principle: **data follows schema, never the reverse.** The `schema-bootstrap-agent`
shapes the structure once; the user imports their full export deterministically via
Kensa's **Universal format** importer afterwards. This prompt **adapts the schema and
hands off — it imports no cases.**

1. **Resolve samples** — preflight `kensa --version`; if the CLI isn't on PATH, tell
   the user and stop (everything below drives `kensa schema`). No `.tms/memory/`
   required — this typically runs *before* `/kensa-setup` on a migration (schema first,
   then import, then setup learns conventions from the imported cases). Use the given
   paths, else look for export files (CSV / JSON / YAML / XML) and confirm 1–2
   representative ones with the user. If none, ask — never guess a schema from nothing.
   Read the current schema: `kensa schema show --format json` (note system + existing
   custom fields so nothing gets clobbered).
2. **Delegate** — spawn the `schema-bootstrap-agent` with: the sample path(s), the
   current schema, any user intent, and the contract (additive only; preview before
   apply; `adapt ready` last; import nothing; don't delete/rewrite existing fields
   unless asked). It runs `kensa schema preview/apply` (+ `migrate` if v1) then
   `kensa adapt ready`, and returns a mapping report.
3. **Review** — before anything destructive, check the proposed mapping. Default to
   additive (new custom field) over renaming a system field; confirm any drop/overwrite
   with the user. Verify every sample column maps to a system or custom field.
4. **Report** — fields added/renamed (with types), how each column maps (system field ·
   new custom field · "lands in `custom.<key>` on import"), that the schema is adapted
   (`adapt ready` ran — the GUI will prompt), and the one next step: **load the full
   export via Universal format**.

This prompt mutates only `.tms/schema.yaml` (additively) and writes the
`adapt-ready.json` sentinel. It authors **no** test cases and owes no memory
checkpoint — only `/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on.

End your final message with:

✅ **Done:** schema adapted — <N> fields added/renamed; `adapt ready` signaled; mapping report above
➡️ **Next:** 1. load the full export via **Universal format** in the Kensa GUI (unmapped columns land in `custom.<key>`); 2. `/kensa-setup` (update mode) so conventions are learned from the imported cases; 3. `/kensa-audit` to baseline the imported base's health.
