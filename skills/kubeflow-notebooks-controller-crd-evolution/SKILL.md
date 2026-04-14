---
name: kubeflow-notebooks-controller-crd-evolution
description: Safely evolves CRD schemas and related controller/webhook behavior with regeneration and compatibility checks. Use when adding or changing CRD fields, markers, or schema semantics.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Controller CRD Evolution

## Use This Skill When

- Adding CRD fields or changing validation markers/defaults.
- Updating controller or webhook logic tied to CRD schema changes.

## Workflow

1. Confirm approval for CRD/API-surface changes.
2. Update `api/v1beta1/*_types.go` with kubebuilder markers.
3. Regenerate artifacts (`make generate`, `make manifests`).
4. Update reconcile/webhook logic for new semantics.
5. Add or update tests for valid, invalid, and defaulted behavior.
6. Update sample manifests when field behavior is user-visible.

## Guardrails

- Preserve backward compatibility unless explicitly approved otherwise.
- Never hand-edit generated CRD output.
- Keep validation failures precise and field-oriented.

## Done Criteria

- Generated artifacts and tests align with schema changes.
- Status/reconcile behavior matches new field semantics.
