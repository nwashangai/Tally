# Tally Quality Gates

## Gate 0 — Product
- [ ] User problem and primary flow are explicit.
- [ ] Acceptance criteria exist.
- [ ] Scope is controlled.
- [ ] Product assumptions are documented.

## Gate 1 — Architecture
- [ ] Domain rules are isolated.
- [ ] Serverless trust boundary is clear.
- [ ] Provider-specific code is isolated.
- [ ] Offline/sync behavior is defined for mutations.
- [ ] ADR created for material architectural decisions.

## Gate 2 — UI/UX
- [ ] Phone layout verified.
- [ ] Tablet/iPad layout verified.
- [ ] Portrait and landscape considered.
- [ ] Loading/empty/error/offline states exist.
- [ ] Accessibility semantics/touch targets considered.
- [ ] No ad interferes with a critical workflow.

## Gate 3 — Engineering
- [ ] Formatter clean.
- [ ] Analyzer clean.
- [ ] Unit tests.
- [ ] Widget tests for important interaction states.
- [ ] Integration/E2E tests for critical journeys.
- [ ] Regression tests for fixed bugs.

## Gate 4 — Security
- [ ] No secrets in client.
- [ ] Authorization enforced server-side.
- [ ] Cross-user access tested.
- [ ] Duplicate/replay behavior tested.
- [ ] Sensitive logging reviewed.
- [ ] Data collection minimized.

## Gate 5 — Performance
- [ ] Startup/first interaction reviewed.
- [ ] List rendering is appropriate.
- [ ] Images/assets optimized.
- [ ] Web build reviewed.
- [ ] Async work does not block critical interaction.
- [ ] Ad impact measured.

## Gate 6 — Release
- [ ] Production configuration separated from development.
- [ ] Error monitoring configured.
- [ ] Analytics/consent behavior documented.
- [ ] Backup/export strategy considered.
- [ ] Rollback/recovery plan exists.
- [ ] Release notes prepared.
