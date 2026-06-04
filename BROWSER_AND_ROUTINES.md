# Kensa — Browser commands & Routines (integration reference)

> Reference for integrating the **Browser/CDP** tooling and **Routines** into the
> QA_agents plugin. Audience: plugin authors and the agents themselves.
> Introduced in Kensa **v0.17.0**. Companion: `docs/routines-and-agents.md`
> (user-facing), decisions **D152 / D153**.

---

## 1. Mental model

```
Kensa GUI ──launch──▶ Chrome (127.0.0.1:<port>, CDP, throw-away profile)
   │                      ▲
   │ Run routine          │ kensa-cli browser <sub>   (connect → act → disconnect)
   ▼                      │
Embedded terminal ─▶ claude / codex ─┘
        (seeded with the routine prompt)
```

- **Kensa owns the browser.** The user starts Chrome from **Tools → Browser**.
  It binds a CDP debug port to loopback only, with a dedicated `--user-data-dir`
  (never the user's real profile).
- **Agents drive it** by shelling out to `kensa-cli browser …`. They do **not** launch
  their own browser. Each command connects over CDP, performs one action, and
  disconnects. The Chrome process persists between commands (page, cookies, DOM
  survive; in-page JS variables do **not** survive across separate `eval` calls).
- **Routines** are reusable prompt scenarios that launch an agent (`claude`/`codex`)
  in a fresh terminal, seeded with a prompt that tells it what to do.

### The binary name: `kensa-cli`

The plugin always calls the CLI as **`kensa-cli`** — every command and every prose
reference in this doc, the skills, and the agents. It must resolve in a plain shell
(`kensa-cli --version`), because the agents run in the host process, not Kensa's
embedded terminal.

Inside the Kensa app the same binary is *also* injected on the embedded terminal's
PATH under the short alias `kensa`. The agents don't rely on that alias — using
`kensa-cli` everywhere keeps the commands working in both contexts.

---

## 2. Prerequisites & endpoint resolution

Chrome must be running (Tools → Browser → **Start**). Then every `kensa-cli browser`
call resolves the CDP endpoint in this order:

1. `--cdp-url <ws://127.0.0.1:PORT/...>` flag (manual override).
2. `KENSA_CDP_URL` env var (injected into the embedded terminal by Kensa).
3. `endpoint.json` discovery file in the app-cache dir (written on launch).
4. Otherwise: exit **2** with a hint to launch Chrome first.

**Loopback-only.** Any CDP URL that isn't `127.0.0.1` / `localhost` / `[::1]`
(`ws://` scheme, no `user@host`) is rejected.

---

## 3. `kensa-cli browser` command reference

Global form: `kensa-cli browser [--cdp-url <WS-URL>] <subcommand> [args] [--format json]`

`--format`: `table` (default on a TTY) · `json` · `jsonl` · `ids` · `paths`.
For scripting/agents, prefer **`--format json`** — booleans are real JSON booleans
(`{"clicked": true}`), not strings.

### Navigation

| Command | Args / flags | Does | Output (json) |
|---|---|---|---|
| `open <url>` (alias `navigate`) | `--wait load\|domcontentloaded\|networkidle` (def. load) · `--timeout <ms>` (30000) · `--capture-console` · `--capture-network` | Navigate to a URL, wait for the lifecycle event | `{ url, finalUrl, title, console?, network? }` |
| `reload` | `--wait` · `--timeout` · `--capture-console` · `--capture-network` | Reload current page | `{ url, title, console?, network? }` |
| `back` | `--timeout` | History back | `{ url, title }` |
| `forward` | `--timeout` | History forward | `{ url, title }` |
| `url` | — | Current URL | `{ url }` |
| `title` | — | Current page title | `{ title }` |

### Interaction

| Command | Args / flags | Does | Output |
|---|---|---|---|
| `click <selector>` | `--nth <N>` (0) · `--timeout` · `--capture-console` · `--capture-network` | Click the Nth element matching a CSS selector | `{ clicked: true, … }` |
| `type <selector> <text>` | `--clear` · `--delay <ms>` (0) · `--timeout` | Type text key-by-key into an element | `{ typed: true, … }` |
| `fill <selector> <value>` | `--timeout` | Set an input's value (fires input/change events) | `{ filled: true, … }` |
| `press <key>` | `--timeout` | Dispatch a key press (`Enter`, `Tab`, `Escape`, `ArrowDown`, …) | `{ pressed: true }` |

### Capture

| Command | Args / flags | Does | Output |
|---|---|---|---|
| `screenshot --out <path>` | `--out <path>` (**required**; `-` = base64 to stdout) · `--selector <sel>` · `--full-page` | PNG of the viewport, an element, or the full page | writes the file; prints the path/base64 |

### Inspection

| Command | Args / flags | Does | Output |
|---|---|---|---|
| `dom` | `--selector <sel>` | `outerHTML` of an element (or the document element) | HTML string |
| `html` | — | Full page source HTML | HTML string |
| `query <selector>` | — | All elements matching the selector | list of matches |
| `text <selector>` | `--timeout` | Inner text of an element | `{ text }` |
| `attr <selector> <name>` | `--timeout` | An element's attribute value | `{ value }` |

### Scripting & waiting

| Command | Args / flags | Does | Output |
|---|---|---|---|
| `eval <js>` | `--arg <JSON>` (repeatable; as `$args` array) · `--await` (await a Promise) | Evaluate a JS expression in the page | the result value |
| `wait` | one of: `--selector <sel> [--state visible\|hidden\|attached]` · `--text <string>` · `--load networkidle\|domcontentloaded`; plus `--timeout` | Block until a condition holds | `{ waited: true }` |

### Diagnostics

| Command | Args | Does | Output |
|---|---|---|---|
| `status` | — | Probe the CDP endpoint | `{ endpoint, reachable, browserVersion, protocolVersion, targetCount? }` |
| `targets` | — | List open targets (tabs/workers) | list of `{ targetId, type, title, url }` |

### Exit codes

- `0` — success.
- `1` — runtime failure against a reachable browser (selector not found, nav
  timeout, JS threw, …).
- `2` — usage / config error (no endpoint resolved, missing required flag like
  `screenshot --out`, non-loopback `--cdp-url`).

Agents should branch on the exit code: `2` ⇒ fix the invocation / launch Chrome;
`1` ⇒ retry with a different selector or report the page state.

---

## 4. A typical agent flow

```sh
kensa-cli browser status                      # reachable: true ?
kensa-cli browser open https://example.com
kensa-cli browser title
# discover what's clickable:
kensa-cli browser eval "JSON.stringify([...document.querySelectorAll('a,button')].slice(0,30).map(e=>({t:e.tagName,txt:(e.innerText||'').trim().slice(0,40),href:e.getAttribute('href'),id:e.id,cls:e.className})))"
kensa-cli browser click "nav a[href='/pricing']"
kensa-cli browser screenshot --out ./pricing.png
kensa-cli browser open https://example.com/login --capture-console   # catch JS errors
```

Persistence: the page survives between calls, so a `click` then a `text`/`screenshot`
in the next invocation operate on the same page. In-page JS state from one `eval`
does **not** carry to the next `eval`.

---

## 5. Routines

A **routine** is a reusable prompt scenario stored on disk.

### File format — `.tms/routines/RT-NNN.md`

```markdown
---
id: RT-001
name: Smoke-check the marketing site
engine: claude          # "claude" | "codex" (allow-listed; anything else is rejected)
description: Opens the homepage and verifies the hero headline.
---

Open https://example.com with `kensa-cli browser open`, read the `h1` with
`kensa-cli browser text "h1"`, and report whether it still says "Example Domain".
```

- **`id`** — `RT-<digits>`, allocated automatically; also the filename stem.
  Validated `^RT-\d+$` before any path use (path-traversal guard).
- **`engine`** — `claude` or `codex` only.
- **Body = the prompt.** Plain language; reference the `kensa-cli browser` verbs you
  want the agent to use. No `## Steps` parsing — the whole body is the prompt.

Authored in **Tools → Browser → Routines** (New / edit / Run / delete). Routine
files are plain Markdown and committable.

### What "Run" does

1. Writes the prompt body to a temp file: `<app-cache>/kensa-routines/<uuid>.md`
   (UTF-8).
2. Opens a **new embedded terminal tab**.
3. Submits one command that launches the engine seeded with the prompt:
   - PowerShell: `claude (Get-Content -Raw -Encoding UTF8 -LiteralPath '<file>')`
   - POSIX sh:  `claude "$(cat '<file>')"`
   (the multi-line prompt is never inlined into the command — only the file path is).

The agent starts already holding the prompt and works through the task, driving the
browser with `kensa-cli browser …` and reporting back in the terminal.

### Security model (D153)

Routine files are **untrusted** (a repo/PR can plant one). Hardening:
- `engine` is allow-list-mapped to a fixed binary; anything else throws.
- IDs validated `^RT-\d+$` + derived from the filename; mismatched files skipped.
- The temp path is per-shell quoted and rejects CR/LF; the prompt is never inlined.

---

## 6. Plugin integration guide (QA_agents)

How the plugin makes routines + browser useful:

1. **Teach the agents the verb set.** Add the `kensa-cli browser` reference (section 3)
   to the plugin's agent instructions / `CLAUDE.md` section, plus the persistence
   model and the exit-code branching rule.
2. **Teach the "report back into the case" loop.** A browser routine is most useful
   when the agent writes its findings back into a `.tms/` case with the `kensa`
   CLI (e.g. update steps/expected results, attach a screenshot path). Document the
   relevant `kensa` write verbs alongside the browser ones.
3. **Ship starter routines.** Provide a few `.tms/routines/RT-*.md` templates
   (smoke tour, form submission, visual diff baseline) the user can run immediately.

### Proposal — a dedicated `routine-runner` agent (Sonnet)

A thin agent in the plugin whose system prompt bakes in:
- the `kensa-cli browser` verb set + the connect→act→disconnect model,
- the "drive the browser, then write findings back into the case" loop,
- guardrails (loopback only, don't touch the real profile, screenshot to the
  project dir, branch on exit codes).

A routine could then target it by name (`engine: routine-runner`) for more reliable,
cheaper browser-QA behavior than a generic `claude`/`codex` session. **Not built yet
— captured for a future milestone.**

---

## 7. Gotchas

- **Shell on Windows.** The embedded terminal uses `pwsh.exe` → `powershell.exe` →
  `cmd.exe` (in that order). Routine launch commands are PowerShell-form; they need
  a PowerShell-family shell (handled — `cmd.exe` is only a last resort that should
  never be hit on a normal Windows box).
- **UTF-8.** The prompt temp file is UTF-8; the PowerShell read uses
  `-Encoding UTF8` so non-ASCII (e.g. Cyrillic) prompts aren't mangled.
- **`screenshot` needs `--out`.** Omitting it is an exit-2 usage error.
- **One page, reused.** A freshly launched browser may expose only a browser-level
  target at first; `kensa-cli browser` waits briefly for a page and creates one if
  none exists, then reuses it across calls.
- **Headed vs headless.** Chosen in the Browser tab at launch. Headless is fine for
  automation; headed lets the user watch the agent work.
```
