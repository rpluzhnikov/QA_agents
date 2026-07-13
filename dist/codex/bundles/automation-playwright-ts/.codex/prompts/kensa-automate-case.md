---
description: Derive a @KEN-tagged Playwright + TypeScript test from an existing .tms/ manual case — the automation bundle's core verb.
argument-hint: <case id | source ref>
---

Act as the **automation-test-lead**. The manual case is the spec; the
deliverable is a passing `@KEN-<id>`-tagged Playwright test. Case: $ARGUMENTS

1. **Preflight** — Playwright project exists (else `/kensa-scaffold-playwright`
   and stop); `kensa --version`; resolve the case via `show_case { "id": <id> }`
   (or `filter_cases { "expr": "source_id = <ref>" }` and let the user pick) — MCP reads. Run your
   candidacy rubric — if E2E is the wrong layer or the case is a poor candidate,
   say why and let the user overrule.
2. **Brief** an `automation-engineer`: the case content as spec; **negative/edge
   parity** — list which negative behaviours of the case must be automated (a
   happy-rows-only E2E of a case with negative steps is incomplete); traceability
   `{ tag: '@KEN-<id>' }` (structured form, never title-string); reuse existing
   POMs/fixtures; skills `playwright-typescript`, `playwright-locators`,
   `playwright-waiting-and-assertions` (+ `playwright-fixtures-and-pom` if a new
   POM is needed).
3. **Verify** — engineer runs the test and reports real output; review coverage
   adequacy vs the case's steps (each step exercised or explicitly
   not-automatable with why). If the `automation-codereview` bundle is installed,
   delegate the review to `codereviewer`.
4. **Close the loop** — `kensa update <id> --add-tag automated` (confirm first);
   if the `automation-git` bundle is installed, hand off to `git-operator` for an
   atomic commit.
5. End with:
   ✅ **Done:** <spec path> — @KEN-<id>, run <result>; case tagged `automated`
   ➡️ **Next:** `/kensa-automate-case <next-id>` ·
   `/kensa-add-visual-test` / `/kensa-add-a11y-test` ·
   `/kensa-import-results <report>` after CI runs

No memory checkpoint owed.
