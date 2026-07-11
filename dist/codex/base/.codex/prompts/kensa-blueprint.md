---
description: Design, validate, or run a Kensa Blueprint — a node-graph automation (.tms/blueprints/BP-NNN.json) executed by the Rust engine, driven via kensa blueprint. Supports an agent (prompt) node that runs claude/codex inside the flow. Subcommands: list | show <id> | new <name> | validate <id> | run <id>.
argument-hint: [list | show <id> | new <name> | validate <id> | run <id> [--input k=v]]
---

Act as the **test-lead-agent**. Work with a Kensa Blueprint per $ARGUMENTS. Load the
`kensa-blueprints` skill for the node catalog, the `${...}` reference rules, the agent
(`prompt`) node handshake, the CLI surface, the validation codes, and the security model.

Preflight: `kensa --version` — if the CLI isn't on PATH, tell the user and stop
(every subcommand below drives `kensa blueprint`).

Resolve the intent:

- **(empty) or `list`** — `kensa blueprint list`. Show id + name; if none, offer `new`.
- **`show <id>`** — `kensa blueprint show <id>`. Summarize Start → Finish, node families,
  variables/inputs, and any agent (`prompt`) nodes.
- **`new <name>`** — `kensa blueprint new "<name>"` to scaffold `BP-NNN.json`, then help
  wire it: confirm the goal, sketch Start → … → Finish, pick nodes from the catalog, declare
  `outputFields` on any `prompt` node, converge `parallel` arms on a `join`. Edit the JSON or
  guide the user to the Kensa canvas. Finish by validating.
- **`validate <id>`** — `kensa blueprint validate <id>`. For every code (`UNKNOWN_PIN_REF`,
  `PIN_TYPE_MISMATCH`, `DANGLING_EXEC`, `EXEC_CYCLE`, `SECRET_LITERAL`, …) name it, explain it,
  and point at the offending node/pin. Loop until clean — never run an invalid graph.
- **`run <id>`** — `validate` first, then `kensa blueprint run <id> [--input k=v]…`. Script /
  agent nodes are consent-gated: pass `--allow-scripts` only with the user's go-ahead. Report the
  `kind:"blueprint"` run record under `.tms/runs/` and the per-node outcome.

Security to respect: agent-node engines are allow-listed to `claude` / `codex` / `custom`; shells
are allow-listed and never concatenated; CWD is confined to the project root; secrets are
`{ ref: <name> }` handles, never literals.

This prompt authors no test cases and owes no memory checkpoint — only `/kensa-new-feature`
and `/kensa-update-feature` create the `.tms/.pending-checkpoint` marker the Stop hook keys on.

End your final message with (pick the row matching the subcommand):

✅ **Done:** <listed N blueprints / BP-NNN scaffolded / validation clean / run outcome per node>
➡️ **Next:** after `new` → `/kensa-blueprint validate <id>` (never run unvalidated) · after a clean `validate` → `/kensa-blueprint run <id>` (`--allow-scripts` only with explicit go-ahead) · after `run` → inspect the run record in `.tms/runs/`; for live-app checks outside a graph, `/kensa-run-routine`.
