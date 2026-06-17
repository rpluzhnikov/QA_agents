---
name: kensa-blueprints
description: Design, validate, and run Kensa Blueprints — node-graph automations (an Unreal-style canvas) executed by a Rust engine, driven from the terminal via `kensa-cli blueprint …`. A first-class agent (`prompt`) node can run `claude`/`codex` non-interactively inside a flow. Use when a user wants to automate a QA workflow as a wired graph (API calls, scripts, branching, agent steps) rather than a one-off command. Loaded by the Test Lead from `/blueprint`, or by the QA Engineer when a brief names blueprint authoring.
---

> **Non-ISTQB tooling skill**
> Covers project infrastructure: the **Blueprints** node-graph automation system and
> its `kensa-cli blueprint` CLI. Complementary to ISTQB CTFL v4.0.1 — pairs with
> `kensa-cli` (read/write cases) and `kensa-browser` (live browser QA), and is a way
> to operationalise test execution and tooling (§6) as repeatable, wired flows. No
> specific learning objective grounds the content.

## What Blueprints are

Blueprints are **node-graph automations** authored in Kensa (an Unreal-style canvas)
and executed by a Rust engine. A graph has two kinds of wires between nodes:

- **exec pins** — white triangles — **control flow** (the order nodes run in).
- **data pins** — colored circles — **typed values** passed between nodes.

They are the differentiator vs. n8n / Postman: a first-class **agent node** can run
`claude` / `codex` non-interactively inside a flow.

Files live at `.tms/blueprints/BP-NNN.json` (schema v1; the TS implementation is the
source of truth, the Rust engine is byte-parity). A runnable graph needs **exactly one
Start and one Finish**.

## Node families (catalog)

| Family | Nodes |
|---|---|
| Boundary | `input` (Start), `output` (Finish) |
| Flow | `branch`, `switch`, `parallel`, `join`, `foreach`, `delay`, `assert`, `print` |
| Action | `api` (HTTP), `script`, `process`, `prompt` (Agent), `subblueprint` |
| Pure / data | `getVariable`, `setVariable`, `cast`, `stringFormat`, `jsonPath`, `compare`, `bool`, `length`, `default` |
| Canvas | `comment` |

## Referencing context (variables) — `${...}`

Node fields interpolate run context with **braced references**:

- `${name}` — a blueprint variable or input
- `${env.KEY}` — a value from the connected env file (read-only)
- `${context.name}` / `${context.env.KEY}` — the same, with an explicit prefix

The legacy `$context.name` form is still accepted. Precedence (highest first):
**node-local pin > captured value > variable > input**. An undeclared reference is a
**hard error** — never a silent empty string, never a process-env read.

## The agent (`prompt`) node — the two-file handshake

The agent node runs a coding agent non-interactively and captures a **structured
result**:

1. **Build:** Kensa resolves `${...}` in the prompt, writes `context.json` (the run
   context, secrets redacted), an empty `output.json` sink, and the prompt file into a
   per-node temp dir.
2. **Launch:** the engine is allow-listed — `mode` is **`claude` / `codex` / `custom`**
   only. On Windows the npm `.cmd` shims are launched via `cmd /C`. The prompt is fed on
   stdin (`$PROMPT_FILE` is also available).
3. **Complete:** the agent must write `{ "status": "ok"|"fail", "outputs": {…} }` to
   `$OUTPUT_FILE` and exit. `ok` + exit 0 binds the outputs; anything else routes to the
   node's `error` arm.

**Output fields:** declare `outputFields` (name + type) on the prompt node — each becomes
a **typed data-out pin** you can wire onward. With none declared, the whole result is
exposed on a single `output` (json) pin.

> When *you* (an agent) are the one running inside a `prompt` node: read `context.json`
> (or `$PROMPT_FILE`), do the work, and **write `$OUTPUT_FILE`** with `status` + the
> declared `outputs` before exiting. Exit 0 only on `status: "ok"`.

## Authoring tips

- Wire **Start → … → Finish**; every impure node needs an incoming exec edge.
- For a `prompt` node, **declare output fields** for the values you want to wire, and
  describe them in the prompt so the agent fills them.
- Use `setVariable` to capture a value, then read it anywhere with `${name}`.
- `branch` / `switch` route by an inline condition or a wired boolean.
- `parallel` arms must converge on a `join` (`all` / `any` / `count:k`).
- `foreach` iterates a json array; `item` / `index` are per-iteration pins.
- Script / agent nodes are **consent-gated** on first run (a security prompt).

## The CLI surface (`kensa-cli blueprint …`)

| Command | Purpose |
|---|---|
| `kensa-cli blueprint new <name>` | Scaffold a `BP-NNN.json`. |
| `kensa-cli blueprint list` | List blueprints in the project. |
| `kensa-cli blueprint show <id>` | Print a blueprint. |
| `kensa-cli blueprint validate <id>` | Static graph validation (frozen error codes). |
| `kensa-cli blueprint run <id> [--input k=v] [--allow-scripts]` | Headless run → writes a `kind:"blueprint"` run record under `.tms/runs/`. |

```sh
kensa-cli blueprint new "smoke-and-triage"        # scaffold BP-NNN.json
kensa-cli blueprint list --format json
kensa-cli blueprint validate BP-001               # fix every code before running
kensa-cli blueprint run BP-001 --input url=https://staging.example.com
kensa-cli blueprint run BP-001 --allow-scripts    # consent to script/agent nodes
```

> Authoring loop: `new` → wire the graph (in the Kensa canvas or by editing the JSON) →
> `validate` until clean → `run`. **Always `validate` before `run`** — the run engine
> assumes a valid graph.

## Validation codes the skill should recognize (and explain)

Graph-structure codes: `UNKNOWN_NODE_TYPE`, `UNKNOWN_PIN_REF`, `PIN_KIND_MISMATCH`
(exec wired to data or vice-versa), `PIN_TYPE_MISMATCH` (incompatible data types),
`DANGLING_EXEC` (impure node with no incoming exec), `EXEC_CYCLE`, `DATA_CYCLE`.

Reference rules: `INVALID_SUBBLUEPRINT_ID` (a `subblueprint` node points at a missing
BP), `SCRIPT_SHELL_NOT_ALLOWED` (shell off the allow-list), `SECRET_LITERAL` (a secret
written as a literal instead of a `{ ref: <name> }` handle), plus undeclared-`${...}`
reference errors.

When a user hits one of these, name the code, say what it means, and point at the
offending node/pin.

## Security model (what to respect)

- Engines for the agent node are allow-listed to `claude` / `codex` / `custom`.
- Script / process shells are allow-listed (`bash` / `sh` on Unix, `pwsh` / `cmd` on
  Windows); the command body is a **single argv element** — never concatenated.
- CWD is confined to the project root; `..` / absolute / symlink escapes are rejected.
- Secrets are `{ ref: <name> }` handles, masked to `***` before any log/event sink —
  never inline a secret literal (`SECRET_LITERAL`).
- Script and agent nodes are **consent-gated** on first run; a headless `run` needs
  `--allow-scripts` to execute them.

## When to use Blueprints (vs. a one-off command)

Reach for a Blueprint when a QA workflow is **repeatable and multi-step** — e.g. "hit
the staging API, branch on the response, run an agent to triage failures, write a
defect case", or "for each case in a suite, re-run a browser check and collect
results". For a single ad-hoc action, just use `kensa-cli` / `kensa-browser` directly.
