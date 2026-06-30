---
name: kubeflow-notebooks-change-boundary-check
description: Performs pre-change approval and risk gating for sensitive updates. Use when work may affect API contracts, CRDs, security-sensitive logic, dependencies, or deployment-critical manifests.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Change Boundary Check

## Use This Skill When

- The task touches API schemas, CRDs, webhooks, auth, manifests, or dependencies.

## Decision Flow

1. Identify affected artifact types:
   - API contract/OpenAPI
   - CRD/webhook logic
   - dependency graph
   - deployment/base manifests
2. If any item above changes materially, require explicit human confirmation.
3. If no sensitive artifacts change, continue with minimal scoped edits.

## Escalate Before Editing

- Public API contract changes.
- Security-sensitive behavior changes.
- New dependencies or major dependency upgrades.
- Kustomize base changes with cross-environment impact.

## Output Format

- `Impact`: what boundary was detected.
- `Risk`: likely regression domain.
- `Approval needed`: yes/no with reason.
