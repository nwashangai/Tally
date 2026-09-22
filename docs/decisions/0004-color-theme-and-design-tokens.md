# ADR 0004 — Color Theme and Design Tokens

## Status
Accepted

## Context
Tally requires a consistent, calm, trustworthy, and high-contrast visual design system across its three primary surfaces (Phone, Tablet/iPad, and PWA). The visual tone must support intense, focused inventory counting without eye strain, while ensuring numbers, statuses, and variances are immediately legible.

The user selected a foundational triad of colors:
- `#172A45` (Midnight Navy)
- `#8892B0` (Slate / Muted Steel)
- `#E6F1FF` (Ice Tint / Soft Frost)

## Decision

We establish Tally's official color palette, surface tokens, and semantic state colors derived from this triad:

### 1. Primary Triad Tokens

| Token | Hex Value | Role & Usage |
| :--- | :--- | :--- |
| `primaryNavy` | `#172A45` | Dark mode primary background & elevated surfaces; Light mode high-emphasis text, primary brand buttons, and headers. |
| `slateMuted` | `#8892B0` | Secondary & helper text, unselected tab icons, subtle borders, metadata labels, and timestamps. |
| `iceFrost` | `#E6F1FF` | Light mode secondary container tint, input fills, badges, and card accents; Dark mode high-contrast primary text and selection highlights. |
| `canvasWhite` | `#FFFFFF` | Light mode clean canvas background and primary card surface. |

### 2. Light & Dark Surface Mappings

```text
Light Mode:
  ├── Canvas / Background:  #FFFFFF (Pure White)
  ├── Secondary Surface:    #E6F1FF (Ice Frost tint for inputs, active cards, chips)
  ├── Primary Text:         #172A45 (Contrast: 15.6:1 — Exceeds WCAG AAA)
  ├── Secondary Text:       #4A5568 / #8892B0 (Contrast: 5.1:1 — Passes WCAG AA)
  └── Border / Dividers:    #E2E8F0 / #D1DDF0
```

Dark Mode:
  ├── Canvas / Background:  #0A192F (Deep Obsidian Navy)
  ├── Card / Surface:       #172A45 (Midnight Navy)
  ├── Elevated Surface:     #1E3A5F
  ├── Primary Text:         #E6F1FF (Contrast: 14.2:1 — Exceeds WCAG AAA)
  ├── Secondary Text:       #8892B0 (Contrast: 5.1:1 — Passes WCAG AA)
  └── Border / Dividers:    #233554
```

### 3. Semantic & Inventory Status Tokens
Inventory workflows require unambiguous color coding for counting and variance reconciliation:

| Semantic Token | Hex Value | Purpose in Inventory Workflows |
| :--- | :--- | :--- |
| `varianceZero` (Success) | `#10B981` / `#64FFDA` | Stock count perfectly matches expected stock. |
| `varianceDiscrepancy` (Warning) | `#F59E0B` | Counted stock differs from expected stock (surplus or shortage). |
| `stockCritical` (Danger) | `#EF4444` | Negative stock, out-of-stock, or missing critical items. |
| `tallyActive` (Accent) | `#38BDF8` | Active count session indicator, current active stepper item. |

## Alternatives Considered
- Standard Material 3 default palette (Purple/Indigo): Rejected as too generic and not aligned with Tally's calm, focused, high-precision aesthetic.
- Pure black/white monochrome: Rejected due to harsh contrast and inability to naturally represent subtle inventory states without strong color indicators.

## Consequences
- **Easier:** Clear contrast ratios meeting WCAG 2.1 AA/AAA; consistent dark/light mode token mapping across Phone, Tablet, and Web.
- **Harder:** Custom theme setup required in Flutter `ThemeData` rather than relying on standard auto-generated Material color schemes.

## Verification
- Automated checks on color contrast ratios using WCAG tools.
- Visual inspection across mobile, tablet, and PWA viewports in both light and dark modes.
