# ADR 0009 — Store Database Architecture with Drift & Encrypted SQLite

## Status
Accepted

## Context
Tally requires a local-first, highly reliable, ACID-compliant database engine that operates across Phone (Android, iOS), Tablet (iPad, Android), macOS, and Web/PWA.
Each physical store must own its own isolated database file to allow offline operations, zero cross-store data leakage, simple backup/sync, and user-controlled export.

## Decision
1. **Engine**: Adopt **Drift** (`drift`, `drift_dev`) over **Encrypted SQLite** (`sqlite3`, `sqlcipher_flutter_libs`).
2. **File-Per-Store**: Each store's local operational database is stored at `<documents>/tally/stores/<store_id>.db`.
3. **Encryption at Rest**: Databases are encrypted using SQLCipher 256-bit AES keys. The encryption key for each store is uniquely generated and managed via `StoreKeyManager` backed by `flutter_secure_storage`.
4. **Lifecycle Port**: The application and domain layers interact exclusively through the abstract `StoreDatabaseManager` interface.
5. **Safe Checkpointing**: Before any copy, export, or cloud synchronization, the database executes `PRAGMA wal_checkpoint(FULL)` to ensure all WAL pages are flushed to the main `.db` file.

## Consequences
- High performance, type-safe Dart queries and relational integrity.
- Full encryption at rest protects sensitive business inventory data on mobile devices.
- Single-file export/import is straightforward and independent of other stores.

## Verification
- Unit tests verify database creation, schema creation, encryption key enforcement, WAL checkpointing, and integrity validation.
