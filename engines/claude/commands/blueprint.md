---
description: Design, validate, or run a Kensa Blueprint — a node-graph automation (.tms/blueprints/BP-NNN.json) executed by the Rust engine, driven via kensa blueprint. Supports an agent (prompt) node that runs claude/codex inside the flow. Subcommands: list | show <id> | new <name> | validate <id> | run <id>.
argument-hint: [list | show <id> | new <name> | validate <id> | run <id> [--input k=v]]
---

You are the **test-lead-agent**. The user invoked `/blueprint` to work with a Kensa
Blueprint. Load the `kensa-blueprints` skill for the node catalog, the `${...}`
reference rules, the agent (`prompt`) node handshake, the CLI surface, the validation
codes, and the security model. The argument is $ARGUMENTS.

Preflight: `kensa --version` — if the CLI isn't on PATH, tell the user and stop
(every subcommand below drives `kensa blueprint`).

Resolve the intent from $ARGUMENTS:

- **(empty) or `list`** — `kensa blueprint list`. Show the blueprints in the
  project (id + name). If there are none, offer to scaffold one with `new`.
- **`show <id>`** — `kensa blueprint show <id>`. Summarize the graph: Start →
  Finish, the node families used, variables/inputs, and any agent (`prompt`) nodes.
- **`new <name>`** — `kensa blueprint new "<name>"` to scaffold a `BP-NNN.json`,
  then help the user wire it: confirm the goal, sketch **Start → … → Finish**, pick
  nodes from the catalog, declare `outputFields` on any `prompt` node, and converge
  `parallel` arms on a `join`. Edit the JSON (or guide the user to the Kensa canvas).
  Finish by validating.
- **`validate <id>`** — `kensa blueprint validate <id>`. For every reported code
  (`UNKNOWN_PIN_REF`, `PIN_TYPE_MISMATCH`, `DANGLING_EXEC`, `EXEC_CYCLE`,
  `SECRET_LITERAL`, …) name it, explain it, and point at the offending node/pin. Loop
  until clean — **never run an invalid graph.**
- **`run <id>`** — first `validate`. Then `kensa blueprint run <id> [--input k=v]…`.
  If the graph has script / agent nodes, they are consent-gated: pass `--allow-scripts`
  only with the user's go-ahead. Report the `kind:"blueprint"` run record written under
  `.tms/runs/` and the outcome per node.

Security to respect (from the skill): agent-node engines are allow-listed to
`claude` / `codex` / `custom`; shells are allow-listed and never concatenated; CWD is
confined to the project root; secrets are `{ ref: <name> }` handles, never literals.

This command authors no test cases and owes no memory checkpoint — only
`/new-feature` and `/update-feature` create the `.tms/.pending-checkpoint`
marker the Stop hook keys on.

## Epilogue (required)

End your final message with exactly this block (pick the row matching the subcommand):

✅ **Done:** <what happened — listed N blueprints / BP-NNN scaffolded / validation clean / run outcome per node>
➡️ **Next:**
- after `new` → `/blueprint validate <id>` (never run unvalidated)
- after `validate` (clean) → `/blueprint run <id>` (`--allow-scripts` only with explicit go-ahead)
- after `run` → inspect the run record in `.tms/runs/`; for live-app checks outside a graph, `/run-routine`
