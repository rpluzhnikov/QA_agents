---
description: Adapt the Kensa project schema to a user's existing TMS export (CSV / JSON / YAML / XML) — additively add/rename fields to fit their case structure via kensa-cli schema, then signal `adapt ready` and hand off. Imports nothing; the user loads the full export via Universal format afterwards.
argument-hint: [path(s) to 1-2 sample case files] (optional)
---

You are the **test-lead-agent**. The user invoked `/adapt-schema` to fit the project
schema to their **existing** test-case export before importing it. The argument is
$ARGUMENTS — paths to one or two representative sample files (or empty).

The principle: **data follows schema, never the reverse.** You (via the
`schema-bootstrap-agent`) shape the structure once; the user imports their full export
deterministically through Kensa's **Universal format** importer afterwards. This
command **adapts the schema and hands off — it imports no cases.**

## Phase 1 — Resolve the samples

1. If sample paths were given, use them. Otherwise look for likely export files in the
   project (CSV / JSON / YAML / XML) and ask the user to confirm 1–2 representative ones.
   - If none can be found, ask the user to point at 1–2 files. Do **not** guess a schema
     from nothing.
2. Read the current schema: `kensa-cli schema show --format json`. Note system fields
   and any existing custom fields so nothing gets clobbered.

## Phase 2 — Delegate to the schema-bootstrap-agent

Spawn the `schema-bootstrap-agent` (via the Task tool) with a brief containing:
- the sample file path(s),
- the current schema (from `schema show`),
- any user intent ("keep my field names", "map Summary → title", …),
- the contract: **additive only**, preview before apply, `adapt ready` last, **import
  nothing**, don't delete/rewrite existing fields unless the user asked.

The agent reads the samples, infers field names + types, runs
`kensa-cli schema preview` / `apply` (and `schema migrate` if the schema is v1), then
`kensa-cli adapt ready`, and returns a mapping report.

## Phase 3 — Review & confirm

1. Review the agent's proposed mapping **before** anything destructive. If it flagged a
   change that would drop or overwrite an existing field, confirm with the user first —
   default to additive (new custom field) over renaming a system field.
2. Confirm every sample column maps to either a system field or a new custom field.

## Phase 4 — Report

Tell the user, concisely:
- which fields were added / renamed (with types),
- how each of their columns maps (system field · new custom field · "lands in
  `custom.<key>` on import"),
- that the schema is now adapted (`adapt ready` ran — the Kensa GUI will prompt), and
- the one next step: **load the full export via Universal format** — the importer parses
  any CSV / JSON / YAML / XML into this schema; unmapped columns become custom fields.

This command mutates only `.tms/schema.yaml` (additively) and writes the
`adapt-ready.json` sentinel. It authors **no** test cases and does **not** emit
`memory-checkpoint: done` — the Stop hook only enforces checkpoints for `/new-feature`
and `/update-feature`.
