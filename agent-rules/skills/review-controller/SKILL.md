---
name: review-controller
description: Review a pull request that touches workspaces/controller/
argument-hint: "[PR number or branch]"
---

# Review Controller PR

Review a pull request that touches `workspaces/controller/` using the project's established conventions and review standards derived from @thesuperzapper's review patterns.

## When to Use

Use this skill when reviewing PRs that modify files under `workspaces/controller/`. Invoke with `/review-controller` optionally followed by a PR number or branch name.

## How to Perform the Review

1. Identify all changed files in `workspaces/controller/`. **IMPORTANT: NEVER use `main` or `origin/main` as the base.**

   **Option A — PR number (preferred):** If `$ARGUMENTS` contains a PR number, OR you can detect one from the current branch, use `gh pr diff` — this is always correct regardless of local ref staleness:
   ```bash
   PR_NUMBER="${ARGUMENTS:-$(gh pr view --json number --jq .number 2>/dev/null)}"
   gh pr diff "$PR_NUMBER" -- workspaces/controller/
   ```

   **Option B — Local merge-base (fallback):** Only if no PR number is available, fetch the remote first to avoid stale refs, then compute merge-base:
   ```bash
   git fetch upstream notebooks-v2 2>/dev/null || git fetch origin notebooks-v2
   BASE=$(git merge-base HEAD upstream/notebooks-v2 2>/dev/null || git merge-base HEAD origin/notebooks-v2)
   git diff ${BASE}..HEAD -- workspaces/controller/
   ```

   Do NOT diff directly against `upstream/notebooks-v2` HEAD — if upstream has received new commits since the branch was created, a direct diff will show those upstream changes in reverse.
2. Read each changed file in full, plus any files they import or reference
3. Check each item in the review checklist below
4. **Only flag issues introduced by this PR.** Cross-reference each finding against the diff to confirm the flagged code is new or modified in this changeset. If you notice a pre-existing issue in surrounding code that was NOT changed in the diff, you may mention it separately under a "Pre-existing Issues" heading — but clearly label it as pre-existing and do NOT include it in the severity-ranked findings. Never suggest fixing code that was not touched by this PR without labeling it as pre-existing.
5. Report findings organized by severity:
   - **MUST FIX**: Correctness issues (wrong equality comparison, nil pointer dereference, missing CRD markers, security issues like allow-all AuthorizationPolicy)
   - **SHOULD FIX**: Convention violations (wrong import order, wrong naming, missing test cases, using `reflect.DeepEqual` for K8s types)
   - **SUGGESTION**: Style improvements (better variable names, cleaner structure, additional comments)
6. For each finding, quote the relevant code and explain which convention is violated

## Review Checklist

### CRD Type Definitions (`api/v1beta1/`)

- [ ] **Thorough type documentation**: Every exported type and field MUST have a doc comment. These comments appear in `kubectl explain` output and are the primary documentation for cluster operators. Explain what the field does, not just what it is.
- [ ] **Kubebuilder validation markers**: Use appropriate `+kubebuilder:validation:` markers for all fields: `MinLength`, `MaxLength`, `Pattern`, `MinItems`, `Minimum`, `Maximum`, `Enum`, `Optional`, `XValidation` for cross-field validation. Check that markers match the field's intended constraints.
- [ ] **Optional fields use pointers**: Fields that have defaults or can be omitted must be pointer types (`*string`, `*bool`, `*int32`) with `+kubebuilder:validation:Optional` and `+kubebuilder:default=` markers.
- [ ] **List type annotations**: Lists that should be merged by key must use `+listType:="map"` and `+listMapKey:="id"` (or appropriate key field). This enables strategic merge patching.
- [ ] **Immutability markers**: Fields that should not change after creation must have `+kubebuilder:validation:XValidation:rule="self == oldSelf",message="field is immutable"`.
- [ ] **Section headers**: Use the block comment style with `===` separators to organize major sections (Spec, Status, root type, list type).
- [ ] **Run make manifests generate**: After ANY change to types in `api/v1beta1/`, `make manifests` and `make generate` must be run and the regenerated files must be committed.

### Import Ordering & Aliases

- [ ] **Three-group import ordering**: (1) stdlib, (2) external packages, (3) internal packages. Each group separated by a blank line. Within the controller, the convention is: stdlib, then external (istio, k8s.io, sigs.k8s.io), then internal (github.com/kubeflow/notebooks/...).
- [ ] **Standard aliases**: `kubefloworgv1beta1` for API types, `apierrors` for `k8s.io/apimachinery/pkg/api/errors`, `metav1` for `k8s.io/apimachinery/pkg/apis/meta/v1`, `corev1` for `k8s.io/api/core/v1`, `appsv1` for `k8s.io/api/apps/v1`, `ctrl` for `sigs.k8s.io/controller-runtime`, `istiov1` for `istio.io/client-go/pkg/apis/networking/v1`, `networkingv1` for `istio.io/api/networking/v1`.

### Equality Comparisons

- [ ] **Use `equality.Semantic.DeepEqual` for Kubernetes types**: NEVER use `reflect.DeepEqual` for comparing Kubernetes API types. Always use `k8s.io/apimachinery/pkg/api/equality` which handles semantic equivalence (e.g., nil vs empty slice).
- [ ] **Use `proto.Equal` for Istio/protobuf types**: Istio resource specs are protobuf messages. Use `google.golang.org/protobuf/proto.Equal` for comparison, not `reflect.DeepEqual` or `equality.Semantic.DeepEqual`, because protobuf messages with the same values are not considered equal by reflection.

### Reconciler Patterns

- [ ] **State message constants**: Error and status messages must be defined as `const` variables at the top of the file following the naming pattern: `stateMsgError...` for error states, `stateMsg...` for normal states (e.g., `stateMsgErrorGenFailureVirtualService`, `stateMsgPaused`, `stateMsgRunning`). Use `fmt.Sprintf` format strings where dynamic values are needed.
- [ ] **Method vs function**: Functions that need access to the reconciler's client or config should be methods on `WorkspaceReconciler` (receiver `r`). Pure computation functions that only operate on their inputs should be standalone functions (e.g., `generateNamePrefix`, `generateStatefulSet`).
- [ ] **Copy status before reconcile**: Before making any status changes, `DeepCopy` the current status and compare after reconciliation to avoid unnecessary status updates. Dereference the DeepCopy since status fields are not pointers.
- [ ] **Handle NotFound gracefully**: When fetching resources in the reconciler, `client.IgnoreNotFound(err)` should be used for the primary resource. For related resources that might not exist yet, handle `apierrors.IsNotFound(err)` explicitly.
- [ ] **Conflict retry on updates**: When updating resources and receiving a conflict error (`apierrors.IsConflict`), log at V(2) and requeue with `ctrl.Result{Requeue: true}` rather than returning an error.
- [ ] **Resource name length limits**: Respect Kubernetes name length limits. StatefulSet names are limited to 52 characters, Service and VirtualService names to 63 characters. Define these as constants.

### Resource Construction

- [ ] **Build pieces then assemble**: When generating Kubernetes resources (StatefulSet, Service, VirtualService), construct individual components (e.g., the `Rewrite` object, containers, volumes) at the top of the function, explicitly setting empty/default values. Then assemble the full resource object at the bottom so all fields are visible in one place.
- [ ] **Build lookup maps for repeated access**: When needing to look up items by ID (port configs, image configs, etc.), build `map[id]item` once rather than iterating through slices multiple times.
- [ ] **Panic for invariant violations**: When an invariant is violated that should be impossible given webhook validation (e.g., a portID referenced in a Workspace does not exist in the WorkspaceKind), panic with a clear message: `panic(fmt.Sprintf("workspace portID %q does not exist in the workspace kind", portId))`. Add a NOTE comment explaining why this should not be possible.
- [ ] **Self-documenting function signatures**: Make function signatures explicit about what is needed. For example, use `generateHTTPRoute(workspace, service, imageConfigPort, podTemplatePort)` rather than generic parameter names.

### Webhook Validation

- [ ] **Field paths in errors**: All validation errors must include proper field paths using `field.NewPath("spec", "podTemplate", "options", ...)`. Paths should mirror the JSON structure of the CRD. Use `.Child()` for nested fields and `.Key()` for map/list entries by ID.
- [ ] **Only validate what changed on update**: In `ValidateUpdate`, compare old and new objects and only validate fields that actually changed. This avoids rejecting existing valid configurations due to new validation rules.
- [ ] **Return early on blocking errors**: If a required reference (like WorkspaceKind) is not found, return immediately with that error rather than continuing validation that depends on the missing resource.
- [ ] **Consolidated validation**: Do not duplicate the same validation check in multiple places. If both webhook and controller need the same check, put it in a shared helper function.
- [ ] **Do not over-validate**: Avoid validating things that cannot fail or that are already guaranteed by kubebuilder markers. Do not reject potentially valid configurations for eventually-consistent resources (e.g., Secrets that may not exist yet when the Workspace is created).

### CopyFields Helpers (`internal/helper/`)

- [ ] **Field-by-field updates**: When updating existing resources, use the CopyFields pattern (`CopyStatefulSetFields`, `CopyServiceFields`, `CopyVirtualServiceFields`). Never overwrite fields like `spec.clusterIP` on Services. Copy only the fields that should be managed.
- [ ] **Return update boolean**: CopyFields functions must return a `bool` indicating whether any field was actually changed, to avoid unnecessary API calls.
- [ ] **Use correct equality for comparison**: CopyFields functions must use `equality.Semantic.DeepEqual` for Kubernetes types and `proto.Equal` for Istio protobuf types.

### Naming Conventions

- [ ] **Lowercase variable names**: camelCase for local variables (`workspaceKindName`, not `WorkspaceKindName`).
- [ ] **Avoid name conflicts with API types**: Do not name functions identically to well-known types. Add a qualifying verb/noun (e.g., `generateVirtualServiceHTTPRoute` not just `HTTPRoute`).
- [ ] **Consistent state message naming**: Follow the pattern `stateMsgError<Context><Detail>` for error messages and `stateMsg<State>` for state descriptions.
- [ ] **Field name clarity**: Include qualifiers when they add clarity. Use `DefaultDisplayName` instead of `DisplayName` when the field represents an overrideable default.

### Kustomize & Manifests

- [ ] **Do not modify base manager.yaml**: Changes to the controller deployment should be done via kustomize patches in `overlays/` or `components/`, not by modifying `base/manager/manager.yaml`.
- [ ] **Kustomize config hash suffixes**: When using ConfigMap-based configuration, use kustomize `configMapGenerator` with hash suffixes so pods automatically restart when config changes. Do not disable the suffix hash.
- [ ] **Variables via kustomize patches**: Environment variables and configuration that differs between environments should be set via kustomize patches, not hardcoded in base manifests.

### Istio / Networking

- [ ] **ISTIO_MUTUAL for in-mesh traffic**: When configuring Istio traffic policies, use `ISTIO_MUTUAL` TLS mode for services communicating within the mesh. Never use plain `MUTUAL` or skip TLS.
- [ ] **Authorization policies must restrict traffic**: AuthorizationPolicy resources should restrict to trusted traffic sources (e.g., from the Istio gateway). Never create allow-all policies.
- [ ] **VirtualService path templates**: Use the `workspaceConnectPathTemplate` constant for constructing HTTP paths. The format is `/workspace/connect/{namespace}/{workspace_name}/{port_id}/`.

### Comments & Documentation

- [ ] **Comment style**: Use lowercase for inline comments (e.g., `// generate VirtualService`). Use doc comments (capitalized, on exported symbols) for public APIs.
- [ ] **Explain "why not" rather than "what"**: Add comments when code does something non-obvious or deliberately skips something. Example: `// silently ignore port IDs not defined in the workspace kind` with a NOTE explaining why this should not be possible.
- [ ] **Remove stale TODOs**: If the TODO has been addressed, remove it. If it refers to future work, ensure it has a tracking issue reference.
- [ ] **Explain wacky code**: If a piece of code looks wrong or unusual but is intentional, add a comment explaining why.

### Testing

- [ ] **Test nil/default values**: At least one test case must set optional fields to nil to verify that defaults (from kubebuilder markers or `ptr.Deref`) work correctly.
- [ ] **Test edge cases**: Missing references, empty values, nil pointers.
- [ ] **Run make lint and make test**: Verify the PR passes `make lint` and `make test` in `workspaces/controller/`.
- [ ] **Run make manifests generate**: If CRD types were changed, verify that `make manifests` and `make generate` produce no diff.

### General Principles

- [ ] **Do not add complexity unless needed**: Prefer simple, direct solutions. Do not introduce abstractions or indirections that are not immediately useful.
- [ ] **Do not ship broken/untested features**: If a feature is not ready, disable it and comment it out with a TODO referencing a tracking issue, rather than shipping partial or broken code.
- [ ] **Prefer automated approaches**: Do not rely on developers manually maintaining lists or mappings. Use code generation, kubebuilder markers, or helper functions that derive values automatically.
- [ ] **Consistency with existing patterns**: Follow the established patterns in the codebase. If the existing code uses a particular approach for a similar feature, use the same approach.
