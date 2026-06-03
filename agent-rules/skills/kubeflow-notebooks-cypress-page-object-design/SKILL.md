---
name: kubeflow-notebooks-cypress-page-object-design
description: Designs and maintains Cypress page objects that encapsulate selectors, actions, and assertions for readable tests. Use when creating new page objects or refactoring tests away from inline UI details.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cypress Page Object Design

## Use This Skill When

- Creating page objects for new screens/components.
- Migrating test implementation details out of spec files.

## Workflow

1. Define page object class with route and `visit()`/`wait()` flow.
2. Add `find*` element methods using `findByTestId`.
3. Add action methods (`click*`, `select*`, `apply*`, `type*`).
4. Add assertion methods (`assert*`) for behavior-level checks.
5. Keep spec files narrative and concise; call page methods only.

## Guardrails

- Avoid brittle CSS selectors when `data-testid` can be used.
- Keep methods single-purpose and reusable.
- Prefer named params for multi-argument actions/assertions.

## Done Criteria

- Tests read like user stories.
- UI coupling is localized to page object classes.
