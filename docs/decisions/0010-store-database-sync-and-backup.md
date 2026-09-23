# ADR 0010 — Store Database Synchronization & Remote Backup

## Status
Accepted

## Context
Tally is an offline-first inventory application. The operational database is the local encrypted SQLite database file. However, users need automatic background synchronization and manual cloud backups to remote serverless object storage (e.g. Supabase Storage / S3 / Cloud Storage).

## Decision
1. **Local Operational Authority**: All inventory writes execute against the local database file (`<store_id>.db`). No interactive screen requires an active internet connection.
2. **Sync Lifecycle**: Synchronization transitions through explicit states: `idle`, `checking`, `syncing`, `synced`, `offline`, `pending`, `failed`, `conflict`.
3. **Safe Checkpointing**: Before upload, the database executes a full WAL checkpoint to ensure a consistent single-file image.
4. **Serverless Authorization**: The serverless backend independently verifies authenticated user ownership (`ownerId == authenticatedUser.id`) before allowing any upload or download of store database files.

## Consequences
- Resilience against intermittent or zero connectivity.
- Deterministic backup and sync status communicated clearly to the user.

## Verification
- Unit and integration tests verify offline operation, sync transitions, and unauthorized upload/download rejection.
