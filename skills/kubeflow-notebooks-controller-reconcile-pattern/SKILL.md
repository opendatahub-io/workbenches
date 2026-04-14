---
name: kubeflow-notebooks-controller-reconcile-pattern
description: Implements controller reconcile logic with idempotency, status updates, and safe retries. Use when adding or changing controller reconciliation behavior.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Controller Reconcile Pattern

## Use This Skill When

- Updating reconcile loops, condition handling, or status transitions.

## Reconcile Workflow

1. Fetch resource and handle not-found as no-op.
2. Compute desired state from spec.
3. Reconcile external/child resources idempotently.
4. Update status conditions with clear reasons/messages.
5. Requeue only when needed (explicit retry intent).

## Guardrails

- Never place domain business logic in webhook-only paths.
- Avoid side effects before prerequisite validation.
- Keep reconcile operations safe for repeated execution.

## Testing Focus

- Idempotency across repeated reconciles.
- Expected status condition transitions.
- Error paths and retry behavior.

## Verification

From `workspaces/controller/` run:

1. `make lint`
2. `ginkgo run -v ./internal/controller/...`
3. If API types changed: `make generate && make manifests`

Pass criteria:

- Reconcile flow is safe across repeated runs on the same resource.
- NotFound and retry paths behave as no-op/requeue as intended.
- No new lint failures and generated artifacts are current.
