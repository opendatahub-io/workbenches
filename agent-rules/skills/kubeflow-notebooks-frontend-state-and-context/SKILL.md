---
name: kubeflow-notebooks-frontend-state-and-context
description: Guides frontend state placement and React context usage to keep data flow clear and maintainable. Use when introducing or refactoring stateful UI behavior.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Frontend State and Context

## Use This Skill When

- Adding new local/global UI state.
- Refactoring components with prop drilling or context sprawl.

## State Placement Rules

1. Keep state as local as possible.
2. Promote to context only for shared cross-tree concerns.
3. Derive state from source data instead of duplicating it.
4. Isolate side effects and async transitions.

## Context Guardrails

- Keep context value surface minimal and stable.
- Avoid mega-contexts that mix unrelated concerns.
- Provide typed APIs for context consumers.

## Testing Focus

- State transitions for primary user flows.
- Context provider/consumer integration behavior.
- Regression checks for rerender-sensitive components.

## Verification

From `workspaces/frontend/` run:

1. `npm run test:type-check`
2. `npm run test:lint`
3. `npm test -- --testPathPattern="context|provider|<affected-feature>"`

Pass criteria:

- Provider values are stable (memoized where required) and typed.
- No new prop-drilling regressions or rerender loops.
- Consumer behavior is validated with provider-wrapped tests.
