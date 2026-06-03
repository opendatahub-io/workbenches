---
name: kubeflow-notebooks-frontend-jest-rtl-testing
description: Writes frontend unit and integration tests with Jest and React Testing Library focused on user-observable behavior. Use when adding features, fixing bugs, or preventing regressions in frontend code.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Frontend Jest/RTL Testing

## Use This Skill When

- Adding or updating frontend behavior.
- Fixing regressions that need durable coverage.

## Testing Workflow

1. Prefer behavior-driven tests over implementation details.
2. Render with required providers/helpers from project patterns.
3. Assert user-visible outcomes (text, controls, state feedback).
4. Cover at least one failure path for async interactions.

## Guardrails

- Avoid brittle snapshot-heavy tests for dynamic UIs.
- Avoid mocking everything by default; mock only unstable boundaries.
- Keep test names specific to behavior and scenario.

## Regression Pattern

- Reproduce failing behavior in test first.
- Implement fix.
- Ensure test passes and fails without fix.

## Verification

From `workspaces/frontend/` run:

1. `npm run test:type-check`
2. `npm run test:lint`
3. `npm test -- --testPathPattern="<changed-feature-or-component>"`

Pass criteria:

- New tests fail before the fix (for bugfix work) and pass after.
- Assertions are behavior-driven (user-visible state), not implementation internals.
- Updated tests pass consistently without snapshot churn.
