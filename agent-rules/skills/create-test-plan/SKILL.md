---
name: create-test-plan
description: Generate a manual test plan for a PR or current branch, focusing on behavioral verification that CI cannot cover
argument-hint: "[PR number]"
allowed-tools: Bash, Read, Write
---

# Create Test Plan

Generate a manual test plan for a PR or the current branch. The plan focuses ONLY on behavioral verification that CI cannot cover — it reads CI workflow configurations to determine what is already tested automatically and generates manual tests exclusively for the gaps.

## Critical Principles

1. **Never list CI-covered checks as manual steps.** Read the CI workflow files and determine exactly what they cover for this PR's changed paths. Only generate manual tests for behaviors CI does not exercise.
2. **Validate all kubectl commands against source code.** Label selectors, resource names, namespaces, and path templates MUST be derived from actual source code constants. Never guess these values.
3. **Assume Tilt Kind cluster.** The dev environment uses a Kind cluster managed by Tilt. Workspaces are created in the default namespace — do NOT add `-n <NAMESPACE>` to workspace kubectl commands.
4. **Use merge-base for diff scoping.** Always diff against `upstream/notebooks-v2` (or `origin/notebooks-v2` fallback). **NEVER use `main` or `origin/main` as the base.**
5. **Be module-aware.** Tailor tests based on which modules (controller, backend, frontend) are affected by the changes.

---

## Step 1: Get the Diff and PR Metadata

**Option A — PR number provided in `$ARGUMENTS`:**

```bash
PR_NUMBER="$ARGUMENTS"
gh pr view "$PR_NUMBER" --repo kubeflow/notebooks --json number,title,body,author,url,baseRefName,headRefName
gh pr diff "$PR_NUMBER" --repo kubeflow/notebooks
gh pr diff "$PR_NUMBER" --repo kubeflow/notebooks --name-only
```

**Option B — No arguments, detect PR from current branch:**

```bash
PR_NUMBER=$(gh pr view --json number --jq .number 2>/dev/null)
```

If detected, use Option A with that number.

**Option C — No PR found, use local merge-base:**

```bash
git fetch upstream notebooks-v2 2>/dev/null || git fetch origin notebooks-v2
BASE=$(git merge-base HEAD upstream/notebooks-v2 2>/dev/null || git merge-base HEAD origin/notebooks-v2)
git diff ${BASE}..HEAD
git diff ${BASE}..HEAD --name-only
```

From the PR metadata or commit messages, extract:
- **Issue link**: Look for `fixes #NNN`, `closes #NNN`, or `resolves #NNN` patterns (case-insensitive)
- **Author**: From PR metadata or `git log --format='%an' -1`
- **Summary**: From PR title and body

---

## Step 2: Determine Affected Modules

Classify changed files into modules:

| Path Prefix | Module |
|---|---|
| `workspaces/controller/` | controller |
| `workspaces/backend/` | backend |
| `workspaces/frontend/` | frontend |
| `.github/workflows/` | ci |
| `developing/` | dev-tooling |
| `testing/` | test-infra |

Record which modules are affected — this determines which CI workflows trigger and which AGENTS.md files to consult.

---

## Step 3: Read CI Workflows and Determine Coverage

Read ALL workflow files:

- `.github/workflows/ws-controller-test.yml`
- `.github/workflows/ws-backend-test.yml`
- `.github/workflows/ws-frontend-test.yml`
- `.github/workflows/ws-e2e-test.yml`
- `.github/workflows/semantic-prs.yaml`

For each workflow:

1. **Will it trigger for this PR?** Cross-reference the workflow's `pull_request.paths` filter against the actual changed file list. A workflow only triggers if at least one changed file matches its path filter.

2. **What does it check?** Map each triggered workflow to its specific checks:

   | Workflow | Trigger Paths | Checks |
   |---|---|---|
   | Controller - Build and Test | `workspaces/controller/**`, `workspaces/backend/**`, `releasing/version/VERSION` | `go mod tidy`, `make lint`, `make build` (includes `manifests`, `generate`, `fmt`, `vet`), porcelain check, `make test` (unit + webhook tests via envtest), `make test-e2e` (Kind cluster) |
   | Backend - Build and Test | `workspaces/backend/**`, `workspaces/controller/**`, `releasing/version/VERSION` | `go mod tidy`, `make lint`, `make build` (includes `swag`), porcelain check, `make test` (unit tests) |
   | Frontend - Build and Test | `workspaces/frontend/**`, `releasing/version/VERSION` | `npm ci`, build, `npm run test` (lint + type-check + Jest + Cypress), porcelain check |
   | E2E Tests | `workspaces/**` | Kind cluster deploy, `make setup-cluster`, `make deploy-all`, `make sanity-check`, `make local-e2e` |
   | Semantic PRs | All PRs | PR title format |

3. **Classify each check as COVERED or NOT COVERED for this PR.** Only checks from triggered workflows count as COVERED.

---

## Step 4: Extract Source Code Constants

**This step is MANDATORY.** Do not write any kubectl commands until you have extracted these values from source code. This is the most important step — wrong constants produce broken test plans.

### Always extract:

**From `workspaces/controller/internal/controller/workspace_controller.go`:**

```bash
grep -n 'workspaceNameLabel\|workspaceSelectorLabel\|workspaceConnectPathTemplate\|workspacePodTemplateContainerName\|stateMsgError' \
  workspaces/controller/internal/controller/workspace_controller.go | head -30
```

Key constants you will find:
- `workspaceNameLabel` — the label key for selecting resources by workspace name (e.g., `notebooks.kubeflow.org/workspace-name`)
- `workspaceConnectPathTemplate` — URL path format (e.g., `/workspace/connect/%s/%s/%s/`)

**Controller namespace and pod labels:**

```bash
grep -rn 'namespace\|app:' workspaces/controller/manifests/kustomize/base/manager/ | head -10
```

### Conditionally extract (based on changed files):

- If **webhook code** changed: Read `workspaces/controller/internal/webhook/` for validation error messages and field paths
- If **CRD types** changed: Read `workspaces/controller/api/v1beta1/` for field names and kubebuilder markers
- If **helper code** changed: Read `workspaces/controller/internal/helper/` for function signatures and template function names
- If **backend handlers** changed: Read `workspaces/backend/api/` for route paths and response types

### Validation rules for all kubectl commands in the test plan:

1. **Label selectors**: Use the exact label key from `workspaceNameLabel`. Example: `-l notebooks.kubeflow.org/workspace-name=<name>`
2. **Controller namespace**: Always use `-n kubeflow-workspaces` when querying controller pods/logs
3. **Workspace namespace**: Default namespace is implied — do NOT add `-n default` or `-n <NAMESPACE>`
4. **Controller log command**: Always `kubectl logs -n kubeflow-workspaces -l app=workspaces-controller --tail=50`

---

## Step 5: Read Module Testing Guidance

For each affected module, read its AGENTS.md:

| Module | File |
|---|---|
| controller | `workspaces/controller/AGENTS.md` |
| backend | `workspaces/backend/AGENTS.md` |
| frontend | `workspaces/frontend/AGENTS.md` |

Extract testing patterns, known pitfalls, and test utilities that should inform the manual test plan. Skip modules not affected by the PR.

---

## Step 6: Analyze the Diff Semantically

Read the full diff and answer:

1. **What behavior changed?** Describe the functional change in plain language.
2. **What is the risk?** What could break if this change is wrong?
3. **What does CI already verify?** Map each risk to a CI check from Step 3.
4. **What does CI NOT verify?** These gaps become manual tests.

Common CI gaps that require manual testing:

| Change Type | Why Manual Testing Needed |
|---|---|
| Generated Istio resources (VirtualService) | CI e2e may not inspect specific Istio resource fields |
| Template rendering in generated K8s resources | Live cluster behavior may differ from unit test mocks |
| Webhook admission wiring | envtest validates logic but live admission may behave differently |
| Controller status reporting | Live workspace status messages need visual confirmation |
| New CRD fields affecting resource generation | Serialization in a live cluster may differ from envtest |
| Frontend UI with live backend | Cypress tests use mocked API, not real backend |
| Backend API with real cluster data | envtest shapes may differ from live cluster |
| Nil-safety / edge cases in resource generation | Specific field combinations may not be covered by unit tests |

---

## Step 7: Generate and Write the Test Plan

Write the test plan to:
- `developing/TEST-PLAN-PR-<PR_NUMBER>.md` — if a PR number is known
- `developing/TEST-PLAN-<BRANCH_NAME>.md` — if no PR number (sanitize branch: replace `/` with `-`)

### Output Format

Use this exact structure:

```markdown
# Test Plan: PR #<NUMBER> — <PR Title>

**PR**: <PR URL>
**Issue**: <Issue URL or "N/A">
**Author**: @<author>
**Reviewer**: @<reviewer or "TBD">

## Summary

<2-3 sentence description of what this PR does, written in terms of behavior change>

## CI Coverage

The following are covered by GHA checks and are prerequisites for PR approval — they are
**not** listed as manual steps:

| GHA Workflow | Triggered | What It Covers |
|---|---|---|
| **Controller - Build and Test** | Yes/No | <specific checks, or "N/A — no matching path changes"> |
| **Backend - Build and Test** | Yes/No | <specific checks, or "N/A — no matching path changes"> |
| **Frontend - Build and Test** | Yes/No | <specific checks, or "N/A — no matching path changes"> |
| **E2E Tests** | Yes/No | <specific checks, or "N/A — no matching path changes"> |
| **Semantic PRs** | Yes | PR title format |

---

## Prerequisites

All commands assume the Tilt dev environment with `kubectl` targeting the Kind cluster
in the default namespace.

1. Start the Tilt dev environment:
   ```bash
   cd developing
   make tilt-up
   ```

2. Apply the common sample resources (PVCs, ServiceAccount, etc.):
   ```bash
   kubectl apply -k workspaces/controller/manifests/kustomize/samples/common/
   ```
   This creates `workspace-home-pvc`, `workspace-data-pvc`, `default-editor`
   ServiceAccount, and other resources used by the test workspaces below.

---

<Test sections follow — see rules below>

---

## Test Matrix Summary

| # | Test | Verifies |
|---|------|----------|
| <N.M> | <Short test name> | <One-line description of what it proves> |
```

### Rules for Test Cases

1. **Every kubectl command uses validated constants from Step 4.** No exceptions.
2. **Include both positive and negative tests.** Valid input should work AND invalid input should be rejected.
3. **Always include Expected output.** Be specific: show the exact YAML path and value.
4. **Always include Cleanup commands.** Delete resources in reverse creation order (Workspaces before WorkspaceKinds).
5. **Use existing sample manifests when possible.** Reference files from `workspaces/controller/manifests/kustomize/samples/` instead of writing custom YAML when a sample covers the test case.
6. **For custom resources, write minimal YAML.** Only the fields necessary for the test. Use `workspace-home-pvc` for home volumes and `default-editor` for service accounts.
7. **Group related tests under a section header.** Each section tests one aspect of the change.
8. **Wait for workspace state.** Use `kubectl get workspace <name> -w` or `kubectl wait --for=jsonpath='{.status.state}'=Running workspace/<name> --timeout=120s`.
9. **VirtualService/Service inspection uses the workspace label.** Always: `kubectl get virtualservice -l <workspaceNameLabel>=<name> -o yaml` using the label key extracted in Step 4.

### Module-Specific Test Guidance

**Controller changes** — focus on:
- Generated resource correctness (StatefulSet, Service, VirtualService field values)
- Workspace status conditions and state transitions
- Webhook admission behavior (both create AND update paths)
- Controller logs (no panics, correct log messages): `kubectl logs -n kubeflow-workspaces -l app=workspaces-controller --tail=50`
- Nil-safety for optional fields

**Backend changes** — focus on:
- API response format and HTTP status codes via `curl` to the backend (port 4000 via Tilt)
- Error responses for invalid input
- Correct data returned from live cluster resources

**Frontend changes** — focus on:
- Manual browser testing of affected UI components at `localhost:9000`
- Verify displayed data matches actual cluster state
- Test error/loading states (delete a resource, check UI handles it)

---

## Step 8: Validate Commands (Optional — Safety-Gated)

This step validates key kubectl commands against a live cluster. To prevent accidental
execution against non-dev clusters, **all kubectl commands in this step MUST use the
guard script** at `.claude/scripts/safe-kubectl.sh` instead of calling `kubectl` directly.

The guard script checks that the active kubectl context is exactly `kind-tilt` before
forwarding to kubectl. If the context is anything else (EKS, GKE, OpenShift, another Kind
cluster, etc.), the script exits with an error and kubectl never runs. This is a hard
shell-level gate — it cannot be bypassed.

**Usage**: Replace `kubectl` with `.claude/scripts/safe-kubectl.sh` in every command:

```bash
.claude/scripts/safe-kubectl.sh get ns kubeflow-workspaces
.claude/scripts/safe-kubectl.sh get pods -n kubeflow-workspaces -l app=workspaces-controller
.claude/scripts/safe-kubectl.sh get crd workspaces.kubeflow.org workspacekinds.kubeflow.org
.claude/scripts/safe-kubectl.sh apply -k workspaces/controller/manifests/kustomize/samples/common/ --dry-run=client
```

If the guard script blocks execution, note it in the test plan output and move on.
The test plan is valid regardless of whether this step runs.

**NEVER call `kubectl` directly in this step. ALWAYS use `.claude/scripts/safe-kubectl.sh`.**
