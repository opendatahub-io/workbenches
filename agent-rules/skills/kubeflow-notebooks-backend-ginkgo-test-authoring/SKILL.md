---
name: kubeflow-notebooks-backend-ginkgo-test-authoring
description: Authors backend tests with Ginkgo/Gomega using stable setup, isolation strategy, and table-driven coverage. Use when adding or updating backend unit or integration tests.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Backend Ginkgo Test Authoring

## Use This Skill When

- Adding tests for handlers, repositories, or model validation.
- Refactoring backend behavior that needs regression coverage.

## Workflow

1. Choose test scope: unit-style or integration-style.
2. Use `BeforeEach` for independent setup; use `Ordered`/`Serial` only when state coupling is unavoidable.
3. Use unique resource names for cluster-backed tests.
4. Add clear `By(...)` steps for long flows.
5. Add table-driven cases for repeated validation/error variants.

## Guardrails

- Always assert both status and response/body shape where relevant.
- Include at least one failure-path test for each new behavior.
- Avoid hidden shared mutable state between specs.

## Done Criteria

- Tests are deterministic and readable.
- Setup/cleanup is explicit.
- New behavior is covered with success and failure cases.

## Verification

From `workspaces/backend/` run:

1. `make lint`
2. `ginkgo run -v ./...`

Pass criteria:

- All new and existing tests pass.
- No lint failures.
