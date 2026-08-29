# ERL Skill Authorization Policy v1

This is agent UX and security policy, not a persistent-state Requirement.

## L0 — read-only

No mutation authorization is required. Examples: `erl-check`, chapter export,
and dry-run planning.

## L1 — bounded or idempotent mutation

The current explicit user request authorizes staging or ingestion of one named
Candidate after a valid dry-run. Do not ask a second redundant confirmation unless
the plan materially differs from the request or contains warnings.

## L2 — batch or identity/state creation

Book ingest, Chapter batch ingest, and Classic Reduce reconciliation require a
dry-run followed by explicit confirmation of the displayed plan.

## L3 — destructive lifecycle or dependency cascade

Book Reduce requires a fresh dry-run, exact closure disclosure, explicit
confirmation of the exact plan, and apply with the matching plan fingerprint.
Cross-book dependencies require separate explicit consent.

Authorization never permits bypassing the ERL CLI or weakening an invariant.
