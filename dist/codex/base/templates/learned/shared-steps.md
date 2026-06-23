# Shared steps catalog

The plugin scans `.tms/shared-steps/` and remembers what's available,
so workers can be told what to reuse. Auto-updated on `/setup` and
when the user runs `/save-memory`.

<!-- Format:
- path: <shared-step path>
  purpose: <one-line description>
  used_by: <approximate count or "many">
-->

## Entries

<!-- Examples:

- path: auth/login-as-user
  purpose: "Log in as a generic standard user (precondition for
    any case requiring an authenticated standard user)."
  used_by: many

- path: auth/login-as-admin
  purpose: "Log in as an admin user."
  used_by: ~20

- path: cleanup/clear-test-data
  purpose: "Postcondition: clear test data created in this run."
  used_by: 8
-->
