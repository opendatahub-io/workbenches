---
name: kubeflow-notebooks-global-guardrails
description: Runs a global preflight and verification workflow before and after code changes. Use when starting any coding task in controller, backend, frontend, or cypress modules.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Global Guardrails

## Use This Skill When

- Starting any implementation, refactor, or bug fix.
- Unsure if a change might violate project boundaries.

## Policy Source of Truth

- Global policy: `AGENTS.md` at repository root.
- Module policy: module-local `AGENTS.md` in backend/controller/frontend/cypress.
- This skill is an execution wrapper; do not duplicate policy here.

## Preflight Workflow

1. Read global and module `AGENTS.md` before editing.
2. Identify changed module(s) and expected verification commands.
3. Confirm whether the task needs approval-bound changes (API/CRD/security/dependency).
4. Plan minimal, scoped edits and required tests.

## Escalate Immediately If

- The task requires approval-bound changes without prior approval.
- The task needs cross-module scope in a single change set.
- The owner and regeneration command for changed generated files are unclear.

## Verification

Run only the relevant module checks for files changed:

- Backend (`workspaces/backend/`): `make lint` then targeted tests with `ginkgo run -v ./...`
- Controller (`workspaces/controller/`): `make lint` and `ginkgo run -v ./...`
- Frontend (`workspaces/frontend/`): `npm run test:lint` and `npm run test:type-check`
- Cypress (`workspaces/frontend/`): targeted spec run via `npm run test:cypress-ci -- --spec "<spec-path>"`

Pass criteria:

- Commands exit successfully.
- No newly introduced lint/type/test failures.
- Any skipped verification is explicitly reported with reason.

## Delivery Output

- State assumptions and constraints from `AGENTS.md`.
- Report risks and follow-up checks.
- List verification commands run and outcomes.
