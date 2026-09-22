# Tally Testing Rules

## 1. The Testing Pyramid

Every increment must maintain appropriate test coverage according to layer:

- **Unit Tests (Pure Dart):**
  - All domain entities, value objects, invariants, and variance calculation routines.
  - All application use cases (tested using mock/fake repositories implementing port interfaces).
  - Target: $\ge 90\%$ test coverage on `domain/` and `application/`.
- **Widget Tests (Flutter):**
  - Critical UI components and interaction states: loading, populated, error, empty, offline.
  - Form validation and input entry (e.g. numeric stepper, tally counter).
  - Verifying touch targets and accessibility semantics.
- **Integration Tests:**
  - Complete vertical user journeys (e.g., Create Item $\rightarrow$ Start Count Session $\rightarrow$ Adjust Quantities $\rightarrow$ Review Variance $\rightarrow$ Reconcile).

## 2. Quality Gate Verification Workflow

Before reporting an increment as completed, run:

1. **Format Check:**
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
2. **Static Analysis:**
   ```bash
   flutter analyze
   ```
   Zero warnings, zero errors. Never ignore linter warnings with inline comments without documenting rationale.
3. **Automated Tests:**
   ```bash
   flutter test
   ```
   All tests must pass.
4. **Regression Protection:**
   - Any bug fix must include a reproducing test that failed before the fix and passes after.
