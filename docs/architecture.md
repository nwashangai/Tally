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

## Serverless boundary

The Flutter client must never contain privileged backend credentials.

Serverless functions/edge functions are responsible for operations requiring trusted validation or secrets. Database policies/RLS/security rules enforce ownership and authorization.

## Offline strategy

Use a local-first write queue only for workflows whose conflict semantics are explicitly defined.

Each queued mutation should have:
- client mutation ID/idempotency key;
- creation time;
- entity/version information as needed;
- retry count/state;
- deterministic payload;
- reconciliation behavior.

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
