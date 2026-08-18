---
name: kubeflow-notebooks-controller-status-transitions
description: Manages controller status updates with conflict-safe retries, clear state messaging, and minimal churn. Use when changing resource state handling or status condition logic in controllers.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Controller Status Transitions

## Use This Skill When

- Updating status fields, state constants, or condition logic.
- Refactoring reconcile paths that affect status progression.

## Workflow

1. Compute desired status from observed reconcile outcome.
2. Compare current and desired status; update only on meaningful change.
3. Use `Status().Update(...)` separately from spec updates.
4. Handle update conflicts with requeue-safe behavior.
5. Keep messages actionable and user-oriented.

## Guardrails

- Avoid noisy status writes on every reconcile.
- Do not leak internal implementation details in status text.
- Keep state transitions deterministic and test-backed.

## Done Criteria

- Status changes are conflict-safe and idempotent.
- Tests cover success, error, and conflict/requeue scenarios.

## Verification

From `workspaces/controller/` run:

1. `make lint`
2. `ginkgo run -v ./internal/controller/...`

Pass criteria:

- Status writes occur only on meaningful changes.
- Conflict/retry scenarios do not cause status churn loops.
- Condition reason/message content remains actionable and stable.
