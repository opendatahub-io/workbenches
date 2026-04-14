---
name: kubeflow-notebooks-frontend-component-authoring
description: Builds frontend React/TypeScript components with consistent PatternFly usage, typing, rendering structure, and testability hooks. Use when creating or refactoring frontend components.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Frontend Component Authoring

## Use This Skill When

- Creating a new UI component or page section.
- Refactoring component structure for readability and maintainability.

## Workflow

1. Define typed props interface (`Props` suffix), avoid `any`.
2. Use PatternFly `/dist/esm` imports and `~/` absolute internal imports.
3. Model loading/error/empty states with early-return rendering.
4. Add stable `data-testid` on test-critical elements.
5. Keep component focused; move complex state/effects into hooks.

## Guardrails

- No direct `process.env` reads in component bodies.
- Prefer explicit booleans (`is`, `has`, `can`, `should`) for readability.
- Keep conditional rendering clear; avoid deep nested ternaries.

## Done Criteria

- Component is strongly typed, testable, and pattern-consistent.
- UI behavior is covered by unit/integration tests where needed.
