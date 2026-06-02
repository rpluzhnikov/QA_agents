---
name: kensa-test-authoring
description: Author Kensa QA artifacts on disk — test cases, shared steps, test plans, and runs in the .tms/ + suites/ format. Use when writing or editing case .md files, schema.yaml, config.yaml, shared-steps, plans, or runs by hand, and for the conventions that make a good test case.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (the Kensa on-disk file format for test cases, shared steps, plans, runs, schema, and config). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: implements CTFL §1.4.3 testware (test cases, test data, test execution schedule) as on-disk artefacts under §5.4 configuration-management discipline (Markdown + YAML + JSON under git).

## Overview — when to use

Use this skill when you author or edit **Kensa QA artifacts directly on disk**: test
cases, shared steps, test plans, test runs, the project schema, and config. Kensa
stores everything as plain files in a project — Markdown for cases/shared-steps,
YAML for schema/config, JSON for plans/runs. There is no database and no server;
the files **are** the source of truth.

This skill teaches the **exact on-disk format** (byte-for-byte; round-trips must be
stable) plus the **conventions for writing good cases**. For bulk querying,
filtering, and maintenance from the terminal, pair it with the **`kensa-cli`** skill
— prefer the CLI for reads and large edits, hand-edit files for authoring single
artifacts.

**The golden rule:** the `.tms/` formats are reproduced byte-for-byte by Kensa's
serializer. When you edit by hand, match the canonical layout exactly (key order,
indentation, blank lines, trailing newline) so git diffs stay clean and the GUI
re-save doesn't churn the file.

---

## Directory layout

```
<projectRoot>/
├── .tms/
│   ├── config.yaml              # project config + ID counters
│   ├── schema.yaml              # custom field definitions
│   ├── shared-steps/<id>.md     # reusable step sequences
│   ├── plans/<id>.json          # test plans (named case collections)
│   ├── runs/<id>.json           # test run history + per-case results
│   ├── attachments/<caseId>/    # per-case attachment files
│   └── trash/<id>.md            # soft-deleted cases (recoverable)
├── suites/                      # the test cases
│   ├── auth/
│   │   ├── 001.md
│   │   ├── 002.md
│   │   └── checkout/            # nested suite (arbitrary depth)
│   │       └── 003.md
│   └── reports/
│       └── 004.md
├── CLAUDE.md                    # instructions for AI agents (optional)
└── README.md
```

- **Suites are just folders** under `suites/`. Nest them to any depth. A case's
  "suite path" is its folder path relative to `suites/` (e.g. `auth/checkout`).
- A case lives at `suites/<suitePath>/<id>.md`. Moving a case = moving the file.
- `.tms/` holds everything that is *about* the project rather than a case body.

---

## 1. Test case — `suites/<suitePath>/<id>.md`

A case is YAML frontmatter + a Markdown body split into `## ` sections.

### Frontmatter fields (canonical order)

Write known keys in **this order**; unknown keys are preserved but sorted
alphabetically after the known ones (use the `custom:` map instead of inventing
top-level keys).

| Key | Type | Notes |
|-----|------|-------|
| `id` | number **or** string | **Required.** Authoritative — must equal the filename stem. Plans/runs reference this. |
| `title` | string | **Required.** One concise sentence describing the scenario. |
| `priority` | string | Project-defined values (commonly `low` / `medium` / `high` / `critical`). |
| `status` | string | Project-defined values (commonly `draft` / `active` / `deprecated`). |
| `tags` | string[] | Block-list style (one `- tag` per line). Omit or `[]` if none. |
| `preconditions` | string (block `\|`) | Setup state before Step 1. Multiline allowed. |
| `custom` | map | Schema-defined custom fields (see `schema.yaml`). |
| `source_id` | string | External tracker ref, e.g. `testrail:C12345`, `LIN-89`. |
| `created_at` | string | ISO-8601, quoted: `'2026-05-10T14:30:00Z'`. |
| `updated_at` | string | ISO-8601, quoted. |

### Body sections

- `## Steps` — the numbered test steps (see format below).
- `## Notes` — free-form notes. Verbatim text; trailing newline is part of content.
- Any other `## Heading` — preserved as-is (forward-compat "extra sections").

### Step format (exact)

Steps are a **numbered list**. Each step's action is the text after `N. `.
Optional child bullets, **indented 3 spaces**, attach to that step:

```
1. <action text>
   - Expected: <an expected result>
   - Expected: <another expected result>
   - Attachment: <filename.ext>
   - <free note line that is neither Expected nor Attachment>
2. <next action>
```

Parsing rules (mirror these precisely):
- Step line: `^(\d+)\.\s+(.*)$` → step number + action text.
- `   - Expected: <text>` → appends to that step's expected results (a step may
  have zero, one, or many).
- `   - Attachment: <name>` → references a file in `.tms/attachments/<caseId>/`.
- Any other indented `   - <text>` (or indented continuation) → the step's `notes`.
- A step with only an action and no children is just `N. <action>` on one line.

### Canonical example

```markdown
---
id: 218
title: Login with valid credentials
priority: high
status: active
tags:
  - auth
  - smoke
  - regression
preconditions: |
  User is registered and email is verified.
  No active session exists.
custom:
  browser: chrome
  estimated_duration: 30
  test_type: functional
source_id: testrail:C12345
created_at: '2026-05-10T14:30:00Z'
updated_at: '2026-05-10T16:45:00Z'
---

## Steps

1. Open login page at /login
   - Expected: Login form is displayed with email and password fields
2. Enter valid email "user@example.test"
3. Enter valid password
4. Click "Login" button
   - Expected: User is redirected to /dashboard
   - Expected: User name is displayed in header

## Notes

Дополнительная информация о кейсе.
```

### Formatting invariants

- One blank line after the closing `---`, one blank line before/after each `## `.
- Steps use **3-space** indentation for child bullets — not 2, not a tab.
- File ends with a single trailing `\n`; no double blank lines at the end.
- A case may legitimately have **no `## Steps`** (e.g. a notes-only case) — that's valid.

---

## 2. Case IDs — filename == id invariant

**The frontmatter `id` is authoritative and the file MUST be named `<id>.md`.**
If they ever diverge, the file is renamed to match the frontmatter — never the
reverse. Don't hand-pick an id that collides with an existing case anywhere under
`suites/`.

ID format is set per-project in `config.yaml` → `project.id_format`:

- **`numeric`** — zero-padded to ≥3 digits from the `next_id` counter:
  `1 → 001`, `42 → 042`, `1000 → 1000`.
- **`prefixed`** — `<prefix>-<padded>` using `project.id_prefix`:
  with prefix `AUTH`: `1 → AUTH-001`, `7 → AUTH-007`.

**Don't hand-allocate ids.** Create cases with `kensa-cli new --suite <path> --title "<t>"`
— it atomically allocates the next id (reconciles the counter against what's on disk, formats it
per the rule above), writes the case shell, and returns `{id, path}`. Concurrent `new` calls never
collide, so parallel authoring needs no id-range coordination. You then edit the returned file to
add the body (see the authoring workflow below).

> Hand-allocate (read `project.next_id`, format it, write `suites/<suite>/<id>.md`, then increment
> `next_id`) **only** when editing a tree entirely outside the CLI. In that case run
> `kensa-cli sync` afterward to reconcile the counter, and set `next_id` past the highest existing
> id to survive merge collisions.

---

## 3. `schema.yaml` — custom field definitions

Defines the `custom:` fields a case may carry. Top-level keys: `version`, `fields`.

```yaml
version: 1
fields:
  - key: test_type
    name: Test Type
    type: select
    required: false
    default: functional
    options: [functional, performance, security, accessibility]
    order: 1
  - key: browser
    name: Browser
    type: multiselect
    required: false
    options: [chrome, firefox, safari, edge]
    order: 2
  - key: estimated_duration
    name: Estimated Duration (min)
    type: number
    required: false
    default: 15
    order: 3
```

Field key order (canonical): `key`, `name`, `type`, `required`, `default`,
`options`, `order`, `description`. Field `type` is one of `text`, `textarea`,
`select`, `multiselect`, `number`, `date`, `checkbox`, `url`. `options` is required
for `select`/`multiselect`. A case's `custom:` keys should match `key` values here;
`required: true` fields must be present on every case.

---

## 4. `config.yaml` — project config + ID counters

```yaml
version: 1
project:
  name: My Test Suite
  description: Optional description
  id_format: numeric        # or "prefixed"
  id_prefix: null           # required string when id_format == "prefixed"
  next_id: 1                # next case id to allocate
  next_shared_step_id: 1    # next shared-step id (optional, defaults to 1)
  next_plan_id: 1           # next plan id (optional, defaults to 1)
ui:
  default_view: list        # list | kanban
  terminal_position: right  # right | bottom
```

Key order is fixed (`version`, `project`, `ui`; under `project` the order above) so
diffs stay stable. Unknown keys are appended alphabetically.

---

## 5. Shared steps — `.tms/shared-steps/<id>.md`

Reusable step sequences referenced from multiple cases. Same step format as a case;
frontmatter known keys are `id`, `title`, `description` (only).

```markdown
---
id: LOGIN
title: Standard login steps
---

## Steps

1. Navigate to the login page
   - Expected: Login form is visible
2. Enter username and password
   - Expected: Credentials are accepted
3. Click Login button
   - Expected: User is authenticated
```

### Referencing a shared step from a case

Use `@shared:<id>` as a step's action text. The id matches `[A-Za-z0-9_-]+`:

```markdown
## Steps

1. @shared:LOGIN
2. Complete checkout
   - Expected: Order placed
```

Keep shared-step ids short and stable (e.g. `LOGIN`, `SETUP-DB`). Renaming an id
breaks every `@shared:` reference — update referencing cases too. The `kensa-cli`
skill's `shared-step usage`/`orphan` commands find references and dead steps.

---

## 6. Test plans — `.tms/plans/<id>.json`

A plan is a **named, ordered collection of cases** (a subset of the project) — e.g.
"Regression Suite", "Release 1.4 smoke". Plans don't hold pass/fail; they define
*what* to test. Id format `PLAN-NNN` (3-digit zero-padded). JSON, 2-space indent,
trailing newline.

```json
{
  "id": "PLAN-001",
  "name": "Regression Suite",
  "description": "Daily regression for critical paths",
  "createdAt": "2026-05-20T10:00:00Z",
  "updatedAt": "2026-05-22T14:30:00Z",
  "cases": [
    {
      "caseId": "218",
      "casePath": "/abs/path/suites/auth/218.md",
      "caseTitle": "Login with valid credentials",
      "suitePath": "auth"
    },
    {
      "caseId": "220",
      "casePath": "/abs/path/suites/checkout/220.md",
      "caseTitle": "Checkout flow",
      "suitePath": "checkout"
    }
  ]
}
```

Each `cases[]` entry snapshots `caseId` (the authoritative ref), `caseTitle` (at add
time — may go stale), `suitePath`, and an absolute `casePath`. `caseId` is the field
that survives renames/moves.

---

## 7. Test runs — `.tms/runs/<id>.json`

A run is **one execution pass** over a scope of cases, recording each case's
pass/fail/skip/pending result. Run id format: `YYYYMMDD-HHMMSS-<6-hex>` (sortable +
collision-resistant). JSON, 2-space indent, trailing newline.

```json
{
  "id": "20260522-143055-a1b2c3",
  "name": "Smoke Test Run - May 22",
  "createdAt": "2026-05-22T14:30:55.000Z",
  "finishedAt": null,
  "scope": {
    "suitePaths": ["auth"],
    "explicitCaseIds": []
  },
  "results": [
    {
      "caseId": "218",
      "casePath": "/abs/path/suites/auth/218.md",
      "caseTitle": "Login with valid credentials",
      "suitePath": "auth",
      "status": "pending",
      "reason": null,
      "updatedAt": "2026-05-22T14:30:55.000Z"
    },
    {
      "caseId": "220",
      "casePath": "/abs/path/suites/checkout/220.md",
      "caseTitle": "Checkout flow",
      "suitePath": "checkout",
      "status": "fail",
      "reason": "Navigation button not visible",
      "updatedAt": "2026-05-22T14:33:45.000Z"
    }
  ]
}
```

Field reference:
- `finishedAt`: `null` while in progress; ISO timestamp once the run is marked finished.
- `scope.suitePaths`: suites chosen at creation; `scope.explicitCaseIds`: individually
  picked case ids (not coming from a suite selection).
- `results[].status`: one of `"pending"`, `"pass"`, `"fail"`, `"skip"`.
- `results[].reason`: free-form note — fail explanation, skip rationale, or `null`.
- `results[].caseTitle`: snapshot — the case may be renamed/deleted after the run;
  `caseId` is the stable link.

Every in-scope case gets a `results[]` row at creation (status `pending`); executing
the run flips statuses and stamps `updatedAt`.

---

## Writing good test cases (conventions)

Format correctness is necessary but not sufficient. Aim for cases that another
person — or an AI agent — can execute without guessing.

1. **One case = one scenario.** A case verifies a single behavior. "Login" and
   "Login with wrong password" are two cases, not one with branches.
2. **Title states the scenario, not the feature.** "Login with valid credentials",
   not "Login". Make the expected outcome inferable from the title.
3. **Put setup in `preconditions`, not Step 1.** Steps should be the actions under
   test; the starting state belongs in `preconditions`.
4. **Each step is one user action.** "Enter email" and "Enter password" are separate
   steps. Avoid "Fill the form and submit" — split it.
5. **Attach `Expected:` to the step that produces the observable result** — usually
   the last action, sometimes intermediate verifications. Not every step needs one,
   but a case with zero expected results across all steps verifies nothing.
6. **Expected results are observable and specific.** "User is redirected to
   /dashboard" beats "It works". State *what* the tester should see.
7. **Reuse via shared steps.** Repeated setup/login sequences → a `@shared:` step.
   Keeps cases short and updates ripple from one place.
8. **Tag for slicing.** Tags drive run scopes and filters (`smoke`, `regression`,
   `auth`). Be consistent; reuse existing tags rather than minting near-duplicates.
9. **Set `priority`/`status` deliberately.** New/unreviewed → `draft`; ready to run →
   `active`; obsolete → `deprecated` (don't delete history-bearing cases, deprecate).
10. **Keep `custom:` aligned with `schema.yaml`.** Only use defined keys; satisfy
    `required` fields.

---

## Authoring workflow

```
1. Orient    → kensa-cli list --tree ; kensa-cli stats        (what suites/cases exist)
2. Create    → kensa-cli new --suite <suite> --title "<t>" [--priority …] [--tag …] [--source-id …] --format json
               (atomic id allocation; returns {id, path} — no manual next_id handling)
3. Author    → edit the returned path: add ## Steps (+ preconditions, custom, ## Notes)  (match canonical format above)
4. Validate  → kensa-cli validate  (schema)  ; kensa-cli lint  (quality)  ; kensa-cli doctor (integrity)
```

- **Create cases via `kensa-cli new`** — it allocates the id and writes a valid shell; you only
  author the body. Don't hand-pick ids or touch `next_id`.
- **Reads & bulk edits**: use the **`kensa-cli`** skill (`filter`, `bulk update`,
  `context bundle`, etc.) — it's faster and safer than hand-editing many files.
- **Body authoring**: edit the case file using the formats here.
- **After any hand-edit batch**: run `kensa-cli validate && kensa-cli lint && kensa-cli doctor`
  to catch schema violations, empty steps, and id/filename drift.
- **Never** invent top-level frontmatter keys (use `custom:`), break the
  filename==id invariant, or hard-delete a case (move to `.tms/trash/`).
