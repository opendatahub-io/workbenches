---
name: kubeflow-notebooks-generated-code-regeneration
description: Handles generated files safely by regeneration instead of manual edits. Use when tasks touch OpenAPI clients, controller codegen artifacts, or other generated outputs.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Generated Code Regeneration

## Use This Skill When

- A changed file appears to be generated.
- A feature requires updating generated artifacts.

## Workflow

1. Confirm file is generated via module guidelines.
2. Select the canonical generation command for that module.
3. Run generator instead of editing generated output directly.
4. Review generated diff for scope and correctness.
5. Ensure source-of-truth files are committed with generated output when required.

## Common Cases

- Frontend API client under generated directories.
- Controller `zz_generated.*.go` files.
- Backend artifacts generated from OpenAPI annotations.

## Hard Rule

- Never hand-edit generated files to "quick fix" behavior.

## Verification

Use the module-specific generator from the owning workspace:

- Frontend client (`workspaces/frontend/`): `npm run generate:api`
- Controller codegen (`workspaces/controller/`): `make generate && make manifests`
- Backend OpenAPI (`workspaces/backend/`): `make swag`

Then verify:

1. Generated diff only includes expected files for that workflow.
2. Source-of-truth input files are present in the same change set.
3. Relevant lint/test checks pass for the owning module.
