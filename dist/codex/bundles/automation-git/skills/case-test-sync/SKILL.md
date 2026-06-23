---
name: case-test-sync
description: Bi-directional case↔test sync — drift detection (orphan/gap/lag) in CI, results feedback per @KEN-<id>, and greenfield stub generation from untagged tests. Load when keeping .tms/ cases and automated tests in sync, in either direction.
---

## Overview — when to use

Use this skill to keep `.tms/*.md` cases and automated tests in lockstep — in
either direction. It covers the CI machinery that detects drift between cases and
code, feeds test results back to the owning case, and (for automation-first teams)
reverse-generates case stubs from untagged tests so traceability is never lost.

This builds directly on the `@KEN-<id>` tag convention — see the
**`ken-traceability`** skill for how the tag is authored per framework and parsed
out of reports. This skill is about the *sync loop* around that tag, not the tag
itself.

## Concept — case-as-truth, both directions

kensa's default ownership model is **case-as-truth**: the `.tms/*.md` file is
authoritative, and every automated test must point to a real case via its
`@KEN-<id>` tag. The case carries the canonical `id` (the join key); a test that
references an id with no matching `.tms/` file is broken, not the case. This model
is the right default for regulated/audited contexts and is what makes a clean
bi-directional traceability matrix possible.

The alternative — *test-as-truth*, where code is authoritative and cases are
auto-created from incoming results (TestRail code-first, Zephyr
`autoCreateTestCases`) — is faster for automation-first teams but, per those
vendors' own docs, tends to spawn orphan and duplicate cases. kensa resolves the
tension by keeping the Markdown case as the truth **while** providing a test-first
generator (see *Greenfield path*) so automation-first teams aren't penalised.

So sync runs in both directions:
- **case → test** (default): author writes the case with an `id`; developer adds
  the matching `@KEN-<id>` tag; CI records results back to the case.
- **test → case** (greenfield): developer writes an untagged test; a generator
  scaffolds the case stub and writes the tag back into the source.

## Drift detection

A `kensa lint` step runs every pipeline and exposes the two failure directions of
a requirements-traceability matrix — **orphan tests** (a test with no real case)
and **coverage gaps** (a case with no test):

- **Orphan tag (hard fail):** code references `@KEN-9999` but no matching `.tms/`
  file exists → the build fails. This is the check that catches deleted cases and
  copy-paste tag errors.
- **Uncovered case (warn / report):** a `.tms/` case marked `status: automated`
  but with no linked test in the latest report → surfaced in the coverage summary.
  A case with `status: manual` is *expected* to have no linked test, so it is not
  flagged.
- **Stale / duplicate:** two cases sharing an `id`, or a tag pointing to a case
  whose `title` has materially diverged from the test → flagged for review.

Track the four traceability signals as measurable CI metrics:

| Signal | Meaning |
|---|---|
| **Coverage %** | Share of cases that have ≥1 linked automated test. |
| **Orphan rate** | Tests referencing no real case (should trend to ~0). |
| **Gap rate** | `automated`-status cases with no linked test. |
| **Update lag** | Time between a case change and the corresponding test change. |

If orphan rate climbs above a few percent, tighten generation discipline; if a
manual case's frequency or risk rises, re-score it for automation rather than
letting the gap sit.

## Results feedback

CI writes pass/fail **back to the case**, per `@KEN-<id>`. After tests run, a
`kensa ingest` step parses the report (JUnit XML, or Cucumber JSON for BDD),
extracts every `KEN-####` token, maps each result to its case by `id`, and records
the outcome:

- Result is written into the case frontmatter `automation:` block (`last_run`,
  `last_status`) — or a sidecar `.tms/.results.json` to keep case files diff-clean.
- **1 case : N tests** — the case is `passed` only if *all* linked tests pass.
- **N cases : 1 test** — the result is recorded against *each* referenced key.
- On the first linked run, a case flips `status: manual → automated`.

Crucially, CI writes only the machine-owned `automation:` fields (last run, status,
tags) — **never** the human-authored body, title, or intent. The case stays the
source of truth; CI only annotates it with results.

## Greenfield path

When automation is written first, preserve traceability by **reverse-generation**
rather than name-matching. A `kensa generate` (`test-first`) step:

1. Scans the test report for tests with **no** `KEN-` tag.
2. Scaffolds one `.tms/*.md` stub per untagged test — deriving `title` from the
   test name and a body skeleton from `describe` / `test.step` / assertion text.
3. Assigns the next free `id`.
4. **Writes the `@KEN-<id>` tag back into the source test file**, so the link is
   explicit, not derived from a name or signature hash that breaks on rename.

The generated stubs are *skeletal* — their business intent still needs human
review (the same caveat that applies to Zephyr/TestRail auto-create). Generation
buys traceability; it does not replace authoring a real case.

## Pitfalls

- **`autoCreateTestCases`-style minting.** Letting the ingest step silently create
  a case for every unkeyed test (Zephyr's `autoCreateTestCases=true`) spawns orphan
  and duplicate cases. Use the deliberate `kensa generate` path instead, which
  assigns a stable id and writes the tag back.
- **Silent drift.** Without a hard-failing orphan check in CI, deleted cases and
  copy-paste tag errors accumulate invisibly. Run `kensa lint` every pipeline; once
  past warn-only rollout, make orphan tags a hard build failure.
- **Letting CI write to case bodies.** Result feedback must touch only the
  machine-owned `automation:` fields (or the sidecar results file). If CI ever
  rewrites the title, steps, or intent, the case stops being the source of truth and
  case-as-truth collapses into test-as-truth.

---

Cross-reference: **`ken-traceability`** — the `@KEN-<id>` tag convention this skill
builds on (per-framework authoring + report parsing).
