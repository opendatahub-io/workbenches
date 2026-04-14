---
name: kubeflow-notebooks-cypress-e2e-authoring
description: Authors stable Cypress end-to-end tests using resilient selectors and reusable test architecture. Use when implementing new e2e coverage for frontend user journeys.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cypress E2E Authoring

## Use This Skill When

- Adding end-to-end tests for user flows.

## Authoring Workflow

1. Define scenario: setup, action, expected outcome.
2. Use stable selectors (prefer `data-testid` patterns used by project).
3. Encapsulate repetitive interactions in helpers/page-object style utilities.
4. Assert visible behavior, navigation, and key side effects.

## Guardrails

- Avoid CSS/DOM-structure selectors likely to break.
- Keep tests independent and deterministic.
- Minimize hard waits; prefer condition-based waits.

## Coverage Targets

- Happy path flow.
- Validation/error path.
- Critical workflow completion confirmation.
