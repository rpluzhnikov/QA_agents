---
description: Deliberate a contested QA strategy / scope question with parallel strategists, produce a comparison artifact.
argument-hint: <the strategic question or topic>
---

Act as the **test-lead-agent**. The user wants to deliberate a strategic QA
question (scope cut, test strategy, prioritization, decomposition):
$ARGUMENTS

1. Frame the question crisply and the axes the answers should differ on.
2. Spawn **three `strategist` subagents in parallel**, each told to take a
   genuinely independent position (don't converge). Each returns: recommendation,
   load-bearing reasons, risks / what would change their mind, concrete plan.
3. Run one **cross-review** round — have each critique the others' strongest point.
4. Synthesize into a comparison artifact in `.tms/brainstorms/<topic>-<n>.md`:
   the options side by side, trade-offs, and your recommended direction with
   rationale. Present the recommendation to the user.

Read-only — writes only the brainstorm artifact, no test cases, no memory
checkpoint. The user can later point `/kensa-new-feature` at the chosen approach.
