---
name: tally-serverless
description: >-
  Guidance for designing serverless backend adapters, database schemas, edge functions, and secure synchronization protocols for Tally.
---

# Tally Serverless Integration Workflow

Use this skill when designing or implementing backend adapters (e.g. Supabase, Firebase), database policies, edge functions, and offline sync queues.

## Backend Principles

1. **Adapter Isolation:** The Flutter app connects to backend services solely through abstract port interfaces defined in `lib/src/ports/`. The domain and application layers must never know which provider is used.
2. **Serverless Boundary:**
   - Client is untrusted.
   - Database tables must enforce Row Level Security (RLS) or security rules scoped to authenticated workspace members.
   - Critical workflows (e.g., final reconciliation commits, subscription verification) must be validated server-side.
3. **Offline Sync Queue:**
   - Every mutation sent from the client must include an idempotency key (client mutation UUID).
   - In offline mode, mutations are written to a local durable queue and processed sequentially upon reconnect.
   - Provide explicit conflict resolution strategies (e.g., last-write-wins or version vector rejection).

## Implementation Checklist

- [ ] ADR in `docs/decisions/` exists and is accepted before writing provider-specific code.
- [ ] No privileged backend keys or service role secrets embedded in client code.
- [ ] Tenant isolation verified via unit/integration tests with two separate tenant IDs.
- [ ] Error codes from backend translated into domain exceptions at the infrastructure adapter boundary.
