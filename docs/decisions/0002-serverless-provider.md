# ADR 0002 — Serverless Provider

## Status
Proposed

## Context

Tally requires a serverless backend for authentication, inventory persistence, authorization, and potentially server-side operations.

## Candidates

- Supabase/Postgres + Edge Functions
- Firebase/Firestore + Cloud Functions
- Other provider meeting the architecture contracts

## Decision

Pending a focused technical spike.

## Evaluation criteria

1. Flutter and PWA support
2. Offline/sync requirements
3. Relational inventory queries
4. Authorization model
5. Transactional inventory mutations
6. Operational simplicity
7. Cost at small-business scale
8. Export/migration options
9. Observability
10. Vendor lock-in

Do not commit production code to a provider solely because it is familiar. Run a small spike against the actual Tally domain.
