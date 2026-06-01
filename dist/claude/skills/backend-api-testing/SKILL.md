---
name: backend-api-testing
description: API-specific test scenarios for REST/GraphQL backend services tested via tools like Postman, curl, or DevTools Network tab. Covers status codes, schema validation, idempotency, rate limiting, authentication (token expiry, refresh), pagination, filtering, error structure, and contract concerns. Use when the feature under test is a backend API or has a notable API contract. Loaded by the QA Engineer when the Test Lead specifies backend platform.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 2 — Testing Throughout the SDLC, §2.2.1 Test Levels (especially system integration testing), §2.2.2 Test Types (functional and non-functional — ISO 25010 quality characteristics: functional suitability, performance efficiency, reliability, security); Chapter 4 — Test Analysis and Design, §4.4.3 Checklist-Based Testing.
> Learning objectives: FL-2.2.1 (K2) distinguish test levels (API tests live mostly at system integration test level — between services and across system boundaries); FL-2.2.2 (K2) distinguish test types (this skill covers contract / functional plus non-functional API concerns); FL-4.4.3 (K2) explain checklist-based testing (this skill IS a domain checklist for REST/GraphQL APIs).
> See also: the `sdlc-and-test-lifecycle` skill for the level/type taxonomy.

# Backend / API testing — what not to forget

API testing splits into two layers:

1. **Contract** — what the API promises (status codes, schema,
   headers, error shapes). Tested by sending requests and checking
   responses against the spec.
2. **Behavior under stress** — what happens when the contract is
   violated by the client (bad input, race conditions, pagination
   abuse, rate-limit attacks). Tested by deliberately misbehaving.

Both layers are in scope for manual QA when the tools are simple
(Postman, curl, Insomnia, DevTools Network tab). For load testing or
fuzzing-scale stress, escalate to the perf or security team.

This skill is a structured walk across eight areas.

## 1. Status codes

### Success codes — pick the right 2xx

- **Test:** A successful POST that creates a resource returns `201
  Created`, not `200 OK`. The `Location` header points at the new
  resource.
- **Test:** A successful DELETE returns `204 No Content` with empty
  body, or `200 OK` with a confirmation body per spec.
- **Test:** PUT on existing resource → `200` or `204`; PUT creating
  a new resource → `201`.
- **Test:** A request that's accepted but processed async → `202
  Accepted` with a status URL or polling endpoint.

### Client errors

- **Test:** Missing required field → `400 Bad Request` with body
  identifying the missing field.
- **Test:** Auth required but missing → `401 Unauthorized` with
  `WWW-Authenticate` header.
- **Test:** Auth provided but insufficient permissions → `403
  Forbidden`. Note: 401 vs 403 distinction is real — clients use it
  to decide whether to prompt for re-auth.
- **Test:** Resource not found → `404`. But careful: don't leak
  existence — for protected resources, return 404 (not 403) when
  the user lacks permission, so the existence isn't revealed.
- **Test:** Request body too large → `413 Payload Too Large`.
- **Test:** Method not allowed on this endpoint → `405 Method Not
  Allowed` with `Allow` header listing supported methods.
- **Test:** Idempotency conflict → `409 Conflict`.
- **Test:** Validation passed but business rule failed → `422
  Unprocessable Entity`.

### Server errors

- **Test:** Server-side bug → `500 Internal Server Error` with **no
  stack trace or framework details in the body**. Generic message.
- **Test:** Downstream dependency unavailable → `502 Bad Gateway` or
  `503 Service Unavailable`. The latter should include `Retry-After`.
- **Test:** Request took too long → `504 Gateway Timeout`.

### If your feature has an API surface, add to the checklist:

- Success: right 2xx + Location header on create
- 400 / 401 / 403 distinguished correctly
- 404 does not leak existence for protected resources
- 5xx body contains no stack traces, no DB schema, no framework version

## 2. Schema validation

### Required fields

- **Test:** Omit each required field one at a time → `400` with body
  identifying the missing field.
- **Test:** All required fields present → success.

### Unknown / extra fields

- **Test:** Send a body with an extra field not in spec → behavior
  per contract (some APIs reject with `400`, some ignore silently,
  some accept and warn). Check the spec; consistency matters more
  than which choice.

### Wrong types

- **Test:** Send a string where the spec expects an integer → `400`.
- **Test:** Send a number where the spec expects a string → `400`.
- **Test:** Send a JSON array where the spec expects an object → `400`.

### Null values where not allowed

- **Test:** Send `null` for a required field → `400`.
- **Test:** Send `null` for an optional field with a defined null
  semantics → success per spec.

### Empty arrays / objects

- **Test:** `[]` where an array is required but must be non-empty
  → `400`.
- **Test:** `{}` where an object is required → behavior per spec.

### Deeply nested structures

- **Test:** Send a structure nested 100 levels deep → `400` or
  `413`, not 500.
- **Test:** Send a structure with a 10 MB JSON body → `413` with
  reasonable error message.

### If your feature has structured input, add to the checklist:

- Missing required fields (one per call)
- Wrong type for each field
- Extra fields per spec contract
- Null where not allowed
- Oversized payloads → 413, not 500

## 3. Authentication / authorization

### Missing token

- **Test:** Call protected endpoint with no `Authorization` header →
  `401` with `WWW-Authenticate`.

### Expired access token

- **Test:** Use an access token past its `exp` claim → `401`. Body or
  header includes a hint for refresh (e.g. `error: invalid_token,
  error_description: token expired`).

### Token for different user

- **Test:** Get a token for user A; call user B's protected resource
  with A's token → `403` (or `404` if existence leakage matters).
  See `security-testing` §3.1 for IDOR coverage.

### Wrong audience / wrong scope

- **Test:** Token from audience `api-public` calls `api-admin`
  endpoint → `403`. Body indicates the scope mismatch without
  revealing token internals.

### Refresh token flow

- **Test:** Access token expires → exchange refresh token → new
  access token works for protected calls.
- **Test:** Refresh token expires or has been revoked → exchange
  fails with `400/401 invalid_grant`.
- **Test:** Refresh token rotation — after exchange, the old refresh
  token is invalid (a single refresh token can't be used twice).

### If your feature is auth-protected, add to the checklist:

- Missing / expired / cross-user / wrong-scope token responses
- Refresh token rotation (old token invalidated)

## 4. Idempotency

### Idempotent operations (GET, HEAD, PUT, DELETE)

- **Test:** PUT the same body twice → same final state, no error.
- **Test:** DELETE the same resource twice → first returns 204, second
  returns 204 or 404 per spec (consistency matters).

### Non-idempotent operations (POST)

- **Test:** POST the same body twice → either both processed
  (non-idempotent semantics, two resources created) or one processed
  with idempotency guard.

### Idempotency-Key header

- **Test (if supported):** POST with `Idempotency-Key: abc123`,
  succeeds. Repeat the same request with the same key → returns the
  same response as the first call, does NOT create a duplicate.
- **Test:** Same key, different body → spec-defined behavior
  (typically `422` "key reused with different parameters").
- **Test:** Idempotency-Key expires (typically 24h) → after expiry,
  the same key with the same body creates a new resource.

### If your feature has POST endpoints with side effects, add to the checklist:

- Double POST → either duplicate or idempotency-guarded
- Idempotency-Key (if supported) — replay returns same response

## 5. Pagination and filtering

### Pagination boundaries

- **Test:** First page (`page=1` or `cursor=null`) — works.
- **Test:** Middle page — works.
- **Test:** Last page — works, indicates "no next page" (e.g.,
  `next_cursor: null` or empty `next` link).
- **Test:** Page beyond last → empty page or 404 per spec.
- **Test:** Page = 0 or negative → `400`.

### Page size

- **Test:** `size=1` → one item returned (smallest allowed).
- **Test:** `size=max` (per spec) → max items returned.
- **Test:** `size=max+1` → `400` or capped at max per spec.
- **Test:** `size=0` → `400` or empty page per spec.
- **Test:** `size=-1` → `400`.

### Filter combinations

- **Test:** Each filter alone returns correct results.
- **Test:** Two filters combined (AND semantics typically) → correct
  intersection.
- **Test:** Filter with no matches → empty page with metadata
  (`total: 0`), not 404.

### Sort

- **Test:** Sort by a valid field → correctly ordered.
- **Test:** Sort by an invalid field → `400` with body listing
  allowed sort fields.
- **Test:** Sort direction `asc` / `desc` honored.
- **Test:** Sort by a field with `null` values — `null`s appear
  consistently (always first or always last per spec).

### If your feature has a list endpoint, add to the checklist:

- First / middle / last / beyond-last pages
- Page size = 1, max, max+1
- Empty result set returns metadata, not 404
- Sort by invalid field → 400 with allowed list

## 6. Rate limiting

### Hit the limit

- **Test:** Send N+1 requests in the window where the limit is N →
  request N+1 returns `429 Too Many Requests` with `Retry-After`
  header (seconds or HTTP-date).
- **Test:** Within the cooldown window, all requests → `429`.
- **Test:** After cooldown, requests resume normally.

### Limit scope

- **Test:** Is the limit per-user (token)? Per-IP? Both? Verify by
  testing with multiple users from same IP, same user from multiple
  IPs.

### Burst behavior

- **Test:** Some APIs allow short bursts above the steady-state
  limit. Verify the documented burst is honored.
- **Test:** Sustained traffic above the steady limit triggers `429`
  after the burst budget is exhausted.

### Headers indicating remaining

- **Test:** Response headers include `RateLimit-Limit`,
  `RateLimit-Remaining`, `RateLimit-Reset` (or legacy
  `X-RateLimit-*`). Clients use these to back off proactively.

### If your feature has rate-limiting, add to the checklist:

- N+1 → 429 with Retry-After
- Cooldown release timing
- Per-user vs per-IP scope verified
- RateLimit-* headers present

## 7. Concurrency

### Optimistic concurrency control (ETag / If-Match)

- **Test (if supported):** GET a resource, note the `ETag` header.
  PUT with `If-Match: <that ETag>` → success. PUT with
  `If-Match: <wrong ETag>` → `412 Precondition Failed`.
- **Test:** PUT without `If-Match` on a resource that requires it →
  `428 Precondition Required` per spec.

### Last-write-wins (when intended)

- **Test:** GET resource as user A and as user B. A updates field X;
  B (with stale view) updates field Y. Both succeed; final state has
  both A's X and B's Y → field-level merge worked, OR last write
  overwrites earlier write → simple LWW per spec.

### Race on uniqueness constraints

- **Test:** Two users simultaneously attempt to claim the same
  username / handle / unique slug. Exactly one succeeds (201); the
  other gets `409 Conflict`.

### If your feature has multi-user mutations, add to the checklist:

- ETag-based optimistic concurrency (if supported)
- Race on uniqueness → exactly one 201, one 409
- Concurrent edits to the same resource (per-field or LWW per spec)

## 8. Errors — structure and consistency

### Consistent error envelope

- **Test:** All errors return the same JSON shape. A common pattern:
  ```json
  { "error": "validation_error", "message": "Field X is required", "details": [...] }
  ```
- **Test:** The `error` field is a stable machine-readable code
  (clients switch on it). The `message` field is human-readable.

### Localized error messages

- **Test (if i18n):** Request with `Accept-Language: de-DE` → error
  message in German. `Accept-Language` not set → default language
  per spec.

### No leakage in error bodies

- **Test:** No stack traces.
- **Test:** No DB column names or schema fragments.
- **Test:** No framework version or path-on-disk info.
- **Test:** No internal hostnames or IPs.

### Error correlation IDs

- **Test (if supported):** Every error response includes a
  `request-id` (or `trace-id`) header / field. Same ID appears in
  server logs for that request — testers can use it to file bugs
  with precision.

### If your feature has errors, add to the checklist:

- Consistent envelope across all error responses
- Stable machine-readable error codes
- No stack traces / schema / version leakage
- Correlation ID present in every response

## How to apply

A typical API feature surfaces 10–25 items from this walk. The
worker doesn't write 25 cases — they pick the items that are
material for THIS feature.

A "get user profile" endpoint surfaces: §1 status codes (200, 401,
403, 404), §2 schema for the response, §3 auth, maybe §5 if it's
paginated. Skip §4, §6, §7, §8 if they don't apply.

A "create order" endpoint surfaces: §1 (201 + Location), §2 (every
required field), §3 (auth), §4 (POST idempotency), §6 (rate limit),
§8 (error structure). Skip §5, §7 unless explicit.

Mark each item `[api §N — description]` in the checklist so the Test Lead
can verify coverage maps to the contract.

## Tools — what to use

- **Postman / Insomnia** — saved request collections, environment
  switching, basic chaining
- **curl** — minimal, scriptable, no environment to corrupt
- **DevTools Network tab** — when the UI exercises the API anyway,
  inspect/replay/edit directly from there
- **httpie** — friendlier curl

Stay manual for QA scope. The moment you reach for a fuzzer (ffuf,
SQLMap, etc.) you've crossed into pentest territory — see
`security-testing` for what's in vs out of scope.
