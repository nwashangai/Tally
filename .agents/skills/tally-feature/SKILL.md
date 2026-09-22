---
name: tally-feature
description: >-
  Standard workflow for planning, implementing, and verifying a coherent vertical slice feature in Tally in accordance with the Agent Operating Model.
---

# Tally Feature Implementation Workflow

Use this skill when developing a new vertical slice feature (e.g., item creation, counting workflow, stock adjustment).

## Principles

1. **One prompt = one coherent increment:** Build full vertical slices through the architectural layers rather than horizontal incomplete layers across the whole app.
2. **Adhere to Layer Direction:** Domain $\rightarrow$ Ports $\rightarrow$ Application $\rightarrow$ Infrastructure $\rightarrow$ Presentation.
3. **No Unapproved Inventions:** Check existing ADRs in `docs/decisions/`. If a required architectural decision does not exist, draft an ADR before proceeding.

## Implementation Steps

1. **Analyze Requirements & Domain Invariants:**
   - Read `docs/product-spec.md` and relevant ADRs.
   - Define domain entities, value objects, and business rules.

2. **Domain Layer (Pure Dart):**
   - Create or update entities in `lib/src/domain/`.
   - Ensure immutability and validate invariants on creation.
   - Write pure unit tests in `test/domain/`.

3. **Ports Layer:**
   - Define or update abstract interfaces in `lib/src/ports/` (e.g. `InventoryRepository`).

4. **Application Layer:**
   - Implement use cases / command handlers in `lib/src/application/`.
   - Write unit tests using fake/mock repository implementations in `test/application/`.

5. **Infrastructure Layer:**
   - Implement repository adapters in `lib/src/infrastructure/`.
   - Test adapter serialization, query mapping, and error translation.

6. **Presentation Layer (Flutter):**
   - Implement UI screens and widgets in `lib/src/presentation/`.
   - Connect via controllers/blocs to Application use cases.
   - Handle all five states: empty, loading, populated, error, offline.
   - Write widget tests in `test/presentation/`.

7. **Verification & Quality Gates:**
   - Run format check: `dart format --output=none --set-exit-if-changed .`
   - Run static analysis: `flutter analyze`
   - Run all tests: `flutter test`
   - Confirm quality gates 0–6 in `docs/quality-gates.md`.
