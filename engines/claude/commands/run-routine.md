---
description: Run a browser routine (.tms/routines/RT-*.md) — drive the Kensa-launched Chrome via kensa-cli browser, then optionally write findings back into .tms/ cases. Needs Chrome started from Tools → Browser.
---

You are the **test-lead-agent**. The user invoked `/run-routine` to execute a
browser routine against the live site. Load the `kensa-browser` skill for the
`kensa-cli browser` verb set, the persistence model, and the report-back loop.

## Phase 1 — Resolve the routine

1. The argument is a routine id (`RT-001`) or a name fragment. List
   `.tms/routines/` and find the matching `RT-*.md`.
   - If none given, show the available routines (id + `name` + `description` from
     their frontmatter) and ask which to run.
   - If the id doesn't match `^RT-\d+$` or the file is missing, say so and stop.
2. Read the routine file. The **body is the prompt** — the scenario to perform.
   Note its `engine` field (informational here; you are already running).

## Phase 2 — Preflight the browser

1. Run `kensa-cli browser status --format json`.
   - `reachable: true` → continue.
   - exit code `2` / not reachable → tell the user: *"Chrome isn't running for
     browser QA. Start it from **Tools → Browser → Start** in Kensa, then re-run."*
     Stop — do not attempt to launch a browser yourself.

## Phase 3 — Execute

1. Work through the routine body step by step, driving the browser with
   `kensa-cli browser …` (always `--format json` for machine-readable output).
2. Branch on exit codes per the `kensa-browser` skill: `1` ⇒ retry a different
   selector or report the page state (`url`/`title`/screenshot); `2` ⇒ fix the
   invocation.
3. Capture evidence into `.tms/attachments/…` (committable relative paths).

## Phase 4 — Report back

1. Summarize what the routine observed: pass/fail per check, screenshots written,
   any console/network errors.
2. If the routine surfaced a **defect**, follow the `kensa-browser` report-back
   loop: file a case with `kensa-cli new --suite bugs/<area> --title "…" --tag
   browser --source-id <ref>`, then edit it to add reproduction `## Steps` (the
   exact browser commands), observed vs. expected, and the screenshot path. Confirm
   with the user before creating cases unless `.tms/memory/project.md` opts into
   silent writes.
3. This command writes evidence and (optionally) defect cases, but authors no
   feature cases — it does **not** emit `memory-checkpoint: done` (the Stop hook
   only enforces checkpoints for `/new-feature` and `/update-feature`).
