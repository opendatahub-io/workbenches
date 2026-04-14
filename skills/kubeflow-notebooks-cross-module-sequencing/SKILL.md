---
name: kubeflow-notebooks-cross-module-sequencing
description: Enforces ordering for backend and frontend changes that share API contracts. Use when a feature spans backend endpoints and frontend consumption.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cross-Module Sequencing

## Use This Skill When

- A request touches backend API and frontend UI behavior.

## Required Sequence

1. Implement backend API change first.
2. Merge or reference backend commit containing contract updates.
3. Update frontend API reference (`swagger.version` in target repo).
4. Regenerate frontend client.
5. Implement frontend behavior dependent on new contract.

## Anti-Pattern To Avoid

- One-shot mixed changeset that edits backend contract and dependent frontend behavior together without sequencing.

## Verification

- Backend tests validate contract.
- Frontend type checks pass against regenerated client.
- No manual edits under generated client directories.
