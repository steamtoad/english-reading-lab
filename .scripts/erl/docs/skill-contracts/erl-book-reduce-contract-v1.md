# ERL Book Reduce Operational Contract v1

This reference supplements the common operational contract only for
`erl-book-reduce`.

## Exact-plan protocol

1. Run the initial dry-run without implicit dependency inclusion.
2. If closure exceeds seeds, disclose every additional generation and obtain
   explicit dependency consent.
3. Immediately before apply, run a fresh dry-run with the exact semantic
   arguments accepted by the user. If dependencies were accepted, include
   `--include-dependencies` in this dry-run.
4. Require a deterministic `plan_fingerprint` from that dry-run.
5. Apply with identical semantic arguments, replacing only `--dry-run` with
   `--apply` and adding `--plan-fingerprint HASH`.
6. Any changed argument, target state, preflight hash, or fingerprint is
   `STATE_CONFLICT`; stop before mutation.

The skill never compares or reconstructs mutation plans as a substitute for CLI
enforcement. The CLI owns exact-plan validation.
