---
name: kubeflow-notebooks-cypress-waiting-strategies
description: Stabilizes Cypress synchronization by preferring alias- and state-driven waits over fixed delays. Use when adding tests or fixing timing-related flakiness.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cypress Waiting Strategies

## Use This Skill When

- Writing new Cypress tests with async UI/API behavior.
- Investigating flaky tests caused by timing/synchronization.

## Workflow

1. Alias all relevant API calls and wait on aliases.
2. Use retryable assertions on visible state changes.
3. Replace fixed waits with event/state-based synchronization.
4. Encapsulate wait patterns in page object helpers when repeated.
5. Re-run tests multiple times to validate stability.

## Guardrails

- Avoid `cy.wait(ms)` unless no deterministic signal exists.
- Keep waits close to the action that triggers async behavior.
- Prefer semantic assertions (loaded table, modal closed) over timing assumptions.

## Done Criteria

- Test synchronization is deterministic.
- Flake rate is reduced without masking real defects.
