# ADR 0011 — Local Store Database Export & Restore

## Status
Accepted

## Context
Small business owners demand complete sovereignty over their data. Tally users must be able to export their store's actual database file at any time to keep on their personal storage, USB drives, or external backup archives.

## Decision
1. **Physical File Export**: The export feature provides the actual encrypted database file (`<store_id>.db`) directly to the user's chosen location (via system file picker / share sheet).
2. **Safe Export Pipeline**:
   - `StoreDatabaseManager.checkpoint(storeId)` flushes all WAL pages.
   - Consistent database snapshot is copied to a temporary export destination.
   - User picks destination or downloads file.
3. **Future Import Capability**:
   - Validate SQLite file header and encryption key.
   - Verify store identity and owner authorization.
   - Install to local store database path.

## Consequences
- Zero vendor lock-in; users have physical ownership of their business ledger.
- Exported files are standard SQLite/SQLCipher databases.

## Verification
- Unit and widget tests verify checkpointing, file copy safety, and export triggers.
