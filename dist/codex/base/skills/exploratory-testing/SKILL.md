---
name: exploratory-testing
description: Charter-driven exploratory testing — simultaneous learning, test design, and execution against the running app. Use when the brief calls for a live exploration session (browser/mobile/API), when a spec is too thin to script cases from, or after scripted runs to hunt what they can't catch. Produces session notes in .tms/reports/ and defect cases via kensa new.
---

> **ISTQB CTFL v4.0.1 grounding**
> Chapter 4 — Test Analysis and Design, §4.4.2 Exploratory Testing.
> Learning objective: FL-4.4.2 (K2) explain exploratory testing — "tests are
> simultaneously designed, executed, and evaluated while the tester learns about
> the test object"; most useful "when there are few or inadequate specifications
> or significant time pressure", complementing (never replacing) systematic
> techniques; often organized as **session-based testing** with a time-box and a
> **test charter** covering the objectives.
> See also: §1.4.1 (exploration IS test analysis+design+execution interleaved);
> §5.1.5 (risk decides what to explore first); the `negative-and-edge-cases`
> taxonomy as an in-session idea generator.

# Exploratory testing

Scripted cases verify what the spec promised. Exploration finds what nobody
thought to promise. The two are complements: a case base with no exploration
inherits every blind spot of the spec.

## The charter — write it BEFORE touching the app

One line, always the same shape:

```
Explore <target area>
with <resources: tools, data, personas, constraints>
to discover <the information the session should produce>
```

Examples:

- *Explore the checkout promo-code flow with expired/stacked/foreign-currency
  codes to discover mishandled discount math.*
- *Explore profile editing with a second concurrent session to discover
  lost-update and stale-state behavior.*
- *Explore the mobile onboarding with airplane-mode interruptions to discover
  state-recovery defects.*

A session has ONE charter. Found something outside it? Note it as a new charter
candidate and stay on mission — charter drift is how sessions produce nothing.

## Time-box and cadence

- **60–120 minutes** per session (shorter loses depth, longer loses focus).
- Agent sessions: budget by actions, not minutes — declare it in the notes
  (e.g. "~40 browser commands").
- Split: ~80% on-charter exploration, ~20% note-taking and defect filing.

## Tours — angles of attack

Pick the tour(s) matching the charter (Whittaker's catalog, adapted):

| Tour | You act like | Hunting for |
|---|---|---|
| **Feature tour** | a curious new user touching everything | dead ends, broken affordances |
| **Data tour** | a hoarder: max/min/weird data everywhere | overflow, truncation, encoding, `\x00`-class input bugs |
| **Interruption tour** | someone with a flaky connection and no patience | cancel/refresh/back/offline/timeout recovery |
| **Adversarial tour** | a user actively trying to cheat | bypasses, IDOR, client-side-only validation |
| **Landmark tour** | a task-focused user on the critical path | friction and breakage on the money path |
| **Garbage-collector tour** | a completionist deleting/undoing everything | orphaned state, broken cleanup, zombie records |
| **Supermodel tour** | someone who only looks at the surface | layout breakage, i18n overflow, a11y landmarks |

In-session idea generator: walk the `negative-and-edge-cases` taxonomy
(input / action / state / environment) whenever you run dry.

## Session notes — the deliverable

Write `.tms/reports/session-<slug>-<YYYY-MM-DD>.md` as you go, not after:

```markdown
# Exploratory session — <charter, verbatim>

**Date:** YYYY-MM-DD · **Time-box:** <planned> · **Tour(s):** <names>
**Environment:** <test/staging URL, build, device>

## Log
- <timestamp/step> — <what was tried> → <what was observed>
  (only noteworthy observations — not every click)

## Defects found
- <one line each + the case id filed via `kensa new`>

## Questions / spec gaps
- <things the app does that no spec explains — feed the assumptions ledger>

## New charter candidates
- <out-of-scope smells worth their own session>

## Coverage delta
- <what this session covered that the scripted cases don't — candidates for /new-feature>
```

## Filing what you find

- **Defects** → `kensa new` per the evidence skill you're driving with
  (`kensa-browser` / `kensa-mobile` / `kensa-http`): reproduction steps = the
  exact commands, observed vs expected, screenshot under `.tms/attachments/`,
  external ref in `--source-id`, case-under-test link via `related-<id>` tag.
- **Worth keeping as a scripted case** → recommend it in the Coverage delta
  section; the Lead routes it through `/new-feature`.
- **Spec gaps** → `GAP:` markers; they flow into the assumptions ledger at
  save-memory time.

## Guardrails

- Test/staging only — never real production credentials, payments, or data.
- Exploration complements the dimension-gated checklist — it never substitutes
  for it. If the Lead's brief says "explore instead of writing cases", push back:
  the answer is both, sequenced by risk.
- No charter, no session. "Poke around" is not a charter.
