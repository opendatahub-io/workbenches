---
name: kubeflow-notebooks-cypress-flake-triage
description: Diagnoses and stabilizes flaky Cypress tests with evidence-driven fixes. Use when e2e tests fail intermittently in local runs or CI.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow Cypress Flake Triage

## Use This Skill When

- A Cypress test passes and fails inconsistently.

## Triage Workflow

1. Reproduce with repeated runs.
2. Classify flake source:
   - timing/synchronization
   - data setup leakage
   - selector instability
   - environment/network variance
3. Add targeted instrumentation (logs/snapshots) to isolate failure point.
4. Apply minimal fix and rerun repeatedly.

## Stabilization Patterns

- Replace static waits with state-based assertions.
- Isolate or reset shared test state.
- Use robust selectors and deterministic fixtures.

## Done Criteria

- Repeated local runs are stable.
- CI-specific assumptions are documented and validated.
- Fix does not mask real product defects.
