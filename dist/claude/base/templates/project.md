# Project — <name>

**Stack:** <web / mobile / backend / mixed>
**Test case language:** <en / ru / other>
**Last updated:** <date>

## What this project is

<1-2 sentence description of the product / system under test>

## What kinds of testing live in this TMS

<Check all that apply — the plugin uses this to decide which skills to
load for workers.>

- [ ] Functional UI testing
- [ ] API / contract testing
- [ ] Mobile (iOS / Android / both)
- [ ] Security (manual QA scope per OWASP ASVS L1)
- [ ] Accessibility (manual verifiable subset)
- [ ] Localization / i18n
- [ ] Performance (load tracked elsewhere)
- [ ] Other: <specify>

## Hard rules for this project

<Things the plugin should never violate. Examples below — replace with
your project's actual rules.>

- We don't write performance test cases in this TMS — those live in
  Grafana k6 alongside the code.
- We never include real customer data in test data, even hashed.
- Cases tagged `release-gate` are read-only for the plugin — never
  modify, even on `/update-feature`.

## Preferences

`auto_save_learnings`: <false | true>
  When false (default), the plugin asks before saving anything to
  `learned/*`. When true, the plugin saves automatically and tells
  the user what was saved.

`default_priority`: <medium>
  Priority assigned to new cases when the worker can't infer it from
  the checklist tier.

`default_status_on_create`: <draft>
  Status assigned to new cases. Lead/user promotes to `active` after
  human review.
