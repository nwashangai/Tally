---
name: tally-quality-gate
description: >-
  Step-by-step audit and verification procedures to enforce Quality Gates 0 through 6 before concluding or committing any code in Tally.
---

# Tally Quality Gate Audit Workflow

Use this skill before finalizing any task, prompt, or PR to guarantee all 7 quality gates (`docs/quality-gates.md`) pass cleanly.

## Execution Steps

### 1. Gate 0 — Product
- [ ] Requirements match `docs/product-spec.md`.
- [ ] Acceptance criteria are met without feature creep.

### 2. Gate 1 — Architecture & Reusability
- [ ] Domain logic has zero dependencies on UI, Flutter, or infrastructure SDKs.
- [ ] Serverless trust boundaries respected (client has no service secrets).
- [ ] **Reusability Prioritization:** Audited codebase to ensure common logic and UI widgets (tables, pagination, search, empty/error states) are reused from `lib/presentation/design_system/widgets/` rather than re-implemented ad-hoc.
- [ ] An ADR exists in `docs/decisions/` for any material architectural choice.

### 3. Gate 2 — UI/UX
- [ ] Phone layout verified with responsive mobile card list fallback (no overflowing or awkward horizontal data tables on phones).
- [ ] Tablet/iPad layout verified.
- [ ] Reused standard design system components (`TallySearchField`, `TallyTableContainer`, `TallyPaginationBar`, `TallyEmptyState`, `TallyErrorState`, `TallyFilterChipsBar`, `TallySortableHeader`).
- [ ] All 5 states implemented (empty, loading, populated, error, offline).
- [ ] Touch targets $\ge 48\times48$ dp.
- [ ] No ads placed in active tallying screens.

### 4. Gate 3 — Engineering
Run these commands sequentially:
```bash
# 1. Format check
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze # or dart analyze .

# 3. Unit and widget tests
flutter test
```
- [ ] Zero linter warnings or errors.
- [ ] All unit and widget tests pass cleanly.
- [ ] No duplicated boilerplate or redundant widget implementations.

### 5. Gate 4 — Security
- [ ] No secrets or service role keys committed.
- [ ] Authorization enforced on serverless backend.
- [ ] Client mutations use idempotency keys.

### 6. Gate 5 — Performance
- [ ] Async operations do not block the main UI thread.
- [ ] Minimal rebuilds and proper list view item rendering.

### 7. Gate 6 — Release
- [ ] Git status is clean and free of untracked scratch files.
- [ ] Documentation and walkthrough updated.
