---
name: sot-figma
description: Extract test requirements from a Figma file via the Figma MCP — canonical frames vs WIP, prototype flows, component states/variants, annotations, and comments. Use when the Test Lead hands a QA Engineer a Figma file or node URL as the design source of truth. Tells you how to find the "final" frames, walk prototype flows for end-to-end cases, and read annotations/comments for acceptance criteria. For programmatic deep inspection of node structure, defer to the figma-use skill.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (Figma MCP server integration for extracting test requirements from Figma designs). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: operationalises CTFL §1.4.4 traceability between test basis and testware for Figma as the Source of Truth; surfaces acceptance criteria per §4.5.2 from prototype flows, component states/variants, and frame annotations.

# SOT — Figma

Designs encode requirements the written spec omits: every visual state, validation
message, empty/loading/error view, and interaction is in the file. Your job is to read
the design as a behavior spec and turn it into test scope — without inventing intent
the designer didn't express.

## MCP tools

Figma reads go through the **`figma`** MCP server (the official Dev Mode MCP, wired by
`/setup` at `http://127.0.0.1:3845/mcp`; it requires the Figma desktop app running with
Dev Mode MCP enabled). List the available `mcp__figma__*` tools and match by purpose —
typically: get the metadata/structure of a selected node, get an image of a frame, and
get the variable/token definitions used by a node. Work from the node the user selects
or the node ID in the URL (`?node-id=...`).

For deep, programmatic inspection (walking the full node tree, reading exact
auto-layout, reading annotation panels via the Plugin API), use the **`figma-use`**
skill and its `use_figma` tool instead — it executes JavaScript in the file context.
Most QA reads don't need that; reach for it only when the read MCP can't surface what
you need.

If no Figma MCP is connected, ask the user to run `/setup` (and start Figma desktop) or
to paste screenshots / the relevant frame details.

## Find the canonical frames first

Figma files are full of explorations, old versions, and scratch frames. Before
extracting, identify what's actually being built:

- Prefer the specific node the Jira/Linear issue or the user points at.
- Look for a page/section named `Final`, `Handoff`, `Ready for dev`, `✅`, or marked
  with a status; ignore `WIP`, `Explorations`, `Archive`, `Old`.
- If you can't tell the canonical frame from a draft, ask the Test Lead — don't write cases
  against an exploration.

## What to extract

1. **States and variants.** Component variants and frame variations enumerate the
   states to cover: default / hover / focus / active / disabled, empty / loading /
   loaded / error, and validation states. Each is a case (and often a negative case).
2. **Prototype flows.** Follow the prototype connections frame-to-frame — they describe
   the end-to-end user journeys. Each complete flow is an end-to-end scenario; each
   branch (e.g. "if invalid → error frame") is a negative path.
3. **Annotations and Dev Mode notes.** Designers attach measurements, behavior notes,
   and acceptance notes ("error shows after 3s", "max 140 chars"). These are
   first-class AC — quote them verbatim into expected results.
4. **Comments.** Open design comments often contain unresolved decisions or late
   requirements. An unresolved comment touching in-scope UI is a `GAP:`.
5. **Content and copy.** Exact button labels, error messages, empty-state text — pull
   them verbatim; tests assert on exact strings.
6. **Tokens/variables.** Spacing/color tokens rarely matter for manual QA, but
   referenced semantic states (e.g. an `error` color) confirm which states exist.

## Mapping to scope

- One screen with N states → roughly N positive cases plus the invalid/edge variants.
- One prototype flow → one end-to-end case, plus a negative case per branch.
- Responsive variants (mobile/tablet/desktop frames) → cross-reference the platform
  skill (`web-testing` / `mobile-testing`) for viewport coverage.

## Pitfalls

- A static frame can't tell you timing, focus order, or what a control *does* on tap —
  infer cautiously and mark inferred behavior as `ASSUMPTION:` for the Test Lead.
- Designs drift from the final spec; when the design contradicts the written AC,
  surface the conflict rather than picking one.
- Record the node URL (with `node-id`) as `source_id` so QA Engineers cite the exact frame.

If this team marks canonical frames or annotations a consistent way, note it in
`.tms/memory/learned/patterns.md`.
