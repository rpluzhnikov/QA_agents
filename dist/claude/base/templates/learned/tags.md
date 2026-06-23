# Tag taxonomy

Tags used in this project's cases. The plugin uses this to:
- Suggest correct tags to workers (preventing tag drift)
- Identify cases for `/update-feature` searches
- Surface coverage gaps

<!-- Format:
- tag: <tag>
  meaning: <what it indicates>
  applies_to: <kind of case>
  required_with: [<other tags that must accompany this one>]
-->

## Entries

# Baseline tags seeded by /setup. These four appear in almost every project,
# so the plugin pre-registers them — workers can use them on the first
# /new-feature without the Lead having to extend the taxonomy retroactively.
# Add project-specific tags below as you go.

- tag: smoke
  meaning: "Release-gate; runs on every build. Critical happy paths only."
  applies_to: "The minimum set that proves the feature is alive."
  required_with: []

- tag: regression
  meaning: "Included in the full regression cycle."
  applies_to: "Cases covering areas that have historically had bugs, or that guard against re-introductions."
  required_with: []

- tag: negative
  meaning: "Negative / reject scenario — the system correctly rejects invalid input or unauthorized action."
  applies_to: "All validation, error-handling, and access-denied cases."
  required_with: []

- tag: tbd
  meaning: "Case is blocked by an unresolved spec gap and is parked in `status: draft` until the question is answered."
  applies_to: "Any case where the worker hit a question only product/design can answer. Pair with an entry in `learned/patterns.md` describing the open question."
  required_with: []

<!-- Project-specific examples — extend as your taxonomy grows. Delete this
     comment block once you have your own entries below:

- tag: auth
  meaning: "Touches authentication or session."
  applies_to: "Login, logout, session, 2FA, password reset cases."
  required_with: []

- tag: 2fa
  meaning: "Specific to 2FA functionality."
  applies_to: "Any 2FA case."
  required_with: [auth]

- tag: api
  meaning: "API-level (not UI) testing."
  applies_to: "Cases that interact with API directly."
  required_with: []

- tag: mobile-only
  meaning: "Only applies to mobile clients."
  applies_to: "Native mobile UI cases."
  required_with: []
-->
