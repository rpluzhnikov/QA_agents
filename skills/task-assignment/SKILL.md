---
name: task-assignment
description: How the Lead formulates a precise task brief when delegating to a worker via the Task tool. Defines the brief schema, what each section must contain, and the difference between Stage 1 (checklist) and Stage 2 (cases) briefs. Lead-only skill. Use before every Task invocation.
---

# Task assignment

A worker has narrow context — they don't see the user, they don't have
project memory loaded by default, they don't know what other workers
are doing. The brief is everything.

A bad brief produces:
- Worker asking clarifying questions (it can't actually ask, so it
  guesses or marks `GAP:` and you re-spawn it)
- Worker covering the wrong scope
- Worker writing in the wrong style
- Worker not using shared steps that exist
- Cases that pass review by the letter but feel "off" because conventions
  weren't passed through

## Brief schema — Stage 1 (checklist)

```markdown
# Worker brief — <feature short name> — Stage 1: Checklist

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

## Open from Lead
<questions the Lead has that the worker should NOT answer but should
acknowledge — informational only>
```

## Brief schema — Stage 2 (cases)

```markdown
# Worker brief — <feature short name> — Stage 2: Cases

## Approved checklist
<the checklist content, with Lead's notes inline if any>

## Scope adjustments since Stage 1
<anything that changed in response to user feedback during plan review>

## References
<same as Stage 1>

## Existing cases for style reference
<same as Stage 1, or refined if Lead saw style mismatches>

## Shared steps to use
<explicit list — Lead has decided which shared steps apply>

## Skills to load
- test-case-writing-craft
- test-design-techniques
- negative-and-edge-cases
- <platform skill>

## Output target
- Suite path: <.tms/suites/auth/2fa/>
- Naming pattern: <e.g., `setup-001.md`, `setup-002.md`, ...>
- Frontmatter requirements:
  - `id`: <auto per Kensa convention>
  - `priority`: <use checklist tier — must-have → high/critical;
    should-have → medium; nice-to-have → low>
  - `status: draft`
  - `tags`: <list of tags worker should apply>
  - `source_id`: <SOT ref>
  - `generated_by: kensa-qa@0.1.0`

## Project conventions to enforce
<distilled from .tms/memory/conventions.md — the 3-5 things most
relevant to this batch>

## Constraints
- Write cases as files directly into the suite path
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

This protects the worker from quietly expanding scope and forces them to
flag if they see something that looks out of scope.

### References — pointer + section

Not: "See LIN-89"
Yes: "See LIN-89, specifically the 'Setup flow' section in the description
and AC items 1-4 in the AC field."

The worker may not have time to read the whole ticket. Tell them where
to land.

### Existing cases for style — pick representative ones

Not: "see other cases in this suite"
Yes: "Read these for style:
- `.tms/suites/auth/login-001.md` — typical happy-path case in this area
- `.tms/suites/auth/login-fail-003.md` — typical negative case
- `.tms/suites/auth/password-reset-002.md` — multi-step flow"

Pick cases that match the kind of testing the worker is about to do. If
they're about to write a multi-step flow, point at multi-step examples,
not single-action ones.

### Shared steps — explicit list

Not: "use shared steps where applicable"
Yes:
- "Use `auth/login-as-user` for the precondition where a user logs in"
- "Use `auth/login-as-admin` for admin-action cases"
- "Do NOT extract new shared steps for this batch unless you find a
  sequence repeating 3+ times — that's a Lead decision."

Don't make the worker hunt for shared steps. You already know what's
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

The worker reads the full `conventions.md` only if you tell it to.

## Anti-patterns in briefs

### 1. The "good luck" brief

> "Write test cases for the 2FA feature. See LIN-89. Use our conventions."

Tells the worker nothing. Worker will guess.

### 2. The wall of text

A 2000-word brief with three layers of headings. Worker will skim and
miss things.

Aim for 400-800 words per brief.

### 3. Pasting the whole spec

The worker reads the spec themselves via MCP. Your brief is the
**interpretation layer** — what's in scope, what to focus on, what
style. Don't duplicate the spec.

### 4. Implicit assumptions

> "Standard tests for this kind of feature."

What's standard for you isn't standard for the worker. Spell it out or
point at examples.

### 5. Skill spam

> "Skills: test-case-writing-craft, test-design-techniques,
> negative-and-edge-cases, checklist-design, scope-analysis,
> review-rubrics, web-testing, security-testing, ..."

Don't load all skills "just in case". Each skill in context is tokens.
Pick the 4-6 that actually apply.

## Spawning the worker

In Claude Code, use `Task` tool with the brief as the prompt. Specify
the worker agent (`worker` per `agents/worker.md`).

For parallel workers: spawn all in the same turn. Don't sequentially
wait for one before launching the next.

For sequential dependence (rare — usually means decomposition was wrong):
finish one worker, review, then spawn the next with the prior worker's
output as additional context.

## Recording the brief

Keep a copy of the brief in your context. When the worker returns, you
need to compare what they did against what you asked for. If you don't
remember exactly what you asked, you can't review properly.

(In v0.2, the memory-keeper will optionally save briefs and outcomes to
`.tms/memory/sessions/`. For v0.1, just remember.)
