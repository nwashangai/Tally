---
name: tally-ui
description: >-
  Workflow for designing, building, and auditing responsive UI components and screens for Tally across phone, tablet, and PWA surfaces.
---

# Tally UI & Multi-Surface Design Workflow

Use this skill when creating or revising UI widgets, layouts, responsive screens, and verifying surface compatibility.

## Core Directives

1. **Design System First & Component Reusability:**
   - **Audit Before Building:** Always check `lib/presentation/design_system/widgets/` before implementing any UI pattern. Reuse existing design tokens (`TallyColors`, `TallySpacing`, `TallyRadii`) and core components:
     - `TallySearchField` — Standard expandable/responsive search input.
     - `TallyTableContainer` — Standard surface container for tables and list headers.
     - `TallyPaginationBar` — Unified footer pagination control.
     - `TallyEmptyState` — Actionable empty state with optional illustration, title, description, and action button.
     - `TallyErrorState` — Error display with retry mechanism.
     - `TallyFilterChipsBar` — Filter chips with clear actions.
     - `TallySortableHeader` — Standard sortable column header.
   - **Identify Redundancies & Extract:** If a layout pattern, card structure, table wrapper, or dialog structure appears in $\ge 2$ features (e.g. Items, Receivings, Counts, Reports), immediately refactor it into a reusable component under `lib/presentation/design_system/widgets/` or a shared widget directory.
   - **Zero Ad-Hoc Styling:** Ensure all components use centralized design tokens rather than arbitrary margins, paddings, or magic numbers.

2. **Target Surfaces:**
   - **Phone (< 600dp width):** Single column, bottom navigation or drawer, large touch targets, thumb-friendly tally actions, and responsive card lists (mirroring Item List cards) instead of wide horizontal-scrolling data tables.
   - **Tablet / iPad (600dp - 1024dp width):** Master-detail / two-column layouts, modal sheets, persistent sidebar navigation.
   - **PWA / Desktop (> 1024dp width):** Centered max-width content or multi-pane view, keyboard shortcuts, hover states, full data tables.

3. **Touch Targets & Accessibility:**
   - Interactive elements must be at least **48x48 dp**.
   - Use semantic labels (`Semantics` widget or tooltip) on icon-only buttons.
   - Contrast ratio must meet WCAG AA standards (4.5:1 for normal text).

4. **Ad Placement Guardrails:**
   - Ads must NEVER appear within an active count session or reconciliation modal.
   - Banners must have fixed container dimensions to avoid layout jumps (CLS).

## Checklist for New Screens & Components

- [ ] **Reusability Check:** Verified that existing design system widgets (`TallySearchField`, `TallyTableContainer`, `TallyPaginationBar`, `TallyEmptyState`, `TallyErrorState`, etc.) are reused.
- [ ] **Redundancy Audit:** Identified any repeated UI blocks and extracted them into reusable components.
- [ ] Responsive wrapper applied (`LayoutBuilder` or `context.isPhone` responsive branching).
- [ ] Explicit handling of all 5 UI states:
  - Initial / Empty state (`TallyEmptyState`)
  - Loading skeleton or indicator
  - Success / Populated content
  - Error state with retry option (`TallyErrorState`)
  - Offline indicator (when connectivity is lost)
- [ ] Mobile card fallback used in place of horizontal table scrolling on phone screens.
- [ ] Landscape orientation tested for mobile & tablet.
- [ ] Widget tests written in `test/widget/` verifying key user interactions and responsive rendering.

