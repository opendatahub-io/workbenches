---
name: Frontend React Agent - Patterns
description: Detailed code patterns and examples for the React/TypeScript frontend application.
---

# Frontend Module - Detailed Patterns

This file contains detailed patterns and examples for the frontend module.

**For essential guidelines, see [AGENTS.md](./AGENTS.md).**

---

## Table of Contents

- [UI & UX Guidelines](#ui--ux-guidelines)
- [State & Data Flow](#state--data-flow)
- [Testing Guidelines](#testing-guidelines)
- [Code Conventions](#code-conventions)
- [API Integration](#api-integration)
- [Error Handling Patterns](#error-handling-patterns)
- [React Context Patterns](#react-context-patterns)
- [Constants and Environment Variables](#constants-and-environment-variables)
- [Common Tasks](#common-tasks)

---

## UI & UX Guidelines

- Follow the existing PatternFly design system
- Reuse existing components from `shared/components/` or `app/components/`
- Avoid unnecessary visual or behavioral changes
- Maintain consistency with existing UI patterns

### Accessibility

- All UI **MUST** meet WCAG accessibility standards
- Do not introduce regressions in keyboard navigation
- Ensure screen reader support for all interactive elements
- Use semantic HTML and ARIA attributes appropriately
- Always add `aria-label` to icon-only buttons

```typescript
// Good - accessible icon button
<Button variant="plain" aria-label="Delete workspace" icon={<TrashIcon />} />

// Bad - missing aria-label
<Button variant="plain" icon={<TrashIcon />} />
```

### Performance

- Avoid unnecessary re-renders (use React.memo, useMemo, useCallback appropriately)
- Be mindful of bundle size when adding dependencies
- Lazy load heavy components when appropriate

**Use stable keys in lists - never use array index:**

```typescript
// Bad - using index as key
workspaces.map((workspace, index) => (
  <WorkspaceRow key={index} workspace={workspace} />
));

// Good - using stable unique identifier
workspaces.map((workspace) => (
  <WorkspaceRow key={workspace.id} workspace={workspace} />
));
```

---

## State & Data Flow

- Follow existing state management patterns
- Use React Context for shared state across components
- Keep component state local when possible
- Use custom hooks to encapsulate state logic

### Loading and Error States

```typescript
// Good - explicit state handling
if (workspacesLoadError) {
  return (
    <LoadError title="Failed to load workspaces" error={workspacesLoadError} />
  );
}

if (!workspacesLoaded || !namespacesLoaded) {
  return <LoadingSpinner />;
}

return <WorkspaceTable workspaces={workspaces} />;
```

**Use NotReadyError for dependencies not yet loaded:**

```typescript
if (!apiAvailable) {
  return Promise.reject(new Error('API not yet available'));
}
if (!namespacesLoaded) {
  return Promise.reject(new NotReadyError('Namespaces not yet available'));
}
```

### Data Transformation

**Transform data in utility functions or custom hooks, not in render methods:**

```typescript
// Good - transform in utility/hook
const idleWorkspaces = filterIdleWorkspaces(workspaces);
const workspacesByNamespace = groupWorkspacesByNamespace(workspaces);

// Avoid - inline transformations in JSX
return (
  <Table>
    {workspaces
      .filter((w) => w.state !== "Running")
      .map((w) => (
        <WorkspaceRow key={w.id} workspace={w} />
      ))}
  </Table>
);
```

---

## Testing Guidelines

### Unit Testing (Jest)

**Test file structure:**

- Place tests in `__tests__/` directory next to the code
- Name test files with `.spec.tsx` for React components and `.spec.ts` for hooks/utilities

**Unit test patterns:**

```typescript
import { renderHook } from '~/__tests__/unit/testUtils/hooks';
import { useWorkspacesByNamespace } from '~/app/hooks/useWorkspaces';
import { useNotebookAPI } from '~/app/hooks/useNotebookAPI';
import { buildMockWorkspace, buildMockWorkspaceList } from '~/shared/mock/mockBuilder';
import { NotebookApis } from '~/shared/api/notebookApi';

jest.mock('~/app/hooks/useNotebookAPI', () => ({
  useNotebookAPI: jest.fn(),
}));

const mockUseNotebookAPI = useNotebookAPI as jest.MockedFunction<typeof useNotebookAPI>;

describe('useWorkspacesByNamespace', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns error when API unavailable', async () => {
    mockUseNotebookAPI.mockReturnValue({
      api: {} as NotebookApis,
      apiAvailable: false,
      refreshAllAPI: jest.fn(),
    });

    const { result, waitForNextUpdate } = renderHook(() =>
      useWorkspacesByNamespace('test-namespace'),
    );
    await waitForNextUpdate();

    const [data, loaded, error] = result.current;
    expect(data).toEqual([]);
    expect(loaded).toBe(false);
    expect(error).toBeDefined();
  });

  it('fetches workspaces successfully', async () => {
    const mockWorkspaces = buildMockWorkspaceList({ count: 10 });
    const listWorkspacesByNamespace = jest
      .fn()
      .mockResolvedValue({ ok: true, data: mockWorkspaces });

    mockUseNotebookAPI.mockReturnValue({
      api: {
        workspaces: { listWorkspacesByNamespace },
      } as unknown as NotebookApis,
      apiAvailable: true,
      refreshAllAPI: jest.fn(),
    });

    const { result, waitForNextUpdate } = renderHook(() =>
      useWorkspacesByNamespace('test-namespace'),
    );
    await waitForNextUpdate();

    const [data, loaded, error] = result.current;
    expect(data).toEqual(mockWorkspaces);
    expect(loaded).toBe(true);
    expect(error).toBeUndefined();
  });
});
```

**Unit testing best practices:**

✅ **DO**: Use builder functions for mock data

```typescript
const workspace = buildMockWorkspace({
  name: 'test-workspace',
  namespace: 'default',
  workspaceKind: buildMockWorkspaceKindInfo({ name: 'jupyterlab' }),
});
```

✅ **DO**: Test all states (loading, success, error)

✅ **DO**: Use `beforeEach` to reset mocks

```typescript
beforeEach(() => {
  jest.clearAllMocks();
});
```

✅ **DO**: Use tuple destructuring for hook returns

```typescript
const [data, loaded, error] = result.current;
```

---

## Code Conventions

### Component Pattern Template

```typescript
import React, { useState } from "react";
import { Spinner } from "@patternfly/react-core/dist/esm/components/Spinner";
import { Alert } from "@patternfly/react-core/dist/esm/components/Alert";

interface MyComponentProps {
  title: string;
  onAction?: () => void;
}

export const MyComponent: React.FC<MyComponentProps> = ({
  title,
  onAction,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  if (loading) return <Spinner />;
  if (error) return <Alert variant="danger" title={error.message} />;

  return <div data-testid="my-component">{/* Component content */}</div>;
};
```

### TypeScript Type Safety (CRITICAL)

**Never use the `any` keyword.**

- Use specific types or interfaces instead
- Use `unknown` if the type is truly unknown, then narrow with type guards
- Use generics for reusable typed components

```typescript
// Bad
const handleData = (data: any) => {
  /* ... */
};

// Good
const handleData = (data: WorkspaceData) => {
  /* ... */
};
```

### Conditional Rendering Patterns

**Prefer early returns over deeply nested ternaries:**

```typescript
// Good - early returns for error/loading states
const Workspaces: React.FC = () => {
  if (error) {
    return <LoadError error={error} />;
  }

  if (!loaded) {
    return <LoadingSpinner />;
  }

  return <WorkspaceTable workspaces={workspaces} />;
};

// Avoid - deeply nested ternaries
const Workspaces: React.FC = () => {
  return error ? (
    <LoadError error={error} />
  ) : !loaded ? (
    <LoadingSpinner />
  ) : (
    <WorkspaceTable workspaces={workspaces} />
  );
};
```

**Use logical AND for conditional rendering:**

```typescript
return (
  <div>
    {isLoading && <Spinner />}
    {error && <Alert>{error.message}</Alert>}
    {workspaces.length === 0 && <EmptyState />}
  </div>
);
```

### Import Patterns

**Use absolute imports with the `~/` alias:**

```typescript
import { useWorkspaces } from '~/app/hooks/useWorkspaces';
import { WorkspaceTable } from '~/app/components/WorkspaceTable';
```

**PatternFly imports MUST use `/dist/esm/` paths for tree-shaking:**

```typescript
// Good - tree-shakeable imports
import { Button } from '@patternfly/react-core/dist/esm/components/Button';
import { Stack, StackItem } from '@patternfly/react-core/dist/esm/layouts/Stack';

// Bad - imports entire library
import { Button, Stack } from '@patternfly/react-core';
```

**Group and order imports logically:**

```typescript
// 1. React and core libraries
import React, { useCallback, useEffect, useMemo } from 'react';

// 2. External UI libraries
import { Button } from '@patternfly/react-core/dist/esm/components/Button';

// 3. Internal app imports
import { useWorkspaces } from '~/app/hooks/useWorkspaces';
import { WorkspaceTable } from '~/app/components/WorkspaceTable';

// 4. Generated types
import { Workspace, WorkspaceState } from '~/generated/data-contracts';

// 5. Styles (last)
import './styles.css';
```

### Component Props Patterns

**Always define props interfaces with `Props` suffix:**

```typescript
interface WorkspaceTableProps {
  workspaces: Workspace[];
  onRefresh: () => void;
  isLoading?: boolean;
}

export const WorkspaceTable: React.FC<WorkspaceTableProps> = ({
  workspaces,
  onRefresh,
  isLoading = false,
}) => {
  // ... implementation
};
```

**Use `ReactNode` for children prop:**

```typescript
interface ProviderProps {
  children: ReactNode;
}

export const Provider: React.FC<ProviderProps> = ({ children }) => {
  return <Context.Provider value={value}>{children}</Context.Provider>;
};
```

**Name boolean props with prefixes: `is`, `has`, `should`, `can`:**

```typescript
interface TableProps {
  isLoading: boolean;
  hasError: boolean;
  shouldShowPagination: boolean;
  canDelete: boolean;
}
```

**Name event handlers with `handle` prefix, callbacks with `on` prefix:**

```typescript
interface ComponentProps {
  onSave: (data: Data) => void;
  onCancel: () => void;
}

const Component: React.FC<ComponentProps> = ({ onSave, onCancel }) => {
  const handleSubmit = () => {
    onSave(processedData);
  };

  return <form onSubmit={handleSubmit}>{/* ... */}</form>;
};
```

### Custom Hook Patterns

**Follow tuple destructuring pattern for data-fetching hooks:**

```typescript
const [workspaces, workspacesLoaded, workspacesLoadError, refreshWorkspaces] =
  useWorkspacesByNamespace(namespace);
```

**Hook return tuple variations:**

| Return Type     | Pattern                          | When Used                  |
| --------------- | -------------------------------- | -------------------------- |
| 3-element tuple | `[data, loaded, error]`          | Read-only data             |
| 4-element tuple | `[data, loaded, error, refresh]` | Data that may need refresh |

**Custom hooks MUST check for proper context:**

```typescript
export const useAppContext = (): AppContextType => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useAppContext must be used within AppContextProvider');
  }
  return context;
};
```

**Always include exhaustive dependency arrays for React hooks:**

```typescript
// Good - all dependencies listed
const fetchData = useCallback(async () => {
  if (!apiAvailable) {
    throw new Error('API not available');
  }
  const result = await api.getData(namespace, filter);
  return result;
}, [api, apiAvailable, namespace, filter]);

// Bad - missing dependencies
const fetchData = useCallback(async () => {
  const result = await api.getData(namespace, filter);
  return result;
}, []);
```

**Use `useMemo` for expensive computations, not all derived values:**

```typescript
// Good - expensive computation
const filteredWorkspaces = useMemo(() => {
  return workspaces.filter((w) => matchesFilters(w, complexFilters));
}, [workspaces, complexFilters]);

// Avoid - simple computation
const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
// Just do: const fullName = `${firstName} ${lastName}`;
```

**Use `useRef` for values that shouldn't trigger re-renders:**

```typescript
const isInitializedRef = useRef(false);

useEffect(() => {
  if (isInitializedRef.current) {
    return;
  }
  isInitializedRef.current = true;
  // Run initialization once
}, []);
```

### useEffect Anti-Patterns

**Extract to a custom hook when useEffect:**

- Sets 3 or more state variables
- Contains async function definitions
- Handles loading/error states manually
- Transforms API response data

```typescript
// ❌ BAD - useEffect managing loading/error states manually
useEffect(() => {
  const fetchData = async () => {
    setIsLoading(true);
    try {
      const response = await api.getData(id);
      setData(response);
    } catch {
      setError('Failed to load');
    } finally {
      setIsLoading(false);
    }
  };
  fetchData();
}, [api, id]);

// ✅ GOOD - Extract to custom hook using useFetchState
const [data, loaded, error] = useData(id);
```

**Why this matters:**

- **Testability**: Custom hooks can be unit tested independently
- **Reusability**: Logic can be shared across components
- **Separation of concerns**: Data fetching is decoupled from UI
- **Consistency**: Follows the `[data, loaded, error]` tuple pattern used throughout the codebase

### Function Complexity

**Signs a function needs refactoring:**

- Exceeds 30-40 lines
- Contains duplicated code blocks
- Mixes multiple concerns
- Has many parameters or dependencies
- Contains inline data transformations

**Refactoring strategies:**

| Problem | Solution |
|---------|----------|
| Duplicated code blocks | Extract to helper function |
| Inline data transformation | Extract to utility function |
| Too many concerns | Split into smaller focused functions |
| Complex conditionals | Use early returns or extract to separate functions |

### Function Signature Patterns

**For functions with multiple parameters, use an object with named properties:**

```typescript
// Bad - positional parameters are confusing
export const buildWorkspace = (name: string, namespace: string, kind: string, state: string) => {};

// Good - object with named properties
export const buildWorkspace = (args: {
  name: string;
  namespace: string;
  kind: string;
  state: WorkspaceState;
}) => {
  const { name, namespace, kind, state } = args;
  // ... implementation
};

buildWorkspace({
  name: 'my-workspace',
  namespace: 'default',
  kind: 'jupyterlab',
  state: WorkspaceState.Running,
});
```

### TypeScript Type Safety

**CRITICAL: Never use the `any` keyword.**

```typescript
// Bad
const handleData = (data: any) => {
  /* ... */
};

// Good - specific type
const handleData = (data: WorkspaceData) => {
  /* ... */
};

// Good - unknown with type guard
const handleData = (data: unknown) => {
  if (isWorkspaceData(data)) {
    // data is now WorkspaceData
  }
};

// Good - generic
const handleData = <T extends BaseData>(data: T) => {
  /* ... */
};
```

---

## API Integration

The frontend consumes the backend API via the generated OpenAPI client in `src/generated/`.

**Important**: Changes depending on backend API modifications **MUST** wait until those API changes are merged and `scripts/swagger.version` is updated.

---

## Error Handling Patterns

### Error Boundary

```typescript
// ErrorBoundary usage (already in place at app root)
<ErrorBoundary>
  <App />
</ErrorBoundary>
```

**ErrorBoundary implementation pattern:**

```typescript
type ErrorBoundaryState =
  | { hasError: false }
  | {
      hasError: true;
      error: Error;
      errorInfo: React.ErrorInfo;
      isUpdateState: boolean;
    };

class ErrorBoundary extends React.Component<Props, ErrorBoundaryState> {
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    this.setState({
      hasError: true,
      error,
      errorInfo,
      isUpdateState: error.name === 'ChunkLoadError',
    });
  }
}
```

### API Error Handling

```typescript
// Good - explicit error handling with notification
try {
  await api.workspaces.deleteWorkspace(namespace, name);
  notification.success("Workspace deleted successfully");
} catch (error) {
  notification.error(`Failed to delete workspace: ${error.message}`);
  throw error;
}

// Good - error state in component
const [error, setError] = useState<Error | null>(null);

useEffect(() => {
  fetchWorkspaces().then(setWorkspaces).catch(setError);
}, []);

if (error) {
  return <Alert variant="danger" title="Error loading workspaces" />;
}
```

---

## React Context Patterns

### Context Provider Structure

```typescript
// 1. Define context type
export type MyContextType = {
  value: string;
  setValue: (value: string) => void;
};

// 2. Create context with undefined default
export const MyContext = React.createContext<MyContextType | undefined>(
  undefined
);

// 3. Create custom hook with error checking
export const useMyContext = (): MyContextType => {
  const context = useContext(MyContext);
  if (!context) {
    throw new Error("useMyContext must be used within a MyContextProvider");
  }
  return context;
};

// 4. Create provider component
interface MyContextProviderProps {
  children: React.ReactNode;
}

export const MyContextProvider: React.FC<MyContextProviderProps> = ({
  children,
}) => {
  const [value, setValue] = useState<string>("");

  // CRITICAL: Memoize context value
  const contextValue = useMemo(
    () => ({
      value,
      setValue,
    }),
    [value]
  );

  return (
    <MyContext.Provider value={contextValue}>{children}</MyContext.Provider>
  );
};
```

### Exhaustive Switch with `never`

```typescript
switch (action) {
  case ActionType.Edit:
    handleEdit();
    break;
  case ActionType.Delete:
    handleDelete();
    break;
  case ActionType.ViewDetails:
    handleView();
    break;
  default: {
    const value: never = action;
    console.error('Unreachable code', value);
  }
}
```

---

## Constants and Environment Variables

### Environment Variables

Centralize environment variables in `~/shared/utilities/const.ts`:

```typescript
export const POLL_INTERVAL = process.env.POLL_INTERVAL
  ? parseInt(process.env.POLL_INTERVAL)
  : 30000;

export const DEV_MODE = process.env.APP_ENV === 'development';

export const MANDATORY_NAMESPACE = process.env.MANDATORY_NAMESPACE || undefined;

export const STYLE_THEME = asEnumMember(process.env.STYLE_THEME, Theme) || Theme.MUI;
```

**Don't access `process.env` directly in components:**

```typescript
// Bad - direct access
if (process.env.DEV_MODE === 'development') {
}

// Good - use constant
import { DEV_MODE } from '~/shared/utilities/const';
if (DEV_MODE) {
}
```

### Application Constants

```typescript
export const DEFAULT_POLL_INTERVAL = 30000;
export const MAX_WORKSPACE_NAME_LENGTH = 63;
export const CONTENT_TYPE_KEY = 'Content-Type';
```

### Enums for Related Constants

```typescript
export enum ActionType {
  ViewDetails = 'ViewDetails',
  Edit = 'Edit',
  Delete = 'Delete',
  Start = 'Start',
  Stop = 'Stop',
}
```

---

## Common Tasks

### Adding a New Component

1. **Create the component file** in `src/app/components/`:

   ```typescript
   // src/app/components/MyComponent.tsx
   import React from "react";
   import { Button } from "@patternfly/react-core/dist/esm/components/Button";

   interface MyComponentProps {
     title: string;
     onAction: () => void;
   }

   export const MyComponent: React.FC<MyComponentProps> = ({
     title,
     onAction,
   }) => (
     <div data-testid="my-component">
       <h2>{title}</h2>
       <Button onClick={onAction}>Action</Button>
     </div>
   );
   ```

2. **Add tests** in `src/__tests__/` with `.spec.tsx` extension

3. **Export from index** if creating a shared component

### Adding a New Custom Hook

1. **Create the hook file** in `src/app/hooks/` using `useFetchState` from `mod-arch-core`:

   ```typescript
   // src/app/hooks/useMyData.ts
   import { useCallback } from 'react';
   import {
     FetchState,
     FetchStateCallbackPromise,
     useFetchState,
     NotReadyError,
   } from 'mod-arch-core';
   import { useNotebookAPI } from '~/app/hooks/useNotebookAPI';
   import { ApiMyDataEnvelope } from '~/generated/data-contracts';

   export const useMyData = (namespace: string): FetchState<ApiMyDataEnvelope['data']> => {
     const { api, apiAvailable } = useNotebookAPI();

     const call = useCallback<FetchStateCallbackPromise<ApiMyDataEnvelope['data']>>(async () => {
       if (!apiAvailable) {
         return Promise.reject(new Error('API not yet available'));
       }
       if (!namespace) {
         return Promise.reject(new NotReadyError('Namespace not yet available'));
       }
       const envelope = await api.myResource.listByNamespace(namespace);
       return envelope.data;
     }, [api.myResource, apiAvailable, namespace]);

     return useFetchState(call, []);
   };
   ```

2. **Return type**: `FetchState<T>` is a 4-element tuple `[data, loaded, error, refresh]`

3. **Add tests** using `renderHook` and `standardUseFetchState` from test utilities

### Adding a New Page

1. **Create page component** in `src/app/pages/[PageName]/`:

   ```typescript
   // src/app/pages/MyPage/MyPage.tsx
   import React from "react";
   import {
     Content,
     ContentVariants,
   } from "@patternfly/react-core/dist/esm/components/Content";
   import { PageSection } from "@patternfly/react-core/dist/esm/components/Page";
   import {
     Stack,
     StackItem,
   } from "@patternfly/react-core/dist/esm/layouts/Stack";
   import { useMyData } from "~/app/hooks/useMyData";
   import { LoadError } from "~/app/components/LoadError";
   import { LoadingSpinner } from "~/app/components/LoadingSpinner";

   export const MyPage: React.FunctionComponent = () => {
     const [data, loaded, error, refresh] = useMyData("default");

     if (error) {
       return <LoadError title="Failed to load data" error={error} />;
     }

     if (!loaded) {
       return <LoadingSpinner />;
     }

     return (
       <PageSection isFilled>
         <Stack hasGutter>
           <StackItem>
             <Content
               component={ContentVariants.h1}
               data-testid="app-page-title"
             >
               My Page
             </Content>
           </StackItem>
           <StackItem isFilled>{/* Page content */}</StackItem>
         </Stack>
       </PageSection>
     );
   };
   ```

2. **Add route** in `src/app/routes.ts`

3. **Register in AppRoutes** in `src/app/AppRoutes.tsx`

4. **Add navigation** if needed in `src/app/standalone/NavSidebar.tsx`

### Adding a Context Provider

1. **Define context type and create context**:

   ```typescript
   // src/app/context/MyContext.tsx
   import React, { ReactNode, useContext, useMemo, useState } from "react";

   export type MyContextType = {
     value: string;
     setValue: (value: string) => void;
   };

   export const MyContext = React.createContext<MyContextType | undefined>(
     undefined
   );

   export const useMyContext = (): MyContextType => {
     const context = useContext(MyContext);
     if (!context) {
       throw new Error("useMyContext must be used within a MyContextProvider");
     }
     return context;
   };

   interface MyContextProviderProps {
     children: ReactNode;
   }

   export const MyContextProvider: React.FC<MyContextProviderProps> = ({
     children,
   }) => {
     const [value, setValue] = useState("");

     const contextValue = useMemo(
       () => ({
         value,
         setValue,
       }),
       [value]
     );

     return (
       <MyContext.Provider value={contextValue}>{children}</MyContext.Provider>
     );
   };
   ```

2. **Wrap components** that need access to the context

3. **Always memoize** the context value to prevent unnecessary re-renders
