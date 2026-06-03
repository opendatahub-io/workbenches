---
name: kustomize-compare
description: Compare kustomize manifest output between a PR branch and a baseline for a workspaces component (controller or backend)
argument-hint: "<component> [--baseline-only | --compare-only | --structure-only]"
---

# Kustomize Manifest Comparison Skill

You are performing a kustomize manifest comparison for a component in the kubeflow/notebooks repo.
The component name is provided as `$ARGUMENTS` (e.g. `controller`, `backend`).
The kustomize directory is at `workspaces/<component>/manifests/kustomize/`.
If no flags are given, run all phases.

## Inputs

- **Component**: One of `controller` or `backend`.
  The kustomize directory is at `workspaces/<component>/manifests/kustomize/`.
- **Manifests output directory**: `workspaces/<component>/manifests/` (where baseline/PR/comparison files live).
- **Flags** (optional):
  - `--baseline-only`: Only regenerate baseline files from the current branch (use when on `main`).
  - `--compare-only`: Only regenerate PR files and diff against existing baselines.
  - `--structure-only`: Only do the structural alignment check.
  - *(no flag)*: Run the full workflow (regenerate PR files, diff, structural check).

## Phase 1: Discover Kustomize Targets

1. List the kustomize directory tree at `workspaces/<component>/manifests/kustomize/`.
2. Identify the `base/` directory.
3. Identify all `overlays/*/` directories (e.g. `overlays/istio`).
4. Identify all `components/*/` directories and note which are commented out in the overlay kustomization files.
5. This gives you the list of build targets: `base`, plus one per overlay.
6. For overlays with commented-out optional components (e.g. `#- ../../components/prometheus`), also build a variant with those enabled to verify they still work.

## Phase 2: Build and Compare Manifests

For **each target** (base, and each overlay):

### If `--baseline-only`:
1. Run `kustomize build <target-path>` and save output to `<manifests-dir>/baseline_<target-name>.yaml`.
   - For base: `baseline_base.yaml`
   - For overlays: `baseline_overlays_<overlay-name>.yaml` (e.g. `baseline_overlays_istio.yaml`)
2. Report what was generated.

### If `--compare-only` or no flags:
1. Run `kustomize build <target-path>` and save output to `<manifests-dir>/pr<PR_NUMBER>_<target-name>.yaml`.
   - Ask the user for the PR number if not evident from the branch name or git context.
   - For base: `pr<N>_base.yaml`
   - For overlays: `pr<N>_overlays_<overlay-name>.yaml`
2. Run `diff -u <baseline-file> <pr-file>` to produce a unified diff.
3. If there is **no diff**, note this in the comparison file and move on.
4. If there **is a diff**, analyze it and write a comparison markdown file at `<manifests-dir>/comparison_<target-name>.md`.

### Comparison Markdown Format

Use this template for each comparison file:

```markdown
# Comparison: <Target Name>

**Baseline:** `<baseline-filename>` (main branch)
**PR<N>:** `<pr-filename>` (PR branch)

## File Statistics

| Metric | Baseline | PR | Delta |
|--------|----------|-----|-------|
| Size | X bytes | Y bytes | +/-Z bytes |
| Lines | X | Y | +/-Z |

## Summary of Changes

### 1. <Category of change>
<Description of what changed, why it matters, and whether it could be breaking>

### 2. <Next category>
...

## Items Requiring Attention
- <List any breaking changes, missing resources, or behavioral differences>

## Full Diff

\`\`\`diff
<unified diff output>
\`\`\`
```

### Analysis Categories to Check For

When analyzing diffs, look for and categorize these types of changes:

1. **Label changes** — Added, removed, or renamed labels. Flag if they appear in `selector.matchLabels` (immutable after Deployment creation) or `Service.spec.selector`.
2. **Resource name changes** — Renamed resources. Check that all cross-references (replacements, roleRef, subjects, selectors) are updated consistently.
3. **RBAC changes** — Role/ClusterRole rule changes, binding changes, subject namespace changes.
4. **Webhook changes** — ValidatingWebhookConfiguration name, service references, failurePolicy.
5. **Cert-manager changes** — Certificate/Issuer names, secretName, dnsNames, issuerRef.
6. **ConfigMap changes** — Key renames, removed keys, added keys.
7. **Environment variable changes** — Moved from explicit `env` to `envFrom`, renamed vars, removed vars.
8. **Resource additions/removals** — Entire resources added or removed from a layer.
9. **Istio-specific changes** — `sidecar.istio.io/inject` label, VirtualService, AuthorizationPolicy changes.
10. **Security context changes** — Any changes to pod/container security settings.
11. **Image changes** — Registry, name, or tag changes.
12. **Prometheus changes** — ServiceMonitor selectors, scrape annotations, metrics port/args.

### Breaking Change Detection

Flag as **potentially breaking** if any of these are true:
- Labels removed from or added to `Deployment.spec.selector.matchLabels` (selectors are immutable)
- Labels removed from or added to `Service.spec.selector`
- Resource names changed for cluster-scoped resources (ClusterRole, ClusterRoleBinding, ValidatingWebhookConfiguration) without migration notes
- Environment variable names changed (app code must be updated to match)
- ConfigMap keys renamed (if consumed by name in app code)
- Resources removed that other components may depend on
- RBAC permissions reduced

### Upgrade Safety Analysis

When selector breaking changes are detected, assess the **blast radius** based on the resource type:

- **Webhook Deployments**: Check `ValidatingWebhookConfiguration` for `failurePolicy`. If `Fail`, the webhook being unavailable during Deployment recreation will **block pod creation cluster-wide** (in matching namespaces). Document a safe upgrade sequence:
  1. Temporarily patch `failurePolicy` to `Ignore`
  2. Delete the old Deployment
  3. Apply new manifests (which restores `failurePolicy: Fail`)
  4. Wait for new pods to be Ready
- **Regular Deployments**: Note that the Deployment must be deleted and recreated, but impact is limited to the component itself.

### Cross-Resource Reference Audit (Phase 2.5)

After building the rendered manifests for each overlay target, audit **every value that appears in more than one resource** to verify it has a single source of truth. This catches hardcoded values that should be wired via `replacements` or `nameReference`.

#### How to audit

1. Extract all resource names, secret names, service account names, and other identifiers from the rendered output.
2. For each value that appears in multiple resources, classify it as:
   - **Wired by replacement** — a `replacements` block in the kustomization copies this value from source to target
   - **Wired by nameReference** — a `configurations`/`kustomizeconfig.yaml` `nameReference` entry handles this
   - **Wired by kustomize built-in** — kustomize natively handles this cross-reference (e.g., ServiceAccount name -> Deployment serviceAccountName, ClusterRole name -> ClusterRoleBinding roleRef)
   - **Wired by code generation** — a code generator (e.g., controller-gen markers) produces the correct value natively
   - **NOT wired (hardcoded in multiple files)** — the same value is hardcoded in separate source files with no mechanism keeping them in sync

3. Present findings as a table:

```markdown
### Cross-Resource Reference Map

| Value | Source Resource | Target Resource(s) | Mechanism |
|-------|---------------|-------------------|-----------|
| `workspaces-webhook-service` | Service name | Webhook clientConfig, Certificate dnsNames | Replacement |
| `webhook-server-cert` | Certificate secretName | Deployment volume secretName | Replacement |
```

4. For any **NOT WIRED** references, flag them and suggest a `replacements` block that would wire them. Note which kustomization file the replacement should go in.

#### Common cross-references to check

- Certificate `spec.secretName` <-> Deployment `volumes[].secret.secretName`
- Service name/namespace <-> webhook `clientConfig.service`
- Service name/namespace <-> Certificate `dnsNames` and `commonName`
- Certificate name/namespace <-> webhook annotation `cert-manager.io/inject-ca-from`
- Issuer name <-> Certificate `spec.issuerRef.name`
- ServiceAccount name <-> Deployment `serviceAccountName` and ClusterRoleBinding `subjects`
- ClusterRole name <-> ClusterRoleBinding `roleRef.name`
- Role name <-> RoleBinding `roleRef.name`
- ServiceAccount namespace <-> ClusterRoleBinding/RoleBinding `subjects[].namespace`

## Phase 3: Structural Alignment Check (if not `--baseline-only`)

This repo defines the reference pattern for kustomize manifests. Verify internal consistency across components by comparing the component's structure against this checklist.

### Structural Comparison Checklist

Evaluate alignment on these dimensions:

| Dimension | Expected Pattern |
|---|---|
| **Directory layout** | `base/`, `components/common/`, `components/istio/`, `overlays/*/` |
| **Base kustomization** | Uses `labels` with `includeSelectors: true`, has `images` block, uses `resources` list |
| **Common component** | Kind `Component`, adds `app.kubernetes.io/managed-by`, `app.kubernetes.io/name`, `app.kubernetes.io/part-of` with `includeSelectors: true` |
| **Istio component** | Kind `Component`, has istio-specific patches or resources |
| **Cert-manager component** | If present: Kind `Component`, adds Certificate/Issuer resources and Deployment/webhook patches |
| **Overlay composition** | References `../../base` as resource, includes relevant `../../components/*` entries. The `common` component should be listed **last** to ensure labels cover all resources |
| **Replacements** | Uses `replacements` (not `vars`) for dynamic value wiring |
| **No `commonLabels`** | Should use the newer `labels` field, not the deprecated `commonLabels` |
| **No deprecated directives** | Should not use `bases` (use `resources`), `commonLabels` (use `labels`), or `patchesStrategicMerge` (use `patches`) |
| **No `namePrefix`** | Prefer hardcoding fully-qualified resource names with a `workspaces-` prefix over using `namePrefix`. This makes resource names grep-able and replacements easier to reason about |
| **Resource naming** | All resource names should be prefixed with `workspaces-` to avoid collisions in shared namespaces (e.g. `kubeflow`). Exceptions: Deployment/ServiceAccount already named `workspaces-controller`, CRDs (globally unique by API group), user-facing ClusterRoles already prefixed with `kubeflow-workspaces-` |

### Report Format

Present findings as a table:

```markdown
## Structural Alignment

| Category | Expected Pattern | This Component | Aligned? | Notes |
|---|---|---|---|---|
| Directory layout | base/components/overlays | ... | Yes/No | ... |
| Common component labels | managed-by, name, part-of | ... | Yes/No | ... |
| ... | ... | ... | ... | ... |
```

Then list any **gaps or deviations** with context on whether they are:
- **Expected** (component-specific need)
- **Actionable** (should be fixed to match the pattern)
- **Optional** (nice-to-have alignment)

## Phase 4: `includeSelectors` Impact Analysis (if not `--baseline-only`)

When a component uses `labels` with `includeSelectors: true`, those labels are injected into `Deployment.spec.selector.matchLabels`, `Service.spec.selector`, and pod template labels. Evaluate:

1. **Are all labels in `includeSelectors: true` appropriate for immutable selectors?**
   - Labels like `app.kubernetes.io/managed-by: kustomize` couple the selector to the deployment tool. If the team later migrates to Helm or another tool, the Deployment must be deleted and recreated.
   - This is acceptable if it matches the established pattern in this repo, but should be noted.

2. **Do labels from the `common` component leak into resources that don't need selectors?**
   - CRDs, ClusterRoles, ClusterRoleBindings, Certificates, and Issuers don't have selectors. `includeSelectors: true` only affects resources with selector fields, so this is usually safe. Verify by checking the rendered output.

3. **Does the `base` target produce a different selector set than overlays?**
   - If the `common` component is only included in overlays, the base will have fewer selector labels. Document this difference and note that deploying `base` standalone vs. an overlay will produce Deployments with different immutable selectors (they cannot be switched between without recreation).

4. **Do Service selectors match the labels actually present on pods?**
   - For every Service in the rendered output, verify that its `spec.selector` labels are a subset of the pod template labels from the Deployment it targets. Pay special attention to Services defined in a different kustomization layer than the Deployment (e.g., a webhook Service in `base/webhook/` selecting pods from `base/manager/`) — labels applied by one kustomization may not propagate to resources in another unless both are composed together.
   - When `includeSelectors` is used, check whether it adds labels to a Service's `spec.selector` that don't exist on the target pods. If a sub-kustomization applies `includeSelectors: true` with a component-specific label (e.g., `component: webhook`), that label will be injected into the Service selector, but the target pods (managed by a different sub-kustomization) won't have it. Use `includeSelectors: false` for labels that should appear in metadata only.

## Phase 5: Rendered Manifest Completeness Review (if not `--baseline-only`)

After building the rendered manifests, review them holistically for production-readiness gaps. Do not assume that the kustomize source files being well-structured means the rendered output is complete.

### Deployment Spec Review

For each Deployment in the rendered output, check:

1. **Container ports** — Are all ports the container listens on declared in `ports[]`? Missing port declarations don't prevent functionality but break named port references, NetworkPolicy targeting, and service mesh visibility. Check if any Service `targetPort` or probe `port` uses a numeric value that could be a named port reference instead.

2. **Probes** — Do liveness and readiness probes reference ports consistently? If container ports are declared with names, probes should use the named port rather than hardcoded numbers. This ensures the port value has a single source of truth.

3. **Security context** — Evaluate against Kubernetes Pod Security Standards (Restricted profile):
   - Pod-level: `seccompProfile`, `runAsNonRoot` or `runAsUser`
   - Container-level: `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `readOnlyRootFilesystem` (where feasible)
   - Flag any gaps but do not prescribe specific UIDs or implementation — just note what's missing relative to the Restricted profile.

4. **Resource requests/limits** — Are CPU/memory requests and limits set? Flag if missing entirely. Do not prescribe specific values.

5. **Stale boilerplate** — Are there large blocks of commented-out scaffolding code (e.g., TODO comments from code generators) that should be cleaned up or acted on?

### Service Spec Review

For each Service in the rendered output, check:

1. **Port naming** — Are ports named? Named ports enable more readable references in other resources (probes, targetPort, NetworkPolicy).
2. **targetPort** — Does it use a named port reference rather than a hardcoded number? Named references ensure the value stays in sync with the Deployment's container port declarations.
3. **Selector accuracy** — Do the selector labels match the actual pod template labels? (Cross-check with Phase 4 findings.)

### Network-Level Hardening

Review whether the component's network exposure is appropriately constrained:

1. **Webhook accessibility** — If the component serves a webhook, the kube-apiserver must be able to reach it. Is there a NetworkPolicy (or equivalent) that permits ingress on the webhook port? Without one, a default-deny policy would break webhook delivery.
2. **Metrics accessibility** — If the component exposes a metrics endpoint, is access appropriately scoped? Consider whether the metrics port should be restricted to monitoring infrastructure only.
3. **Unnecessary exposure** — Are any ports or services exposed beyond what's functionally required?

Do not prescribe specific NetworkPolicy implementations — flag the gaps and let the team decide the approach.

### Strategic Merge Patch Fragility

Review all strategic merge patches (non-JSON patches) that target array fields:

1. **Args override** — If a patch specifies `args:` on a container, strategic merge will replace the entire args list (since args elements have no merge key). Flag any patch that re-specifies args the base already defines — if the base later adds an arg, the patch will silently discard it. Suggest using a JSON patch (`op: add`) to append/replace individual args, or document the coupling.
2. **Ports override** — Same concern applies to `ports:` if the merge key (`containerPort`) isn't used carefully.
3. **Volume/volumeMount override** — Check that patches extending volumes use the merge key (`name`) correctly.

## Phase 6: Tooling and Generation Audit (if not `--baseline-only`)

When the component uses code generators (e.g., `controller-gen`, `swag`), check whether kustomize workarounds exist for limitations that the generators may have already solved.

### How to audit

1. **Identify generators** — Check the Makefile for generator invocations (e.g., `controller-gen`, `swag`, `protoc`). Note the tool and its version.
2. **Check for version currency** — Is the generator version current or significantly behind? Check if newer versions offer features that would eliminate kustomize workarounds currently in place (e.g., configurable output names, new markers/annotations).
3. **Identify workarounds** — Look for kustomize patches, replacements, or post-generation scripts that exist solely to fix up generator output (e.g., renaming resources, injecting values the generator hardcodes). For each workaround, ask: does the generator now support this natively?
4. **Check marker usage** — For controller-gen specifically, review the kubebuilder markers in Go source files. Are there newer markers available that would produce the desired output without kustomize intervention?
5. **Porcelain check** — Can you run the generator and get a clean `git diff`? If the generated files have been manually edited, the porcelain check will fail, indicating the edits should either be upstreamed to marker configuration or moved to kustomize patches that layer on top of clean generated output.

### Report Format

```markdown
## Tooling Audit

| Generator | Current Version | Latest Stable | Workarounds in Place | Could Be Eliminated? |
|-----------|----------------|---------------|---------------------|---------------------|
| controller-gen | vX.Y.Z | vA.B.C | <describe workaround> | Yes/No/Investigate |
```

## Phase 7: Test and CI Reference Audit (if not `--baseline-only`)

Check whether tests, CI workflows, or other non-manifest files reference resource names, labels, or other values that changed in this PR.

### How to audit

1. Search test files (`test/`, `*_test.go`, `*.test.ts`, `*.spec.ts`, `*.cy.ts`) for any resource names that were changed in the manifests.
2. Search CI workflow files (`.github/workflows/`) for references to changed resource names, namespaces, or labels.
3. Search Tilt files (`Tiltfile`, `developing/`) for hardcoded references to changed values.
4. Search Makefile targets for hardcoded references to changed resource names.

Flag any stale references that would cause test failures, CI failures, or broken dev workflows.

## Final Output

After all phases, present a concise summary to the user:
1. Number of targets compared
2. High-level delta summary per target
3. List of breaking changes (if any)
4. Structural alignment score (e.g. "8/11 dimensions aligned")
5. Cross-resource reference audit results (any unwired references)
6. Rendered manifest completeness findings (any production-readiness gaps)
7. Tooling audit findings (any generator workarounds that could be eliminated)
8. Test/CI reference audit findings (any stale references)
9. Recommended follow-up items
