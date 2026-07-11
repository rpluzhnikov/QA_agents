---
description: Run a browser routine (.tms/routines/RT-*.md) — drive the Kensa-launched Chrome via kensa browser, then optionally write findings back into .tms/ cases. Needs Chrome started from Tools → Browser.
argument-hint: [routine id or name, e.g. RT-001] (optional)
---

Act as the **test-lead-agent**. Run the browser routine identified by:
$ARGUMENTS. Load the `kensa-browser` skill for the `kensa browser` verb set,
the persistence model, and the report-back loop.

1. **Resolve** — check `kensa --version`; if the CLI isn't on PATH, tell the user
   and stop. Find the matching `RT-*.md` in `.tms/routines/` (id or name
   fragment). If none was given, list the available routines (id + name +
   description) and ask which to run. If `.tms/routines/` is missing or empty,
   point at the two ways to get routines — `/kensa-new-routine` (author one now)
   or `/kensa-setup` (seed the starter smoke / form / visual-baseline routines) —
   and stop. Reject ids that don't match `^RT-\d+$` or files that don't exist.
   Read the file — its **body is the scenario prompt**.
2. **Preflight** — `kensa browser status --format json`. If not reachable
   (exit code 2), tell the user to start Chrome from **Tools → Browser → Start**
   and stop. Do not launch a browser yourself.
3. **Execute** — work through the routine body with `kensa browser …`
   (`--format json`). Branch on exit codes: `1` ⇒ retry a different selector or
   report page state; `2` ⇒ fix the invocation. Capture evidence into
   `.tms/attachments/…`.
4. **Report** — summarize pass/fail per check, screenshots written, console/network
   errors. For a genuine defect, file a case with `kensa new --suite
   bugs/<area> --title "…" --tag browser --source-id <ref>`, then add reproduction
   `## Steps`, observed vs. expected, and the screenshot path. Confirm before
   creating cases unless `project.md` opts into silent writes.

This command authors no feature cases and owes no memory checkpoint — only
`/kensa-new-feature` and `/kensa-update-feature` create the
`.tms/.pending-checkpoint` marker the Stop hook keys on.

End your final message with:

✅ **Done:** RT-<id> <pass/fail summary>; <N> screenshots in .tms/attachments/; <M> defect cases filed
➡️ **Next:** re-run `/kensa-run-routine RT-<id>` after the defect is fixed, to confirm · `/kensa-new-routine` — capture today's ad-hoc checks as a reusable routine · `/kensa-save-memory` — if the run surfaced patterns worth keeping.
