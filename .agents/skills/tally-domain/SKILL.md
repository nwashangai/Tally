---
name: tally-domain
description: >-
  Procedures for modeling inventory entities, value objects, audit movements, and variance reconciliation in pure Dart.
---

# Tally Domain Modeling Workflow

Use this skill when defining or modifying inventory rules, domain entities, value objects, audit logs, or reconciliation algorithms.

## Rules & Constraints

1. **Pure Dart Only:** `lib/src/domain/` must have no imports of Flutter widgets, material, cupertino, or third-party storage/networking packages.
2. **Immutability:** Use `@immutable` or copyWith patterns for all models.
3. **Explicit Invariants:** Validate inputs upon construction. Throw domain-specific exceptions (e.g., `InvalidQuantityException`) rather than allowing inconsistent states.

## Key Domain Concepts

- **InventoryItem:** ID, workspace ID, name, SKU (optional), category, current stock quantity, timestamps.
- **StockQuantity:** Value object representing non-negative stock counts (or fractional units if specified in ADR).
- **StockMovement:** Immutable audit record of quantity change:
  - `type`: `initialCount`, `adjustmentIn`, `adjustmentOut`, `reconciliationAdjustment`, `lossOrDamage`.
  - `quantityDelta`: Signed amount of change.
  - `previousQuantity` & `newQuantity`.
  - `reason` & `performedByUserId`.
  - `occurredAt`.
- **CountSession:** Active tally session with item counts.
- **Variance:** Discrepancy between expected quantity and counted quantity (`counted - expected`).

## Verification Steps

- Every domain model must have a corresponding test suite in `test/domain/`.
- Ensure boundary cases are covered: zero quantity, maximum value overflow, negative stock prevention, and floating-point precision safety.
