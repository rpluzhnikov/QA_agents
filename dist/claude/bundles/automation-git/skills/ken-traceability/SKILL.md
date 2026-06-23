---
name: ken-traceability
description: The @KEN-<id> tag convention linking automated tests 1:1 to .tms/ cases, expressed natively per framework, with mapping-granularity rules (1:N, N:1, parameterized, shared steps). Load when tagging tests or designing test↔case traceability.
---

Kensa traceability is one rule: a single canonical tag, `@KEN-<id>`, where `<id>`
is exactly the `id` in a `.tms/` case file. That tag is the *only* link between an
automated test and the manual case it covers. It is written using each framework's
**native** tag/annotation — no custom runner, no parser convention beyond reading
the tag back out of the report. This skill defines the tag, how to express it in
each shortlisted framework, and how to map cases to tests when the relationship
isn't 1:1.

For drift detection (orphaned tags, uncovered cases) and the sync workflow, see
the sibling **`case-test-sync`** skill — this skill is about *authoring* the link;
that one is about *keeping it honest*.

## Concept

**The case is the truth; the tag points at it.** Each `.tms/*.md` case has an
authoritative `id` (== its filename stem). The tag `@KEN-<id>` embedded in a test
declares "this test covers that case." The id is **human-authored and explicit** —
never derived from the test's name, class, file path, or a signature hash.

This is deliberate. The robust traceability systems in the wild (Xray's
`@TEST_KEY-123`, Zephyr Scale's `@TestCaseKey=ABC-T123`, Qase's `qase.id(1)`) all
embed a **stable, project-scoped, human-chosen key**. The brittle ones derive the
identifier — TestRail's `automation_id` (= classname + method name) and Allure's
`testCaseId = md5(fullName, sort(names(parameters)))`. The failure mode is the
same for both: rename the test (or change its parameters) and the derived id
changes, silently abandoning the old case and minting a duplicate. TestRail's own
docs warn that renaming a method "creates a duplicate case"; Allure's warn that a
changed `fullName` "abandons" the previous AllureID.

`@KEN-<id>` sidesteps this entirely: **the link survives renames, moves, and
refactors** because it is a literal string a human wrote, not a fingerprint of the
code. Rename the test function freely — as long as the `@KEN-218` token rides
along, the case stays covered. Generalize the Xray/Zephyr/Qase "test-case-key tag"
pattern; reject the TestRail name-matching and Allure hash-drift patterns.

## The tag, per framework

Use the framework's first-class tag/annotation mechanism. The token is always the
literal `@KEN-<id>` (matching the `.tms/` id format — bare numeric like `@KEN-218`,
or prefixed like `@KEN-AUTH-007` when the project uses `id_prefix`).

| Framework | Native syntax | Read back from |
|---|---|---|
| **Playwright** | `test('logs in', { tag: '@KEN-218' }, …)` (object syntax, preferred) — or a `@KEN-218` token in the title | `TestCase.tags` / `test.info().annotations` in a reporter |
| **pytest** | a **registered** marker: `@pytest.mark.ken("218")` (register in `pytest.ini`/`pyproject.toml`) | JUnit XML / reporter plugin; id read via a collection hook |
| **JUnit 5** | `@Tag("KEN-218")` — or a custom composed annotation `@Ken("218")` wrapping `@Tag` | JUnit XML / report properties |
| **Cucumber / Gherkin** | **scenario-level** tag `@KEN-218` directly above `Scenario:` | Cucumber JSON, consumed by any TMS |
| **Cypress** | `@cypress/grep` (cy-grep) tags: `it('…', { tags: ['@KEN-218'] }, …)` or a `@KEN-218` token in the title | custom reporter parsing tags/titles |

Notes:
- **Playwright**: prefer the object `{ tag }` form over a title token — title tags
  duplicate into the HTML report label and are noisier to parse. Multiple tags:
  `{ tag: ['@KEN-12', '@KEN-13'] }`.
- **pytest**: the marker **must be registered** (`markers = ken: …` in config) or
  unregistered-marker warnings stay silent unless `--strict-markers` is on. The id
  lives in the marker argument, so result ingestion needs a small collection hook
  to pull it out — that's expected, not a smell.
- **JUnit 5**: `@Tag` values are plain strings (typos are silent). A custom
  composed `@Ken("218")` annotation gives you a typed, greppable surface and a
  single place to evolve the convention.
- **Cucumber**: tag at the **scenario** level, not the feature level (see Pitfalls).
- **Cypress**: there is no first-class metadata API; the grep plugin (or a title
  token) is the mechanism. Keep tags out of free prose so the parser is simple.

The ingestion contract across all of them is identical: **parse the `@KEN-<id>`
token out of the test report** and look up that `id` in `.tms/`. No tool-specific
round-trip, no name matching.

## Mapping granularity

Real suites are rarely 1:1. The tag convention covers four shapes:

- **1 case : N tests.** One manual case ("user can checkout") is exercised by
  several automated tests (happy path, declined card, out-of-stock edge). **All N
  tests carry the same `@KEN-<id>`.** Coverage/status semantics: the case is
  **covered** if ≥1 linked test exists, and **passing only if *all* linked tests
  pass** (any failure ⇒ the case is failing).

- **N cases : 1 test.** One automated test validates several cases. **Attach
  multiple keys**: Playwright `{ tag: ['@KEN-12', '@KEN-13'] }`, Cucumber
  `@KEN-12 @KEN-13` above the scenario, a repeated/space-joined marker in pytest,
  multiple `@Tag` in JUnit. Each key maps that test to its own case.

- **Parameterized / data-driven.** One test definition, many data rows ⇒ **one case
  by default.** Tag the test once; do not mint a case per row (this mirrors Qase's
  reporter auto-parameterizing a single case). Split into multiple `@KEN` keys
  **only** when rows represent genuinely distinct *business* cases, not just
  different input values for the same behavior.

- **Shared steps / helpers / page-objects / fixtures carry NO tag.** They are not
  cases — only **test functions** carry `@KEN-<id>`. A login helper, a POM method,
  or a fixture is reused machinery; tagging it would map a case to infrastructure
  instead of to the test that exercises it. The case↔test mapping lives at the
  **test level**, never the helper level. (This mirrors `.tms/` shared steps, which
  have their own `@shared:<id>` ids and are likewise not cases.)

## Pitfalls

- **Derived-id drift (the cardinal sin).** Never let traceability rest on a test's
  name, class, path, or a parameter hash. That is exactly the TestRail
  `automation_id` / Allure `testCaseId` failure — a rename or signature change
  abandons the old case and spawns a duplicate. The whole point of `@KEN-<id>` is
  that a human wrote it, so it survives refactors. If you find yourself matching by
  name, stop and add the explicit tag.

- **Feature-level Gherkin tags over-apply.** In Cucumber, a tag above `Feature:`
  **inherits to every scenario** in the file. Putting `@KEN-218` there silently
  stamps that one case id onto all scenarios — instant false coverage and drift
  when scenarios are copy-pasted. Tag at the **scenario** level. Reserve
  feature-level tags for genuine cross-cutting concerns (`@smoke`), never for a
  case key.

- **Unregistered / unenforced markers.** pytest markers that aren't registered warn
  but don't fail unless `--strict-markers`; JUnit `@Tag` strings and Cypress title
  tokens have no typo protection at all. A misspelled `@KEN-281` (transposed) is a
  silent orphan. Mitigate: register pytest markers and run `--strict-markers`;
  prefer a typed composed annotation in JUnit; and rely on `case-test-sync`'s lint
  to fail CI on tags that reference an unknown `.tms/` id.

---

**See also:** `case-test-sync` — bi-directional drift detection (orphaned tags vs.
uncovered cases) and the CI sync workflow that enforces this convention.
