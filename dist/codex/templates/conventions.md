# Test case conventions

How cases are written in this project. The plugin reads this on every
session. Update it directly whenever conventions evolve.

## Titles

**Form:** <imperative starting with a verb | declarative | noun phrase>
**Example:** "<concrete example title from this project>"
**Anti-example:** "<title style we don't use>"

## Steps

**Verb form:** <imperative ('Open', 'Click') | other>
**Granularity:** <atomic (one action per step) | grouped where trivial>
**Numbering:** <1. 2. 3. | other>

## Expected results

**Location:** <per-step (right after the action) | end-state (separate
section after steps) | mixed>
**Phrasing:** <state observable facts; no 'should', no 'must', no
'verify that' preamble>

## Preconditions

**Style:** <bullet list | prose | YAML block>
**Common reusable preconditions:**
- <"User is logged in as admin" — use shared step `auth/login-as-admin`>
- <"Test data fixture X is loaded" — reference X in preconditions>

## Frontmatter

**Always present:**
- `id` (auto-allocated by Kensa)
- `title`
- `priority` (allowed values: <critical | high | medium | low>)
- `status` (allowed values: <draft | active | deprecated>)
- `tags`
- `source_id` (SOT ref — ticket ID or URL)
- `generated_by` (when written by plugin: `kensa-qa@<version>`)

**Sometimes present:**
- `preconditions` (when complex enough to be structured)
- `custom` (project-specific fields per schema)

## Tag taxonomy

See `learned/tags.md` for the live list.

## Shared step conventions

**When to extract:** sequence of 3+ steps appearing in 3+ cases.
**Location:** `.tms/shared-steps/<category>/<name>.md`
**Reference syntax:** `Use shared step: <path>`

## Language / phrasing

**Case body language:** <en / ru / both>
**Mixed content:** <e.g., "UI text in original language (Russian), step
descriptions in English">

## Anti-patterns we've banned

<List specific anti-patterns and why. Examples:>

- **No "verify that..." preambles** — every step is a verification; the
  preamble adds nothing.
- **No selector / xpath in step text** — manual cases describe what the
  tester clicks, not what the automation finds.
- **No screenshot-as-expected-result** — describe the observable state
  in words; screenshots are auxiliary.
