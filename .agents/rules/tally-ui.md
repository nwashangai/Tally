# Tally UI & UX Rules

## 1. Multi-Surface Support

Tally targets three primary surfaces:
- **Phone:** Fast one-handed counting, dense and legible summary views.
- **Tablet / iPad:** Two-pane or split layouts taking advantage of larger viewports without awkward whitespace.
- **Progressive Web App (PWA):** Desktop browser responsive behavior, keyboard navigation, and mouse-friendly interactions.

## 2. Calm, Fast, Trustworthy Aesthetic

- Use modern, high-contrast, clean typography and curated color palettes. Avoid default or jarring colors.
- Micro-interactions and feedback transitions must feel instant ($\le 200\text{ms}$).
- Clearly distinguish between estimated stock and confirmed counted stock.

## 3. Interaction & Touch Targets

- Minimum touch target size for interactive controls is **48x48 dp** on mobile/tablet.
- Provide clear visual focus and hover states for web/desktop.
- Provide prominent, distraction-free numeric entry controls for tallying.

## 4. UI State Discipline

Every screen or data widget must explicitly handle all states:
- **Initial / Empty:** Actionable empty states guiding the user to create their first item or session.
- **Loading:** Non-blocking skeleton loaders or subtle spinners.
- **Active / Populated:** Content-focused, clear hierarchy.
- **Error:** Human-readable error messages with recovery / retry actions.
- **Offline / Syncing:** Subtle status badge showing local-only or pending sync state.

## 5. Monetization Guardrails

- **Zero Ads in Counting Workflows:** No ads may be displayed during an active count session or reconciliation review.
- **No Deceptive Placements:** Ads must never resemble primary buttons, action controls, or inventory items.
- **No Layout Shift:** Reserve layout space for banner ads to prevent Cumulative Layout Shift (CLS).
- Ads must be fully isolated behind the `AdService` port.

## 6. Official Color Palette & Design Tokens (ADR 0004)

All UI elements, themes, and illustrations must adhere to the accepted palette:
- **Primary Navy (`#172A45`):** Dark mode background/surfaces, light mode high-emphasis text and brand elements.
- **Slate / Muted Steel (`#8892B0`):** Secondary text, unselected icons, helper labels, subtle dividers.
- **Ice Frost (`#E6F1FF`):** Light mode surface tints/chips/input backgrounds, dark mode high-contrast primary text and selection highlights.
- **Canvas White (`#FFFFFF`):** Light mode primary canvas background.
- **Semantic Accents:**
  - Zero Variance (Success): `#10B981` / `#64FFDA`
  - Discrepancy (Warning): `#F59E0B`
  - Critical / Negative Stock (Danger): `#EF4444`
  - Active Tally Session (Accent): `#38BDF8`

## 7. Design System First & Reusable Component Hierarchy

- **Design System First:** Always reuse standard components from `lib/presentation/design_system/widgets/` instead of implementing ad-hoc duplicates:
  - `TallySearchField` for search inputs
  - `TallyTableContainer` for table wrappers and list headers
  - `TallyPaginationBar` for pagination
  - `TallyEmptyState` for empty views
  - `TallyErrorState` for error handling
  - `TallyFilterChipsBar` for active filter chips
  - `TallySortableHeader` for table sort headers
- **Identify Redundancies:** Before writing UI for new screens, scan existing screens for identical patterns (e.g., mobile card layouts, status badges, confirmation dialogs) and reuse or extract them into reusable widgets.
- **Mobile Table Avoidance:** Always provide a responsive mobile card fallback (`context.isPhone`) rather than rendering horizontal-scrolling data tables on phone viewports.


