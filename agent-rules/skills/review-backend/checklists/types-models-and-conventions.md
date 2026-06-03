# Types, Models & Conventions Review Checklist

## Project Context

The backend uses a structured model layer under `internal/models/`:

- **Model sub-packages** mirror the API URL structure (e.g., `internal/models/workspacekinds/podtemplate/options/`).
- **Type files**: `types.go` (read models), `types_write.go` (create/update models). **Conversion files**: `funcs.go` (CRD-to-model), `funcs_write.go` (model-to-CRD).
- Conversion functions convert directly between controller CRD types (`kubefloworgv1beta1.*`) and backend model types — never model-to-model.
- **Import ordering**: (1) stdlib, (2) external packages (`k8s.io`, `github.com/...`), (3) internal packages (`github.com/kubeflow/notebooks/workspaces/backend/...`). Each group separated by a blank line.
- **Standard aliases**: `models` for model packages, `repository` for repo packages, `apierrors` for `k8s.io/apimachinery/pkg/api/errors`, `metav1` for `k8s.io/apimachinery/pkg/apis/meta/v1`, `kubefloworgv1beta1` for controller API types.

## Checklist

### Naming Conventions

- [ ] **Lowercase variable names**: Local variables must use camelCase, not PascalCase (e.g., `virtualServiceName` not `VirtualServiceName`).
- [ ] **Function names avoid type conflicts**: Function names should not collide with well-known type names from imported packages. Add a qualifying prefix/suffix (e.g., `generateVirtualServiceHTTPRoute` instead of `HTTPRoute`).
- [ ] **Handler function naming**: Action handlers that handle both directions of a toggle should use a unified name (e.g., `HandlePauseAction` covering both pause and unpause, not separate `PauseWorkspace`/`UnpauseWorkspace`).
- [ ] **Descriptive cross-reference type names**: Types that represent cross-references to other resources should use the `Info` suffix and indicate the domain clearly (e.g., `PodInfo`, `WorkspaceInfo`, `StorageClassInfo`) — not ambiguous names like `PVCPod` or `PVStorageClass`.

### Model Conversion Functions

- [ ] **Construct pieces then assemble**: Builder functions (e.g., `NewWorkspaceListItemFromWorkspace`) should construct individual "pieces" at the top of the function, setting empty/default values explicitly, then assemble the full output object at the bottom with all fields visible in one place.
- [ ] **No model-to-model conversion chains**: Conversion functions should convert directly between CRD types and model types (in either direction). Do not create functions that convert one model type into another model type (e.g., `BuildResponseFromModel(model)`) — this indicates the intermediate model is unnecessary or that the conversion should operate on the CRD directly. Each conversion should be a single hop: `CRD → Model` or `Model → CRD`.
- [ ] **Error-returning conversions when user input drives filtering**: When a conversion function accepts user-provided input that selects or filters data (e.g., a context ID that must match an option in the CRD), the function MUST return `(T, error)`, not just `T`. Invalid user input (like a filter ID that doesn't exist in the source data) MUST produce an aggregated `helper.NewInternalValidationError(fieldErrors)`, not silently return empty results. The handler then checks `helper.IsInternalValidationError(err)` and returns 422.
- [ ] **Map copies**: When copying maps from Kubernetes types to model types, create a new map and copy entries rather than using the original map reference.
- [ ] **Switch on enums without default**: When converting enum values between Kubernetes types and model types, use switch statements WITHOUT a default case so that the linter catches missing cases when new values are added.
- [ ] **Build lookup maps**: When needing to find items by ID multiple times, build a `map[id]item` first rather than iterating through slices repeatedly.

### Type Safety

- [ ] **Use native Kubernetes types over strings**: Prefer Kubernetes enum types from `corev1` (e.g., `corev1.PersistentVolumeAccessMode`, `corev1.PersistentVolumeMode`, `corev1.PodPhase`) and controller CRD types (e.g., `kubefloworgv1beta1.WorkspaceState`) instead of raw strings. This provides compile-time safety and auto-documents the API via OpenAPI enum values.
- [ ] **Single source of truth for types**: Backend model types should reference controller CRD types rather than duplicating them. Avoid defining parallel enums or state constants in the backend when the controller already defines them.
- [ ] **Export types used in exported struct fields**: Types that appear as fields in exported structs MUST be exported (PascalCase). Unexported types in exported fields prevent downstream packages from constructing or comparing values. Additionally, do not reuse a single type for semantically different purposes — create distinct types even if the fields are currently identical (e.g., `ClusterKindMetrics` for workspace-kind-level metrics vs `ClusterOptionMetrics` for per-option metrics).

### Import Ordering & Aliases

- [ ] **Three-group import ordering**: Imports must follow: (1) stdlib, (2) external packages (k8s.io, github.com/..., etc.), (3) internal packages (github.com/kubeflow/notebooks/workspaces/backend/...). Each group separated by a blank line.
- [ ] **Model package aliases**: Model packages MUST be imported with the alias `models` (e.g., `models "...internal/models/workspaces"`). Repository packages MUST be imported with the alias `repository` (e.g., `repository "...internal/repositories/workspaces"`).
- [ ] **Kubernetes API aliases**: Follow existing conventions: `apierrors` for `k8s.io/apimachinery/pkg/api/errors`, `metav1` for `k8s.io/apimachinery/pkg/apis/meta/v1`, `kubefloworgv1beta1` for controller API types.
