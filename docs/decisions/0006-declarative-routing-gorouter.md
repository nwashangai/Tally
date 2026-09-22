# ADR 0006 — Declarative Routing with GoRouter

## Status
Accepted

## Context
Tally operates on Mobile (Android, iOS) and Desktop/Web (PWA). Deep-linking, URL routing, authentication redirect guards, and declarative routing hierarchies are essential for a smooth multi-platform experience.

## Decision
Adopt **GoRouter** (`go_router`) as Tally's declarative navigation framework.

Key architectural rules:
1. Route path strings are centralized as constants in `TallyRoutes` within `lib/app/router/app_router.dart`.
2. Router redirection logic reacts dynamically to authentication state via `refreshListenable` and Riverpod subscriptions.
3. Nested shell routes will be used for bottom navigation / sidebar layouts across form factors.

## Alternatives considered
- **Navigator 2.0 RouterDelegate/RouteInformationParser**: Too verbose and high maintenance.
- **AutoRoute / Beamer**: Code generation overhead and larger API surface with frequent breaking changes across Flutter releases.

## Consequences
- Single navigation solution for both Mobile and Web/PWA with browser URL synchronization and back-button support.
- Centralized auth redirect policy.

## Verification
- Widget tests and integration tests verify route transitions, deep linking, and unauthorized redirects.
