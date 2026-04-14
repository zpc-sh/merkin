# Interface Drift Policy

This directory is the canonical review surface for interface drift.

## Required updates

Update the relevant `.well-known` file in the same change when any of the following change:

- canonical mu interface ownership or execution boundary
- generalized solve surface
- procsi binary section layout
- genius procsi attestation or APP-masked fingerprint contract
- compatibility or versioning rules

## Review heuristic

If code or docs affecting mu, solve, procsi, APP-masked fingerprinting, handler resolution, or callback/pubsub semantics changed but no `.well-known` file changed, reviewers should assume the interface may have drifted silently.

## Canonical files

- `mu-interface.json`
- `procsi-sections.json`

These files are intentionally small so they are easy to diff.
