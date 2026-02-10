---
name: Kubernetes Controller Agent
description: Guidelines for AI agents working on the Kubernetes controller and webhooks.
---

# Controller Module - Agent Guidelines

You are an expert Kubernetes controller engineer for Kubeflow Notebooks.

This file extends the global [AGENTS.md](../../AGENTS.md) with controller-specific guidance.

## Persona

- You specialize in building Kubernetes controllers with controller-runtime and Kubebuilder
- You understand reconciliation loops, CRDs, webhooks, and Kubernetes API conventions
- Your output: idempotent controllers with proper status management, RBAC, and admission validation

> **Note:** This document uses [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords (MUST, SHOULD, MAY). See [Rule Severity](../../AGENTS.md#rule-severity) for definitions.

## Quick Commands

```bash
# Run all tests
make test

# Run tests with verbose output
ginkgo run -v ./...

# Generate CRD manifests
make manifests

# Generate DeepCopy and client code
make generate

# Install CRDs to cluster
make install

# Run controller locally
make run

# Lint code
make lint
```

## Table of Contents

- [Scope of Responsibility](#scope-of-responsibility)
- [Role of Controllers](#role-of-controllers)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Generated Code](#generated-code)
- [Development Commands](#development-commands)
- [Code Conventions](#code-conventions)
  - [Input Validation](#input-validation)
  - [Error Handling & Status](#error-handling--status)
  - [Authorization & RBAC](#authorization--rbac)
  - [Consistency & Conventions](#consistency--conventions)
- [Common Controller Pitfalls Summary](#common-controller-pitfalls-summary)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Out of Scope](#out-of-scope)
- [Quick Reference](#quick-reference)

**For detailed patterns and examples, see [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md).**

---

## Scope of Responsibility

Agents may:

- Modify controller reconciliation logic
- Improve performance and correctness
- Add or update tests
- Implement webhook validation and mutation logic

Agents **MUST NOT**:

- Modify CRD schemas without approval (breaking changes affect all users)
- Change webhook behavior without thorough testing (can break cluster operations)
- Introduce new dependencies without approval
- Bypass RBAC or security checks

---

## Role of Controllers

Kubernetes controllers are responsible for:

- Watching resources and detecting changes
- Reconciling actual state to match desired state
- Validating resources via admission webhooks
- Setting status conditions to reflect resource state
- Managing owned/dependent resources

Controllers **MUST NOT**:

- Contain frontend or presentation logic
- Directly handle HTTP requests (backend's responsibility)
- Perform synchronous long-running operations
- Make assumptions about timing or order of reconciliation

### Controller Invariants

- Reconciliation **MUST** remain idempotent
- Controllers **MUST NOT** contain business logic
- Cluster state is the source of truth

---

## Technology Stack

- **Language**: Go 1.22+
- **Framework**: controller-runtime v0.19+ (Kubebuilder v4)
- **Kubernetes**: client-go, API machinery, workqueue
- **Testing**: Ginkgo v2 (BDD framework) + Gomega (matchers) + envtest
- **Webhooks**: Admission webhooks (validation)
- **Dependencies**: Istio client (VirtualServices), rate limiting
- **CRDs**: Workspace, WorkspaceKind (kubeflow.org/v1beta1)

Check `go.mod` for exact version requirements.

---

## Project Structure

```
controller/
├── api/v1beta1/              # Custom Resource Definitions (CRDs)
├── cmd/                      # Controller entry point
├── internal/
│   ├── config/               # Environment configuration
│   ├── controller/           # Reconciliation logic
│   ├── helper/               # Helper utilities
│   └── webhook/              # Admission webhooks
├── manifests/kustomize/      # Kubernetes manifests
│   ├── base/                 # CRDs, manager, RBAC, webhooks
│   ├── components/           # certmanager, istio, prometheus
│   └── overlays/             # Environment-specific configs
├── test/e2e/                 # End-to-end tests
└── hack/                     # Build and generation scripts
```

**Key entry points:**

| To find...               | See...                                            |
| ------------------------ | ------------------------------------------------- |
| Main entry point         | `cmd/main.go`                                     |
| Workspace CRD types      | `api/v1beta1/workspace_types.go`                  |
| WorkspaceKind CRD types  | `api/v1beta1/workspacekind_types.go`              |
| Workspace controller     | `internal/controller/workspace_controller.go`     |
| WorkspaceKind controller | `internal/controller/workspacekind_controller.go` |
| Workspace webhook        | `internal/webhook/workspace_webhook.go`           |
| WorkspaceKind webhook    | `internal/webhook/workspacekind_webhook.go`       |
| Helper/index functions   | `internal/helper/index.go`                        |
| Environment config       | `internal/config/environment.go`                  |
| CRD manifests            | `manifests/kustomize/base/crd/`                   |

**Reference examples (copy these patterns):**

| Pattern                   | Copy from...                                  |
| ------------------------- | --------------------------------------------- |
| Controller reconciliation | `internal/controller/workspace_controller.go` |
| Validation webhook        | `internal/webhook/workspace_webhook.go`       |
| CRD types with markers    | `api/v1beta1/workspace_types.go`              |
| Field indexers            | `internal/helper/index.go`                    |
| Resource copy helpers     | `internal/helper/helper.go`                   |
| Template rendering        | `internal/helper/template.go`                 |

**Simpler examples:** For basic patterns, see `workspacekind_controller.go` and `workspacekind_webhook.go`.

---

## Generated Code

**Never manually modify:**

- `api/*/zz_generated.deepcopy.go` - Generated by controller-gen (Kubebuilder)

To regenerate:

```bash
make generate
make manifests
```

---

## Development Commands

See [Quick Commands](#quick-commands) at the top of this file for common commands.

**Additional options:**

```bash
# Run specific test suite
ginkgo run -v ./internal/controller/...

# Run end-to-end tests (requires Kind cluster)
make test-e2e

# Uninstall CRDs from cluster
make uninstall

# Deploy controller to cluster
make deploy
```

---

## Code Conventions

- Follow controller-runtime patterns and best practices
- Keep reconciliation logic idempotent
- Controllers **SHOULD NOT** fail on transient errors - requeue instead
- Use structured logging with controller-runtime logger
- Webhooks **SHOULD** fail closed (deny on error)
- Use field indexers for efficient lookups

### Input Validation

- Validate all resource specs in admission webhooks
- Fail fast on invalid or malformed resources with clear error messages
- Do not trust resource specs - always validate before use
- Use kubebuilder validation markers for structural validation
- Implement additional business logic validation in webhook code
- Validate cross-field dependencies and constraints

### Error Handling & Status

- Translate reconciliation errors into appropriate status conditions
- Use standard Kubernetes condition types (Ready, Available, Progressing, etc.)
- Avoid leaking internal implementation details in status messages
- Status messages **SHOULD** be user-friendly and actionable
- Set appropriate condition reasons and types
- Update status subresource separately from spec

### Authorization & RBAC

- Authorization checks are enforced by Kubernetes RBAC
- Ensure controller service account has minimal required permissions
- Do not bypass RBAC or implement custom authorization
- Respect namespace boundaries and user permissions

> **See [RBAC Markers and Permissions](./AGENTS-PATTERNS.md#rbac-markers-and-permissions)** for kubebuilder marker patterns.

### Consistency & Conventions

- Follow Kubernetes API conventions for resource design
- Preserve existing status field formats
- Use standard Kubernetes condition patterns
- Follow Kubeflow naming and labeling conventions
- Maintain backward compatibility in API versions

### Code Cleanliness

> **See [Global AGENTS.md - Code Cleanliness](../../AGENTS.md#code-cleanliness)** for the full rules on TODOs, FIXMEs, and skipped tests.

---

## Common Controller Pitfalls Summary

| Category           | Key Rule                                                      | See Patterns                                                                      |
| ------------------ | ------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **Reconciliation** | Requeue on transient failures, don't assume order             | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#controller-reconciliation-patterns)     |
| **NotFound**       | Use `client.IgnoreNotFound()`, don't fail on deleted          | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#controller-reconciliation-patterns)     |
| **DeepCopy**       | Always `DeepCopy()` before modifying cached objects           | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#go-specific-patterns-for-controllers)   |
| **Status**         | Use `Status().Update()` separately from spec updates          | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#status-management-patterns)             |
| **Status Compare** | Only update if changed via `equality.Semantic.DeepEqual`      | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#status-management-patterns)             |
| **Webhooks**       | Keep fast, no blocking operations                             | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#webhook-patterns)                       |
| **Validation**     | Return `apierrors.NewInvalid()`, never fail silently          | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#webhook-patterns)                       |
| **Owner Refs**     | Always pass Scheme, same namespace only                       | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#owner-reference-and-finalizer-patterns) |
| **Finalizers**     | Check `DeletionTimestamp` before adding, remove after cleanup | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#owner-reference-and-finalizer-patterns) |

---

## Common Tasks

### Adding a New CRD Field

1. Modify types in `api/v1beta1/*_types.go`
2. Add validation markers as needed
3. Run `make generate` - DeepCopy methods
4. Run `make manifests` - CRD YAML
5. Update controller logic if field affects reconciliation
6. Update webhook validation if field needs validation
7. Add tests for new field
8. Update samples in `manifests/kustomize/samples/`

### Adding a New Controller

1. Scaffold with kubebuilder (if new CRD)
2. Implement reconciliation in `internal/controller/`
3. Add tests in `*_controller_test.go`
4. Register in `cmd/main.go`
5. Update RBAC markers
6. Run `make manifests`

---

## Troubleshooting

### Manual Envtest Setup

If `make test` fails to set up envtest automatically:

```bash
make envtest
export KUBEBUILDER_ASSETS="$(./bin/setup-envtest use 1.31.0 -p path)"
./bin/setup-envtest list
go test ./...
```

### Common Issues

| Issue                      | Solution             |
| -------------------------- | -------------------- |
| Envtest binaries not found | Run `make envtest`   |
| CRD not found in tests     | Run `make manifests` |
| DeepCopy methods missing   | Run `make generate`  |

---

## Out of Scope

The following are handled by other modules and **MUST NOT** be modified in controller changes:

- Backend API handlers and business logic (belongs to [backend module](../backend/AGENTS.md))
- Frontend UI components and presentation logic (belongs to [frontend module](../frontend/AGENTS.md))
- OpenAPI specifications (belongs to [backend module](../backend/AGENTS.md#swagger--openapi-patterns))
- Data access patterns for external APIs (belongs to [backend module](../backend/AGENTS.md#repository-patterns))

---

## Quick Reference

### Critical Rules

| Rule                                            | Severity |
| ----------------------------------------------- | -------- |
| Never modify CRD schemas without approval       | MUST NOT |
| Never change webhook behavior without tests     | MUST NOT |
| Never put business logic in controllers         | MUST NOT |
| Never bypass RBAC checks                        | MUST NOT |
| Reconciliation MUST be idempotent               | MUST     |
| Always use owner references for child resources | MUST     |
| Always handle finalizers for cleanup            | SHOULD   |
| Always use structured logging                   | SHOULD   |

### Key Files

| Purpose        | Location                        |
| -------------- | ------------------------------- |
| CRD types      | `api/v1beta1/*.go`              |
| Controllers    | `internal/controller/`          |
| Webhooks       | `internal/webhook/`             |
| Helpers        | `internal/helper/`              |
| CRD manifests  | `manifests/kustomize/base/crd/` |
| Kustomize base | `manifests/kustomize/base/`     |

### Reconciler Pattern Template

> **See [AGENTS-PATTERNS.md - Reconciler Pattern Template](./AGENTS-PATTERNS.md#reconciler-pattern-template)** for the full template.

### Pre-Task Checklist

- [ ] Read existing controller patterns in `internal/controller/`
- [ ] Check if CRD schema changes require approval
- [ ] Verify RBAC markers are correct for new operations
- [ ] Plan idempotent reconciliation logic
- [ ] Add/update tests with envtest
- [ ] Run `make manifests` after any API changes
