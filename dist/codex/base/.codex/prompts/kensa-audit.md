---
description: Mechanical health check of the .tms/ repository — schema validation, duplicates, drift, tag hygiene.
argument-hint: [scope path, e.g. suites/auth] (optional)
---

Act as the **test-lead-agent**. Run a mechanical audit over the `.tms/` repository
(scope: $ARGUMENTS, default = all). This is the deterministic counterpart to the
semantic `/kensa-analyze-cases`.

Preflight: `.tms/memory/` exists (else "run `/kensa-setup` first" and stop);
`kensa --version` on PATH (else stop — every check below needs the CLI);
`kensa stats` — if the repo has < 20 cases, tell the user it's too small for a
meaningful audit ("come back at ~20+ cases; until then `kensa validate` and
`kensa lint` cover the basics") and stop.

Using the `kensa` skill, check:
- **Schema** — every case has required frontmatter (id, title, priority, status,
  tags, source_id) and valid values; report violations.
- **Duplicates** — `duplicates` / id collisions, filename clashes.
- **Drift** — cases whose conventions diverge from `.tms/memory/conventions.md`.
- **Tags** — tags not in the taxonomy (`learned/tags.md`); unused canonical tags.
- **Coverage** — `coverage --by-source` to spot sources with no cases.

Produce one markdown report in `.tms/reports/` with findings grouped by severity
and a concrete fix list. In the Recommendations, route content fixes via
`/kensa-update-feature`, point at `/kensa-analyze-cases` for the semantic layer
this mechanical scan can't see (qa-analytics bundle), and at `/kensa-traceability`
for requirement-coverage questions. Write no test cases; this command owes no
memory checkpoint — only `/kensa-new-feature` and `/kensa-update-feature` create
the `.tms/.pending-checkpoint` marker the Stop hook keys on.

End your final message with (only suggest commands whose bundle is installed —
otherwise name the bundle):

✅ **Done:** <N findings by severity; report at .tms/reports/audit-<date>.md>
➡️ **Next:** `/kensa-analyze-cases` — semantic layer on top of this scan (qa-analytics bundle) · `/kensa-update-feature <ref>` — route content fixes for flagged cases · `/kensa-traceability` — if untraced cases were found.
