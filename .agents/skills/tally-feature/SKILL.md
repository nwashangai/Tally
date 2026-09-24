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
3. **Prioritize Reusability & DRY (Don't Repeat Yourself):**
   - Before implementing new UI components, dialogs, queries, or helper logic, audit existing shared code in `lib/presentation/design_system/widgets/`, `lib/core/`, and shared domain/application utilities.
   - Actively identify redundant or duplicated patterns across feature modules (e.g. search fields, pagination bars, table containers, filter bars, empty/error states) and extract them into reusable, well-tested components.
4. **No Unapproved Inventions:** Check existing ADRs in `docs/decisions/`. If a required architectural decision does not exist, draft an ADR before proceeding.

## Implementation Steps

1. **Analyze Requirements & Domain Invariants:**
   - Read `docs/product-spec.md` and relevant ADRs.
   - Define domain entities, value objects, and business rules.

2. **Domain Layer (Pure Dart):**
   - Create or update entities in `lib/src/domain/` (or `lib/domain/`).
   - Ensure immutability and validate invariants on creation.
   - Write pure unit tests in `test/domain/` (or `test/unit/domain/`).

3. **Ports Layer:**
   - Define or update abstract interfaces in `lib/src/ports/` (or `lib/domain/`) (e.g. `InventoryRepository`).

4. **Application Layer:**
   - Implement use cases / command handlers / notifiers in `lib/src/application/` (or `lib/application/`).
   - Write unit tests using fake/mock repository implementations in `test/application/`.

5. **Infrastructure Layer:**
   - Implement repository adapters in `lib/src/infrastructure/` (or `lib/infrastructure/`).
   - Test adapter serialization, query mapping, and error translation.

6. **Presentation Layer (Flutter) & Reusable Component Adoption:**
   - **Audit Existing Components:** Check `lib/presentation/design_system/widgets/` (e.g., `TallySearchField`, `TallyTableContainer`, `TallyPaginationBar`, `TallyEmptyState`, `TallyErrorState`, `TallyFilterChipsBar`, `TallySortableHeader`) and reuse them.
   - **Extract Common Patterns:** If a new UI pattern or layout is duplicated across screens or modules, extract it into a reusable design system widget rather than copying ad-hoc code.
   - Implement UI screens and widgets in `lib/src/presentation/` (or `lib/presentation/`).
   - Connect via controllers/notifiers to Application use cases.
   - Handle all five states: empty, loading, populated, error, offline.
   - Write widget tests in `test/presentation/` (or `test/widget/`).

7. **Verification & Quality Gates:**
   - Run format check: `dart format --output=none --set-exit-if-changed .`
   - Run static analysis: `flutter analyze` or `dart analyze .`
   - Run all tests: `flutter test`
   - Confirm quality gates 0–6 in `docs/quality-gates.md`.

