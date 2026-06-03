---
name: kubeflow-notebooks-cypress-api-mocking-and-builders
description: Sets up deterministic Cypress tests with interceptApi aliases and builder-driven mock data. Use when adding or updating mocked E2E scenarios.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cypress API Mocking and Builders

## Use This Skill When

- Building mocked Cypress scenarios for new user flows.
- Refactoring flaky tests caused by inconsistent setup data.

## Workflow

1. Build fixtures using project builders (avoid large inline objects).
2. Register `cy.interceptApi(...)` mocks before page visits.
3. Alias every mocked request and wait by alias.
4. Keep setup helpers small and composable.
5. Return typed setup objects for scenario reuse.

## Guardrails

- Never hit real backend endpoints in mocked suites.
- Avoid hardcoded waits; synchronize on aliases or visible state.
- Keep test data local to each spec or `beforeEach`.

## Done Criteria

- Scenarios are deterministic and isolated.
- Mock setup is readable and reusable across tests.
