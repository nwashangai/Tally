---
name: tally-pwa
description: >-
  Best practices and procedures for Progressive Web App (PWA) configuration, manifest, service worker caching, and web performance optimization in Tally.
---

# Tally PWA Deployment & Optimization Workflow

Use this skill when auditing, configuring, or testing Tally as a Progressive Web App (PWA).

## Requirements & Setup

1. **Manifest Configuration (`web/manifest.json`):**
   - Correct `name`, `short_name`, `start_url`, and `display: "standalone"`.
   - Brand theme colors matching Tally design tokens.
   - Standard icon assets (192x192 and 512x512 maskable/any PNGs).

2. **Web Rendering & Performance:**
   - Optimize load times (CanvasKit vs. HTML renderer considerations).
   - Ensure initial JavaScript payload is compressed and fonts are locally cached or preloaded.
   - No unnecessary blocking web scripts.

3. **Responsive Web Navigation:**
   - Support browser back/forward buttons and URL synchronization via declarative routing (`go_router`).
   - Deep-linking to specific inventory items or count sessions.

## Verification

- Test build with `flutter build web --release`.
- Verify responsive layout across desktop and tablet screen widths.
- Ensure service worker handles asset caching gracefully for offline readiness.
