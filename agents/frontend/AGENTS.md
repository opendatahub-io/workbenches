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
# Start development server
npm run start:dev

# Run unit tests
npm test

# Run unit tests in watch mode
npm run test:watch

# Run Cypress E2E tests
npm run test:cypress-ci

# Generate API client from OpenAPI spec
npm run generate:api

# Lint code
npm run test:lint

# Type check
npm run test:type-check

# Build for production
npm run build
```

## Table of Contents

- [Scope of Responsibility](#scope-of-responsibility)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Generated Code](#generated-code)
- [Development Commands](#development-commands)
- [Code Conventions](#code-conventions)
- [Common Pitfalls Summary](#common-pitfalls-summary)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Out of Scope](#out-of-scope)
- [Quick Reference](#quick-reference)

**For detailed patterns and examples, see [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md).**

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

The frontend requires Node.js v20.0.0 or later. This is enforced via `package.json` engines field.

```bash
node --version  # Should output v20.x.x or higher
nvm install 20
nvm use 20
```

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

## Generated Code

**Never manually modify:**

- `src/generated/` - OpenAPI client code generated from backend API spec

To regenerate the OpenAPI client:

1. Update `scripts/swagger.version` with the appropriate backend commit reference
2. Run: `npm run generate:api`

---

## Development Commands

See [Quick Commands](#quick-commands) at the top of this file for common commands.

**Additional options:**

```bash
# Install dependencies
npm ci

# Run linter with auto-fix
npm run test:lint:fix

# Run all tests (lint + type-check + unit + cypress)
npm run test
```

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

> **See [AGENTS-PATTERNS.md - TypeScript Type Safety](./AGENTS-PATTERNS.md#typescript-type-safety-critical)** for examples.

### Code Cleanliness

> **See [Global AGENTS.md - Code Cleanliness](../../AGENTS.md#code-cleanliness)** for the full rules on TODOs, FIXMEs, and skipped tests.

---

## Common Pitfalls Summary

| Category        | Key Rule                                                   | See Patterns                                                                   |
| --------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Imports**     | Use specific PatternFly imports, not barrel imports        | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#import-patterns)                     |
| **PatternFly**  | Use variants/utilities, never override styles              | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#ui--ux-guidelines)                   |
| **Context**     | Always memoize provider values, validate context exists    | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#react-context-patterns)              |
| **Environment** | Centralize in `const.ts`, never use `process.env` directly | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#constants-and-environment-variables) |
| **Errors**      | Never swallow silently, always show user feedback          | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#error-handling-patterns)             |
| **State**       | Use custom hooks with loading/error states                 | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#state--data-flow)                    |
| **Rendering**   | Use early returns, avoid nested ternaries                  | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#code-conventions)                    |
| **Types**       | Avoid `any`, use type guards over assertions               | [Code Conventions](#typescript-type-safety-critical)                           |
| **Functions**   | Use named object params for 2+ arguments                   | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#function-signature-patterns)         |
| **Hooks**       | Extract complex useEffect (3+ state updates) to custom hook | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#useeffect-anti-patterns)             |
| **Data Fetch**  | Use `useFetchState` for async data loading, not manual state | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#custom-hook-patterns)                |
| **Functions**   | Refactor functions >30-40 lines or mixing multiple concerns  | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#function-complexity)                 |
| **DRY**         | Extract duplicated code blocks into helper functions         | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#function-complexity)                 |

---

## Common Tasks

### Adding a new page

1. Create component in `src/app/pages/`
2. Add route in `src/app/routes.ts`
3. Update `src/app/AppRoutes.tsx`
4. Add tests

### Adding a new API endpoint integration

1. Wait for backend API changes to be merged
2. Update `scripts/swagger.version` with new backend commit
3. Regenerate OpenAPI client: `npm run generate:api`
4. Use generated client in `src/shared/api/`
5. Add appropriate error handling

### Adding a new shared component

1. Create component in `src/shared/components/`
2. Write tests
3. Export from appropriate index file
4. Document props with TypeScript types

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
- API contract changes (handled by [backend module](../backend/AGENTS.md#swagger--openapi-patterns))
- Authentication or authorization implementation (belongs to [backend module](../backend/AGENTS.md#authentication--authorization))
- Kubernetes resource definitions (belongs to [controller module](../controller/AGENTS.md#custom-resource-definitions-crds))
- Database or storage logic

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

> **See [AGENTS-PATTERNS.md - Component Pattern Template](./AGENTS-PATTERNS.md#component-pattern-template)** for the full template.

### Pre-Task Checklist

- [ ] Check if API changes are needed (requires separate PR)
- [ ] Update `swagger.version` if API changed
- [ ] Run `npm run generate:api` after API updates
- [ ] Follow existing component patterns
- [ ] Add `data-testid` attributes for Cypress
- [ ] Handle loading, error, and empty states
- [ ] Add/update unit tests
