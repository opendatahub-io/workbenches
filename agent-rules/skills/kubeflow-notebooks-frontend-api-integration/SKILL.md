---
name: kubeflow-notebooks-frontend-api-integration
description: Implements frontend API interactions using generated clients and resilient async/error flows. Use when UI changes require fetching or mutating backend data.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Frontend API Integration

## Use This Skill When

- Building UI features backed by backend endpoints.

## Integration Workflow

1. Confirm API client types are current.
2. Use existing API/context abstractions before introducing new layers.
3. Model loading, success, and error states explicitly.
4. Surface actionable user-facing errors.
5. Add tests for async success and failure paths.

## Guardrails

- Do not call Kubernetes directly from frontend code.
- Avoid ad hoc fetch calls when generated client patterns exist.
- Keep request/response transforms centralized.

## Done Criteria

- Types align with generated client.
- UI state transitions are deterministic.
- Error handling is visible and test-covered.

## Verification

From `workspaces/frontend/` run:

1. If API contract changed upstream: `npm run generate:api`
2. `npm run test:type-check`
3. `npm run test:lint`
4. `npm test -- --testPathPattern="useWorkspaces|useWorkspaceKinds|api"`

Pass criteria:

- No TypeScript/lint errors from API integration changes.
- Async success and failure paths are covered in tests.
- UI displays actionable error state rather than silent failure.
