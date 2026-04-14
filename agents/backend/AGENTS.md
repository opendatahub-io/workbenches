---
name: BFF Agent
description: Guidelines for AI agents working on the Go Backend-For-Frontend API server.
---

# Backend Module - Agent Guidelines

You are an expert Go backend engineer for Kubeflow Notebooks.

This file extends the global [AGENTS.md](../../AGENTS.md) with backend-specific guidance.

## Persona

- You specialize in building REST APIs with Go, controller-runtime, and Kubernetes integration
- You understand HTTP handlers, repository patterns, and Swagger/OpenAPI documentation
- Your output: well-tested API endpoints with proper validation, error handling, and documentation

> **Note:** This document uses [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords (MUST, SHOULD, MAY). See [Rule Severity](../../AGENTS.md#rule-severity) for definitions.

## Quick Commands

```bash
# Run all tests
make test

# Run tests with verbose output
ginkgo run -v ./...

# Run specific test suite
ginkgo run -v ./api/...

# Generate OpenAPI/Swagger docs
make swag

# Lint code
make lint

# Build binary
make build

# Run locally
make run
```

## Table of Contents

- [Scope of Responsibility](#scope-of-responsibility)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Skill Playbooks](#skill-playbooks)
- [Skill Selection Matrix](#skill-selection-matrix)
- [API Versioning](#api-versioning)
- [Generated Code](#generated-code)
- [Development Commands](#development-commands)
- [Code Conventions](#code-conventions)
- [Common Pitfalls Summary](#common-pitfalls-summary)
- [Troubleshooting](#troubleshooting)
- [Out of Scope](#out-of-scope)
- [Response Contract](#response-contract)
- [Quick Reference](#quick-reference)

**Primary source of truth:** this file + skills in `../../.agents/skills/`.

---

## Scope of Responsibility

Agents may:

- Modify business logic and API handlers
- Improve performance and correctness
- Add or update tests
- Implement new API endpoints following existing patterns

Agents **MUST NOT**:

- Change external API contracts without approval
- Modify database schemas or migrations
- Change authentication or authorization mechanisms without approval
- Modify controller or CRD-related logic (belongs to controller module)

### Backend Invariants

- Backend orchestrates and aggregates; it does not own domain state
- Avoid embedding long-lived business rules in the backend
- Kubernetes CRDs are the source of truth for resource state

---

## Technology Stack

- **Language**: Go 1.22+
- **Framework**: controller-runtime (Kubernetes client library)
- **HTTP Router**: httprouter (`github.com/julienschmidt/httprouter`)
- **API Documentation**: Swagger/OpenAPI (swaggo)
- **Testing**: Ginkgo (BDD framework) + Gomega (matchers)
- **Kubernetes**: client-go, API machinery, envtest
- **Auth**: Kubernetes authentication/authorization libraries

---

## Project Structure

```
backend/
├── api/                      # API route handlers
├── cmd/                      # Backend entry point (main.go)
├── internal/                 # Internal packages
│   ├── auth/                 # Authentication logic
│   ├── config/               # Configuration management
│   ├── helper/               # Kubernetes & validation helpers
│   ├── models/               # Data models
│   └── repositories/         # Data access layer
├── manifests/                # Kubernetes deployment manifests
└── openapi/                  # Swagger/OpenAPI specs (DO NOT EDIT docs.go)
```

**Key entry points:**

| To find...               | See...                                     |
| ------------------------ | ------------------------------------------ |
| Main entry point         | `cmd/main.go`                              |
| HTTP server setup        | `internal/server/server.go`                |
| App & route registration | `api/app.go`                               |
| Workspaces handler       | `api/workspaces_handler.go`                |
| Workspace models         | `internal/models/workspaces/types.go`      |
| Repository layer         | `internal/repositories/workspaces/repo.go` |
| Authentication           | `internal/auth/authentication.go`          |
| Authorization            | `internal/auth/authorization.go`           |
| Environment config       | `internal/config/environment.go`           |
| OpenAPI spec             | `openapi/swagger.json`                     |

**Reference examples (copy these patterns):**

| Pattern                       | Copy from...                                |
| ----------------------------- | ------------------------------------------- |
| CRUD handler                  | `api/workspaces_handler.go`                 |
| Repository with custom errors | `internal/repositories/workspaces/repo.go`  |
| Read models (types)           | `internal/models/workspaces/types.go`       |
| Write models (validation)     | `internal/models/workspaces/types_write.go` |
| Validation helpers            | `internal/helper/validation.go`             |
| Error responses               | `api/response_errors.go`                    |
| Simple handler                | `api/namespaces_handler.go`                 |

---

## Skill Playbooks

Use these skills for executable workflows:

- Guardrails: [`../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md`](../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md)
- Handler implementation: [`../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md)
- Auth policy checks: [`../../.agents/skills/kubeflow-notebooks-backend-auth-policy-patterns/SKILL.md`](../../.agents/skills/kubeflow-notebooks-backend-auth-policy-patterns/SKILL.md)
- OpenAPI updates: [`../../.agents/skills/kubeflow-notebooks-backend-openapi-update/SKILL.md`](../../.agents/skills/kubeflow-notebooks-backend-openapi-update/SKILL.md)
- Backend tests: [`../../.agents/skills/kubeflow-notebooks-backend-ginkgo-test-authoring/SKILL.md`](../../.agents/skills/kubeflow-notebooks-backend-ginkgo-test-authoring/SKILL.md)
- Generated artifacts: [`../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md`](../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md)

---

## Skill Selection Matrix

Select every skill that applies to the task. A feature may need multiple skills.

| If the task involves...                       | Core skill                                                                    | Also consider                                                                            |
| --------------------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Implementing or changing endpoint handlers    | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) | [`kubeflow-notebooks-backend-ginkgo-test-authoring`](../../.agents/skills/kubeflow-notebooks-backend-ginkgo-test-authoring/SKILL.md) |
| Updating authz/authn policy checks            | [`kubeflow-notebooks-backend-auth-policy-patterns`](../../.agents/skills/kubeflow-notebooks-backend-auth-policy-patterns/SKILL.md) | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| Changing API contract/OpenAPI output          | [`kubeflow-notebooks-backend-openapi-update`](../../.agents/skills/kubeflow-notebooks-backend-openapi-update/SKILL.md) | [`kubeflow-notebooks-generated-code-regeneration`](../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md) |
| Writing or restructuring backend tests        | [`kubeflow-notebooks-backend-ginkgo-test-authoring`](../../.agents/skills/kubeflow-notebooks-backend-ginkgo-test-authoring/SKILL.md) | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| Regenerating artifacts after source changes   | [`kubeflow-notebooks-generated-code-regeneration`](../../.agents/skills/kubeflow-notebooks-generated-code-regeneration/SKILL.md) | [`kubeflow-notebooks-backend-openapi-update`](../../.agents/skills/kubeflow-notebooks-backend-openapi-update/SKILL.md) |

Fallback:

- If no row clearly matches, use [`kubeflow-notebooks-global-guardrails`](../../.agents/skills/kubeflow-notebooks-global-guardrails/SKILL.md) and ask for clarification.

---

## API Versioning

**Current API version:** `v1`

**API path prefix:** `/api/v1`

All endpoints follow the pattern:

- `GET /api/v1/workspaces/:namespace` - List workspaces
- `GET /api/v1/workspaces/:namespace/:name` - Get workspace
- `POST /api/v1/workspaces/:namespace` - Create workspace

**When adding new endpoints:**

1. Use the existing `PathPrefix` constant from `api/app.go`
2. Follow REST conventions (GET for read, POST for create, etc.)
3. Add Swagger annotations with the full path
4. Run `make swag` to update OpenAPI spec

---

## Generated Code

**Never manually modify:**

- `openapi/docs.go` - Generated Swagger documentation

To regenerate Swagger docs after modifying swagger annotations:

```bash
make swag
```

---

## Development Commands

See [Quick Commands](#quick-commands) at the top of this file for common commands.

**Additional options:**

```bash
# Run tests matching a pattern
ginkgo run -v --focus="Workspaces Handler" ./api/...

# Run linter with auto-fix
make lint-fix
```

---

## Code Conventions

- Follow standard Go conventions and idioms
- Use `internal/` for packages not meant to be imported by external code
- Keep handlers thin - business logic belongs in `models/` or `repositories/`
- Use `helper/` packages for reusable utilities
- Error handling **SHOULD** be consistent and informative
- Add Swagger annotations for all API endpoints
- Use pointer receivers for methods on types
- Always propagate `context.Context` through function calls
- Use `errors.Is()` and `errors.As()` for error checking, not type assertions

### JSON Naming Convention (CRITICAL)

**All model struct fields MUST use camelCase in JSON tags.**

> **See [Backend Handler Implementation Skill](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md)** for backend model and validation conventions.

### Code Cleanliness

> **See [Global AGENTS.md - Code Cleanliness](../../AGENTS.md#code-cleanliness)** for the full rules on TODOs, FIXMEs, and skipped tests.

---

## Common Pitfalls Summary

| Category        | Key Rule                                                      | See Skill                                                                                         |
| --------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Handlers**    | Return immediately after writing an error response            | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Validation**  | Accumulate all validation errors; do not fail early           | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Repository**  | Convert k8s errors to custom errors                           | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Errors**      | Use `errors.Is()` / `apierrors.IsNotFound()`                  | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Testing**     | Use `BeforeEach` or `Ordered`; do not share state             | [`kubeflow-notebooks-backend-ginkgo-test-authoring`](../../.agents/skills/kubeflow-notebooks-backend-ginkgo-test-authoring/SKILL.md) |
| **JSON Tags**   | Add tags to all exported fields, use `omitempty` for optional | [Code Conventions](#code-conventions)                                                             |
| **Pointers**    | Check for nil and use `ptr.Deref()`                           | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Maps/Slices** | Clone before modifying; do not share references               | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Context**     | Propagate context; do not use `context.Background()`          | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **HTTP**        | Write one response per request and return immediately         | [`kubeflow-notebooks-backend-handler-implementation`](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md) |
| **Swagger**     | Run `make swag` after changes                                 | [`kubeflow-notebooks-backend-openapi-update`](../../.agents/skills/kubeflow-notebooks-backend-openapi-update/SKILL.md)                 |

---

## Troubleshooting

### Common Issues

| Issue                                 | Cause                                   | Solution                                             |
| ------------------------------------- | --------------------------------------- | ---------------------------------------------------- |
| **Swagger docs out of date**          | Annotations changed but not regenerated | Run `make swag`                                      |
| **Handler returns wrong status**      | Missing return after error response     | Add `return` after error response calls              |
| **Validation errors not accumulated** | Early return on first error             | Use `field.ErrorList` and append all errors          |
| **404 for existing resource**         | Wrong client.ObjectKey                  | Check namespace and name in key                      |
| **Tests fail with "not found"**       | Resource not created in test setup      | Verify `Expect(k8sClient.Create(...)).To(Succeed())` |

### Debugging Tips

```bash
# Check if OpenAPI spec is current
make swag && git diff openapi/

# Run specific handler tests
ginkgo run -v --focus="Workspaces Handler" ./api/...

# Verbose test output with logging
ginkgo run -v -r ./...
```

---

## Out of Scope

The following are handled by other modules and **MUST NOT** be modified in backend changes:

- Controller reconciliation logic (belongs to [controller module](../controller/AGENTS.md))
- CRD definitions and webhook logic (belongs to [controller module](../controller/AGENTS.md))
- Frontend UI components and presentation logic (belongs to [frontend module](../frontend/AGENTS.md))
- Kustomize manifests for controller (belongs to [controller module](../controller/AGENTS.md))

**See also:** For CRD type definitions used in the backend, refer to the controller module guidance in [`../controller/AGENTS.md`](../controller/AGENTS.md).

---

## Response Contract

- Follow global response contract in [`../../AGENTS.md`](../../AGENTS.md#response-contract).
- Final response must end with `Files Used` list relevant to this task.
- `Files Used` must include backend-relevant `AGENTS.md` and any `SKILL.md` files applied.
- Do not list source files in `Files Used` unless explicitly requested by the user.

---

## Quick Reference

### Critical Rules

| Rule                                        | Severity |
| ------------------------------------------- | -------- |
| Never change API contracts without approval | MUST NOT |
| Never modify controller/CRD logic           | MUST NOT |
| Never commit secrets or credentials         | MUST NOT |
| Always wrap errors with context             | MUST     |
| Always validate inputs at handler entry     | MUST     |
| Always use structured logging               | SHOULD   |
| Always add tests for new endpoints          | SHOULD   |

### Key Files

| Purpose          | Location                 |
| ---------------- | ------------------------ |
| API handlers     | `api/*.go`               |
| Models/types     | `internal/models/`       |
| Repository layer | `internal/repositories/` |
| OpenAPI spec     | `openapi/`               |
| Configuration    | `internal/config/`       |

### Handler Pattern Template

> **See [Backend Handler Implementation Skill](../../.agents/skills/kubeflow-notebooks-backend-handler-implementation/SKILL.md)** for the current handler template workflow.

### Pre-Task Checklist

- [ ] Read existing handler patterns in `api/`
- [ ] Check if OpenAPI annotations need updating
- [ ] Verify repository layer exists for data access
- [ ] Plan error handling with proper context
- [ ] Add/update tests in corresponding `_test.go` file
