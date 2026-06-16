# Kensa QA plugin — schema adaptation & the Blueprints skill

> Audience: people writing / maintaining the **kensa-qa** plugin (agents,
> commands, skills) for Claude Code / Codex. This explains two capabilities the
> plugin leans on: the **schema-adaptation** flow and the **Blueprints** skill.
> Not committed to the Kensa app repo — copy into the plugin repo as needed.

---

## Part A — Adapting Kensa to the user's test-case schema

### The problem

A QA team arrives with an existing export from some no-name TMS: a CSV / JSON /
XML dump whose columns are `TC_Ref`, `Summary`, `Pre-Reqs`, `Anticipated
Outcome`, … — nothing like Kensa's canonical fields. Historically the only path
was "let an agent generate cases", which **rewrote the project structure** to fit
the incoming file. That mangled a schema the user had already designed.

### The principle: data follows schema, never the reverse

Kensa now separates two concerns that used to be tangled:

1. **Schema adaptation (optional, agent-driven, additive).** The agent looks at
   a couple of the user's real case files and *adapts Kensa's schema* to match —
   adding fields, renaming system fields — and then **hands off**. It never
   imports the cases itself.
2. **Import (deterministic, format-agnostic).** The user loads their full export
   through the **Universal format** importer, which parses **any** format
   (CSV / JSON / YAML / XML) **into the current schema**. Whatever maps to a known
   field maps; everything else lands in a **custom field**. Nothing is dropped,
   and the schema is never mutated by the import.

This is the whole fix: the agent shapes the structure once (if needed); the
importer fills it. They are orthogonal.

### The agent's role + the CLI it drives

The plugin's schema-bootstrap agent authors the schema through the `kensa` CLI
(it ships on the embedded terminal's PATH):

| Command | What it does |
|---|---|
| `kensa schema show` | Print the project's current schema (system + custom fields). |
| `kensa schema preview <field-spec>` | Dry-run a schema change; show the diff, write nothing. |
| `kensa schema apply <field-spec>` | Apply the schema change to `.tms/schema.yaml` (byte-parity preserved). |
| `kensa schema migrate` | Upgrade a v1 schema to v2 so custom fields can be defined. |
| `kensa adapt ready` | Signal "schema is adapted" — writes `.tms/.cache/adapt-ready.json` (a gitignored sentinel). |

The flow:

1. The user picks **Adapt with AI** in the Import wizard (or runs the bootstrap
   routine), choosing an engine (Claude/Codex) and a couple of sample case files.
2. Kensa launches a terminal agent seeded with an infer-schema prompt.
3. The agent reads the samples, calls `kensa schema preview` / `apply` to fit the
   schema, then runs **`kensa adapt ready`**.
4. The GUI watches the `adapt-ready.json` sentinel (`fs://changed`), refreshes the
   schema, and tells the user: *"Schema adapted — now load your full export in
   Universal format."*
5. The user imports the full file via **Universal format**; cases land under the
   adapted schema.

> **Contract for the agent:** adapt the schema *additively* and signal `adapt
> ready`. Do **not** import cases, and do **not** delete/rewrite existing fields
> unless the user asked. The import step is the user's, deterministic, and
> reversible.

### The Universal importer (what the agent does NOT need to do)

The importer is engine-free and lives in the app:

- **Format-agnostic front-end** turns CSV / JSON / YAML / XML into a flat
  `{ headers, rows }` table (nested JSON/XML is flattened to dotted-path columns;
  step-object arrays collapse into a usable steps cell).
- **Synonym mapping** auto-guesses `Summary → title`, `Pre-Reqs → preconditions`,
  `Anticipated Outcome → expected`, etc. (leaf-aware, so `fields.title → title`).
- **Custom-field fallback:** any unmapped column becomes `frontmatter.custom.<key>`.
- The user reviews/edits the mapping in a column-mapping step before import.

Export mirrors it: **Export → "Current schema"** writes the project out in
CSV / JSON / YAML / XML, round-trippable through the same importer.

### Why this matters for the plugin

The plugin's value is the *intelligence* (inferring a good schema, authoring
cases), not the plumbing. Keep agents focused on:

- inferring + applying the schema (`kensa schema …` + `kensa adapt ready`), and
- authoring high-quality cases with `kensa new` / Write,

and let the deterministic importer handle format wrangling. This keeps agent runs
cheap, reviewable, and non-destructive.

---

## Part B — The Blueprints skill

### What Blueprints are

Blueprints are **node-graph automations** authored in Kensa (an Unreal-style
canvas) and executed by a Rust engine. A graph has **exec pins** (white
triangles — control flow) and **data pins** (colored circles — typed values),
wired between nodes. They are the differentiator vs. n8n/Postman: a first-class
**agent node** can run `claude`/`codex` non-interactively inside a flow.

Files live at `.tms/blueprints/BP-NNN.json` (schema v1, TS source of truth, Rust
byte-parity). The skill helps a user **design, validate, and run** them.

### Node families (catalog)

| Family | Nodes |
|---|---|
| Boundary | `input` (Start), `output` (Finish) |
| Flow | `branch`, `switch`, `parallel`, `join`, `foreach`, `delay`, `assert`, `print` |
| Action | `api` (HTTP), `script`, `process`, `prompt` (Agent), `subblueprint` |
| Pure / data | `getVariable`, `setVariable`, `cast`, `stringFormat`, `jsonPath`, `compare`, `bool`, `length`, `default` |
| Canvas | `comment` |

A runnable graph needs exactly **one Start and one Finish**.

### Referencing context (variables) — `${...}`

Node fields interpolate run context with **braced references**:

- `${name}` — a blueprint variable or input
- `${env.KEY}` — a value from the connected env file (read-only)
- `${context.name}` / `${context.env.KEY}` — the same, with an explicit prefix

The legacy `$context.name` form is still accepted. Precedence:
**node-local pin > captured value > variable > input**. An undeclared reference is
a hard error (never a silent empty string, never a process-env read).

### The agent (`prompt`) node — the two-file handshake

The agent node runs a coding agent non-interactively and captures a **structured
result**:

1. **Build:** Kensa resolves `${...}` in the prompt, writes `context.json` (the
   run context, secrets redacted), an empty `output.json` sink, and the prompt
   file into a per-node temp dir.
2. **Launch:** the engine is allow-listed — `mode` is **`claude` / `codex` /
   `custom`** only. On Windows the npm `.cmd` shims are launched via `cmd /C`.
   The prompt is fed on stdin (`$PROMPT_FILE` is also available).
3. **Complete:** the agent must write `{ "status": "ok"|"fail", "outputs": {…} }`
   to `$OUTPUT_FILE` and exit. `ok` + exit 0 binds the outputs; anything else
   routes to the node's `error` arm.

**Output fields:** declare `outputFields` (name + type) on the prompt node — each
becomes a **typed data-out pin** you can wire onward; with none declared, the
whole result is exposed on a single `output` (json) pin.

### Authoring tips the skill should give

- Wire **Start → … → Finish**; every impure node needs an incoming exec edge.
- For a `prompt` node, **declare output fields** for the values you want to wire;
  describe them in the prompt so the agent fills them.
- Use `setVariable` to capture a value, then read it anywhere with `${name}`.
- `branch`/`switch` route by an inline condition or a wired boolean.
- `parallel` arms must converge on a `join` (`all` / `any` / `count:k`).
- `foreach` iterates a json array; `item` / `index` are per-iteration pins.
- Script/agent nodes are **consent-gated** on first run (a security prompt).

### The CLI surface

| Command | Purpose |
|---|---|
| `kensa blueprint new <name>` | Scaffold a `BP-NNN.json`. |
| `kensa blueprint list` | List blueprints in the project. |
| `kensa blueprint show <id>` | Print a blueprint. |
| `kensa blueprint validate <id>` | Static graph validation (frozen error codes). |
| `kensa blueprint run <id> [--input k=v] [--allow-scripts]` | Headless run → writes a `kind:"blueprint"` run record under `.tms/runs/`. |

Validation codes the skill should recognize (and explain): `UNKNOWN_NODE_TYPE`,
`UNKNOWN_PIN_REF`, `PIN_KIND_MISMATCH`, `PIN_TYPE_MISMATCH`, `DANGLING_EXEC`,
`EXEC_CYCLE`, `DATA_CYCLE`, plus reference rules (`INVALID_SUBBLUEPRINT_ID`,
`SCRIPT_SHELL_NOT_ALLOWED`, `SECRET_LITERAL`, …).

### Security model (what the skill must respect)

- Engines for the agent node are allow-listed to `claude` / `codex` / `custom`.
- Script/process shells are allow-listed (`bash`/`sh` on Unix, `pwsh`/`cmd` on
  Windows); the command body is a single argv element (never concatenated).
- CWD is confined to the project root; `..`/absolute/symlink escapes are rejected.
- Secrets are `{ ref: <name> }` handles, masked to `***` before any log/event sink.
