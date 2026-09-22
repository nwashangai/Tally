# Tally Agent Operating Model

This document is the operating contract for AI-assisted development.

## One prompt = one coherent increment

Prompts should preferably produce one coherent vertical slice rather than a broad rewrite.

Good:
> Implement item creation from the inventory screen through repository persistence, including validation, tests, loading/error states, and documentation.

Risky:
> Build the whole inventory system.

## Before implementation

The agent must:
- inspect current repository state;
- identify applicable rules/skills;
- inspect existing patterns;
- state assumptions;
- create a plan for non-trivial work.

## During implementation

The agent should:
- avoid unrelated refactors;
- preserve existing behavior;
- reuse established components;
- add tests with behavior;
- update docs when architecture changes.

## After implementation

The agent must:
- format;
- analyze;
- test;
- build affected targets;
- inspect diff;
- summarize files changed and verification.

## Stop conditions

Ask before proceeding when:
- a destructive migration is required;
- a material product decision is ambiguous;
- a security boundary is unclear;
- data loss is possible;
- credentials or external production access are required;
- a change would invalidate a settled ADR.

## Artifact discipline

Do not overwrite or delete product/architecture documentation merely to make a task pass. Preserve historical ADRs and append superseding decisions instead.
