---
name: Cypress E2E Testing Agent - Patterns
description: Detailed code patterns and examples for Cypress end-to-end tests.
---

# Cypress E2E Testing - Detailed Patterns

This file contains detailed patterns and examples for Cypress E2E testing.

**For essential guidelines, see [AGENTS.md](./AGENTS.md).**

---

## Table of Contents

- [Test Architecture](#test-architecture)
- [Core Patterns](#core-patterns)
- [Code Conventions](#code-conventions)
- [Testing Best Practices](#testing-best-practices)
- [Common Patterns and Best Practices](#common-patterns-and-best-practices)
- [Common Tasks](#common-tasks)
- [Performance Considerations](#performance-considerations)
- [Handling Flaky Tests](#handling-flaky-tests)

---

## Test Architecture

### Page Object Model (POM)

**CRITICAL: All UI interactions MUST be defined in page objects, not in test files.**

Tests use the Page Object Model pattern:

- **Location**: `cypress/pages/`
- **Structure**: Each page/component has its own class with:
  - `find*()` methods - Locate DOM elements
  - `click*()` methods - Click actions
  - `select*()` / `choose*()` methods - Selection actions
  - `apply*()` / `toggle*()` methods - State changes
  - `assert*()` methods - Verify UI state
  - `verify*()` methods - Complex verifications
- **Instantiation**: Export singleton instances

**Example - Clean test code:**

```typescript
// ❌ BAD - test file with implementation details
it('should delete a workspace', () => {
  cy.visit('/workspaces');
  cy.wait('@getWorkspaces');
  cy.findByTestId('workspaces-table')
    .find('tbody tr')
    .first()
    .findByTestId('action-column')
    .find('button')
    .click();
  cy.findByTestId('action-delete').click();
  cy.findByTestId('delete-modal').should('exist');
  cy.findByTestId('delete-modal-input').type('test-workspace');
  cy.findByTestId('delete-button').click();
  cy.wait('@deleteWorkspace');
  cy.findByTestId('workspaces-table').find('tbody tr').should('have.length', 0);
});

// ✅ GOOD - clean, readable test code
it('should delete a workspace', () => {
  workspaces.visit();
  cy.wait('@getWorkspaces');

  workspaces.clickDeleteAction('test-workspace');
  deleteModal.assertModalExists();
  deleteModal.typeConfirmation('test-workspace');
  deleteModal.clickDeleteButton();

  cy.wait('@deleteWorkspace');
  workspaces.assertWorkspaceCount(0);
});
```

**Page Object Implementation:**

```typescript
class Workspaces {
  visit() {
    cy.visit('/workspaces');
  }

  findWorkspacesTable() {
    return cy.findByTestId('workspaces-table');
  }

  findWorkspaceRow(workspaceName: string) {
    return this.findWorkspacesTable()
      .find('tbody tr')
      .filter(`:contains("${workspaceName}")`)
      .first();
  }

  clickDeleteAction(workspaceName: string) {
    this.findWorkspaceRow(workspaceName).findByTestId('action-column').find('button').click();
    cy.findByTestId('action-delete').click();
  }

  applyFilter(args: { key: string; value: string }) {
    const { key, value } = args;
    cy.findByTestId('filter-dropdown').click();
    cy.findByTestId(`filter-dropdown-${key}`).click();
    cy.findByTestId(`filter-${key}-input`).type(value);
  }

  assertWorkspaceCount(count: number) {
    this.findWorkspacesTable().find('tbody tr').should('have.length', count);
  }
}

class DeleteModal {
  findModal() {
    return cy.findByTestId('delete-modal');
  }

  typeConfirmation(text: string) {
    this.findModal().findByTestId('delete-modal-input').type(text);
  }

  clickDeleteButton() {
    this.findModal().findByTestId('delete-button').click();
  }

  assertModalExists() {
    this.findModal().should('exist');
  }
}

export const workspaces = new Workspaces();
export const deleteModal = new DeleteModal();
```

---

## Core Patterns

### Test Pattern Template

```typescript
import { mockModArchResponse } from 'mod-arch-core';
import { myPage } from '~/__tests__/cypress/cypress/pages/myFeature/myPage';
import {
  buildMockNamespace,
  buildMockWorkspace,
  buildMockWorkspaceKindInfo,
} from '~/shared/mock/mockBuilder';
import { NOTEBOOKS_API_VERSION } from '~/__tests__/cypress/cypress/support/commands/api';
import { navBar } from '~/__tests__/cypress/cypress/pages/components/navBar';

const DEFAULT_NAMESPACE = 'default';

type NamespaceSetup = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockWorkspaces: ReturnType<typeof buildMockWorkspace>[];
};

const setupWorkspaces = (namespaceName: string, workspaceCount: number): NamespaceSetup => {
  const mockNamespace = buildMockNamespace({ name: namespaceName });
  const mockWorkspaceKind = buildMockWorkspaceKindInfo({ name: 'jupyterlab' });
  const mockWorkspaces = Array.from({ length: workspaceCount }, (_, i) =>
    buildMockWorkspace({
      name: `Workspace ${i + 1}`,
      namespace: mockNamespace.name,
      workspaceKind: mockWorkspaceKind,
    }),
  );

  cy.interceptApi(
    'GET /api/:apiVersion/namespaces',
    { path: { apiVersion: NOTEBOOKS_API_VERSION } },
    mockModArchResponse([mockNamespace]),
  ).as('getNamespaces');

  cy.interceptApi(
    'GET /api/:apiVersion/workspaces/:namespace',
    { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: mockNamespace.name } },
    mockModArchResponse(mockWorkspaces),
  ).as('getWorkspaces');

  return { mockNamespace, mockWorkspaces };
};

const navigateToWorkspaces = (namespaceName: string): void => {
  myPage.visit();
  cy.wait('@getNamespaces');
  navBar.selectNamespace(namespaceName);
  cy.wait('@getWorkspaces');
};

describe('Feature Name', () => {
  beforeEach(() => {
    setupWorkspaces(DEFAULT_NAMESPACE, 5);
  });

  it('should perform expected action', () => {
    navigateToWorkspaces(DEFAULT_NAMESPACE);
    myPage.findActionButton().click();
    myPage.assertResultText('Expected');
  });
});
```

### Page Object Template

```typescript
class MyPage {
  readonly MY_PAGE_ROUTE = '/my-route';

  visit() {
    cy.visit(this.MY_PAGE_ROUTE);
    this.wait();
  }

  findPageTitle() {
    return cy.findByTestId('app-page-title').should('exist').and('contain', 'My Page');
  }

  verifyPageURL() {
    return cy.verifyRelativeURL(this.MY_PAGE_ROUTE);
  }

  private wait() {
    this.findPageTitle();
    cy.testA11y();
  }

  findActionButton() {
    return cy.findByTestId('action-button');
  }

  findResultElement() {
    return cy.findByTestId('result-element');
  }

  assertResultText(expectedText: string) {
    this.findResultElement().should('contain.text', expectedText);
  }
}

export const myPage = new MyPage();
```

### 1. API Mocking

```typescript
import { mockModArchResponse } from 'mod-arch-core';
import { NOTEBOOKS_API_VERSION } from '~/__tests__/cypress/cypress/support/commands/api';

// GET list requests
cy.interceptApi(
  'GET /api/:apiVersion/namespaces',
  { path: { apiVersion: NOTEBOOKS_API_VERSION } },
  mockModArchResponse([mockNamespace]),
).as('getNamespaces');

cy.interceptApi(
  'GET /api/:apiVersion/workspaces/:namespace',
  { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: 'default' } },
  mockModArchResponse(mockWorkspaces),
).as('getWorkspaces');

// GET single resource
cy.interceptApi(
  'GET /api/:apiVersion/workspaces/:namespace/:workspaceName',
  {
    path: {
      apiVersion: NOTEBOOKS_API_VERSION,
      namespace: 'default',
      workspaceName: 'my-workspace',
    },
  },
  mockModArchResponse(mockWorkspace),
).as('getWorkspace');

// POST/PUT/DELETE
cy.interceptApi(
  'POST /api/:apiVersion/workspaces/:namespace',
  { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: 'default' } },
  mockModArchResponse(mockWorkspace),
).as('createWorkspace');

cy.interceptApi(
  'DELETE /api/:apiVersion/workspaces/:namespace/:workspaceName',
  { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: 'default', workspaceName: 'test' } },
  undefined,
).as('deleteWorkspace');

// Wait for requests
cy.wait('@getNamespaces');
cy.wait('@getWorkspaces');
```

**Rules:**

- Always alias intercepted requests with `.as('requestName')`
- Wait for requests before making assertions
- Use `mockModArchResponse()` to wrap response data
- Import `NOTEBOOKS_API_VERSION` from `support/commands/api`
- For DELETE requests without response body, use `undefined` as response

### 2. Test Data Builders

```typescript
import {
  buildMockNamespace,
  buildMockWorkspace,
  buildMockWorkspaceList,
  buildMockWorkspaceKind,
  buildMockWorkspaceKindInfo,
  buildMockPodTemplate,
  buildMockOptionInfo,
} from '~/shared/mock/mockBuilder';
import { WorkspacesWorkspaceState } from '~/generated/data-contracts';

const mockWorkspace = buildMockWorkspace({
  name: 'test-workspace',
  namespace: 'default',
  workspaceKind: buildMockWorkspaceKindInfo({ name: 'jupyterlab' }),
  state: WorkspacesWorkspaceState.WorkspaceStateRunning,
});
```

**Available builders** (from `~/shared/mock/mockBuilder`):

- `buildMockNamespace()` - Creates mock namespace
- `buildMockWorkspace()` - Creates single workspace
- `buildMockWorkspaceList()` - Creates multiple workspaces
- `buildMockWorkspaceKind()` - Creates workspace kind definition
- `buildMockWorkspaceKindInfo()` - Creates workspace kind info (name/displayName)
- `buildMockPodTemplate()` - Creates pod template with options
- `buildMockOptionInfo()` - Creates option info (id, displayName, description, labels)
- `buildPodTemplateOptions()` - Creates pod template options structure
- `buildMockImageConfig()` / `buildMockPodConfig()` - Creates image/pod config

**Additional test builders** (from `~/__tests__/cypress/cypress/utils/testBuilders`):

- `buildMockWorkspaceWithGPU()` - Workspace with GPU configuration
- `buildMockWorkspaceWithImage()` - Workspace with specific image
- `buildMockWorkspaceWithPodConfig()` - Workspace with custom pod config
- `createMockPodTemplateWithImage()` - Simple pod template with image name

### 3. Test Organization

```typescript
describe('Feature Name', () => {
  describe('Sub-feature', () => {
    beforeEach(() => {
      // Setup common to all tests
    });

    it('should do something specific', () => {
      // Arrange, Act, Assert
    });
  });
});
```

### 4. Accessibility Testing

Every page **MUST** be tested for accessibility:

```typescript
workspaces.visit();
cy.wait('@getWorkspaces');
workspaces.findPageTitle();
cy.testA11y();
```

---

## Code Conventions

### Test File Structure

```typescript
import {} from '~/__tests__/cypress/cypress/pages/...';
import {} from '~/shared/mock/mockBuilder';
import {} from '~/generated/data-contracts';

const DEFAULT_NAMESPACE = 'default';
const TEST_WORKSPACE_NAME = 'TestWorkspace';

type SetupResult = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
};

const setupTest = (): SetupResult => {
  // Setup logic
};

describe('Feature', () => {
  // Tests
});
```

### Naming Conventions

**File and Class Names:**

- **Test files**: `featureName.cy.ts`
- **Page objects**: `featureName.ts`
- **Page object classes**: PascalCase
- **Page object instances**: camelCase

**Method Names in Page Objects:**

- **`find*()`** - Returns Cypress chainable for element location
- **`click*()`** - Performs click actions
- **`select*()` / `choose*()`** - Selection actions
- **`apply*()`** - Applies settings, filters
- **`toggle*()`** - Toggles states
- **`type*()` / `enter*()`** - Text input
- **`assert*()`** - Verifies UI state
- **`verify*()`** - Complex verifications

**Test Descriptions:**

| Pattern                              | Example                                      | When to Use |
| ------------------------------------ | -------------------------------------------- | ----------- |
| `should [verb] [object]`             | `should display workspaces`                  | Default     |
| `should [verb] when [condition]`     | `should display error when API fails`        | Conditional |
| `should not [verb] when [condition]` | `should not show delete button when running` | Negative    |
| `should [verb] after [action]`       | `should refresh list after deletion`         | Sequential  |

### TypeScript Type Safety

> **See [Frontend AGENTS.md - TypeScript Type Safety](../../../AGENTS.md#typescript-type-safety-critical)** for general patterns.

**CRITICAL: Never use the `any` keyword.**

```typescript
// Bad
const setupTest = (data: any) => {
  /* ... */
};

// Good
type SetupResult = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
};

const setupTest = (): SetupResult => {
  /* ... */
};
```

### Selectors

**CRITICAL: Always prefer `data-testid` attributes with `cy.findByTestId()`**

**Priority order:**

1. **`data-testid` (STRONGLY PREFERRED)**: `cy.findByTestId('workspace-name')`
2. **Accessible roles**: `cy.findByRole('button', { name: 'Create' })`
3. **Text content**: `cy.contains('Workspaces')` (sparingly)
4. **CSS classes**: Only as last resort

```typescript
// Excellent
findWorkspacesTable() {
  return cy.findByTestId('workspaces-table');
}

// Acceptable when data-testid not available
findCreateButton() {
  return cy.findByRole('button', { name: 'Create workspace' });
}

// Avoid
findWorkspacesTable() {
  return cy.get('.pf-v6-c-table tbody');
}
```

**Never use:**

- Element IDs (except for forms)
- Complex CSS selectors
- XPath selectors
- Direct element selectors

---

## Testing Best Practices

### 1. Test Independence

- Each test **MUST** be independent and runnable in isolation
- Use `beforeEach()` for common setup, not `before()`
- Don't rely on test execution order

### 2. Skipped Tests

**Avoid skipping tests. If absolutely necessary, include a ticket reference:**

```typescript
// Skip until backend API supports pagination (#1234)
it.skip('should paginate large result sets', () => {
  // Test implementation
});
```

### 3. Waiting Strategies

- Always wait for API calls before assertions: `cy.wait('@aliasName')`
- Use implicit waits via Cypress commands (they auto-retry)
- Avoid explicit `cy.wait(milliseconds)`

```typescript
// Good
cy.wait('@getWorkspaces');
workspaces.assertWorkspaceCount(5);

// Avoid
cy.wait(1000);
workspaces.assertWorkspaceCount(5);
```

### 4. Error Handling

Test both success and error scenarios:

```typescript
it('should display error in modal when delete fails', () => {
  cy.interceptApi(
    'DELETE /api/:apiVersion/workspaces/:namespace/:workspaceName',
    {
      path: {
        apiVersion: NOTEBOOKS_API_VERSION,
        namespace: DEFAULT_NAMESPACE,
        workspaceName: 'test-workspace',
      },
    },
    {
      error: {
        code: '500',
        message: 'Failed to delete workspace',
      },
    },
  ).as('deleteWorkspaceError');

  workspaces.findAction({ action: 'delete', workspaceName: 'test-workspace' }).click();
  deleteModal.findConfirmationInput().type('test-workspace');
  deleteModal.findSubmitButton().click();

  cy.wait('@deleteWorkspaceError');

  deleteModal.assertModalExists();
  deleteModal.assertErrorAlertContainsMessage('Error: Failed to delete workspace');
});

it('should delete workspace successfully', () => {
  cy.interceptApi(
    'DELETE /api/:apiVersion/workspaces/:namespace/:workspaceName',
    {
      path: {
        apiVersion: NOTEBOOKS_API_VERSION,
        namespace: DEFAULT_NAMESPACE,
        workspaceName: 'test-workspace',
      },
    },
    undefined,
  ).as('deleteWorkspace');

  workspaces.findAction({ action: 'delete', workspaceName: 'test-workspace' }).click();
  deleteModal.findConfirmationInput().type('test-workspace');
  deleteModal.findSubmitButton().click();

  cy.wait('@deleteWorkspace').then((interception) => {
    expect(interception.response?.statusCode).to.be.equal(200);
  });

  deleteModal.assertModalNotExists();
});
```

### 5. Comprehensive Test Coverage

Test for each feature:

- **Happy path** - Normal successful workflow
- **Empty states** - No data scenarios
- **Edge cases** - Boundary conditions
- **Error handling** - Failed API calls
- **User interactions** - Clicks, typing, navigation
- **State transitions** - Moving between states
- **Filtering and sorting** - If applicable
- **Pagination** - If applicable
- **Modal interactions** - Open, cancel, submit, error states
- **Accessibility** - Screen reader support, keyboard navigation

---

## Common Patterns and Best Practices

### Page Object Pattern: Keep Tests Readable

**The Golden Rule: Tests should read like user stories.**

```typescript
// ❌ BAD - Technical implementation
it('should create a workspace', () => {
  cy.visit('/workspaces');
  cy.findByTestId('create-button').click();
  cy.findByTestId('name-input').type('my-workspace');
  cy.findByTestId('namespace-dropdown').click();
  cy.findByTestId('namespace-option-default').click();
  cy.findByTestId('submit-button').click();
  cy.wait('@createWorkspace');
  cy.findByTestId('workspaces-table').find('tbody tr').should('contain', 'my-workspace');
});

// ✅ GOOD - Readable, story-like
it('should create a workspace', () => {
  workspaces.visit();
  workspaces.clickCreateWorkspace();

  workspaceForm.enterWorkspaceName('my-workspace');
  workspaceForm.selectNamespace('default');
  workspaceForm.clickSubmit();

  cy.wait('@createWorkspace');
  workspaces.assertWorkspaceExists('my-workspace');
});
```

### Function Signature Patterns

> **See [Frontend AGENTS.md - Function Signature Patterns](../../../AGENTS.md#function-signature-patterns)** for the full pattern.

**Page object methods with multiple parameters use named parameters:**

```typescript
// Named parameters for methods with multiple arguments
workspaces.findAction({ action: 'delete', workspaceName: 'test' });
workspaces.applyFilter({ key: 'name', value: 'workspace', name: 'Name' });
```

**Setup functions use positional parameters for simplicity:**

```typescript
// Positional parameters for setup functions
setupSingleNamespaceWorkspaces('default', 10);
setupSingleNamespaceWorkspaces('default', 5, 'jupyterlab');

// Helper functions for test steps use positional parameters
navigateToNamespace('default');
selectWorkspaceKind('jupyterlab');
```

### Test Data Management

```typescript
import { mockModArchResponse } from 'mod-arch-core';
import {
  buildMockNamespace,
  buildMockWorkspaceList,
  buildMockWorkspaceKindInfo,
} from '~/shared/mock/mockBuilder';
import { NOTEBOOKS_API_VERSION } from '~/__tests__/cypress/cypress/support/commands/api';

const DEFAULT_NAMESPACE = 'default';
const KUBEFLOW_NAMESPACE = 'kubeflow';
const DEFAULT_PAGE_SIZE = 10;
const TEST_WORKSPACE_NAME = 'Workspace';

type NamespaceSetup = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
};

type MultiNamespaceSetup = {
  mockDefaultNs: ReturnType<typeof buildMockNamespace>;
  mockKubeflowNs: ReturnType<typeof buildMockNamespace>;
  defaultNsWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
  kubeflowNsWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
};

const setupSingleNamespaceWorkspaces = (
  namespaceName: string,
  workspaceCount: number,
  kindName = 'jupyterlab',
): NamespaceSetup => {
  const mockNamespace = buildMockNamespace({ name: namespaceName });
  const mockWorkspaceKind = buildMockWorkspaceKindInfo({ name: kindName });
  const mockWorkspaces = buildMockWorkspaceList({
    count: workspaceCount,
    namespace: mockNamespace.name,
    kind: mockWorkspaceKind,
  });

  cy.interceptApi(
    'GET /api/:apiVersion/namespaces',
    { path: { apiVersion: NOTEBOOKS_API_VERSION } },
    mockModArchResponse([mockNamespace]),
  ).as('getNamespaces');

  cy.interceptApi(
    'GET /api/:apiVersion/workspaces/:namespace',
    { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: mockNamespace.name } },
    mockModArchResponse(mockWorkspaces),
  ).as('getWorkspaces');

  return { mockNamespace, mockWorkspaces };
};
```

### Test Organization Patterns

**Use table-driven tests for similar scenarios:**

```typescript
const testCases = [
  { filterType: 'name', value: 'Workspace 1', expectedCount: 1 },
  { filterType: 'state', value: 'Running', expectedCount: 2 },
  { filterType: 'kind', value: 'jupyterlab', expectedCount: 3 },
] as const;

testCases.forEach(({ filterType, value, expectedCount }) => {
  it(`should filter workspaces by ${filterType}`, () => {
    workspaces.applyFilter({ key: filterType, value, name: filterType });
    workspaces.assertWorkspaceCount(expectedCount);
  });
});
```

---

## Common Tasks

### Adding a new test file

1. Create file in `cypress/tests/mocked/[feature]/[testName].cy.ts`
2. Import required page objects, builders, and API constants
3. Define constants and type aliases at the top
4. Add setup helper functions for API mocking
5. Structure with describe blocks
6. Write comprehensive test cases
7. Ensure accessibility testing is included (automatic via page `wait()`)

```typescript
import { mockModArchResponse } from 'mod-arch-core';
import { myPage } from '~/__tests__/cypress/cypress/pages/myFeature/myPage';
import { buildMockNamespace, buildMockResource } from '~/shared/mock/mockBuilder';
import { NOTEBOOKS_API_VERSION } from '~/__tests__/cypress/cypress/support/commands/api';
import { navBar } from '~/__tests__/cypress/cypress/pages/components/navBar';

const DEFAULT_NAMESPACE = 'default';

type SetupResult = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockResources: ReturnType<typeof buildMockResource>[];
};

const setupTest = (resourceCount: number): SetupResult => {
  const mockNamespace = buildMockNamespace({ name: DEFAULT_NAMESPACE });
  const mockResources = Array.from({ length: resourceCount }, (_, i) =>
    buildMockResource({ name: `Resource ${i + 1}` }),
  );

  cy.interceptApi(
    'GET /api/:apiVersion/namespaces',
    { path: { apiVersion: NOTEBOOKS_API_VERSION } },
    mockModArchResponse([mockNamespace]),
  ).as('getNamespaces');

  cy.interceptApi(
    'GET /api/:apiVersion/resources/:namespace',
    { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: mockNamespace.name } },
    mockModArchResponse(mockResources),
  ).as('getResources');

  return { mockNamespace, mockResources };
};

const navigateToFeature = (namespaceName: string): void => {
  myPage.visit();
  cy.wait('@getNamespaces');
  navBar.selectNamespace(namespaceName);
  cy.wait('@getResources');
};

describe('My Feature', () => {
  beforeEach(() => {
    setupTest(5);
  });

  describe('Resource List', () => {
    it('should display resources', () => {
      navigateToFeature(DEFAULT_NAMESPACE);
      myPage.assertRowCount(5);
    });

    it('should show empty state when no resources', () => {
      setupTest(0);
      navigateToFeature(DEFAULT_NAMESPACE);
      myPage.assertEmptyStateExists();
    });
  });
});
```

### Adding a new page object

1. Create class in `cypress/pages/[feature]/[pageName].ts`
2. Add route constant and `visit()` method with private `wait()` helper
3. Add `find*()` methods for locating elements
4. Add action methods (`click*()`, `select*()`, `apply*()`, `type*()`, `open*()`)
5. Add `assert*()` methods for verifying UI state
6. Export singleton instance

```typescript
class MyPage {
  readonly MY_PAGE_ROUTE = '/my-page';

  visit() {
    cy.visit(this.MY_PAGE_ROUTE);
    this.wait();
  }

  private wait() {
    this.findPageTitle();
    cy.testA11y();
  }

  // FIND methods - return Cypress chainables
  findPageTitle() {
    return cy.findByTestId('app-page-title').should('exist').and('contain', 'My Page');
  }

  findMyTable() {
    return cy.findByTestId('my-table');
  }

  findMyTableRows() {
    return this.findMyTable().find('tbody tr');
  }

  findTableRow(name: string) {
    return this.findMyTableRows().filter(`:contains("${name}")`).first();
  }

  findCreateButton() {
    return cy.get('button:contains("Create item")');
  }

  // ACTION methods
  openActionDropdown(itemName: string) {
    this.findTableRow(itemName).findByTestId('action-column').find('button').click();
  }

  findAction(args: { action: 'delete' | 'edit' | 'view'; itemName: string }) {
    this.openActionDropdown(args.itemName);
    return cy.findByTestId(`action-${args.action}`);
  }

  applyFilter(args: { key: string; value: string; name: string }) {
    cy.findByTestId('filter-dropdown').click();
    cy.findByTestId(`filter-dropdown-${args.key}`).click();
    cy.findByTestId(`filter-${args.key}-input`).clear();
    cy.findByTestId(`filter-${args.key}-input`).type(args.value);
  }

  // ASSERT methods
  assertRowCount(count: number) {
    this.findMyTableRows().should('have.length', count);
  }

  assertRowName(index: number, name: string) {
    return cy.findByTestId(`item-row-${index}`).findByTestId('item-name').should('have.text', name);
  }

  assertEmptyStateExists() {
    cy.findByTestId('empty-state').should('exist');
  }
}

export const myPage = new MyPage();
```

### Adding a custom command

```typescript
// cypress/support/commands/myCommand.ts
/* eslint-disable @typescript-eslint/no-namespace */
declare global {
  namespace Cypress {
    interface Chainable {
      verifyRelativeURL: (relativeURL: string) => Cypress.Chainable<string>;
    }
  }
}

Cypress.Commands.add('verifyRelativeURL', (relativeURL: string) => {
  const rel = relativeURL.startsWith('/') ? relativeURL : `/${relativeURL}`;

  return cy.location().then((loc) => {
    const expected = `${loc.protocol}//${loc.host}${rel}`;
    return cy
      .url()
      .should('eq', expected)
      .then(() => expected);
  });
});

export {};
```

**Using in page objects:**

```typescript
class MyPage {
  verifyPageURL() {
    return cy.verifyRelativeURL(this.MY_PAGE_ROUTE);
  }
}
```

### Setup Helper Functions

```typescript
type NamespaceSetup = {
  mockNamespace: ReturnType<typeof buildMockNamespace>;
  mockWorkspaces: ReturnType<typeof buildMockWorkspaceList>;
};

const setupSingleNamespaceWorkspaces = (
  namespaceName: string,
  workspaceCount: number,
  kindName = 'jupyterlab',
): NamespaceSetup => {
  const mockNamespace = buildMockNamespace({ name: namespaceName });
  const mockWorkspaceKind = buildMockWorkspaceKindInfo({ name: kindName });
  const mockWorkspaces = buildMockWorkspaceList({
    count: workspaceCount,
    namespace: mockNamespace.name,
    kind: mockWorkspaceKind,
  });

  cy.interceptApi(
    'GET /api/:apiVersion/namespaces',
    { path: { apiVersion: NOTEBOOKS_API_VERSION } },
    mockModArchResponse([mockNamespace]),
  ).as('getNamespaces');

  cy.interceptApi(
    'GET /api/:apiVersion/workspaces/:namespace',
    { path: { apiVersion: NOTEBOOKS_API_VERSION, namespace: mockNamespace.name } },
    mockModArchResponse(mockWorkspaces),
  ).as('getWorkspaces');

  return { mockNamespace, mockWorkspaces };
};
```

### Before/After Hook Patterns

```typescript
describe('Workspaces', () => {
  beforeEach(() => {
    setupSingleNamespaceWorkspaces('default', 10);

    workspaces.visit();
    cy.wait('@getNamespaces');
    navBar.selectNamespace('default');
    cy.wait('@getWorkspaces');
  });

  it('test 1', () => {
    workspaces.assertWorkspaceCount(10);
  });

  it('test 2', () => {
    workspaces.findCreateWorkspaceButton().click();
  });
});
```

✅ **DO**: Use `beforeEach` for test independence
❌ **DON'T**: Use `before` for test data
❌ **DON'T**: Share mutable state across tests

---

## Performance Considerations

### Timing Guidelines

| Metric               | Target       | Action if Exceeded                   |
| -------------------- | ------------ | ------------------------------------ |
| Single test duration | < 30 seconds | Split into smaller tests             |
| Test file duration   | < 2 minutes  | Move tests to separate files         |
| API mock response    | < 100ms      | Check mock complexity                |
| Page load wait       | < 5 seconds  | Verify mocks are set up before visit |

### Best Practices

- Mock all API calls - never hit real backend
- Keep tests focused - one behavior per test
- Minimize DOM queries - cache element references in page objects
- Use efficient selectors - `data-testid` is faster than complex CSS

### Retry Configuration

Tests run in CI with automatic retries (configured in `cypress.config.ts`):

```typescript
retries: {
  runMode: 2,   // 2 retries in CI
  openMode: 0,  // No retries in interactive mode
}
```

---

## Handling Flaky Tests

### Common Causes and Fixes

| Cause                | Symptom                          | Fix                                    |
| -------------------- | -------------------------------- | -------------------------------------- |
| **Race condition**   | Element not found intermittently | Wait for API: `cy.wait('@alias')`      |
| **Animation timing** | Click doesn't register           | `.should('be.visible').click()`        |
| **Stale data**       | Wrong count/content              | Use `beforeEach`, not `before`         |
| **Shared state**     | Test order dependency            | Don't share variables                  |
| **Network timing**   | Timeout errors                   | Increase timeout for specific commands |

### Fixing Flaky Tests

**1. Add explicit waits for API calls**

```typescript
// Bad
workspaces.visit();
workspaces.assertWorkspaceCount(5);

// Good
workspaces.visit();
cy.wait('@getWorkspaces');
workspaces.assertWorkspaceCount(5);
```

**2. Wait for elements to be actionable**

```typescript
// Bad
cy.findByTestId('submit-button').click();

// Good
cy.findByTestId('submit-button').should('be.visible').and('be.enabled').click();
```

**3. Isolate test data**

```typescript
// Bad - shared state
let workspaceId: string;
before(() => {
  workspaceId = 'abc';
});

// Good - fresh data per test
beforeEach(() => {
  const workspaceId = 'abc';
});
```

### When to Skip a Flaky Test

Only skip as a **last resort** and always with a ticket:

```typescript
// TODO(#1234): Fix race condition in workspace deletion flow
it.skip('should handle rapid successive deletions', () => {
  // Test implementation
});
```
