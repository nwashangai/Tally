# Tally Product Specification

## 1. Product

Tally is a small-business inventory tallying and stock-balancing app. Its core job is to let a user record what they have, count it quickly, compare expected and counted stock, and understand variances.

Primary surfaces:
- phone;
- tablet/iPad;
- Progressive Web App.

The product should feel fast, calm, trustworthy, and exceptionally polished.

## 2. Product principles

1. Counting should be faster than spreadsheet-style data entry.
2. The user should always understand the current stock state.
3. Inventory changes must be auditable and recoverable.
4. The app should remain useful with unreliable connectivity where the workflow supports it.
5. Navigation should be shallow and predictable.
6. Ads must remain secondary to the product.

## 3. Initial domain concepts

Candidate MVP entities:
- Business/Workspace
- User
- Inventory Item
- Category
- Stock Movement
- Stock Count/Session
- Reconciliation/Variance
- Audit Event

Final schema must be decided through ADRs after the first domain modeling pass.

## 4. Candidate MVP flows

- onboarding/sign-in;
- create workspace/business;
- add/edit/archive inventory item;
- browse/search/filter inventory;
- quick stock adjustment;
- start stock-count session;
- enter counted quantities;
- calculate variance;
- review and confirm reconciliation;
- view recent stock activity;
- offline/sync status where implemented.

## 5. Deliberately deferred until decided

- purchasing;
- suppliers;
- sales/invoicing;
- barcode scanning;
- receipt/OCR;
- multi-location inventory;
- team roles/permissions beyond the minimum;
- exports;
- advanced reporting;
- paid plans.

These can be added later without prematurely designing every feature.

## 6. Monetization

The intended model is advertising with restrained placement.

Rules:
- no ad during an active count;
- no ad disguised as a primary control;
- no disruptive interstitial during critical inventory work;
- use platform-appropriate providers;
- isolate ad integration behind an interface;
- include consent/privacy handling where required;
- monitor layout shift and performance impact.

## 7. Product success signals

Track product behavior only after privacy and analytics decisions are documented. Candidate signals:
- time to complete a count;
- count completion rate;
- sync failure rate;
- reconciliation correction rate;
- active inventory items;
- crash/error rate;
- web performance metrics.

Do not optimize for ad impressions at the expense of core workflow quality.
