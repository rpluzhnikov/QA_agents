---
name: kensa-http
description: Author, edit, and execute HTTP requests from the terminal via `kensa http` — a local request runner with reusable collections, environments, `{{var}}` templating, and response captures — then write findings back into `.tms/` cases. Use when a test scope needs live API evidence (endpoint smoke checks, auth flows, contract spot-checks). Loaded by the QA Engineer when the brief names API-driven QA, and pairs with the `backend-api-testing` skill (what to test) and `kensa` (how to read/write cases).
---

> **Non-ISTQB tooling skill**
> Covers project infrastructure: the `kensa http` subcommands that CRUD and execute
> HTTP requests stored inside the project as reusable collections. Complementary to
> ISTQB CTFL v4.0.1 — pairs with `backend-api-testing` (what to test at the API level)
> and `kensa` (how to read/write cases). Light cross-reference: supports API-level
> functional testing (Ch 4) and evidence capture for defect reports (§5.5). No specific
> learning objective grounds the content.

## Mental model — collections, environments, captures

```
.tms/tools/http/<collection>.http     ← a collection = an ordered set of requests
.tms/tools/http/env/<env>.json        ← an environment = a {{var}} lookup table

kensa http new  → kensa http edit  → kensa http run --env <env>
                                        │
                                        └─ {{var}} resolves; a --capture threads a
                                           response value into later requests
```

- **Requests live in the project.** Collections are `.http` text files under
  `.tms/tools/http/` (legacy `.json` is still read/written); environments are JSON
  under `.tms/tools/http/env/`. They are committable and travel with the repo.
- **Names are bare file stems.** A collection or env name may not contain path
  separators, `..`, or an absolute/drive prefix — those exit **2**.
- **Templating over a precedence chain.** `{{var}}` placeholders in URL, query,
  headers, and body resolve at run time; an **undefined** `{{var}}` anywhere is a hard
  error (never sent literally).

## Command reference

Global form: `kensa http <subcommand> [args] [--format json]`

| Command | Key args / flags | Does |
|---|---|---|
| `list` | — | List all collections and their requests. Records: `collection`, `name`, `method`, `url`. Malformed collections are skipped with a stderr warning. |
| `show <COLLECTION>` | `--request <NAME>` (omit = all) | Print a request as an object: `collection`, `name`, `method`, `url`, `query`, `headers`, `body_type`, `body_text`, `captures`, `vars`. Unknown request → exit **1**. |
| `new <COLLECTION>` | `--request <NAME>` (default `"New request"`) | Create a new collection (`<name>.http`) with a first request. Already exists → exit **1**. |
| `add <COLLECTION>` | `--request <NAME>` (required) | Append an empty request to an existing collection. Duplicate name → exit **1**. |
| `edit <COLLECTION>` | `--request <NAME>` (required) + the edit flags below | Update fields on a request (non-interactive, all upserts). |
| `run <COLLECTION>` | `--request <NAME>` (omit = all, in order) · `--env <ENV>` | Execute via a blocking HTTP client (30s timeout, ≤10 redirects, no invalid certs). |

### `edit` flags

- `--set FIELD=VALUE` (repeatable): `name`, `method` (upper-cased), `url`, `body`,
  `body_type`|`body-type` (`json` / `xml` / `text`; default `json`). Unknown field → exit **2**.
- `--header NAME=VALUE`, `--query NAME=VALUE`, `--var NAME=VALUE`,
  `--capture NAME=PATH` — each repeatable, **upsert-by-name**. A `--capture` extracts a
  value from the response (e.g. `$.token`) and threads it into later requests in the run.

### Environments — `kensa http env …`

| Command | Does |
|---|---|
| `env list` | List env files. |
| `env set <NAME> <KEY> <VALUE>` | Set a key (creates the env file if absent). |
| `env get <NAME> <KEY>` | Print a value (missing key → exit **1**). |

## `{{var}}` resolution — precedence (highest first)

1. **request-local vars** (`--var` on the request)
2. **captured vars** (`--capture` values, threaded across the run)
3. **collection `@file` vars**
4. **env file** (`--env <ENV>`)

An **undefined `{{var}}`** anywhere (URL, query, header, body) is a **hard error
(exit 2)** — it is never sent literally. This is a feature: it catches a missing
`--env` or a typo'd variable before a request goes out.

## Exit codes — branch on them

- **`0`** — success.
- **`1`** — not found (`show`/`env get` on a missing request/key) or a create collision
  (`new`/`add` on an existing name).
- **`2`** — usage/config error: a bad collection/env name (separators/`..`/absolute),
  an unknown `--set` field, or an **undefined `{{var}}`** at run time. ⇒ fix the
  invocation (define the var, correct the name); do not retry verbatim.

## Output shape

`run` in `json` / `jsonl` emits `{request, status, statusText, headers, body}`; other
formats print a raw HTTP response block. **For scripting/agents, always prefer
`--format json`** so `status` and `body` come back structured.

## A typical flow

```sh
kensa http new api --request Login                                   # scaffold
kensa http edit api --request Login --set method=post \
  --set url='{{base}}/login' \
  --header Content-Type=application/json \
  --set body='{"user":"{{user}}","pass":"{{pass}}"}' \
  --capture token=$.token                                            # thread the token onward
kensa http env set staging base https://staging.example.com
kensa http env set staging user qa@example.com
kensa http run api --request Login --env staging --format json       # → {status, body, …}
# the captured {{token}} is now available to later requests in the same run:
kensa http add api --request Me
kensa http edit api --request Me --set url='{{base}}/me' \
  --header Authorization='Bearer {{token}}'
kensa http run api --env staging --format json                       # runs Login → Me in order
```

## Report findings back into the case (the loop)

An API run is only useful if the evidence lands in `.tms/`. Pair every check with
`kensa` writes (see the `kensa` skill for the full verb set):

1. **Read the case under test** first:
   ```sh
   kensa show API-021 --format json
   ```
2. **Run the request** and keep the structured response as evidence. Save a response
   body worth attaching into the project tree:
   ```sh
   kensa http run api --request Login --env staging --format json > .tms/attachments/api-021-login.json
   ```
3. **Write the result back:**
   - *Behaved as expected* — annotate the case:
     ```sh
     kensa update API-021 --set custom.api_checked=yes --format json
     ```
   - *Found a defect* — file a **new** case, attaching the request name, env, observed
     status/body vs. expected, and the SOT ref:
     ```sh
     kensa new --suite bugs/api --title "Login returns 200 with an empty token on bad password" \
       --priority high --tag api --tag regression --tag related-API-021 \
       --source-id LIN-142 --format json
     ```
     `--source-id` = external tracker ref only — never an internal case id; the
     case under test is linked via the `related-<case-id>` tag
     (convention in `kensa-test-authoring`).
     Then `Edit` the returned file to add `## Steps` (the exact `kensa http`
     commands + env), observed vs. expected, and a `## Notes` line pointing at the
     saved response. Follow `kensa-test-authoring` for the byte-exact format.

## Guardrails

- **Requests live in the project** (`.tms/tools/http/`) — committable, reviewable,
  reusable. Don't scatter ad-hoc curls; author a collection.
- **Never inline a real secret** into a collection file — put it in an env value or a
  `--var` and reference it as `{{token}}`. Env files under `.tms/tools/http/env/` may
  hold non-production credentials only; treat them as committed.
- **Undefined `{{var}}` is a hard stop** — resolve it (usually a missing `--env` or a
  typo), don't work around it.
- **Stay in scope.** Drive the app's test/staging API — never hit real production
  endpoints with real credentials, submit real payments, or mutate live data.
