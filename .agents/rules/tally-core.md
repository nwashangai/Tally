# Tally Core Rules

## 1. Architectural Integrity & Layer Boundaries

Tally strictly enforces a clean 5-layer architecture. Dependencies must only point inward:

```text
Presentation (Screens, Widgets, Controllers)
    ↓
Application (Use Cases, Commands, Queries)
    ↓
Domain (Entities, Value Objects, Stock Rules)
    ↓
Ports / Interfaces (Repository & Service Contracts)
    ↓
Infrastructure (Adapters, Persistence, External Clients)
```

- **Domain Layer Isolation:** `lib/src/domain/` must be pure Dart. Zero imports from `flutter/`, `infrastructure/`, or third-party storage/backend SDKs.
- **Application Layer:** Orchestrates business operations and interacts only with Domain entities and Port interfaces.
- **Ports Layer:** Defines abstract interfaces (`abstract class`) for all external dependencies (e.g., `InventoryRepository`, `AuthService`, `SyncService`, `AdService`).
- **Infrastructure Layer:** Implements Port interfaces. Never import infrastructure concrete classes directly into presentation or domain.
- **Presentation Layer:** Consumes Application use cases and state view-models. Must not invoke infrastructure directly.

## 2. Agent Operating Principles

- **One Prompt = One Coherent Increment:** Implement single vertical slices rather than wide, incomplete refactors.
- **No Inventions Without ADR:** Do NOT introduce a backend provider, state management package, routing solution, design system, or storage engine without an accepted ADR in `docs/decisions/`.
- **Quality Gates Mandatory:** Every increment must pass Gates 0 through 6 (`docs/quality-gates.md`).
- **Immutability by Default:** All domain entities and value objects must be immutable.

## 3. Serverless Trust Boundary

- The Flutter client must never hold administrative backend credentials or bypass server-side rules.
- Authoritative validation, tenant isolation, and sensitive calculations must be enforced server-side (e.g., via Database Policies / Row Level Security or Serverless Edge Functions).

## 4. Offline & Mutation Discipline

- Offline writes must use a deterministic mutation queue.
- Every mutation must include:
  - Client-generated UUID (idempotency key)
  - UTC timestamp
  - Entity version / concurrency token
  - Deterministic payload
