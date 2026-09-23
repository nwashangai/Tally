# ADR 0008 — Separate Authentication Subsystem & Boundary

## Status
Accepted

## Context
Tally needs to support multiple authentication providers (Google, Apple, Facebook). In multi-store inventory systems, a common anti-pattern is intertwining authentication credentials or session state with the store database itself. This creates security risks, makes multi-store access messy, and violates the single responsibility principle.

## Decision
1. **Separation of Concerns**: Authentication is a distinct subsystem from Store Management and Store Databases.
2. **No Credentials in Store DB**: Passwords, OAuth tokens, session tokens, and refresh tokens must never be written into any store database (`<store-id>.db`).
3. **Session Storage**: The active session and user identity are managed via `AuthRepository` and stored securely in `FlutterSecureStorage`.
4. **Mock Provider Support**: For offline development and testing, `MockAuthRepository` simulates Google, Apple, and Facebook sign-in without requiring active OAuth client keys or network connectivity.

## Consequences
- Clean boundary: UI only interacts with `AuthRepository` and `AuthState`.
- Switching stores or logging out leaves local store databases intact.
- Multi-store ownership resolution operates via `ownerId` without embedding user secrets in databases.

## Verification
- Unit and widget tests verify Google, Apple, and Facebook mock sign-in, session restoration, and sign-out isolation.
