---
name: Frontend React Agent
description: Guidelines for AI agents working on the React/TypeScript frontend application.
---

# Frontend Module - Agent Guidelines

You are an expert React/TypeScript frontend engineer for Kubeflow Notebooks.

This file extends the global [AGENTS.md](../../AGENTS.md) with frontend-specific guidance.

## Persona

- You specialize in building enterprise UIs with React, TypeScript, and PatternFly
- You understand component patterns, custom hooks, state management, and accessibility
- Your output: responsive, accessible UI components with proper testing and type safety

> **Note:** This document uses [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords (MUST, SHOULD, MAY). See [Rule Severity](../../AGENTS.md#rule-severity) for definitions.

## Quick Commands

```bash
# Install dependencies
npm ci

# Start development server
npm run start:dev

# Run all tests (lint + type-check + unit + cypress)
npm test

# Run unit tests in watch mode
npm run test:watch

# Run Cypress E2E tests
npm run test:cypress-ci

# Generate API client from OpenAPI spec
npm run generate:api

# Lint code
npm run test:lint

# Lint with auto-fix
npm run test:lint:fix

# Type check
npm run test:type-check

# Build for production
npm run build
```

## Table of Contents

- [Scope of Responsibility](#scope-of-responsibility)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Skill Playbooks](#skill-playbooks)
- [Skill Selection Matrix](#skill-selection-matrix)
- [Generated Code](#generated-code)
- [Code Conventions](#code-conventions)
- [Common Pitfalls Summary](#common-pitfalls-summary)
- [Cypress Coverage Gate](#cypress-coverage-gate)
- [Troubleshooting](#troubleshooting)
- [Out of Scope](#out-of-scope)
- [Response Contract](#response-contract)
- [Quick Reference](#quick-reference)

**Primary source of truth:** this file + skills in `../../.agents/skills/`.

---

## Scope of Responsibility

Agents may:

- Modify UI components
- Improve performance and readability
- Fix bugs and add tests
- Implement new features within existing patterns

Agents **MUST NOT**:

- Introduce new frameworks or UI libraries without approval
- Change visual design direction without approval
- Modify backend logic or API contracts
- Change authentication or authorization rules

### Frontend Invariants

- Frontend consumes backend API only — no direct Kubernetes calls
- All API interactions use the generated OpenAPI client
- UI state is derived from API responses, not local assumptions
- PatternFly is the single source of truth for UI components

---

## Technology Stack

- **Language**: TypeScript
- **Framework**: React 18+
- **UI Library**: PatternFly v6
- **Build Tool**: Webpack
- **Testing**: Jest, React Testing Library
- **Node.js**: v20.0.0 or later

### Node.js Version

Node.js v20.0.0 or later is required (enforced via `package.json` engines field). Use `nvm use 20` if needed.

---

## Project Structure

```
frontend/
└── src/
    ├── __mocks__/            # Mock data for tests
    ├── __tests__/            # Test files
    ├── app/                  # Main application code
    │   ├── components/       # Reusable React components
    │   ├── context/          # React context providers
    │   ├── hooks/            # Custom React hooks
    │   └── pages/            # Page components
    ├── shared/               # Shared utilities & components
    │   ├── api/              # API client
    │   ├── components/       # Shared components
    │   └── hooks/            # Shared hooks
    ├── generated/            # Generated OpenAPI client (DO NOT EDIT)
    └── images/               # Static assets
```

**Key entry points:**

| To find...            | See...                                                   |
| --------------------- | -------------------------------------------------------- |
| Routes / navigation   | `src/app/AppRoutes.tsx`                                  |
| Main app entry        | `src/app/App.tsx`                                        |
| Sidebar navigation    | `src/app/standalone/NavSidebar.tsx`                      |
| Global context        | `src/app/context/AppContext.tsx`                         |
| Environment variables | `src/shared/utilities/const.ts`                          |
| API hooks             | `src/app/hooks/useWorkspaces.ts`, `useWorkspaceKinds.ts` |
| Reusable components   | `src/app/components/`                                    |
| Page components       | `src/app/pages/`                                         |

**Reference examples (copy these patterns):**

| Pattern                       | Copy from...                                            |
| ----------------------------- | ------------------------------------------------------- |
| Table with filters/pagination | `src/app/components/WorkspaceTable.tsx`                 |
| Data-fetching hook            | `src/app/hooks/useWorkspaces.ts`                        |
| Reusable filter hook          | `src/shared/hooks/useToolbarFilters.ts`                 |
| Page component                | `src/app/pages/Workspaces/Workspaces.tsx`               |
| Delete modal                  | `src/shared/components/DeleteModal.tsx`                 |
| Form drawer                   | `src/app/pages/Workspaces/Form/WorkspaceFormDrawer.tsx` |

**Note:** `src/app/error/ErrorBoundary.tsx` uses a class component — this is required for Error Boundaries and is correct.

---

## Skill Playbooks

Use these skills for executable workflows:

- Guardrails: [`../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md`](../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md)
- Component authoring: [`../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md)
- API integration: [`../../.agents/skills/kubeflow-notebooks-frontend-api-integration/SKILL.md`](../../.agents/skills/kubeflow-notebooks-frontend-api-integration/SKILL.md)
- State/context design: [`../../.agents/skills/kubeflow-notebooks-frontend-state-and-context/SKILL.md`](../../.agents/skills/kubeflow-notebooks-frontend-state-and-context/SKILL.md)
- Hook/effect refactors: [`../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md)
- Jest/RTL testing: [`../../.agents/skills/kubeflow-notebooks-frontend-jest-rtl-testing/SKILL.md`](../../.agents/skills/kubeflow-notebooks-frontend-jest-rtl-testing/SKILL.md)
- Generated artifacts: [`../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md`](../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md)

---

## Skill Selection Matrix

Select every skill that applies to the task. A feature may need multiple skills.

| If the task involves...                       | Core skill                                                                    | Also consider                                                                            |
| --------------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Creating/updating components or pages         | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) | [`kubeflow-notebooks-frontend-jest-rtl-testing`](../../.agents/skills/kubeflow-notebooks-frontend-jest-rtl-testing/SKILL.md) |
| Wiring UI to backend API data                 | [`kubeflow-notebooks-frontend-api-integration`](../../.agents/skills/kubeflow-notebooks-frontend-api-integration/SKILL.md) | [`kubeflow-notebooks-generated-code-regeneration`](../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md) |
| Refactoring state ownership or context usage  | [`kubeflow-notebooks-frontend-state-and-context`](../../.agents/skills/kubeflow-notebooks-frontend-state-and-context/SKILL.md) | [`kubeflow-notebooks-frontend-hook-and-useeffect-refactor`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md) |
| Untangling complex hooks/useEffect behavior   | [`kubeflow-notebooks-frontend-hook-and-useeffect-refactor`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md) | [`kubeflow-notebooks-frontend-jest-rtl-testing`](../../.agents/skills/kubeflow-notebooks-frontend-jest-rtl-testing/SKILL.md) |
| Writing/updating RTL regression coverage      | [`kubeflow-notebooks-frontend-jest-rtl-testing`](../../.agents/skills/kubeflow-notebooks-frontend-jest-rtl-testing/SKILL.md) | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| Changing user flows requiring browser coverage | [`kubeflow-notebooks-cypress-e2e-authoring`](../../.agents/skills/kubeflow-notebooks-cypress-e2e-authoring/SKILL.md) | [`kubeflow-notebooks-cypress-page-object-design`](../../.agents/skills/kubeflow-notebooks-cypress-page-object-design/SKILL.md) |

Fallback:

- If no row clearly matches, use [`kubeflow-notebooks-global-guardrails`](../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md) and ask for clarification.

---

## Generated Code

**Never manually modify:**

- `src/generated/` - OpenAPI client code generated from backend API spec

To regenerate the OpenAPI client:

1. Update `scripts/swagger.version` with the appropriate backend commit reference
2. Run: `npm run generate:api`

---

## Code Conventions

- Follow existing TypeScript patterns in the codebase
- Use functional components with hooks
- Prefer named exports over default exports (except for lazy-loaded routes)
- Keep components focused and single-responsibility
- Extract reusable logic into custom hooks

### File Naming Conventions

- **Components**: PascalCase - `WorkspaceTable.tsx`
- **Hooks**: camelCase with `use` prefix - `useWorkspaces.ts`
- **Utilities**: camelCase - `workspaceUtils.ts`
- **Types**: PascalCase - `types.ts`
- **Test files**: Match source file with `.spec.tsx` or `.spec.ts`

### TypeScript Type Safety (CRITICAL)

**Never use the `any` keyword.**

- Use specific types or interfaces instead
- Use `unknown` if the type is truly unknown, then narrow with type guards
- Use generics for reusable typed components

> **See [Frontend Component Authoring Skill](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md)** for typed component examples.

### Code Cleanliness

> **See [Global AGENTS.md - Code Cleanliness](../../AGENTS.md#code-cleanliness)** for the full rules on TODOs, FIXMEs, and skipped tests.

---

## Common Pitfalls Summary

| Category        | Key Rule                                                     | See Skill                                                                                             |
| --------------- | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Imports**     | Use specific PatternFly imports; avoid barrel imports        | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| **PatternFly**  | Use variants/utilities; do not override styles               | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| **Context**     | Memoize provider values and validate context presence        | [`kubeflow-notebooks-frontend-state-and-context`](../../.agents/skills/kubeflow-notebooks-frontend-state-and-context/SKILL.md) |
| **Environment** | Centralize config in `const.ts`; do not use `process.env` directly | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| **Errors**      | Do not swallow errors silently; show user feedback           | [`kubeflow-notebooks-frontend-api-integration`](../../.agents/skills/kubeflow-notebooks-frontend-api-integration/SKILL.md) |
| **State**       | Use custom hooks with loading/error states                   | [`kubeflow-notebooks-frontend-state-and-context`](../../.agents/skills/kubeflow-notebooks-frontend-state-and-context/SKILL.md) |
| **Rendering**   | Use early returns and avoid nested ternaries                 | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| **Types**       | Avoid `any`; use type guards instead of assertions           | [Code Conventions](#typescript-type-safety-critical)                                                  |
| **Functions**   | Use named object params for 2+ arguments                     | [`kubeflow-notebooks-frontend-component-authoring`](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md) |
| **Hooks**       | Extract complex `useEffect` (3+ state updates) into a custom hook | [`kubeflow-notebooks-frontend-hook-and-useeffect-refactor`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md) |
| **Data Fetch**  | Use `useFetchState` for async loading; avoid manual state wiring | [`kubeflow-notebooks-frontend-api-integration`](../../.agents/skills/kubeflow-notebooks-frontend-api-integration/SKILL.md) |
| **Complexity**  | Refactor functions longer than 30-40 lines or with mixed concerns | [`kubeflow-notebooks-frontend-hook-and-useeffect-refactor`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md) |
| **DRY**         | Extract duplicated code blocks into helper functions          | [`kubeflow-notebooks-frontend-hook-and-useeffect-refactor`](../../.agents/skills/kubeflow-notebooks-frontend-hook-and-useeffect-refactor/SKILL.md) |

---

## Cypress Coverage Gate

**MUST** evaluate Cypress impact for any frontend task that alters user-visible behavior, routing, form submissions, table actions, or API-driven screen states. This gate is not optional.

### Steps

1. **Read** the Cypress module guidelines: [`../frontend/cypress/AGENTS.md`](../frontend/cypress/AGENTS.md). Do not skip this step.
2. **Read** the relevant Cypress skill (typically [`kubeflow-notebooks-cypress-e2e-authoring`](../../.agents/skills/kubeflow-notebooks-cypress-e2e-authoring/SKILL.md)).
3. Evaluate the trigger checklist below.
4. If **any trigger matches**, Cypress tests **MUST** be added or updated in the same changeset. See the decision rules below.
5. Include a `Cypress Gate` section in the final response listing which triggers matched and what tests were added.

### Trigger checklist

Evaluate each item. If **one or more** are true, Cypress tests are **required** — not optional, not deferred.

- [ ] New route or page added
- [ ] Form behavior changed (fields, validation, submission)
- [ ] Table row actions added or modified
- [ ] Navigation flow changed
- [ ] Modal or drawer added or modified
- [ ] Delete/create/update workflow changed

### Decision rules

- **One or more triggers match → add Cypress tests.** "Recommend as follow-up" or "existing coverage is sufficient" are not acceptable justifications for skipping. New user flows require new test coverage even if they reuse existing components.
- **No triggers match → skip is acceptable.** Include a `Cypress Gate` section stating no triggers matched and why.
- **Genuinely blocked** (e.g., test infrastructure missing, external dependency unavailable) → state the blocker explicitly. This is the only valid reason to defer when triggers match.

---

## Troubleshooting

### Common Issues

| Issue                            | Cause                                  | Solution                                           |
| -------------------------------- | -------------------------------------- | -------------------------------------------------- |
| **API client out of date**       | `swagger.version` not updated          | Update version and run `npm run generate:api`      |
| **Build fails with type errors** | Generated types changed                | Regenerate API client, update component types      |
| **Tests fail with mock errors**  | Mock data doesn't match new API schema | Update mock builders in `src/__mocks__/`           |
| **Context undefined error**      | Component outside provider             | Wrap component tree with required context provider |
| **Infinite re-render loop**      | Missing dependency in useEffect        | Check and fix dependency arrays                    |

### Debugging Tips

```bash
# Check if API client is current
npm run generate:api && git diff src/generated/

# Run specific test file
npm test -- --testPathPattern="WorkspaceTable"

# Check for TypeScript errors
npm run test:type-check

# Check for lint errors with details
npm run test:lint -- --format stylish
```

---

## Out of Scope

The following are handled by other modules and **MUST NOT** be modified in frontend changes:

- Backend logic and business rules (belongs to [backend module](../backend/AGENTS.md))
- API contract changes (handled by [backend module](../backend/AGENTS.md))
- Authentication or authorization implementation (belongs to [backend module](../backend/AGENTS.md))
- Kubernetes resource definitions (belongs to [controller module](../controller/AGENTS.md))
- Database or storage logic

---

## Response Contract

Follow the [global response contract](../../AGENTS.md#response-contract).

---

## Quick Reference

### Critical Rules

| Rule                                                   | Severity   |
| ------------------------------------------------------ | ---------- |
| Never talk directly to Kubernetes                      | MUST NOT   |
| Never modify `src/generated/` files                    | MUST NOT   |
| Never introduce new UI libraries without approval      | MUST NOT   |
| Avoid using `any` type - use proper types or `unknown` | SHOULD NOT |
| Always use PatternFly components                       | MUST       |
| Always add `data-testid` for testable elements         | MUST       |
| Always handle loading and error states                 | SHOULD     |
| Always use TypeScript strict mode                      | SHOULD     |
| Extract useEffect with 3+ state updates to custom hook | SHOULD     |
| Use `useFetchState` for async data fetching            | SHOULD     |
| Refactor functions >30-40 lines or mixing concerns     | SHOULD     |
| Extract duplicated code blocks into helpers            | SHOULD     |

### Key Files

| Purpose                | Location                 |
| ---------------------- | ------------------------ |
| Components             | `src/app/components/`    |
| Pages                  | `src/app/pages/`         |
| API client (generated) | `src/generated/`         |
| Shared utilities       | `src/shared/`            |
| Test mocks             | `src/__mocks__/`         |
| Cypress tests          | `src/__tests__/cypress/` |

### Component Pattern Template

> **See [Frontend Component Authoring Skill](../../.agents/skills/kubeflow-notebooks-frontend-component-authoring/SKILL.md)** for the current component template workflow.
