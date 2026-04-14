---
name: kubeflow-notebooks-backend-handler-implementation
description: Implements or updates backend HTTP handlers with consistent validation, error handling, and response structure. Use when adding or modifying API endpoints in the backend module.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Backend Handler Implementation

## Use This Skill When

- Adding a new endpoint.
- Updating handler behavior, validation, or response shape.

## Handler Workflow

1. Define request/response contract first.
2. Validate inputs at boundary (required fields, format, constraints).
3. Delegate business logic to service/domain layer.
4. Return consistent status codes and structured errors.
5. Add regression/unit tests for success and failure paths.

## Error Handling Rules

- Fail explicitly; no swallowed errors.
- Include context in errors (resource, namespace, operation).
- Avoid leaking secrets or internal-only details.

## Checklist

- Endpoint behavior aligns with existing patterns.
- Validation and authorization are explicit.
- Logs are actionable and non-sensitive.
- Tests cover negative paths, not only happy path.

## Verification

From `workspaces/backend/` run:

1. `make lint`
2. `ginkgo run -v ./api/...`
3. If contract/annotation changed: `make swag`

Pass criteria:

- Handler tests include success and failure paths.
- Error responses and status codes match existing endpoint conventions.
- No lint failures and no generated-file hand edits.
