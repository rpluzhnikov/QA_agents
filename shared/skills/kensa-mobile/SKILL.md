---
name: kensa-mobile
description: Drive a real Android device or iOS Simulator from the terminal via `kensa mobile` — an observe→act driver (snapshot the screen, then tap/type/swipe by alias) — and write findings back into `.tms/` cases. Use when a test scope needs live device evidence (app smoke tours, native form flows, on-device visual checks). Loaded by the QA Engineer when the brief names mobile-driven QA, and pairs with the `mobile-testing` skill (what to test) and `kensa` (how to read/write cases).
---

> **Non-ISTQB tooling skill**
> Covers project infrastructure: the `kensa mobile` subcommands that drive an
> Android device over `adb` (everywhere) or an iOS Simulator via a delegated
> `sim-use` binary (macOS only). Complementary to ISTQB CTFL v4.0.1 — pairs with
> `mobile-testing` (what to test on a device) and `kensa` (how to read/write cases).
> Light cross-reference: supports dynamic/experience-based testing (§4.4) and
> evidence capture for defect reports (§5.5). No specific learning objective grounds
> the content.

## Mental model — observe, then act

```
kensa mobile ui        →  banded outline of the screen + a per-device alias cache
                          (@0 @1 @2 … and #resource-id handles)
kensa mobile tap @3    →  act on an element from that snapshot
kensa mobile ui        →  re-snapshot after the screen changed (aliases are stale)
```

- **Project-independent, machine-scoped.** `kensa mobile` needs no `.tms/` project —
  it talks to whatever device/emulator is attached to the machine. Sync, tokio-free.
- **Observe→act.** You almost never tap raw coordinates. Run `ui` to capture a compact
  banded outline of the current screen; it persists an **alias cache** so the next
  `tap @N` / `tap #resource-id` / `tap --label "…"` resolves against what you just saw.
- **Aliases go stale.** Any screen change (navigation, rotation, a dialog) invalidates
  the `@N` aliases. **Re-run `ui`** after every transition. A snapshot older than
  **5 minutes** prints a stale-warning (it never blocks the tap, but re-snapshot).

## Device selection — the `--device` global flag

`--device <ID>` is **global on this family** (accepted before *or* after the
subcommand). Routing is by id shape:

- **UUID-shaped** (`8-4-4-4-12` hex, case-insensitive) → **iOS Simulator**.
- Android serial charset `[A-Za-z0-9._:-]+` (e.g. `emulator-5554`) → **Android**.
- Any other charset → exit **2**.

When `--device` is **omitted**, the target auto-selects **only if exactly one**
candidate device is reachable:

- 0 devices → exit **2** ("no devices").
- many devices → exit **2** listing the candidates (then pass `--device`).

**iOS gate:** any iOS-routed verb on a non-macOS host → exit **2** ("requires macOS");
on macOS with `sim-use` absent → a distinct "sim-use binary not found" (exit **2**).
There is deliberately **no env override**. `ANDROID_HOME` helps resolve `adb`.

## Command reference

Global form: `kensa mobile [--device <ID>] <subcommand> [args] [--format json]`

| Subcommand | Args | Behavior |
|---|---|---|
| `devices` | — | List Android devices (`adb devices -l`) + iOS Simulators on macOS. Records: `id`, `platform`, `state`, `model`. Exit **2** only when `adb` is unresolved AND the list is still empty; otherwise **0** (an empty list with `adb` present is a valid result). |
| `ui` | — | Capture a compact banded outline of the current screen (`~0.5–2s`), render it (text or JSON envelope), and persist the per-device alias cache. **Run this first.** |
| `tap` | `[@N \| #resource-id]` positional, or `--label <TEXT>`, or `-x <X> -y <Y>` | **Exactly one** selector source. `@N` / `#id` / `--label` resolve against the last `ui` cache; `-x/-y` are raw device coords (bypass cache). Ambiguous/unknown selectors → exit **2** with hints. |
| `swipe` | `--from X,Y --to X,Y [--duration-ms <MS>]` | Straight-line swipe. |
| `type <TEXT>` | — | Types printable ASCII (`0x20–0x7E`) on Android; spaces → `%s`; newlines / non-ASCII → exit **2** (Unicode is fine on the iOS delegate). |
| `button <NAME>` | — | `back` / `home` / `enter` / `recents` (Android keyevents 4/3/66/187). On iOS only `home` forwards. Unknown name → exit **2**. |
| `screenshot` | `--out <PATH>` (**required**; `-` = base64 on stdout) | PNG via `adb exec-out screencap -p` (binary-safe). Missing `--out` → exit **2** before device resolution. |

The alias cache lives at `<app-cache>/kensa-mobile/ui-cache-<sanitized-device>.json`
and is overwritten on each `ui` — it is **machine-scoped, not in the project**.

## Exit codes & the JSON error envelope — branch on them

- **`0`** — success (including an empty `devices` list when `adb` is present).
- **`2`** — usage/config error: bad `--device` charset, no/many devices without
  `--device`, an unknown selector, missing `screenshot --out`, an iOS verb off macOS,
  a non-ASCII `type` on Android. ⇒ **fix the invocation** (or attach a device / pass
  `--device`); do not retry verbatim.

In `json` / `jsonl` mode a failing verb also writes a machine-readable envelope to
**stdout** (in addition to the stderr message and the non-zero exit):

```json
{"error": "<message>", "hint": "<hint>"}
```

(the `hint` key is omitted when there is none). The iOS delegation path re-wraps
sim-use's own `{"ok":true,"data":…}` as `{"ok":true,"data":…,"source":"sim-use"}`.

## A typical flow

```sh
kensa mobile devices --format json                 # find a target
kensa mobile --device emulator-5554 ui             # snapshot + alias cache
kensa mobile tap --label "Sign in"                 # resolve against the snapshot
kensa mobile type "user@example.com"
kensa mobile button enter
kensa mobile ui                                    # screen changed → re-snapshot
kensa mobile tap @3                                # tap by fresh alias
kensa mobile swipe --from 500,1500 --to 500,300 --duration-ms 300
kensa mobile screenshot --out .tms/attachments/login-after.png
```

**Always `ui` → act → re-`ui`.** Never fire a chain of `tap @N` across a navigation
without re-snapshotting — the aliases point at the previous screen.

## Report findings back into the case (the loop)

A device run is only useful if the evidence lands in `.tms/`. Pair every scenario
with `kensa` writes (see the `kensa` skill for the full verb set):

1. **Read the case under test** first, so you know its preconditions and expected
   results:
   ```sh
   kensa show AUTH-014 --format json
   ```
2. **Drive the device** and **capture evidence** into the project tree (committable,
   relative paths):
   ```sh
   kensa mobile screenshot --out .tms/attachments/auth-014-after-submit.png
   ```
3. **Write the result back:**
   - *Behaved as expected* — annotate the case:
     ```sh
     kensa update AUTH-014 --set custom.device_checked=yes --format json
     ```
   - *Found a defect* — file a **new** case rather than editing the spec, attaching
     the evidence path and the SOT ref:
     ```sh
     kensa new --suite bugs/auth --title "Login: keyboard covers Submit on small screens" \
       --priority high --tag mobile --tag regression --source-id AUTH-014 --format json
     ```
     Then `Edit` the returned file to add `## Steps` (the exact `kensa mobile`
     commands that reproduce it — including the `ui` snapshots), the observed vs.
     expected result, and a `## Notes` line pointing at the screenshot. Follow
     `kensa-test-authoring` for the byte-exact format.

## Guardrails

- **Machine-scoped, not project-scoped** — the alias cache lives under `<app-cache>`,
  never in `.tms/`. Do not commit it.
- **Screenshots into the project dir** (`.tms/attachments/…`) so they're committable
  and referenced from cases — not into temp.
- **`screenshot` needs `--out`** — omitting it is an exit-`2` usage error.
- **Re-snapshot after every screen change** — `@N` aliases from a stale `ui` will tap
  the wrong element.
- **Stay in scope.** Drive the app's test/staging build — never log into real
  production accounts, submit real payments, or mutate live data on a device.
