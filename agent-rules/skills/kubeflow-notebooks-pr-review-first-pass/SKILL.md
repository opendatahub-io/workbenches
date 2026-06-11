---
name: kubeflow-notebooks-pr-review-first-pass
description: Runs a standards-based first-pass review of a branch or pull request using AGENTS constraints. Use when asked to review commits for policy violations, regressions, and missing tests.
compatibility: Designed for Kubeflow Notebooks (notebooks-v2 branch)
metadata:
  author: caponetto
  version: "1.0"
---

# Kubeflow PR Review First Pass

## Use This Skill When

- Reviewing a PR, branch diff, or committed changes.

## Prerequisites

Before starting the review, ask the user for the following (if not already provided):

- **PR link** (e.g., GitHub pull request URL)
- **Branch name** (if reviewing locally instead of a PR)
- **Issue / ticket URL** (if available)

Do not proceed until at least a PR link or branch name is provided.

## Review Order

1. Gather context: PR description, linked issues, acceptance criteria.
2. Read global + module `AGENTS.md` and relevant patterns.
3. Review committed diff only.
4. Flag:
   - MUST/MUST NOT violations (blocking)
   - SHOULD violations (recommendations)
   - likely regressions and missing tests

## Finding Template

- `File`: path
- `Severity`: Blocking | Recommendation
- `Rule`: quoted requirement
- `Rationale`: why this is risky or incorrect
- `Suggested fix`: concrete direction

## Guardrails

- Prioritize correctness and risk over stylistic preferences.
- If no issues found, state that and list residual test gaps.
