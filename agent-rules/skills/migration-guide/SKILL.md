---
name: migration-guide
description: Update the Notebook-to-Workspace migration guide with new context, decisions, or code changes
---

# Migration Guide Maintenance

Continue iterating on the Notebook CRD to WorkspaceKind + Workspace migration analysis. This skill bootstraps context from prior research so new sessions can pick up where we left off.

## When to Use

Use this skill when:
- New decisions have been made about migration approach or CRD changes
- Code changes affect the Workspace or WorkspaceKind CRDs
- A friction point has been resolved or a new one discovered
- You need to update the migration guide with customer-specific findings

Invoke with `/migration-guide` followed by what changed or what you want to update.

## Key Files to Read

Before making any changes, read these files to understand current state:

1. **Migration guide** (the document being maintained):
   `notebook-to-workspace-migration-guide.md` (repo root)

2. **Feature comparison** (broader v1 vs v2 analysis):
   `feature-comparison-v1-vs-v2.md` (repo root)

3. **v2 CRD types** (source of truth for v2 field structure):
   - `workspaces/controller/api/v1beta1/workspace_types.go`
   - `workspaces/controller/api/v1beta1/workspacekind_types.go`

4. **v2 CRD manifests** (generated schema):
   - `workspaces/controller/manifests/kustomize/base/crd/kubeflow.org_workspaces.yaml`
   - `workspaces/controller/manifests/kustomize/base/crd/kubeflow.org_workspacekinds.yaml`

5. **Sample WorkspaceKinds** (reference implementations):
   - `workspaces/controller/manifests/kustomize/samples/jupyterlab_v1beta1_workspacekind.yaml`
   - `workspaces/controller/manifests/kustomize/samples/rstudio_v1beta1_workspacekind.yaml`
   - `workspaces/controller/manifests/kustomize/samples/codeserver_v1beta1_workspacekind.yaml`
   - `workspaces/controller/manifests/kustomize/samples/jupyterlab_v1beta1_workspace.yaml`

6. **Legacy Notebook CRD** (v1 source, in separate repo):
   - `/Users/astonebe/Development/Code/GitHub/kubeflow/components/notebook-controller/api/v1/notebook_types.go`

## Background Context

### Architecture Difference
- **v1**: Single `Notebook` CRD with full PodSpec. Users specify everything.
- **v2**: `WorkspaceKind` (cluster-scoped, admin-defined templates) + `Workspace` (namespaced, user selections). Admin governance model.

### Migration is a 3-step process
1. **Fleet analysis**: Inventory existing Notebooks to find unique images, resource profiles, and non-mappable features
2. **WorkspaceKind design**: Group notebooks by type and create WorkspaceKinds with curated imageConfig and podConfig options
3. **Workspace creation**: Map each Notebook to a Workspace referencing the appropriate WorkspaceKind and options

### Known High-Friction Points (as of 2026-03-23)
These are v1 features with no direct v2 equivalent:
- **F1**: No arbitrary image selection (must use admin-curated imageConfig options)
- **F2**: No per-workspace environment variables (all env vars come from WorkspaceKind)
- **F3**: No `envFrom` support
- **F4**: No container command/args override
- **F5**: No init containers
- **F6**: No sidecar containers
- **F7**: No arbitrary resource specs (must use admin-curated podConfig options)
- **F8**: Home volume mount path is per-WorkspaceKind (immutable)

### Known Missing PodSpec Fields (as of 2026-03-23)
Fields in v1's PodSpec not exposed in v2:
- `schedulerName`, `priorityClassName`, `topologySpreadConstraints`
- `imagePullSecrets`, `dnsPolicy`, `dnsConfig`, `hostAliases`
- `automountServiceAccountToken`, `runtimeClassName`
- `containers[0].lifecycle` (postStart/preStop hooks)

### Key Design Decisions Already Made
- v2 uses StatefulSets (same as v1), not bare Pods
- v2 has no dedicated restart action (pause + unpause achieves restart)
- `status.pendingRestart` tracks config drift from option redirects or mutable WorkspaceKind field changes; v2 intentionally does NOT auto-restart workspaces
- Culling CRD schema is designed but controller probe execution and auto-pause are not yet wired (#741, #867, #868)

## How to Update

1. Read the migration guide and feature comparison files first
2. Read the v2 CRD Go types if the change involves field mappings
3. Make targeted edits to the relevant sections
4. If a friction point is resolved by a code change, move it from the friction section and update the field mapping table
5. If a new friction point is discovered, add it with an F-number to the friction summary (Section 3.1 or 3.2)
6. Keep the migration process steps (Section 5) and decision flowchart (Section 7) in sync with any field mapping changes
