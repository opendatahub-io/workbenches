# Kubeflow Notebooks AI Skills

This directory contains focused, tool-agnostic skills that complement the existing `AGENTS.md` hierarchy.

## Goal

Hybrid approach:

- Keep `AGENTS.md` files as stable policy and boundary documents.
- Move repeatable implementation workflows into short, focused `SKILL.md` files.

## Layout

Skills follow the [agentskills.io](https://agentskills.io/specification) open standard.
Each skill lives in its own directory whose name matches the `name` frontmatter field:

```text
skills/
  <skill-name>/
    SKILL.md
```

When installed into the target repository, skills are placed at `.agents/skills/<skill-name>/SKILL.md` for cross-agent portability.

## Usage Model

- Read relevant `AGENTS.md` files first for hard constraints.
- Apply one or more skills based on the concrete task.
- Prefer small skills over large omnibus instructions.

## Skill Index

### Global

- `kubeflow-notebooks-global-guardrails`
- `kubeflow-notebooks-change-boundary-check`
- `kubeflow-notebooks-cross-module-sequencing`
- `kubeflow-notebooks-generated-code-regeneration`
- `kubeflow-notebooks-pr-review-first-pass`

### Backend

- `kubeflow-notebooks-backend-handler-implementation`
- `kubeflow-notebooks-backend-openapi-update`
- `kubeflow-notebooks-backend-ginkgo-test-authoring`
- `kubeflow-notebooks-backend-auth-policy-patterns`

### Controller

- `kubeflow-notebooks-controller-reconcile-pattern`
- `kubeflow-notebooks-controller-webhook-validation`
- `kubeflow-notebooks-controller-rbac-and-finalizers`
- `kubeflow-notebooks-controller-crd-evolution`
- `kubeflow-notebooks-controller-status-transitions`

### Frontend

- `kubeflow-notebooks-frontend-api-integration`
- `kubeflow-notebooks-frontend-state-and-context`
- `kubeflow-notebooks-frontend-jest-rtl-testing`
- `kubeflow-notebooks-frontend-component-authoring`
- `kubeflow-notebooks-frontend-hook-and-useeffect-refactor`

### Cypress

- `kubeflow-notebooks-cypress-e2e-authoring`
- `kubeflow-notebooks-cypress-flake-triage`
- `kubeflow-notebooks-cypress-api-mocking-and-builders`
- `kubeflow-notebooks-cypress-page-object-design`
- `kubeflow-notebooks-cypress-waiting-strategies`

## Routing Smoke Test

Use this checklist after changing `AGENTS.md` routing logic, skill names, or skill paths:

1. Run install/check against a target repo:
   - `./scripts/install.sh /path/to/kubeflow-notebooks`
   - `./scripts/check.sh /path/to/kubeflow-notebooks`
2. Pick one prompt per module (backend/controller/frontend/cypress) with a clear task intent.
3. Confirm the agent states one primary skill (and optional one secondary) from module `Skill Selection Matrix`.
4. Confirm behavior matches selected skill workflow and verification commands.
5. Confirm fallback behavior:
   - ambiguous task should route to `kubeflow-notebooks-global-guardrails` and request clarification.
6. If any route is wrong, update module `AGENTS.md` matrix rows (not skill content first), then re-run this test.

## Notes

Active workflow mapping lives directly in module `AGENTS.md` skill playbooks.
