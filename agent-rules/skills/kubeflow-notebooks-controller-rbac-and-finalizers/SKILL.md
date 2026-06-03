---
name: kubeflow-notebooks-controller-rbac-and-finalizers
description: Handles controller RBAC markers, owner references, and finalizer lifecycle safely. Use when changes affect permissions, resource ownership, or deletion flows.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Controller RBAC and Finalizers

## Use This Skill When

- Updating controller permissions.
- Adding/removing owner refs or finalizers.
- Changing deletion/cleanup behavior.

## Workflow

1. Declare least-privilege RBAC for required operations only.
2. Ensure owned resources have correct owner references.
3. Add finalizer before creating external dependencies that need cleanup.
4. On deletion, run cleanup then remove finalizer.

## Guardrails

- No orphan resources after deletion.
- No permission overreach in RBAC markers.
- Cleanup is retry-safe and idempotent.

## Done Criteria

- Finalizer add/remove lifecycle is tested.
- Cleanup behavior on retry/error is tested.
- Permission-dependent paths fail predictably when unauthorized.

## Verification

From `workspaces/controller/` run:

1. `make lint`
2. `ginkgo run -v ./internal/controller/...`
3. If RBAC markers changed: `make manifests`

Pass criteria:

- Finalizer is added before cleanup-requiring dependencies and removed only after cleanup.
- RBAC manifests reflect least-privilege access for the new/changed operations.
- No orphaned child resources in deletion test paths.
