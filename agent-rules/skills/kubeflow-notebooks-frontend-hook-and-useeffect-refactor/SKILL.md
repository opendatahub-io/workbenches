---
name: kubeflow-notebooks-frontend-hook-and-useeffect-refactor
description: Refactors complex component state/effect logic into reusable hooks with safe dependencies and predictable async behavior. Use when useEffect blocks are growing or causing render/state issues.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Frontend Hook and useEffect Refactor

## Use This Skill When

- A component has complex `useEffect` logic or multiple state transitions.
- Behavior bugs suggest stale dependencies or side-effect coupling.

## Workflow

1. Isolate side-effect responsibility (fetch, derive, sync, cleanup).
2. Extract non-UI logic into a custom hook with typed return.
3. Ensure exhaustive and intentional dependency arrays.
4. Keep component render focused on UI state mapping.
5. Add or update hook tests for loading/success/error transitions.

## Guardrails

- Avoid hidden state mutations inside effects.
- Avoid suppressing dependency warnings as a primary fix.
- Keep hook API small and explicit.

## Done Criteria

- Component is simpler and easier to read.
- Effect behavior is deterministic and covered by tests.

## Verification

From `workspaces/frontend/` run:

1. `npm run test:type-check`
2. `npm run test:lint`
3. `npm test -- --testPathPattern="hooks|useEffect|<feature-name>"`

Pass criteria:

- No exhaustive-deps suppressions added as a workaround.
- Extracted hook tests cover loading/success/error transitions.
- Refactored component renders with equivalent user behavior.
