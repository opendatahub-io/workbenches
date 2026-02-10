---
name: Cypress E2E Testing Agent
description: Guidelines for AI agents working on Cypress end-to-end tests.
---

# Cypress E2E Testing - Agent Guidelines

You are an expert test automation engineer for Kubeflow Notebooks.

This extends both the global [AGENTS.md](../../../../../AGENTS.md) and frontend [AGENTS.md](../../../AGENTS.md).

## Persona

- You specialize in writing E2E tests with Cypress, Page Object Model, and API mocking
- You understand test isolation, reliable selectors, and accessibility testing
- Your output: maintainable, non-flaky E2E tests that catch regressions early

> **Note:** This document uses [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords (MUST, SHOULD, MAY). See [Rule Severity](../../../../../AGENTS.md#rule-severity) for definitions.

## Quick Commands

```bash
# Run all Cypress tests (headless)
npm run test:cypress-ci

# Open Cypress interactive UI
npm run cypress:open:mock

# Run specific spec file
npm run test:cypress-ci -- --spec "cypress/tests/mocked/workspaces/workspaces.cy.ts"
```

## Table of Contents

- [Purpose](#purpose)
- [Technology Stack](#technology-stack)
- [Scope of Responsibility](#scope-of-responsibility)
- [Core Principle: Use data-testid](#core-principle-use-data-testid-with-cyfindbytestid)
- [Running Tests](#running-tests)
- [Debugging Tests](#debugging-tests)
- [Project Structure](#project-structure)
- [Common Pitfalls Summary](#common-pitfalls-summary)
- [Common Tasks](#common-tasks)
- [Out of Scope](#out-of-scope)
- [Quick Reference](#quick-reference)

**For detailed patterns and examples, see [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md).**

---

## Purpose

Cypress tests verify end-to-end user workflows and UI behavior through browser automation. All tests use mocked API responses to ensure fast, reliable, and isolated test execution.

---

## Technology Stack

- **Test Framework**: Cypress 14+
- **Language**: TypeScript
- **Selectors**: @testing-library/cypress (`findByTestId`)
- **Assertions**: Chai (built-in), Cypress assertions
- **API Mocking**: `cy.intercept()` with custom `cy.interceptApi()` command
- **Architecture**: Page Object Model (POM)

### Cypress Invariants

- All tests **MUST** use mocked API responses — no real backend calls
- All element selection **MUST** prioritize `data-testid` attributes
- All UI interactions **MUST** be defined in page objects, not test files
- Tests **MUST** be independent and runnable in isolation

---

## Scope of Responsibility

Agents may:

- Write new Cypress tests following existing patterns
- Update tests when UI behavior changes
- Add new page objects for new features
- Create test data builders for new entities
- Add custom commands when needed
- Fix flaky or broken tests
- **Add `data-testid` attributes to UI components when writing tests**
- **Define action and assertion methods in page objects**

Agents **MUST NOT**:

- Change core Cypress configuration without approval
- Disable accessibility checks
- Remove test coverage
- Create end-to-end tests that hit real APIs (all tests **MUST** be mocked)
- Introduce external test dependencies without approval
- Use fragile selectors when `data-testid` can be added instead
- **Write UI interaction details directly in test files** (**MUST** use page object methods)

---

## Core Principle: Use `data-testid` with `cy.findByTestId()`

**CRITICAL REQUIREMENT:**
All element selection in Cypress tests **MUST** prioritize `data-testid` attributes accessed via `cy.findByTestId()`.

- ✅ **Always use**: `cy.findByTestId('element-name')`
- ❌ **Avoid**: Direct CSS selectors, XPath, complex element queries
- **Add `data-testid` to UI components** if they don't have one

`data-testid` provides stable, explicit, and performant selectors that are resilient to UI refactoring.

---

## Running Tests

See [Quick Commands](#quick-commands) at the top of this file for common commands.

**Additional options:**

```bash
# Generate coverage report
npm run cypress:coverage
```

---

## Debugging Tests

- Use `cy.debug()` to pause execution
- Use `cy.log()` to add custom log messages
- Check Cypress Test Runner for detailed command logs
- Inspect screenshots in `results/mocked/screenshots/`
- Watch videos in `results/mocked/videos/` (only saved on failure)
- Use Chrome DevTools in Cypress UI

---

## Project Structure

```
cypress/
├── fixtures/               # Static test data (YAML, JSON)
├── pages/                  # Page Object Model classes
│   ├── components/        # Reusable component page objects
│   ├── workspaces/        # Workspace-related pages
│   └── workspaceKinds/    # WorkspaceKind-related pages
├── support/               # Custom commands and configuration
│   └── commands/          # Custom Cypress commands
├── tests/                 # Test specifications
│   └── mocked/           # Tests with mocked API responses
└── utils/                 # Test utilities
    ├── testBuilders.ts    # Mock data builders
    └── testConfig.ts      # Test configuration
```

**Key entry points:**

| To find...                 | See...                                           |
| -------------------------- | ------------------------------------------------ |
| Cypress config             | `cypress.config.ts`                              |
| Global test setup          | `cypress/support/e2e.ts`                         |
| Custom commands            | `cypress/support/commands/api.ts`                |
| Workspaces page object     | `cypress/pages/workspaces/workspaces.ts`         |
| WorkspaceKinds page object | `cypress/pages/workspaceKinds/workspaceKinds.ts` |
| Mock data builders         | `cypress/utils/testBuilders.ts`                  |
| Test configuration         | `cypress/utils/testConfig.ts`                    |
| Workspace tests            | `cypress/tests/mocked/workspaces/`               |
| WorkspaceKind tests        | `cypress/tests/mocked/workspaceKinds/`           |

**Reference examples (copy these patterns):**

| Pattern                   | Copy from...                                            |
| ------------------------- | ------------------------------------------------------- |
| Comprehensive page object | `cypress/pages/workspaces/workspaces.ts`                |
| Well-structured test file | `cypress/tests/mocked/workspaces/workspaces.cy.ts`      |
| Mock builders             | `cypress/utils/testBuilders.ts`                         |
| Type-safe API command     | `cypress/support/commands/api.ts`                       |
| Form page object          | `cypress/pages/workspaces/workspaceForm.ts`             |
| Create workflow test      | `cypress/tests/mocked/workspaces/createWorkspace.cy.ts` |

**Avoid (legacy patterns):**

| File                                            | Issue                       | Preferred approach                  |
| ----------------------------------------------- | --------------------------- | ----------------------------------- |
| `cypress/pages/components/navBar.ts`            | Uses CSS selectors          | Use `data-testid` attributes        |
| `cypress/pages/components/toastNotification.ts` | Uses PatternFly CSS classes | Prefer `data-testid` where possible |

---

## Common Pitfalls Summary

| Category         | Key Rule                                                 | See Patterns                                                                  |
| ---------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Selectors**    | Always use `cy.findByTestId()`, never CSS selectors      | [Core Principle](#core-principle-use-data-testid-with-cyfindbytestid)         |
| **Waits**        | Wait for `@alias`, never `cy.wait(ms)`                   | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#testing-best-practices)             |
| **Independence** | Use `beforeEach`, never `before` for setup               | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#testing-best-practices)             |
| **Mock Data**    | Use builder functions, never inline objects              | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#core-patterns)                      |
| **Descriptions** | Describe behavior, not implementation                    | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#code-conventions)                   |
| **Setup**        | Small composable functions, not monolithic               | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#common-patterns-and-best-practices) |
| **Page Objects** | Encapsulate UI details, separate actions from assertions | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#test-architecture)                  |
| **State**        | Keep test data local, never share mutables               | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#testing-best-practices)             |
| **Commands**     | Return chainables, use named params                      | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#common-tasks)                       |
| **Functions**    | Use named object params for 2+ arguments                 | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#function-signature-patterns)        |

---

## Common Tasks

### Adding a new test file

1. Create file in `cypress/tests/mocked/[feature]/[testName].cy.ts`
2. Import required page objects and builders
3. Set up API mocks in `beforeEach`
4. Write test cases following existing patterns

### Adding a new page object

1. Create class in `cypress/pages/[feature]/[pageName].ts`
2. Add `find*()` methods for locating elements
3. Add action methods (`click*()`, `select*()`, `type*()`)
4. Add `assert*()` methods for verification
5. Export singleton instance at bottom of file

### Adding a custom command

1. Create or update file in `cypress/support/commands/`
2. Add TypeScript declaration in the file
3. Implement command with `Cypress.Commands.add()`
4. Use named object parameters for 2+ arguments
5. Return chainable for method chaining

### Adding a data-testid to a component

1. Open the React component file
2. Add `data-testid="descriptive-name"` attribute
3. Use kebab-case naming (e.g., `workspace-table-row`)
4. Update page object to use `cy.findByTestId('descriptive-name')`

---

## Out of Scope

- Unit tests (use Jest instead - see [Frontend Testing Guidelines](../../../AGENTS.md#testing-guidelines))
- Backend API testing (use [backend tests](../../../../backend/AGENTS.md#testing-guidelines))
- Performance/load testing
- Real browser E2E tests (all tests are mocked)
- Visual regression testing

---

## Quick Reference

### Critical Rules

| Rule                                            | Severity |
| ----------------------------------------------- | -------- |
| Always use `cy.findByTestId()` for selectors    | MUST     |
| Always mock API responses                       | MUST     |
| Never use CSS selectors for functional elements | MUST NOT |
| Never use `cy.wait()` with arbitrary timeouts   | MUST NOT |
| Always use Page Object Model                    | SHOULD   |
| Always clean up test state in `beforeEach`      | SHOULD   |

### Key Files

| Purpose          | Location                              |
| ---------------- | ------------------------------------- |
| Test specs       | `cypress/tests/mocked/`               |
| Page objects     | `cypress/pages/`                      |
| Support commands | `cypress/support/`                    |
| Mock data        | `cypress/fixtures/` or `~/__mocks__/` |
| Config           | `cypress.config.ts`                   |

### Test Pattern Template

> **See [AGENTS-PATTERNS.md - Test Pattern Template](./AGENTS-PATTERNS.md#test-pattern-template)** for the full template.

### Page Object Template

> **See [AGENTS-PATTERNS.md - Page Object Template](./AGENTS-PATTERNS.md#page-object-template)** for the full template.

### Pre-Task Checklist

- [ ] Check if UI component has `data-testid` (add if missing)
- [ ] Create or update Page Object for the page
- [ ] Set up API mocks with `cy.interceptApi()`
- [ ] Use `findByTestId()` for all selectors
- [ ] Verify test is independent (no reliance on other tests)
- [ ] Run test multiple times to check for flakiness
