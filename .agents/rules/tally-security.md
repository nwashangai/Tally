# Tally Security Rules

## 1. Zero Secrets in Client

- Never commit or bundle service role keys, master passwords, or database superuser credentials into the client code.
- Only publish public/anonymous keys (e.g. Supabase anon key, Firebase web options) that are safe for client-side distribution.
- Use `.env.example` as a template. Always ignore `.env` files in git.

## 2. Server-Enforced Authorization

- Client-side checks are purely for UX (e.g., hiding buttons). Authoritative security and tenancy enforcement must occur server-side.
- Multi-tenancy isolation: Every read and write query must be scoped to the authenticated user's workspace via Row Level Security (RLS) or serverless edge policies.
- Verify cross-tenant isolation in tests: A user in Workspace A must never read or modify items in Workspace B.

## 3. Auditability & Tamper Resistance

- All inventory adjustments and reconciliations must produce an immutable `StockMovement` or `AuditEvent`.
- Stock quantities cannot be mutated without a corresponding movement record specifying reason, timestamp, and actor.
- Client mutation queue must send idempotency keys to prevent duplicate transaction replay upon network recovery.

## 4. Privacy & Data Minimization

- Collect only data essential for inventory management and error telemetry.
- Comply with consent requirements before loading third-party advertising SDKs or tracking scripts.
- Never log personally identifiable information (PII) or sensitive tokens in debug logs.
