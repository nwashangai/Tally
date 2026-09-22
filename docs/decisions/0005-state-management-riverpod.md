# ADR 0005 — State Management with Riverpod

## Status
Accepted

## Context
Tally needs a robust, testable, compile-safe, and dependency-injection-capable state management solution that works seamlessly across Flutter Mobile and Flutter Web/PWA without global mutable state or BuildContext antipatterns.

## Decision
Adopt **Riverpod 2.x** (`flutter_riverpod`) as Tally's official state management and dependency injection framework.

Key architectural rules:
1. Core infrastructure contracts (Logger, Clock, IdGenerator, Repositories) are exposed via Providers.
2. Domain logic remains decoupled from Riverpod; Riverpod providers live in `lib/app/providers` and `lib/application/`.
3. UI widgets consume state via `ConsumerWidget` or `ConsumerStatefulWidget` without calling business logic directly in lifecycle hooks.
4. Overrides in `ProviderScope` enable trivial mock injection in widget tests without global state leakage.

## Alternatives considered
- **Bloc / Cubit**: Excellent event tracing, but higher boilerplate for simple reactive stores and synchronous value passing.
- **ChangeNotifier + Provider**: Lacks compile-time safety and requires BuildContext for read/watch.
- **Signals / MobX**: Non-standard in enterprise Flutter toolchains and harder to cleanly override per widget-test scope.

## Consequences
- Clean separation of presentation and application logic.
- Consistent testing story across all unit and widget tests.
- Clear mental model for reactive stream subscriptions (e.g., auth state, sync state).

## Verification
- Unit and widget tests verify provider dependency injection and mock overrides without runtime failures.
