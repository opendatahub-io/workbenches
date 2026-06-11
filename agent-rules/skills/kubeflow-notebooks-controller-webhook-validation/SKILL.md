---
name: kubeflow-notebooks-controller-webhook-validation
description: Applies validating and defaulting webhook patterns for Kubernetes resources. Use when implementing or modifying admission logic for custom resources.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Controller Webhook Validation

## Use This Skill When

- Editing validating/defaulting webhooks for CRDs.

## Validation Workflow

1. Validate invariants at admission boundary.
2. Return precise field-level errors with actionable messages.
3. Keep defaulting deterministic and side-effect free.
4. Ensure validation does not depend on transient external state unless required.

## Guardrails

- Reject invalid specs early; do not defer known-invalid state to reconcile.
- Preserve backward compatibility unless change is explicitly approved.
- Avoid duplicating controller business logic in webhook code.

## Done Criteria

- Valid input accepted.
- Invalid variants rejected with clear reasons.
- Defaulted fields match documented behavior.

## Verification

From `workspaces/controller/` run:

1. `make lint`
2. `ginkgo run -v ./internal/webhook/...`
3. If markers/defaults changed: `make generate && make manifests`

Pass criteria:

- Field-level validation errors are deterministic and specific.
- Defaulting behavior is stable across repeated admissions.
- Generated webhook/CRD artifacts are in sync with source types.
