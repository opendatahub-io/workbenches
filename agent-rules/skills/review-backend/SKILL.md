---
name: review-backend
description: Review a pull request that touches workspaces/backend/
argument-hint: "[PR number or branch]"
allowed-tools:
  - Read
  - Bash(git *)
  - Bash(gh pr diff *)
  - Bash(gh pr view *)
---

# Review Backend PR

Orchestrate a parallel code review of a pull request that touches `workspaces/backend/`, using focused sub-agents for each concern area.

## Instructions

Follow these steps exactly. Do not skip the sub-agent step — the review quality depends on parallel focused analysis.

### Step 1: Determine the base branch and capture the diff

Use the following priority order to get the correct diff. **NEVER use `main` or `origin/main` as the base.**

**Option A — PR number (preferred):** If `$ARGUMENTS` contains a PR number, OR you can detect one from the current branch:

```bash
# Try to detect PR number from current branch if not provided
PR_NUMBER="${ARGUMENTS:-$(gh pr view --json number --jq .number 2>/dev/null)}"
```

If a PR number is available, use `gh pr diff` — this is always correct regardless of local ref staleness:

```bash
gh pr diff "$PR_NUMBER" -- workspaces/backend/
```

**Option B — Local merge-base (fallback):** Only if no PR number is available, fetch the remote first to avoid stale refs, then compute merge-base:

```bash
git fetch upstream notebooks-v2 2>/dev/null || git fetch origin notebooks-v2
BASE=$(git merge-base HEAD upstream/notebooks-v2 2>/dev/null || git merge-base HEAD origin/notebooks-v2)
git diff ${BASE}..HEAD -- workspaces/backend/
```

Save the full diff output — you will pass it to each sub-agent.

### Step 2: Read the 4 checklist files

Read all checklist files from the `checklists/` subdirectory of this skill:

- `.claude/skills/review-backend/checklists/architecture-and-handlers.md`
- `.claude/skills/review-backend/checklists/correctness-and-safety.md`
- `.claude/skills/review-backend/checklists/types-models-and-conventions.md`
- `.claude/skills/review-backend/checklists/documentation-and-testing.md`

### Step 3: Spawn 4 parallel review agents

Launch **4 Agent calls in a single message** so they run concurrently. Each agent gets the prompt described below, customized with its checklist content.

For each agent, construct the prompt by combining:

1. The **agent role and project context** (from the "Project Context" section of its checklist file)
2. The **changed file list** (from Step 1)
3. The **full diff output** (from Step 1)
4. The **checklist items** (from the "Checklist" section of its checklist file)
5. The **standard review instructions** (below)

#### Agent prompt template

Use this template for each agent's prompt. Replace the placeholders with the actual content:

```
You are reviewing a Go backend PR for the Kubeflow Notebooks project.
Your focus area: {FOCUS_AREA_NAME}

{PROJECT_CONTEXT from checklist file}

## Changed Files
{file list from git diff --name-only}

## Diff
{full diff output}

## Review Checklist
{checklist items from the checklist file}

## Review Instructions

1. Read each changed file in full using the Read tool to understand the complete context — the diff alone may not show enough.
2. For files that import other internal packages, read the imported files too.
3. Check every applicable item in your checklist against the changed code.
4. Skip checklist items that are not relevant to the files changed in this PR.
5. **Only flag issues introduced by this PR.** Cross-reference each finding against the diff to confirm the flagged code is new or modified in this changeset. If you notice a pre-existing issue in surrounding code that was NOT changed in the diff, you may mention it separately under a "Pre-existing Issues" heading — but clearly label it as pre-existing and do NOT include it in the severity-ranked findings. Never suggest fixing code that was not touched by this PR without labeling it as pre-existing.
6. Report findings organized by severity:
   - **MUST FIX**: Correctness bugs, security issues, broken layering, nil pointer risks
   - **SHOULD FIX**: Convention violations, missing patterns, inconsistencies with codebase
   - **SUGGESTION**: Style improvements, readability, minor optimizations
7. For each finding, include:
   - The file path and line number
   - A quoted code snippet showing the issue
   - Which checklist item is violated
   - A concrete suggestion for how to fix it
8. If no issues are found for your focus area, report "No issues found."
9. Output ONLY your findings — no preamble, no summary statistics.
```

#### The 4 agents to spawn

| Agent | Focus Area | Checklist File |
|-------|-----------|----------------|
| 1 | Architecture & Handler Patterns | `architecture-and-handlers.md` |
| 2 | Correctness & Safety | `correctness-and-safety.md` |
| 3 | Types, Models & Conventions | `types-models-and-conventions.md` |
| 4 | Documentation & Testing | `documentation-and-testing.md` |

### Step 4: Aggregate and report

After all 4 agents return their findings, merge them into a single report:

1. **Deduplicate**: If two agents flag the same code for related reasons, combine into one finding citing both checklist items.
2. **Rank by severity**: MUST FIX first, then SHOULD FIX, then SUGGESTIONS.
3. **Within each severity**, order by file path for easy navigation.

#### Report format

```markdown
## Backend PR Review: {branch-name}

### Changed Files
- {list of changed files}

### MUST FIX
1. **{short description}** — `{file}:{line}`
   > {quoted code}
   
   {explanation and fix suggestion}

### SHOULD FIX
1. ...

### SUGGESTIONS
1. ...

### Summary
- {X} total findings ({Y} must-fix, {Z} should-fix, {W} suggestions)
- Review agents: Architecture & Handlers, Correctness & Safety, Types & Conventions, Documentation & Testing
```

If no issues are found across all agents, report:

```markdown
## Backend PR Review: {branch-name}

No issues found. All checklist items passed for the changed files.
```
