---
name: task-assignment
description: How the Test Lead formulates a precise task brief when delegating to a QA Engineer via the Task tool. Defines the brief schema, what each section must contain, and the difference between Stage 1 (checklist) and Stage 2 (cases) briefs. Test Lead-only skill. Use before every Task invocation.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (agent-orchestration pattern — Test Lead → QA Engineer delegation protocol). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: implements the role separation per §1.4.5 (test management vs testing engineering) and the work-assignment side of test monitoring & control (§5.3).

# Task assignment

A QA Engineer has narrow context — they don't see the user, they don't have
project memory loaded by default, they don't know what other QA Engineers
are doing. The brief is everything.

A bad brief produces:
- QA Engineer asking clarifying questions (it can't actually ask, so it
  guesses or marks `GAP:` and you re-spawn it)
- QA Engineer covering the wrong scope
- QA Engineer writing in the wrong style
- QA Engineer not using shared steps that exist
- Cases that pass review by the letter but feel "off" because conventions
  weren't passed through

## Brief schema — Stage 1 (checklist)

```markdown
# QA Engineer brief — <feature short name> — Stage 1: Checklist

## Scope (IN)
<bulleted list of specific claims to cover>

## Scope (OUT)
<things that look like they belong but don't, with reason>

## References
- Primary spec: <SOT URL or path> §<section>
- Acceptance criteria: <where to find them>
- Designs: <Figma URL with node ID> (if any)

## Existing cases for style reference
<paths to 3-5 representative cases in this project area>

## Shared steps available
<paths to relevant shared steps that should be considered>

## Skills to load
- test-case-writing-craft  (always)
- test-design-techniques   (always)
- negative-and-edge-cases  (always)
- checklist-design         (this stage)
- <platform skill>         (web-testing / mobile-testing / etc.)

## Output
- Markdown checklist following `checklist-design` format
- Save as <path> OR return inline (specify)
- Estimated case count: ~<N>

## Constraints
- DO NOT write test cases yet — checklist only
- DO NOT extend scope beyond the IN list — flag gaps instead
- Mark all assumptions with `[ASSUMPTION]`

## Open from Test Lead
<questions the Test Lead has that the QA Engineer should NOT answer but should
acknowledge — informational only>
```

## Brief schema — Stage 2 (cases)

```markdown
# QA Engineer brief — <feature short name> — Stage 2: Cases

## Approved checklist
<the checklist content, with Test Lead's notes inline if any>

## Scope adjustments since Stage 1
<anything that changed in response to user feedback during plan review>

## References
<same as Stage 1>

## Existing cases for style reference
<same as Stage 1, or refined if Test Lead saw style mismatches>

## Shared steps to use
<explicit list — Test Lead has decided which shared steps apply>

## Skills to load
- test-case-writing-craft
- test-design-techniques
- negative-and-edge-cases
- <platform skill>

## Output target
- Suite path: <.tms/suites/auth/2fa/>
- Naming pattern: <e.g., `setup-001.md`, `setup-002.md`, ...>
- Case creation: the QA Engineer runs `kensa-cli new --suite <path> --title "<t>" …` per case,
  which allocates the id atomically. No `id_range` is needed even for ≥2 parallel engineers —
  the CLI hands out unique, collision-free ids and reconciles the counter itself.
- Frontmatter (pass as `kensa-cli new` flags; the engineer adds `generated_by` when editing the body):
  - `id`: <allocated by `kensa-cli new` — do not hand-pick>
  - `priority`: <use checklist tier — must-have → high/critical;
    should-have → medium; nice-to-have → low>  (`--priority`)
  - `status: draft` (set by `new`)
  - `tags`: <list of tags QA Engineer should apply>  (`--tag` per tag)
  - `source_id`: <SOT ref>  (`--source-id`)
  - `generated_by: kensa-qa@0.13.0`

## Project conventions to enforce
<distilled from .tms/memory/conventions.md — the 3-5 things most
relevant to this batch>

## Constraints
- Create cases with `kensa-cli new` into the suite path, then author the body by editing the returned file
- Use shared steps listed above; do NOT inline duplicate them
- Mark any assumptions you make with `ASSUMPTION:` in case body
- Report list of created files when done
```

## What to include in each section

### Scope (IN) — be specific

Not: "2FA setup flow"
Yes:
- "User can navigate to Settings → Security and click Enable 2FA"
- "After clicking Enable, system displays QR code and secret string"
- "User can scan QR with an authenticator and enter the resulting code"
- "Entering a valid TOTP code completes setup; entering invalid does not"

The level of specificity here drives the level of specificity of cases.
Vague brief → vague cases.

### Scope (OUT) — explicit, with reasons

Not: "(no out of scope)"
Yes:
- "Admin-enforced 2FA — separate ticket LIN-103, different worker later"
- "SMS 2FA — not implemented yet"
- "Performance / load — perf team owns"

This protects the QA Engineer from quietly expanding scope and forces them to
flag if they see something that looks out of scope.

### References — pointer + section

Not: "See LIN-89"
Yes: "See LIN-89, specifically the 'Setup flow' section in the description
and AC items 1-4 in the AC field."

The QA Engineer may not have time to read the whole ticket. Tell them where
to land.

### Existing cases for style — pick representative ones

Not: "see other cases in this suite"
Yes: "Read these for style:
- `.tms/suites/auth/login-001.md` — typical happy-path case in this area
- `.tms/suites/auth/login-fail-003.md` — typical negative case
- `.tms/suites/auth/password-reset-002.md` — multi-step flow"

Pick cases that match the kind of testing the QA Engineer is about to do. If
they're about to write a multi-step flow, point at multi-step examples,
not single-action ones.

### Shared steps — explicit list

Not: "use shared steps where applicable"
Yes:
- "Use `auth/login-as-user` for the precondition where a user logs in"
- "Use `auth/login-as-admin` for admin-action cases"
- "Do NOT extract new shared steps for this batch unless you find a
  sequence repeating 3+ times — that's a Test Lead decision."

Don't make the QA Engineer hunt for shared steps. You already know what's
relevant from the suite scan you did in scope analysis.

### Project conventions — only the relevant ones

Don't paste all of `conventions.md`. Pull the 3-5 conventions most likely
to be violated:

- "Titles are imperative, starting with a verb: 'Enable', 'Submit',
  'Verify' (not noun form: 'Successful enabling')"
- "Expected results are per-step, attached to the action that produces them"
- "All cases tagged with `auth` and the specific feature tag (here: `2fa`)"
- "Recovery code values in cases use the placeholder `RCV-XXXX-XXXX`,
  never real codes"

The QA Engineer reads the full `conventions.md` only if you tell it to.

## Anti-patterns in briefs

### 1. The "good luck" brief

> "Write test cases for the 2FA feature. See LIN-89. Use our conventions."

Tells the QA Engineer nothing. QA Engineer will guess.

### 2. The wall of text

A 2000-word brief with three layers of headings. QA Engineer will skim and
miss things.

Aim for 400-800 words per brief.

### 3. Pasting the whole spec

The QA Engineer reads the spec themselves via MCP. Your brief is the
**interpretation layer** — what's in scope, what to focus on, what
style. Don't duplicate the spec.

### 4. Implicit assumptions

> "Standard tests for this kind of feature."

What's standard for you isn't standard for the QA engineer. Spell it out or
point at examples.

### 5. Skill spam

> "Skills: test-case-writing-craft, test-design-techniques,
> negative-and-edge-cases, checklist-design, scope-analysis,
> review-rubrics, web-testing, security-testing, ..."

Don't load all skills "just in case". Each skill in context is tokens.
Pick the 4-6 that actually apply.

## Spawning the QA Engineer

In Claude Code, use `Task` tool with the brief as the prompt. Specify
the QA Engineer agent (`qa-engineer-agent` per `agents/qa-engineer-agent.md`).

For parallel QA Engineers: spawn all in the same turn. Don't sequentially
wait for one before launching the next.

For sequential dependence (rare — usually means decomposition was wrong):
finish one QA Engineer, review, then spawn the next with the prior QA Engineer's
output as additional context.

## Recording the brief

Keep a copy of the brief in your context. When the QA Engineer returns, you
need to compare what they did against what you asked for. If you don't
remember exactly what you asked, you can't review properly.

(In v0.2, the memory-keeper will optionally save briefs and outcomes to
`.tms/memory/sessions/`. For v0.1, just remember.)
