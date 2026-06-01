# Learned patterns

Patterns the plugin has noticed (or you've taught it) about how cases
are structured for THIS project. Append-only; the plugin uses these
when delegating to workers.

<!-- Format:
- pattern: <one-line description>
  example_cases: [<path to representative case>, ...]
  applies_when: <what triggers this pattern>
  added: <date> [from session: <feature ref>]
-->

## Entries

<!-- Examples — replace with your project's patterns:

- pattern: "For any endpoint accepting user-controlled IDs, we always
    include an IDOR scenario."
  example_cases: [api/orders/get-by-id-005.md]
  applies_when: "Worker brief involves GET / PATCH / DELETE on a
    resource by ID."
  added: 2025-01-15 [from session: LIN-89]

- pattern: "Multi-step wizards always have a 'navigate away and back'
    case to verify state is preserved or cleared per spec."
  example_cases: [checkout/wizard-006.md, kyc/wizard-004.md]
  applies_when: "Feature is a multi-step UI flow."
  added: 2025-01-22 [from session: LIN-103]
-->
