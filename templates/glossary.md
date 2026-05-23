# Glossary

Domain terms used in this project. The plugin reads this when it
encounters unfamiliar terms in SOT or when generating cases.

Add entries as you go. Edit freely.

## Format

```yaml
- term: <canonical term>
  aliases: [<other spellings or synonyms>]
  in_cases: <how this term should appear in case text>
  notes: <optional context, e.g., "Backend uses 'order_id', UI shows
    'Order #', cases use 'order' or 'order ID' as appropriate to
    context.">
```

## Entries

```yaml
- term: KYC
  aliases: [Know Your Customer, identity verification]
  in_cases: "верификация" (in Russian cases) / "KYC verification" (English)
  notes: "We have three KYC levels — basic, intermediate, full. Spec
    sometimes calls them 'tier 1/2/3'."

- term: <next term>
  aliases: [...]
  in_cases: ...
  notes: ...
```
