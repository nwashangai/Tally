# Tally Architecture

## Goals

- Flutter application for mobile, tablet/iPad, and PWA.
- Serverless backend.
- Strong inventory correctness.
- Testable domain logic.
- Provider replaceability where practical.
- Offline-capable workflows without pretending every operation is offline-safe.

## Proposed layers

```text
Presentation
  ├── Screens
  ├── Widgets
  ├── Navigation
  └── State/controllers
          ↓
Application
  ├── Use cases
  ├── Commands/queries
  └── Policies
          ↓
Domain
  ├── Entities/value objects
  ├── Inventory rules
  ├── Reconciliation
  └── Domain services
          ↓
Ports / Interfaces
  ├── Repository interfaces
  ├── Auth interface
  ├── Sync interface
  ├── Analytics interface
  └── Ads interface
          ↓
Infrastructure
  ├── Serverless provider adapter
  ├── Local persistence
  ├── Network client
  ├── Secure storage
  └── Platform adapters
```

## Core Subsystems & Separation of Concerns

Tally is organized around 4 distinct architectural subsystems:

```text
                         TALLY
                           │
             ┌─────────────┴─────────────┐
             │                           │
      Authentication                 Store Management
             │                           │
       Authenticated User          Store Metadata
             │                           │
             └─────────────┬─────────────┘
                           │
                     Current Store
                           │
                           ▼
                  Store Database Manager
                           │
                           ▼
               Drift + Encrypted SQLite
                           │
                           ▼
                      store-id.db
                           │
                 ┌─────────┴─────────┐
                 │                   │
              Local                Remote
               File                 Backup
                 │                   │
                 │             Serverless API
                 │                   │
                 │             Remote Drive
                 │                   │
                 └───────── Sync ────┘
```

1. **Authentication Subsystem**: Handles user authentication (Google, Apple, Facebook), session persistence in `FlutterSecureStorage`, and user identity. Auth data NEVER lives inside store database files.
2. **Store Management Subsystem**: Discovers accessible stores for the authenticated user, verifies ownership relations, and manages store creation/selection.
3. **Store Database Subsystem**: Each store owns its isolated, encrypted database file (`<documents>/tally/stores/<store_id>.db`) powered by **Drift** + **SQLCipher**. All operational inventory transactions run against this local file.
4. **Remote Serverless Storage Subsystem**: Secure serverless object storage for background sync and user-initiated backups of database files with server-side authorization.

## Serverless boundary

The Flutter client must never contain privileged backend credentials.

Serverless functions/edge functions are responsible for operations requiring trusted validation or secrets. Database policies/RLS/security rules enforce ownership and authorization.

## Offline & Local-First Strategy

1. The local encrypted SQLite file is the authoritative interactive database while a store is active.
2. Operations work completely offline without network blocking.
3. Checkpoints (`PRAGMA wal_checkpoint(FULL)`) ensure safe database copies before export, sync, or backup.
4. Background synchronization updates the remote serverless storage without interrupting user workflows.

## Backend provider

No provider is locked in by this document. The implementation should first establish repository interfaces and domain contracts, then select a provider through an ADR.

Potential candidates:
- Supabase/Postgres + Edge Functions;
- Firebase/Firestore + Cloud Functions;
- another serverless backend that satisfies the same contracts.

The choice must consider:
- Flutter support;
- PWA/web support;
- offline requirements;
- relational inventory queries;
- authorization;
- cost;
- observability;
- vendor lock-in;
- export/migration path.

## Navigation

Use a small number of top-level destinations. Candidate:
- Home/Overview
- Inventory
- Count
- Activity
- Settings

Do not finalize the information architecture until the first UX flow pass.

## State management

Choose one state-management approach after inspecting current Flutter dependencies and project size. Keep business logic independent from the selected state library.

## Ads

Define an application-level `AdService` interface. Implement platform-specific adapters. The core domain and inventory screens must not depend directly on an ad SDK.
