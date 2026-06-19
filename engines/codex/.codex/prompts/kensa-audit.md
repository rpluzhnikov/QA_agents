---
description: Mechanical health check of the .tms/ repository — schema validation, duplicates, drift, tag hygiene.
argument-hint: [scope path, e.g. suites/auth] (optional)
---

Act as the **test-lead-agent**. Run a mechanical audit over the `.tms/` repository
(scope: $ARGUMENTS, default = all). This is the deterministic counterpart to the
semantic `/kensa-analyze-cases`.

Using the `kensa` skill, check:
- **Schema** — every case has required frontmatter (id, title, priority, status,
  tags, source_id) and valid values; report violations.
- **Duplicates** — `duplicates` / id collisions, filename clashes.
- **Drift** — cases whose conventions diverge from `.tms/memory/conventions.md`.
- **Tags** — tags not in the taxonomy (`learned/tags.md`); unused canonical tags.
- **Coverage** — `coverage --by-source` to spot sources with no cases.

Produce one markdown report in `.tms/reports/` with findings grouped by severity
and a concrete fix list. Write no test cases. This command does not emit a memory
checkpoint.
