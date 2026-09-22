---
name: tally-ui
description: >-
  Workflow for designing, building, and auditing responsive UI components and screens for Tally across phone, tablet, and PWA surfaces.
---

# Tally UI & Multi-Surface Design Workflow

Use this skill when creating or revising UI widgets, layouts, responsive screens, and verifying surface compatibility.

## Core Directives

1. **Target Surfaces:**
   - **Phone (< 600dp width):** Single column, bottom navigation or drawer, large touch targets, thumb-friendly tally actions.
   - **Tablet / iPad (600dp - 1024dp width):** Master-detail / two-column layouts, modal sheets, persistent sidebar navigation.
   - **PWA / Desktop (> 1024dp width):** Centered max-width content or multi-pane view, keyboard shortcuts, hover states.

2. **Touch Targets & Accessibility:**
   - Interactive elements must be at least **48x48 dp**.
   - Use semantic labels (`Semantics` widget or tooltip) on icon-only buttons.
   - Contrast ratio must meet WCAG AA standards (4.5:1 for normal text).

3. **Ad Placement Guardrails:**
   - Ads must NEVER appear within an active count session or reconciliation modal.
   - Banners must have fixed container dimensions to avoid layout jumps (CLS).

## Checklist for New Screens

- [ ] Responsive wrapper applied (`LayoutBuilder` or responsive utility).
- [ ] Explicit handling of all 5 UI states:
  - Initial / Empty state
  - Loading skeleton or indicator
  - Success / Populated content
  - Error state with retry option
  - Offline indicator (when connectivity is lost)
- [ ] Landscape orientation tested for mobile & tablet.
- [ ] Widget tests written in `test/presentation/` verifying key user interactions.
