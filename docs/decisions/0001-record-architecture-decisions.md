# ADR 0001 — Architecture Decision Process

## Status
Accepted

## Decision

Tally will document material architecture and product decisions as ADRs under `docs/decisions/`.

## Why

AI-assisted development can otherwise cause architecture to drift across many small prompts. ADRs preserve intent and prevent the agent from repeatedly reconsidering settled decisions.

## Required ADR triggers

Create an ADR when deciding:
- backend provider;
- authentication model;
- state management;
- local persistence;
- sync/conflict strategy;
- inventory event model;
- navigation architecture;
- design-system architecture;
- ad provider/placement strategy;
- analytics/consent architecture;
- CI/CD or release strategy.

## ADR template

```md
# ADR NNNN — Title

## Status
Proposed | Accepted | Superseded

## Context
What problem are we solving?

## Decision
What are we choosing?

## Alternatives considered
What else was considered?

## Consequences
What becomes easier/harder?

## Verification
How will we know the decision works?
```
