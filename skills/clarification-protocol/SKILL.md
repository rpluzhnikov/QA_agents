---
name: clarification-protocol
description: When and how the Test Lead should ask the user clarifying questions, and when to proceed with an assumption instead. Defines the threshold for "critical" vs "minor" gaps, batching rules, and the format for asking. Test Lead-only skill.
---

> **Non-ISTQB tooling skill**
> This skill covers project infrastructure (UX / communication pattern for agent ↔ user interaction). It is **complementary** to ISTQB CTFL v4.0.1 but not derived from it — no specific learning objective grounds the content. The skill does not contradict ISTQB guidance; where ISTQB is relevant, cross-references are noted inline.
> Light cross-reference: supports the test-planning conversation per §5.1.1 (eliciting plan context from stakeholders) and §3.2.1 early stakeholder feedback.

# Clarification protocol

The Test Lead's relationship with the user is a budget. Every clarifying
question spends a small amount of attention; over-asking burns trust,
under-asking ships the wrong cases. This skill is how to spend that
budget well.

## The default — proceed with assumptions

When information is missing, the **default is not to ask**. The
default is:

1. Make a defensible assumption.
2. Mark it explicitly (`ASSUMPTION:` in the case body or scope plan).
3. Surface the assumption in the plan to the user so they can override.
4. Proceed.

This rule exists because **a clear assumption is cheaper to correct
than an unanswered question is to extract**. The user can read "I'll
assume TOTP window is ±30s unless you say otherwise" in 5 seconds and
either nod or push back. They can't answer "what should the TOTP
window be?" in 5 seconds — that's a whole research task for them.

## When to STOP and ask

Ask before proceeding **only** when the gap meets ALL of these:

1. The gap blocks scope/decomposition decisions (one QA Engineer vs two,
   in vs out of scope) — not implementation details
2. There's no defensible default in the industry or in
   `conventions.md`
3. Getting it wrong would force significant rework — not just a tweak

Concrete triggers:

- **Contradiction in SOT** — two parts of the spec conflict and you
  can't tell which is current
- **Missing AC for a major behavior** — the happy path itself isn't
  defined
- **Decision changes QA Engineer decomposition** — one QA Engineer or two?
  UI-only or also API?
- **Privacy / legal sensitive area** — when in doubt, ask. Cheaper
  than a redo.
- **User explicitly asked you to confirm before proceeding** — honor it

## When NOT to ask

Don't ask if any of:

- The convention is covered in `.tms/memory/conventions.md` — apply
  it, don't re-ask
- Industry defaults exist (TOTP window, password length per NIST
  800-63B, rate-limit thresholds, OAuth redirect URI exact-match) —
  use the default, mark as `ASSUMPTION`
- The QA Engineer can mark `ASSUMPTION:` in-case and you'll catch it in
  review (small wording / data-value decisions)
- The question is about how to write a case — that's a project
  convention or a craft decision, not a user question
- The question is about whether to use a specific test technique —
  that's a QA Engineer decision per `test-design-techniques`

## Batching — one message, not a drip

If you have N questions: **send ONE message with all N**.

Why: the user is context-switching from their own work to your
questions. They want to spend 2 minutes once, not 30 seconds five
times. Dripping costs them more total attention.

Cap: 4 questions per round. If you have 5+, you have a scope problem,
not a question problem — go back to scope-analysis and re-decompose.

## Question format

Each question has 4 parts:

1. **Specific claim or scenario** — what's the actual decision?
2. **Why you can't answer it** — one line, briefly
3. **Suggested default** — what you'll do if they don't pick
4. **Option list** — if it's binary/ternary, name the options

Worked example — two questions before spawning QA Engineers for a 2FA feature:

> Two open questions before I spawn QA Engineers:
>
> 1. **Recovery codes — one-time use each?**
>    Spec doesn't say. Industry default is single-use.
>    Options: (a) single-use, (b) reusable until regenerated.
>    My default if you don't pick: (a) single-use.
>
> 2. **Active sessions on 2FA enable — keep or force re-login?**
>    Spec says "user enables 2FA in settings", silent on sessions.
>    Options: (a) keep active sessions, (b) force re-login on all
>    devices, (c) keep current device, force re-login elsewhere.
>    My default: (a) keep active sessions.

Worked example — one question in the middle of a QA Engineer round:

> Quick check before I send this checklist back to the QA engineer:
>
> 1. **Admin disabling another user's 2FA — in this batch or separate?**
>    The QA Engineer included it; I think it belongs in a separate ticket
>    because it's a different actor (admin, not end user) and
>    different risk profile.
>    Options: (a) cut from this batch (my preference), (b) keep, you
>    accept the wider scope.

Worked example — what NOT to ask:

> ❌ "Should I write the title in imperative form?"
>    (Covered in conventions.md — read it.)
>
> ❌ "Should the case use the `auth` tag?"
>    (QA Engineer decision per `learned/tags.md`.)
>
> ❌ "What should I assume about TOTP window?"
>    (Industry default is ±30s; assume and surface.)

## What to do with the user's answer

After the user answers:

- **They picked one of your options** → bake it into the brief, drop
  the corresponding assumption
- **They picked "Other"** → ask one clarifying follow-up if needed,
  otherwise bake in
- **They didn't answer some questions** → use your stated defaults
  and proceed; mention in your final report which defaults were used
- **They changed scope mid-conversation** → re-run scope-analysis
  briefly, re-present plan, then proceed

## Communication style

- Open with what the questions block ("Two open questions before I
  spawn QA Engineers" / "Quick check before sending back to the QA engineer")
- Number the questions
- Bold the question itself; keep body terse
- State your default in every question — the user should always be
  able to say "go with your defaults" and have a sensible result

## Anti-patterns

### 1. The lecture before the question

> "QA practice diverges on whether recovery codes should be single-
> use. The historical view from Whittaker (2003) suggests... while
> NIST 800-63B implies..."

The user doesn't need theory. They need the choice.

### 2. The open-ended question

> "How should we handle recovery codes?"

Nothing to anchor on. Give the user options and a default; they pick
or override.

### 3. The 12-question barrage

If you have 12 questions, you haven't planned the feature — you've
serialised your uncertainty. Go back to scope-analysis.

### 4. Asking questions you can answer yourself

> "What's the project's conventions for naming case files?"

That's in `conventions.md`. Read it.

### 5. Asking permission for obvious things

> "Should I add a happy-path case?"

Yes, obviously. Don't ask. The user will fire you if you ask this
twice.

## Calibration over time

After a few `/new-feature` sessions, you'll learn the user's
preferences:

- Some users like to be asked early ("low autonomy" — surface 3–4
  questions per plan)
- Some users prefer maximum autonomy ("you decide, I'll redirect if
  needed" — ask only on category 1 critical items)

Encode the user's preference in their `project.md`:

```markdown
clarification_style: <minimal | standard | thorough>
```

Default: `standard` (3–4 questions per plan, only when category 1 triggers fire).
