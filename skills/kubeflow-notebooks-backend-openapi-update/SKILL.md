---
name: kubeflow-notebooks-backend-openapi-update
description: Updates backend API contracts and OpenAPI artifacts safely with downstream compatibility in mind. Use when endpoint schemas, parameters, or responses are added or changed.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Backend OpenAPI Update

## Use This Skill When

- Editing endpoint signatures, schema models, or documented responses.

## Contract-First Workflow

1. Confirm approval is available for contract changes.
2. Update backend source-of-truth annotations/spec inputs.
3. Regenerate OpenAPI artifacts using module commands.
4. Run backend tests and lint.
5. Document downstream impact for frontend sequencing.

## Compatibility Guardrails

- Prefer additive changes where possible.
- Explicitly mark breaking changes and migration needs.
- Keep examples and status codes synchronized with implementation.

## Done Criteria

- Generated OpenAPI output is up to date.
- No manual patching of generated API artifacts.
- Follow-up sequence for frontend client regeneration is clear.

## Verification

From `workspaces/backend/` run:

1. `make swag`
2. `make lint`
3. `ginkgo run -v ./api/...`

Pass criteria:

- OpenAPI artifacts regenerate cleanly with no manual edits.
- Lint and targeted API tests pass.
- PR notes include frontend follow-up (`swagger.version` update then `npm run generate:api`).
