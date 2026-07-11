---
name: kensa-results
description: Ingest automation test-result reports (JUnit, Playwright, Allure, CTRF, and 7 more) into the Kensa TMS via `kensa results` — parse a report, match each test back to a `.tms/` case, and store a normalized run — then use the matched/orphaned split to keep the manual test base and the automation suite in sync. Loaded by the Test Lead or QA Engineer when the brief involves automation-result ingestion or traceability between cases and CI runs. Pairs with `test-tools-and-automation-overview` (should we automate?) and `kensa` (how to read/write cases).
---

> **Non-ISTQB tooling skill**
> Covers project infrastructure: the `kensa results` subcommands that parse an
> automation report into Kensa's normalized run model, match each test to a `.tms/`
> case, and store or push the result. Complementary to ISTQB CTFL v4.0.1 — pairs with
> `test-tools-and-automation-overview` (Ch 6, the automation decision) and `kensa`
> (how to read/write cases). Light cross-reference: supports test execution &
> completion reporting (§5.3) and the manual↔automation traceability that a mature
> test base keeps. No specific learning objective grounds the content.

## Mental model — parse → match → store

```
report.xml / results.json / out.ndjson
        │  parse (11 formats, auto-detected)
        ▼
normalized run model  ──match──▶  .tms/ cases      →  X matched / Y orphaned
        │  (automation-map > id-tagged > fuzzy)
        ▼
.tms/automation-runs/<id>.json        (ingest)   or   pushed to a transport (push)
```

- **The matched / orphaned split is the signal.** Every ingest reports *X matched / Y
  orphaned* on stderr. Orphaned tests are automation with **no home in the manual test
  base** — either a case is missing, or the test's id/tag is wrong. That gap is the
  traceability work.
- **Two verbs, two homes.** `ingest` writes a normalized run **into the project**
  (`.tms/automation-runs/`). `push` posts it to a transport and writes **nothing
  locally** — and is **project-independent** (no `.tms/` needed).

## `kensa results ingest <PATH> [--report-format <FORMAT>] [--match <STRATEGY>]`

Parse a report, run the case↔test matcher, store the normalized run under
`.tms/automation-runs/<id>.json`, and print a summary.

- `<PATH>` (required): the report file.
- `--report-format <FORMAT>` (default `auto`): one of **11 explicit formats** —
  `junit`, `allure`, `ctrf`, `playwright`, `gotest`, `trx`, `nunit`, `xunit`,
  `mochawesome`, `newman`, `cucumber` — or `auto`.
- `--match <STRATEGY>`: `by-tag` or `by-name`; omit = the **full match chain**
  (automation-map > id-tagged > fuzzy). "Id-tagged" means the test carries the
  case id as a `@KEN-<id>` tag in its title/tags (e.g. a Playwright
  `{ tag: '@KEN-412' }`) — that tag format is the canonical case↔test link (see
  `ken-traceability` in the automation-git bundle).

**`auto` detection precedence:** NDJSON (`Action` key) → gotest; XML root
(`<TestRun>`→trx, `<test-run>`→nunit, `<assemblies>`→xunit,
`<testsuites>`/`<testsuite>`→junit); JSON signature (array→cucumber,
`reportFormat:"CTRF"`→ctrf, config+stats+suites→playwright, `run.executions`→newman,
stats+results-array→mochawesome, `status` key→allure). **Ambiguous → exit 2** (no
blind extension fallback — pass `--report-format` to disambiguate).

The summary (`X matched / Y orphaned`) goes to **stderr**; the written path (table) or
the normalized run JSON (`--format json`) goes to **stdout**.

```sh
kensa results ingest ./ci/junit.xml
kensa results ingest ./ci/playwright.json --report-format playwright --format json
kensa results ingest ./ci/out.ndjson --match by-name        # gotest NDJSON, match by test name
```

## `kensa results push <PATH> [--token <TOKEN>] [--project <ID>] [--report-format <FORMAT>]`

Parse a local report and post it through an injectable transport seam.
**Project-independent** (no `.tms/` needed). **Push-only** — no local write.

- `--token`: defaults to the `KENSA_TOKEN` env var. **No token → a stderr notice and
  exit 0** (by design — CI must not hard-fail before a token is configured).
- `--project <ID>`: attach a project identifier to the run.
- `--report-format`: **`auto` / `junit` / `allure` only** in `push`. The other 9
  formats return "use `kensa results ingest`" and exit **2**.

> The current transport is a **stub** — no real network call; it logs the payload size
> to stderr. This is the documented future egress boundary. Treat `push` as a CI-safe
> no-op today: wire it into pipelines now (it never hard-fails on a missing token), and
> it starts shipping when the transport lands.

```sh
KENSA_TOKEN=… kensa results push ./ci/junit.xml --project my-app
kensa results push ./ci/junit.xml               # no token → stderr notice, exit 0 (CI-safe)
```

## Exit codes — branch on them

- **`0`** — success, **including `push` with no token** (a deliberate CI-safe notice).
- **`1`** — I/O failure (unreadable report).
- **`2`** — ambiguous `auto` detection (pass `--report-format`), or a `push`
  `--report-format` outside `auto`/`junit`/`allure`. ⇒ fix the invocation; do not retry
  verbatim.

## Close the loop — turn orphans into traceability work

The point of ingestion is not the run record; it's the **matched/orphaned split**.
After an ingest, act on it with `kensa`:

1. **Ingest and read the split:**
   ```sh
   kensa results ingest ./ci/junit.xml --format json   # stderr: "42 matched / 7 orphaned"
   ```
2. **Find the manual cases that *should* have automation** but don't, so you know the
   other direction of the gap (untraced cases):
   ```sh
   kensa gaps --against source --format json           # cases with no source_id
   kensa coverage --by-tag --format json               # e.g. how many carry `automated`
   ```
3. **For each orphaned automation test**, decide:
   - the manual case exists but the test's id/tag is wrong → fix the automation's
     annotation (outside Kensa), or
   - no manual case exists → author one so the run has a home next time:
     ```sh
     kensa new --suite api/login --title "Login rejects an expired token" \
       --priority high --tag api --tag automated --source-id API-021 --format json
     ```
     (`--source-id` stays an **external** tracker ref — the ticket the behavior
     comes from — never an internal case id.) Then close the loop from the other
     side: **add the returned id as a `@KEN-<id>` tag to the automated test**, so
     the next ingest matches it instead of re-orphaning it.
4. **Tag matched cases** so coverage reports can see what's automated:
   ```sh
   kensa filter "suite=api and not tag=automated" --format ids \
     | xargs -I{} kensa update {} --add-tag automated
   ```

Report the run and the residual gap to the user the way
`test-monitoring-control-completion` (§5.3) prescribes — matched %, orphan list, and
the untraced-case count — not just a green/red total.

## Guardrails

- **Ingested runs live in the project** (`.tms/automation-runs/`) — committable and
  reviewable. `push` writes nothing locally.
- **`auto` can be ambiguous** — when detection exits 2, pass `--report-format`
  explicitly rather than renaming the file.
- **Don't overwrite the manual spec from a run.** A failing automation result is a
  signal to investigate, not a licence to edit the case's expected results — file a
  defect case (`kensa new`) if the app is wrong, or fix the test if the test is wrong.
- **`push` is a stub today** — do not assume results reached a server; it logs payload
  size only. Prefer `ingest` when you need the run persisted.
