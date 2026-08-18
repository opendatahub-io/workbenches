---
name: kubeflow-notebooks-backend-auth-policy-patterns
description: Applies backend authentication header handling and authorization policy checks consistently in handlers. Use when adding or modifying protected backend endpoints.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Backend Auth Policy Patterns

## Use This Skill When

- Adding endpoint authorization requirements.
- Updating auth checks in existing handlers.

## Workflow

1. Identify required verb/resource/meta policy for operation.
2. Build `ResourcePolicy` entries with correct namespace/name scope.
3. Invoke auth check before repository/business logic.
4. Return early on auth failure.
5. Add tests for authorized and unauthorized paths.

## Guardrails

- Keep auth policy definition close to handler entry.
- Avoid implicit auth assumptions in lower layers.
- Use consistent headers and policy semantics across endpoints.

## Done Criteria

- Auth checks are explicit, scoped, and test-covered.
- Unauthorized requests fail predictably and early.

## Verification

From `workspaces/backend/` run:

1. `make lint`
2. `ginkgo run -v ./api/...`

Pass criteria:

- Authorized and unauthorized paths are tested.
- No lint failures.
