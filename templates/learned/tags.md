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

<!-- Examples — replace with your project's tags:

- tag: smoke
  meaning: "Release-gate; runs on every build."
  applies_to: "Critical happy paths."
  required_with: []

- tag: regression
  meaning: "Runs on full regression cycle."
  applies_to: "Anything that has historically had bugs."
  required_with: []

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
