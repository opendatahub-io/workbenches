# Correctness & Safety Review Checklist

## Project Context

The backend uses a layered error handling approach:

- **Repository layer** (`internal/repositories/`): Defines named sentinel errors (e.g., `ErrWorkspaceNotFound`, `ErrWorkspaceAlreadyExists`). Converts Kubernetes API errors to these sentinels. Also performs resource existence and label validation before create/update operations.
- **Handler layer** (`api/`): Checks errors with `errors.Is()` in a specific order and maps to HTTP responses. Distinguishes between internal validation errors (`helper.IsInternalValidationError`) and Kubernetes API validation errors (`apierrors.IsInvalid`).
- **Validation**: Uses `field.ErrorList` from `k8s.io/apimachinery/pkg/util/validation/field`. Errors are aggregated (never fail on first error) and wrapped via `helper.NewInternalValidationError(fieldErrors)`. Field paths mirror the JSON request body structure.
- **Label-based access control**: Resources carry labels like `notebooks.kubeflow.org/can-mount=true` to control which PVCs/Secrets can be mounted and which StorageClasses can be used.
- **Pointer helpers**: `ptr.Deref(field, default)` for safely reading optional pointer fields, `ptr.To(value)` for setting them.

## Checklist

### Error Handling

- [ ] **Specific repository errors**: Repository functions must define named sentinel errors (e.g., `ErrWorkspaceNotFound`, `ErrWorkspaceAlreadyExists`). Handlers check these with `errors.Is()`.
- [ ] **Internal vs Kubernetes validation errors**: Distinguish between internal validation errors (business logic, pre-K8s-call) and Kubernetes API validation errors (from the API server). Use `helper.NewInternalValidationError(fieldErrors)` for internal validation, and `helper.IsInternalValidationError(err)` to check in handlers.
- [ ] **Handler error hierarchy**: Handlers must check errors in this order: (1) `helper.IsInternalValidationError` → 422, (2) sentinel errors like `ErrNotFound` → 404, (3) permission/label errors like `ErrNotCanUpdate` → 400, (4) `apierrors.IsConflict` → 409, (5) `apierrors.IsInvalid` → 422 with StatusCauses, (6) default → 500.
- [ ] **Kubernetes error translation**: When a Kubernetes API error is received, extract `StatusCauses` using `helper.StatusCausesFromAPIStatus(err)` and pass them to the appropriate response helper.
- [ ] **No leaked internal errors**: `serverErrorResponse` logs the real error but returns a generic message to the client. Never expose internal error details in 500 responses.

### Resource Validation & Data Integrity

- [ ] **Validate referenced resources exist before use**: When a Workspace (or PVC) references another resource (PVC, Secret, StorageClass), the repository layer must validate the resource exists in the cluster before creating or updating the parent resource. Use the `helper.ValidateKubernetes*` functions for this.
- [ ] **Label-based access control**: Resources must carry the appropriate label to be referenced:
  - PVCs and Secrets require `notebooks.kubeflow.org/can-mount=true` to be mounted in Workspaces (validated by `helper.ValidateKubernetesPVCIsMountable` / `helper.ValidateKubernetesSecretIsMountable`)
  - PVCs and Secrets require `notebooks.kubeflow.org/can-update=true` to be modified or deleted
  - StorageClasses require `notebooks.kubeflow.org/can-use=true` to be used for PVC creation (validated by `helper.ValidateKubernetesStorageClassIsUsable`)
- [ ] **Aggregate validation errors**: Collect all `field.ErrorList` errors across home PVC, data PVCs, and secrets before returning. Do NOT fail on the first error — aggregate using `allValErrs = append(allValErrs, valErrs...)` then return `helper.NewInternalValidationError(allValErrs)` at the end.
- [ ] **Structured field paths**: Validation errors must use field paths matching the JSON request body structure (e.g., `podTemplate.volumes.data[0].pvcName`, `podTemplate.volumes.secrets[1].secretName`).
- [ ] **Validate on both Create and Update**: The same resource existence and label validation must be applied in both `CreateWorkspace` and `UpdateWorkspace` repository methods. Do not skip validation on updates.
- [ ] **Domain-specific validation helpers**: Use named validation functions (e.g., `ValidateKubernetesPVCName`, `ValidateKubernetesSecretName`) even if the implementation is identical to a generic function. Named functions serve as documentation and allow future specialization.
- [ ] **Validate methods on nested backend model types**: Each backend-owned model struct with validatable fields SHOULD have its own `Validate(prefix *field.Path)` method. Parent validators pass `prefix.Child("fieldName")` to child validators rather than constructing multi-level paths inline (e.g., avoid `prefix.Child("namespace", "name")` — instead pass `prefix.Child("namespace")` to `ContextNamespace.Validate()`). This does NOT apply to fields that are controller CRD types, which have their own validation via webhooks.

### Pointer Safety

- [ ] **Use `ptr.Deref` for optional fields**: When reading optional pointer fields from Kubernetes types, use `ptr.Deref(field, defaultValue)` to avoid nil pointer dereferences.
- [ ] **Use `ptr.To` for setting pointers**: When setting optional pointer fields, use `ptr.To(value)`.
- [ ] **Guard `ptr.To` for optional strings with CRD validation**: When a model field is `string` (with `omitempty`) but the CRD field is `*string` with `MinLength` validation, do NOT use `ptr.To(value)` directly — `ptr.To("")` will fail CRD validation. Return `nil` for empty strings instead.
