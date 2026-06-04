---
name: kensa-browser
description: Drive a real Chrome browser from the terminal via `kensa-cli browser` (CDP) to perform browser-based QA — navigate, interact, capture screenshots, inspect the DOM — and write findings back into `.tms/` cases. Use when a test scope needs live browser evidence (smoke tours, form flows, visual baselines) or when running a routine (RT-*.md). Loaded by the QA Engineer when the brief names browser-driven QA, and by the Test Lead when running `/run-routine`.
---

> **Non-ISTQB tooling skill**
> Covers project infrastructure: the `kensa-cli browser` subcommands that drive a
> Kensa-launched Chrome over the DevTools Protocol (CDP), plus the loop that writes
> what the browser found back into `.tms/` cases. Complementary to ISTQB CTFL
> v4.0.1 — pairs with `web-testing` (what to test in a browser) and `kensa-cli`
> (how to read/write cases). Light cross-reference: supports dynamic/experience-based
> testing (§4.4) and evidence capture for defect reports (§5.5).

## Mental model

```
Kensa GUI ──launch──▶ Chrome (127.0.0.1:<port>, CDP, throw-away profile)
   │                      ▲
   │                      │ kensa-cli browser <sub>   (connect → act → disconnect)
   ▼                      │
Host shell ─▶ agent ──────┘
```

- **Kensa owns the browser.** The user starts Chrome from **Tools → Browser →
  Start**. It binds a CDP debug port to loopback only, with a dedicated throw-away
  `--user-data-dir` (never the user's real profile). You do **not** launch your own
  browser.
- **You drive it** by shelling out to `kensa-cli browser …`. Each command connects
  over CDP, performs one action, and disconnects. The Chrome process persists
  between commands: **page, cookies, and DOM survive** across separate invocations;
  **in-page JS variables do NOT survive** across separate `eval` calls.
- The binary is `kensa-cli`. If a command isn't found, Chrome probably isn't running
  — start it from Tools → Browser (see exit code `2` below).

## Prerequisites & endpoint resolution

Chrome must be running (Tools → Browser → **Start**). Every `kensa-cli browser`
call resolves the CDP endpoint in this order:

1. `--cdp-url <ws://127.0.0.1:PORT/...>` flag (manual override),
2. `KENSA_CDP_URL` env var (injected into the embedded terminal by Kensa),
3. `endpoint.json` discovery file in the app-cache dir (written on launch),
4. otherwise: exit **2** with a hint to launch Chrome first.

**Loopback-only.** Any CDP URL that isn't `127.0.0.1` / `localhost` / `[::1]`
(`ws://` scheme, no `user@host`) is rejected. Never point it at a remote host.

## Command reference

Global form: `kensa-cli browser [--cdp-url <WS-URL>] <subcommand> [args] [--format json]`

`--format`: `table` (default on a TTY) · `json` · `jsonl` · `ids` · `paths`. **For
scripting/agents, always prefer `--format json`** — booleans come back as real JSON
booleans (`{"clicked": true}`), not strings.

### Navigation
| Command | Key flags | Output (json) |
|---|---|---|
| `open <url>` (alias `navigate`) | `--wait load\|domcontentloaded\|networkidle` (def. load) · `--timeout <ms>` (30000) · `--capture-console` · `--capture-network` | `{ url, finalUrl, title, console?, network? }` |
| `reload` | `--wait` · `--timeout` · `--capture-console` · `--capture-network` | `{ url, title, console?, network? }` |
| `back` / `forward` | `--timeout` | `{ url, title }` |
| `url` / `title` | — | `{ url }` / `{ title }` |

### Interaction
| Command | Key flags | Output |
|---|---|---|
| `click <selector>` | `--nth <N>` (0) · `--timeout` · `--capture-console` · `--capture-network` | `{ clicked: true, … }` |
| `type <selector> <text>` | `--clear` · `--delay <ms>` (0) · `--timeout` | `{ typed: true, … }` |
| `fill <selector> <value>` | `--timeout` | `{ filled: true, … }` |
| `press <key>` | `--timeout` (`Enter`, `Tab`, `Escape`, `ArrowDown`, …) | `{ pressed: true }` |

### Capture
| Command | Key flags | Does |
|---|---|---|
| `screenshot --out <path>` | `--out <path>` (**required**; `-` = base64 to stdout) · `--selector <sel>` · `--full-page` | PNG of viewport / element / full page; prints the path |

### Inspection
| Command | Key flags | Output |
|---|---|---|
| `dom` | `--selector <sel>` | `outerHTML` of an element (or document element) |
| `html` | — | full page source HTML |
| `query <selector>` | — | all matching elements |
| `text <selector>` | `--timeout` | `{ text }` (inner text) |
| `attr <selector> <name>` | `--timeout` | `{ value }` |

### Scripting & waiting
| Command | Key flags | Output |
|---|---|---|
| `eval <js>` | `--arg <JSON>` (repeatable, as `$args` array) · `--await` (await a Promise) | the result value |
| `wait` | one of `--selector <sel> [--state visible\|hidden\|attached]` · `--text <string>` · `--load networkidle\|domcontentloaded`; plus `--timeout` | `{ waited: true }` |

### Diagnostics
| Command | Output |
|---|---|
| `status` | `{ endpoint, reachable, browserVersion, protocolVersion, targetCount? }` |
| `targets` | list of `{ targetId, type, title, url }` |

## Exit codes — branch on them

- **`0`** — success.
- **`1`** — runtime failure against a *reachable* browser (selector not found, nav
  timeout, JS threw). ⇒ **retry with a different selector, or report the page state**
  (`url`, `title`, a `screenshot`) rather than guessing.
- **`2`** — usage/config error (no endpoint resolved, missing required flag like
  `screenshot --out`, non-loopback `--cdp-url`). ⇒ **fix the invocation, or ask the
  user to launch Chrome** (Tools → Browser → Start). Do not retry verbatim.

## A typical flow

```sh
kensa-cli browser status --format json                 # reachable: true?
kensa-cli browser open https://example.com
kensa-cli browser title --format json
# discover what's clickable before guessing selectors:
kensa-cli browser eval "JSON.stringify([...document.querySelectorAll('a,button')].slice(0,30).map(e=>({t:e.tagName,txt:(e.innerText||'').trim().slice(0,40),href:e.getAttribute('href'),id:e.id})))"
kensa-cli browser click "nav a[href='/pricing']"
kensa-cli browser screenshot --out .tms/attachments/pricing.png
kensa-cli browser open https://example.com/login --capture-console   # catch JS errors
```

Persistence: a `click` then a `text`/`screenshot` in the **next** invocation operate
on the same page. In-page JS state from one `eval` does **not** carry to the next —
each `eval` is a fresh evaluation; pass data via `--arg` or re-query the DOM.

## Report findings back into the case (the loop)

A browser run is only useful if the evidence lands in `.tms/`. Pair every routine
with `kensa-cli` writes (see the `kensa-cli` skill for the full verb set):

1. **Read the case under test** before driving the browser, so you know its
   preconditions and expected results:
   ```sh
   kensa-cli show AUTH-014 --format json
   ```
2. **Drive the browser** through the scenario and **capture evidence** into the
   project tree (committable, relative paths):
   ```sh
   kensa-cli browser screenshot --out .tms/attachments/auth-014-after-submit.png --full-page
   ```
3. **Write the result back:**
   - *Case passed / behaved as expected* — annotate it:
     ```sh
     kensa-cli update AUTH-014 --set custom.browser_checked=yes --format json
     ```
   - *Found a defect* — file a new case rather than editing the spec, attaching the
     evidence path and the SOT ref:
     ```sh
     kensa-cli new --suite bugs/auth --title "Login: email field accepts spaces, no validation error" \
       --priority high --tag browser --tag regression --source-id AUTH-014 --format json
     ```
     Then `Edit` the returned file to add `## Steps` (the exact `kensa-cli browser`
     commands that reproduce it), the observed vs. expected result, and a
     `## Notes` line pointing at the screenshot. Follow `kensa-test-authoring` for
     the byte-exact format.
4. **Stay in scope.** The browser is purely local and read-mostly for QA — never use
   it to log into real production accounts with real credentials, submit real
   payments, or mutate live data. Use the app's test/staging environment.

## Guardrails

- **Loopback only** — the CLI rejects non-`127.0.0.1` CDP URLs; don't try to bypass it.
- **Never touch the real profile** — Kensa launches a throw-away `--user-data-dir`; you
  drive whatever it gives you.
- **Screenshots into the project dir** (`.tms/attachments/…`) so they're committable
  and referenced from cases — not into temp.
- **`screenshot` needs `--out`** — omitting it is an exit-`2` usage error.
- **One page, reused** — a freshly launched browser may expose only a browser-level
  target at first; `kensa-cli browser` waits briefly for a page (and creates one if
  none exists), then reuses it across calls.
