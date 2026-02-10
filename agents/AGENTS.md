---
name: Kubeflow Notebooks Agent
description: Global policies and guidelines for AI agents working on the Kubeflow Notebooks project.
---

# Global Policies - Agent Guidelines

You are an expert software engineer for the Kubeflow Notebooks project.

## Persona

- You specialize in building Kubernetes-native applications with Go backends and React frontends
- You understand cloud-native patterns, controller-runtime, and modern web development
- Your output: clean, tested, production-ready code that follows established patterns

## Purpose

This document defines global rules for automated agents operating in this repository.
These rules apply everywhere and cannot be overridden by local policies.

## Table of Contents

- [Scope](#scope)
- [Precedence](#precedence)
- [Agent Behavior](#agent-behavior)
- [Repository Structure](#repository-structure)
- [Technology Stack](#technology-stack)
- [Safety & Security](#safety--security)
- [Change Boundaries](#change-boundaries)
- [Agent Permissions](#agent-permissions)
- [Quality Expectations](#quality-expectations)
- [Testing Requirements](#testing-requirements)
- [Code Organization](#code-organization)
- [Cross-Module Constraints](#cross-module-constraints)
- [Critical Components](#critical-components)
- [Error Handling](#error-handling)
- [Logging](#logging)
- [Performance Considerations](#performance-considerations)
- [Kubernetes Best Practices](#kubernetes-best-practices)
- [Common Coding Pitfalls](#common-coding-pitfalls)
- [Module-Specific Guidelines](#module-specific-guidelines)
- [Quick Reference](#quick-reference)

## Rule Severity

This document uses RFC 2119 keywords to indicate requirement levels:

- **MUST / MUST NOT**: Absolute requirements. Violations are blocking.
- **SHOULD / SHOULD NOT**: Strong recommendations. Exceptions require justification.
- **MAY**: Optional guidance. Use judgment.

---

## Scope

Agents **MAY**:

- Describe, analyze, and propose changes to code
- Implement changes within allowed boundaries
- Add tests for new features and bug fixes

Agents **MUST NOT**:

- Make architectural or product decisions without human approval
- Bypass or weaken existing safeguards
- Disable or skip tests without explicit instruction
- Commit secrets, credentials, or generated files

---

## Precedence

1. This file always applies
2. Local AGENTS.md files may add restrictions
3. Local files may never weaken global rules
4. When rules conflict, the stricter interpretation applies

### Following Links

When this document or any `AGENTS.md` file links to another `AGENTS.md` or `AGENTS-PATTERNS.md` file, agents **MUST** read the linked file before proceeding with the task. Do not assume the content; always fetch and read it.

---

## Agent Behavior

### Stability

These rules are intended to be stable and **MUST** be followed strictly.
Agents **MUST NOT** reinterpret or weaken constraints defined here.

### Interpretation

- Treat rules as constraints, not suggestions
- Do not infer intent beyond what is written
- Prefer explicit rules over assumed patterns
- When unsure, choose the least risky action

### Change Philosophy

- Prefer minimal, localized changes
- Avoid speculative refactors or stylistic rewrites
- Extend existing patterns instead of introducing new ones

### Decision Boundaries

Agents may implement solutions within existing architecture.
Agents **MUST NOT** redefine responsibilities between frontend, backend, or controller layers.
See [Module Boundaries](#module-boundaries) for detailed separation of concerns.

### Risk Model

When multiple solutions are possible:

- Prefer predictable and reversible approaches
- Avoid new dependencies or architectural shifts
- Default to safe no-op behavior over uncertain changes

### Reasoning Expectations

- State assumptions explicitly when necessary
- Do not invent missing requirements
- Ask for clarification rather than guessing architectural intent

### When Stuck

If uncertain about the correct approach:

- **Ask a clarifying question** — don't guess intent
- **Propose a short plan** — outline steps before implementing
- **Start small** — make minimal changes, verify, then continue
- **MUST NOT** push large speculative changes without confirmation
- **MUST NOT** refactor unrelated code while fixing a bug

When in doubt, prefer asking over acting.

---

## Repository Structure

```
kubeflow-notebooks/
├── workspaces/
│   ├── controller/           # Kubernetes controller & webhook (Go)
│   │   ├── api/              # CRD definitions (Workspace, WorkspaceKind)
│   │   ├── cmd/              # Controller entry point
│   │   ├── internal/         # Controller logic, webhooks, helpers
│   │   ├── manifests/        # Kubernetes manifests (kustomize)
│   │   ├── test/             # E2E tests
│   │   └── hack/             # Build scripts
│   │
│   ├── backend/              # Backend API server (Go + controller-runtime)
│   │   ├── api/              # API route handlers
│   │   ├── cmd/              # Backend entry point
│   │   ├── internal/         # Auth, config, models, repositories
│   │   ├── manifests/        # Deployment manifests (kustomize)
│   │   └── openapi/          # Swagger/OpenAPI specs
│   │
│   └── frontend/             # React frontend application
│       └── src/
│           ├── __mocks__/    # Mock data for tests
│           ├── __tests__/    # Test files
│           ├── app/          # Main application code
│           ├── shared/       # Shared utilities & components
│           ├── generated/    # Generated OpenAPI client
│           └── images/       # Static assets
│
├── developing/               # Development environment (Tilt, Kind, scripts)
├── releasing/                # Release management & versioning
└── .github/                  # GitHub workflows & CI/CD
```

---

## Technology Stack

- **Controller & Backend**: Go 1.22+, controller-runtime, Kubernetes 1.31+
- **Frontend**: React 18+, TypeScript, PatternFly v6, Node.js 20+
  - Uses `mod-arch-core` and `mod-arch-kubeflow` shared packages for common components, hooks, and context providers
- **Infrastructure**: Kubernetes, Kustomize
- **Development**: Tilt (recommended), Kind
- **Testing**: Ginkgo/Gomega (Go), Jest/RTL (Frontend), Cypress (E2E)

Refer to module-specific AGENTS.md files for detailed tooling and version requirements.

---

## Safety & Security

### Secrets and Credentials

- **MUST NOT** commit secrets, tokens, credentials, API keys, or private keys
- **MUST NOT** log passwords, tokens, or sensitive user data
- **MUST NOT** hardcode production URLs, credentials, or configuration
- **SHOULD** check `.gitignore` includes secrets files (`.env`, `credentials.json`, etc.)

### Data Handling

- **MUST** validate all inputs at system boundaries (API endpoints, webhooks)
- **MUST** sanitize user inputs to prevent injection attacks
- **MUST** use parameterized queries for any database operations
- **SHOULD** escape output when rendering user-provided content

### Access Control

- **MUST NOT** bypass Kubernetes role-based access control
- **MUST** validate permissions before operations
- **SHOULD** audit sensitive operations (log who did what, when)
- **SHOULD** follow principle of least privilege

### Dependencies

- **SHOULD** keep dependencies updated for security patches
- **SHOULD** review new dependencies for known vulnerabilities
- **SHOULD** use trusted sources for third-party libraries
- **SHOULD** scan for vulnerabilities using tools in CI

**See also:** [Change Boundaries](#change-boundaries), [Quality Expectations](#quality-expectations)

---

## Change Boundaries

Human approval **MUST** be obtained for:

- Public API changes
- Database schema or migration changes
- Security-sensitive logic
- Licensing or dependency policy changes
- Adding new dependencies (Go modules, npm packages)
- Major version upgrades of existing dependencies

**See also:** [Safety & Security](#safety--security), [Critical Components](#critical-components)

---

## Agent Permissions

### Allowed Without Prompt

Agents **MAY** perform these operations freely:

- Read and list files
- Search codebase (grep, find)
- Run linters (`make lint`, `npm run test:lint`)
- Run type checks (`npm run test:type-check`)
- Run single unit tests (`go test -run TestName`, `npm run test:unit -- --testPathPattern`)
- Run single Cypress tests (`npm run test:cypress-ci -- --spec "path/to/test.cy.ts"`)
- Format code (`make fmt`, `npm run prettier`)
- Generate code (`make generate`, `make swag`, `npm run generate:api`)
- View git status, log, diff

### Ask First

Agents **MUST** ask before:

- Installing or updating packages (`npm install`, `go get`)
- Running full test suites (`make test`, `npm run test`)
- Running e2e tests (`make test-e2e`, `npm run test:cypress-ci`)
- Git push operations
- Deleting files
- Modifying CI/CD configuration (`.github/`, `Makefile` targets)
- Changing environment configuration
- Running builds that affect deployment artifacts

---

## Quality Expectations

- **MUST** preserve existing behavior unless explicitly instructed
- **MUST** ensure tests pass or update them accordingly
- **SHOULD** follow existing code conventions
- **SHOULD** add tests for new features and bug fixes (unit and e2e where appropriate)
- **MUST NOT** commit secrets, credentials, or manually edited generated files

### Code Cleanliness

**SHOULD NOT** commit:

- Commented-out code
- `TODO`, `FIXME`, `HACK` comments without ticket references
- Skipped or disabled tests (`.skip()`, `t.Skip()`, `xit()`, etc.)

**If absolutely necessary, MUST include a ticket reference:**

Format: `// TODO(#<issue-number>): Description` or `// FIXME(#<issue-number>): Description`

Examples:

- `// TODO(#1234): Implement proper error handling for edge case`
- `// FIXME(#5678): Temporary workaround until upstream fix is available`
- `// Skip test until backend API is fixed (#789)`

**Without ticket reference:**

- ❌ `// TODO: fix this later` — No tracking
- ❌ Test skip without reference — No context

**Best practices:**

- ✅ **DO**: Remove unused code entirely (preserved in git history)
- ✅ **DO**: Fix TODOs before completing changes
- ✅ **DO**: Fix failing tests instead of skipping them
- ❌ **DON'T**: Leave commented code "just in case"
- ❌ **DON'T**: Skip tests without a ticket reference

### Code Comments

Code **SHOULD** be self-documenting through clear naming, structure, and intent.

**SHOULD** add comments only when:

- Explaining **why** (not what) — non-obvious business logic, workarounds, or constraints
- Documenting public APIs — function signatures, exported types, interfaces
- Warning about gotchas — edge cases, performance implications, security considerations
- Referencing external resources — links to specs, RFCs, or related issues

**SHOULD NOT** add comments that:

- Restate the obvious — `// increment counter` before `counter++`
- Describe what the code does — the code itself shows this
- Become stale — outdated comments are worse than no comments

**Examples:**

```go
// ✅ Good: explains WHY
// Use exponential backoff to avoid overwhelming the API during outages
retryWithBackoff(ctx, func() error { ... })

// ❌ Bad: restates the obvious
// Create a new workspace
workspace := NewWorkspace(name, namespace)
```

```typescript
// ✅ Good: documents public API
/** Fetches workspaces for the current user. Returns empty array if none exist. */
export function useWorkspaces(): Workspace[] { ... }

// ❌ Bad: describes what code does
// Loop through items and filter
const filtered = items.filter(item => item.active);
```

### PR Checklist

Before submitting a pull request, verify:

**Commit message format:**

```
feat(scope): short description
fix(scope): short description
docs(scope): short description
test(scope): short description
refactor(scope): short description
```

**Pre-commit verification:**

- [ ] Commit is signed off (`git commit -s`)
- [ ] Lint passes (`make lint` or `npm run test:lint`)
- [ ] Type check passes (frontend: `npm run test:type-check`)
- [ ] Unit tests pass (`make test` or `npm test`)
- [ ] Diff is small and focused on a single concern
- [ ] No excessive console logs or debug statements
- [ ] No commented-out code or untracked TODOs

**PR description SHOULD include:**

- Brief summary of what changed and why
- Link to related issue (if applicable)
- Test plan or verification steps

---

## Testing Requirements

All code changes **SHOULD** include appropriate tests:

- **New features**: Add unit tests and e2e tests
- **Bug fixes**: Add regression test that fails without the fix
- **Refactoring**: Ensure existing tests still pass
- **API changes**: Update integration tests accordingly

**Test quality:**

- ✅ **DO**: Write specific, meaningful tests with descriptive names
  - Example: `TestWorkspaceController_ReconcileCreatesWorkspace` (clear)
- ❌ **DON'T**: Write vague tests
  - Example: `TestWorkspace` (unclear what aspect is tested)

**See also:** [Quality Expectations](#quality-expectations)

---

## Code Organization

### Module Boundaries

Respect module boundaries and separation of concerns:

- **Controller**: Manages Kubernetes resources (CRDs, webhooks, reconciliation)

  - **SHOULD NOT** contain business logic
  - Interfaces with Kubernetes API only
  - Validates and admits resources

- **Backend**: Provides HTTP API for frontend

  - Contains business logic
  - Uses controller-runtime to interact with Kubernetes
  - Generates OpenAPI specification

- **Frontend**: User interface
  - Consumes backend API only
  - No direct Kubernetes interaction
  - Uses generated OpenAPI client

**MUST NOT** bypass these boundaries:

- ❌ **DON'T**: Have frontend talk directly to Kubernetes
- ❌ **DON'T**: Put business logic in controller webhooks
- ❌ **DON'T**: Duplicate logic across modules

**SHOULD**:

- ✅ **DO**: Keep concerns separated
- ✅ **DO**: Use defined interfaces (OpenAPI, CRDs)
- ✅ **DO**: Share common code via libraries if needed

**See also:** [Cross-Module Constraints](#cross-module-constraints), [Module-Specific Guidelines](#module-specific-guidelines)

---

## Cross-Module Constraints

### API and Frontend Separation

**MUST NOT** combine backend API changes with frontend changes in the same changeset.

The frontend references the backend OpenAPI specification via a version-controlled reference (`workspaces/frontend/scripts/swagger.version`). Frontend changes depending on API modifications **MUST** wait until those API changes are merged.

**When making API changes that affect frontend, MUST follow this order:**

1. Backend API changes **MUST** be complete and in the codebase first
2. Update `swagger.version` with the backend commit hash that includes the API changes
3. Regenerate frontend API client: `npm run generate:api`
4. Only then implement frontend changes that depend on the new API

### Generated Code

**MUST NOT** manually modify auto-generated code. Consult module-specific `AGENTS.md` files for:

- Which files are generated
- How to regenerate them properly

**Common generated files:**

- **Frontend**: `src/generated/` - OpenAPI client generated from backend spec
- **Controller**: `api/*/zz_generated.*.go` - Kubernetes client code
- **Backend**: Various generated files from OpenAPI annotations

**Regeneration commands:**

- Frontend: `npm run generate:api`
- Controller: `make generate` or `make manifests`
- Backend: Check module AGENTS.md

**See also:** [Code Organization](#code-organization), [Critical Components](#critical-components)

---

## Critical Components

Human approval **MUST** additionally be obtained for:

- **Custom Resource Definitions (CRDs)** — Breaking changes affect all users
- **Webhook logic** — Security and admission control critical
- **OpenAPI specifications** — Defines API contract between backend and frontend
- **Kustomize base manifests** — Changes propagate to all overlays

**See also:** [Change Boundaries](#change-boundaries), [Cross-Module Constraints](#cross-module-constraints)

---

## Error Handling

### General Principles

- **Fail explicitly**: Never swallow errors silently
- **Provide context**: Include relevant information in error messages
- **Return early**: Handle errors at point of occurrence
- **Log appropriately**: Error logs **SHOULD** be actionable

### Error Messages

**Good error messages include:**

- What went wrong
- What was being attempted
- Relevant context (resource name, namespace, etc.)
- How to fix or investigate further

✅ **Good**: "Failed to create workspace 'my-workspace' in namespace 'default': connection timeout"

❌ **Bad**: "error" or "API error"

### Error Recovery

- **Don't panic**: Use proper error return values
- **Handle expected errors**: Network timeouts, not found, etc.
- **Propagate unexpected errors**: Let callers decide how to handle
- **Clean up resources**: Use appropriate cleanup mechanisms (language-specific patterns in module AGENTS.md)

**See also:** [Logging](#logging)

---

## Logging

### Logging Levels

Use appropriate log levels:

- **ERROR**: Something failed, requires attention
- **WARN**: Unexpected but handled situation
- **INFO**: Important state changes, lifecycle events
- **DEBUG**: Detailed information for troubleshooting

### Logging Best Practices

✅ **DO**: Log

- Startup and shutdown events
- Configuration loaded
- Important state transitions
- Errors with full context
- External API calls (at DEBUG level)

❌ **DON'T**: Log

- Secrets, tokens, passwords
- Personally identifiable information (PII)
- Excessive debug info in production
- In tight loops (log at boundaries instead)

### Log Message Format

✅ **Good**: Include structured, contextual information

- Example: `Workspace "my-workspace" created successfully in namespace "default"`
- Include: resource names, namespaces, relevant IDs

❌ **Avoid**: Vague, unstructured messages

- Example: "Workspace created" (missing context)

**See also:** [Error Handling](#error-handling)

---

## Performance Considerations

### General Guidelines

- **Profile before optimizing**: Don't optimize without data
- **Design for scale**: Support multiple users, resources
- **Minimize network calls**: Batch operations when possible
- **Cache appropriately**: Use caching for expensive operations
- **Be mindful of resources**: CPU, memory, network bandwidth

### Frontend Performance

- **Lazy load**: Load components and data as needed
- **Minimize bundle size**: Tree-shake imports, code split
- **Optimize re-renders**: Use React.memo, useMemo, useCallback
- **Debounce user inputs**: Avoid excessive API calls

### Backend Performance

- **Limit list operations**: Use pagination, filtering
- **Use efficient queries**: Avoid N+1 queries
- **Set appropriate timeouts**: Don't let requests hang
- **Pool connections**: Reuse HTTP clients, database connections

### Controller Performance

- **Use watches, not polls**: Leverage Kubernetes watch API
- **Rate limit reconciles**: Prevent excessive reconciliation
- **Use caching**: Controller-runtime provides caching
- **Avoid blocking operations**: Don't block reconcile loop

**See also:** [Module-Specific Guidelines](#module-specific-guidelines)

---

## Kubernetes Best Practices

- Respect Kubeflow RBAC patterns and conventions
- Kustomize overlays **MUST NOT** break base configurations
- Service mesh (Istio) components are optional - keep them decoupled
- Use proper health checks (liveness, readiness probes)
- Set resource requests and limits appropriately
- Use namespaces for isolation
- Label resources consistently for observability

---

## Common Coding Pitfalls

### Cross-Module Violations

- ❌ **DON'T**: Mix API and frontend changes in the same changeset
- ✅ **DO**: Implement API changes first, then frontend changes separately
- ❌ **DON'T**: Manually edit generated files
- ✅ **DO**: Use regeneration commands (see module AGENTS.md)
- ❌ **DON'T**: Bypass module boundaries (e.g., frontend calling Kubernetes directly)
- ✅ **DO**: Respect separation: Frontend → Backend → Kubernetes

### Security and Safety

- ❌ **DON'T**: Commit secrets, tokens, or credentials
- ✅ **DO**: Use environment variables and Kubernetes secrets
- ❌ **DON'T**: Log sensitive data (passwords, tokens, PII)
- ✅ **DO**: Log contextual information for debugging
- ❌ **DON'T**: Skip input validation
- ✅ **DO**: Validate at all system boundaries

### Code Quality

- ❌ **DON'T**: Leave commented-out code or debug statements
- ✅ **DO**: Remove unused code (it's in git history)
- ❌ **DON'T**: Commit TODOs/FIXMEs without ticket references
- ✅ **DO**: Include issue numbers: `// TODO(#123): description`
- ❌ **DON'T**: Skip tests without ticket reference
- ✅ **DO**: File an issue first: `it.skip('test', () => {}); // Skip until #456`
- ❌ **DON'T**: Swallow errors silently
- ✅ **DO**: Provide context in error messages
- ❌ **DON'T**: Skip tests for "small changes"
- ✅ **DO**: Add tests for all functional changes
- ❌ **DON'T**: Assume generated code is current
- ✅ **DO**: Regenerate when needed (see Generated Code section)
- ❌ **DON'T**: Add comments that restate what the code does
- ✅ **DO**: Write self-documenting code; comment only the "why"

### Performance

- ❌ **DON'T**: Make N+1 queries or excessive API calls
- ✅ **DO**: Batch operations and use pagination
- ❌ **DON'T**: Block on long-running operations
- ✅ **DO**: Use async patterns appropriately

---

## Module-Specific Guidelines

Each module has its own AGENTS.md file with detailed guidance:

- **[Controller Guidelines](workspaces/controller/AGENTS.md)** - Kubernetes controller, CRDs, webhooks, reconciliation
- **[Backend Guidelines](workspaces/backend/AGENTS.md)** - Go API server, business logic, Kubernetes integration
- **[Frontend Guidelines](workspaces/frontend/AGENTS.md)** - React, TypeScript, UI/UX, PatternFly
- **[Cypress Testing Guidelines](workspaces/frontend/src/__tests__/cypress/AGENTS.md)** - E2E testing, page objects, test patterns

**Agents MUST read the module-specific guidelines when working in that module.**

---

## Quick Reference

### Critical Rules (MUST/MUST NOT)

| Rule                                                 | Severity |
| ---------------------------------------------------- | -------- |
| Never commit secrets, tokens, or credentials         | MUST NOT |
| Never mix API and frontend changes in same changeset | MUST NOT |
| Never manually edit generated files                  | MUST NOT |
| Never bypass module boundaries                       | MUST NOT |
| Obtain human approval for API/CRD/schema changes     | MUST     |
| Preserve existing behavior unless instructed         | MUST     |
| Validate inputs at system boundaries                 | MUST     |
| Include tests for all functional changes             | SHOULD   |

### Decision Tree: Can I Make This Change?

```
Is it a generated file (zz_generated.*, src/generated/)?
├── Yes → STOP. Regenerate instead, don't edit manually.
└── No → Does it change API contract, CRD, or schema?
    ├── Yes → STOP. Requires human approval first.
    └── No → Does it cross module boundaries?
        ├── Yes → STOP. Split into separate changes.
        └── No → ✅ Proceed. Follow module AGENTS.md.
```

### Decision Tree: When to Escalate to Human?

```
Am I uncertain about the correct approach?
├── Yes → Is there an existing pattern in the codebase?
│   ├── Yes → Follow the existing pattern.
│   └── No → ESCALATE. Ask human for guidance.
└── No → Could this change break existing functionality?
    ├── Yes → Are there tests covering this functionality?
    │   ├── Yes → Proceed carefully, run tests.
    │   └── No → ESCALATE. Discuss risk with human first.
    └── No → Does this involve security-sensitive code?
        ├── Yes → ESCALATE. Security changes need review.
        └── No → ✅ Proceed with implementation.
```

**Always escalate when:**

- Multiple valid approaches exist with significant trade-offs
- The task scope is unclear or seems larger than described
- You encounter unexpected errors after 2-3 attempts
- Changes affect authentication, authorization, or data integrity
- You're unsure if a dependency upgrade is safe

### Module Quick Links

| Module     | Path                                         | Key Responsibility             |
| ---------- | -------------------------------------------- | ------------------------------ |
| Controller | `workspaces/controller/`                     | CRDs, webhooks, reconciliation |
| Backend    | `workspaces/backend/`                        | HTTP API, business logic       |
| Frontend   | `workspaces/frontend/`                       | React UI, user experience      |
| Cypress    | `workspaces/frontend/src/__tests__/cypress/` | E2E tests                      |

### Pre-Change Checklist

- [ ] Read the relevant module's AGENTS.md
- [ ] Identify if change requires human approval
- [ ] Check for existing patterns to follow
- [ ] Verify no generated files need manual edits
- [ ] Plan for required tests
