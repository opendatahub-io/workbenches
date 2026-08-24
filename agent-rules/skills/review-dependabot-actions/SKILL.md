---
description: Review a dependabot PR that bumps GitHub Actions versions. Fetches release notes between the old and new version, analyzes the current workflow usage, and produces a per-action safety verdict for the human reviewer. Use this whenever a PR was opened by dependabot and touches .github/workflows/ files.
allowed-tools: Bash, Read, WebFetch, WebSearch, Agent
---

Review a dependabot PR that updates GitHub Actions SHA pins and help the human reviewer decide whether it is safe to merge.

## Inputs

- With a PR number: `/review-dependabot-actions 123`
- Without: operates on the current branch diff vs the default remote branch.

## Step 1: Get the diff

If a PR number was supplied, fetch the diff and PR metadata:
```bash
gh pr view <PR_NUMBER> --json title,body,baseRefName
gh pr diff <PR_NUMBER>
```

Otherwise, detect the base branch and diff locally:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git diff origin/<base>..HEAD -- .github/workflows/
```

## Step 2: Identify updated actions

Parse the diff for lines that change an `uses:` reference. Each updated action looks like:

```diff
-        uses: owner/repo@<old_sha>  # v3.1.0
+        uses: owner/repo@<new_sha>  # v4.2.1
```

The version comment after the SHA is the **claimed** version identifier — it is NOT authoritative until verified in Step 3. Extract:
- `action` — e.g. `actions/checkout`
- `old_version` — e.g. `v3.1.0`
- `new_version` — e.g. `v4.2.1`
- `old_sha` — the full SHA being replaced
- `new_sha` — the full SHA being introduced
- `workflow_files` — which workflow file(s) use this action

Deduplicate by `(action, old_version, new_version)` — the same bump may appear in multiple workflow files.

## Step 3: Verify SHA provenance (supply chain safety)

**This step is critical.** GitHub resolves commit SHAs across the entire fork network, so a malicious PR could pin `owner/repo@<sha-from-a-fork>` while claiming a legitimate version in the comment. This step catches that attack.

For each updated action, verify that the `new_sha` from the diff matches the tag on the **upstream** repository:

### 3a. Resolve the claimed tag to its canonical SHA

```bash
gh api repos/<owner>/<repo>/git/refs/tags/<new_version> --jq '.object'
```

This returns `{"sha": "<tag_sha>", "type": "<commit|tag>"}`.

- If `type` is `"commit"` (lightweight tag): `tag_sha` is the commit SHA. Compare directly against `new_sha` from the diff.
- If `type` is `"tag"` (annotated tag): dereference to get the underlying commit:
  ```bash
  gh api repos/<owner>/<repo>/git/tags/<tag_sha> --jq '.object.sha'
  ```
  Compare the dereferenced commit SHA against `new_sha` from the diff.

### 3b. Confirm commit exists on upstream (not just fork-resolvable)

```bash
gh api repos/<owner>/<repo>/commits/<new_sha> --jq '{sha: .sha, author: .author.login, committer: .committer.login, html_url: .html_url}'
```

Verify:
- The API returns 200 (commit exists on `<owner>/<repo>`, not just a fork)
- The `html_url` points to `https://github.com/<owner>/<repo>/commit/<new_sha>`

### 3c. Also verify the old SHA (optional but recommended)

Repeat 3a for `old_version` / `old_sha` to confirm the baseline is also legitimate. This catches cases where a PR rewrites both the old and new lines to shift the baseline.

### 3d. Evaluate results

- **SHA matches tag and commit exists on upstream**: ✅ Verified — proceed to Step 4.
- **SHA does NOT match tag**: ❌ **STOP.** Output an immediate security finding:

  > **❌ SECURITY: SHA mismatch for `<owner>/<action>`**
  > - Claimed version: `<new_version>`
  > - SHA in PR diff: `<new_sha>`
  > - SHA on upstream tag: `<tag_sha>`
  > - **The SHA in this PR does not match the claimed version tag. This may indicate a supply chain attack (fork-sourced SHA). Do NOT merge.**

  Skip all remaining steps for this action. Set the verdict to `❌ DO NOT MERGE — SHA provenance check failed`.

- **Commit not found on upstream repo (404)**: ❌ **STOP.** Same treatment — the SHA may resolve via the fork network but does not belong to the upstream repository.

- **Tag not found on upstream repo (404)**: ⚠️ The claimed version tag does not exist. Flag for manual review.

- **Version comment mismatch**: If the SHA matches a **different** tag than what the comment claims (e.g., SHA resolves to v4.0.1 but comment says `# v3`), flag the discrepancy. This is not necessarily malicious (dependabot bugs exist) but the reviewer must be aware.

## Step 4: For each verified action, gather release notes

For each unique action update, list all GitHub releases from `old_version` (exclusive) up to `new_version` (inclusive):

```bash
gh api repos/<owner>/<repo>/releases --paginate \
  --jq '[.[] | {tag: .tag_name, published_at: .published_at, body: .body}]'
```

Filter the list to only keep releases that fall in the range `(old_version, new_version]`. If the action does not publish GitHub releases, fall back to fetching `CHANGELOG.md` or `CHANGELOG` from the default branch:

```bash
gh api repos/<owner>/<repo>/contents/CHANGELOG.md --jq '.content' | base64 --decode
```

If neither is available, note this explicitly in the output.

## Step 5: Scan for breaking changes

For each release in range, look for indicators of breaking changes in the release body:
- Section headings like `Breaking Changes`, `BREAKING`, `Migration`, `Removed`, `Deprecated`
- Phrases: "no longer", "has been removed", "is now required", "renamed to", "dropped support"

Collect the relevant excerpts verbatim — don't paraphrase, since the reviewer needs the exact wording to judge severity.

## Step 6: Analyze current workflow usage

For each action being updated, read the full workflow file and extract the section where the action is used:
- The `with:` block (all inputs being passed)
- Any `env:` block on that step
- Any step outputs consumed downstream: `${{ steps.<id>.outputs.<name> }}`
- The `if:` condition on the step, if present

Cross-reference this against the breaking changes found in Step 5:
- Was any input the workflow passes **renamed, removed, or had its semantics changed**?
- Was any output the workflow consumes **renamed or removed**?
- Were any new **required inputs** introduced that the workflow is not passing?
- Did the **default behavior** of any input the workflow relies on change?

Only flag impacts that affect what this repo is actually doing — ignore theoretical breakage for inputs/outputs the workflow doesn't touch.

## Step 7: CI coverage analysis

Determine whether each bumped action will be exercised by CI on this PR (i.e., whether a test workflow actually runs with the new version):

1. **Read each workflow that uses the bumped action** and check its trigger configuration.
2. **For `pull_request` trigger**: Check if the trigger has `paths:` filters. If the filter only includes paths like `workspaces/**`, a PR that only touches `.github/workflows/` will NOT trigger the workflow. Classify as not tested.
3. **For `push` trigger**: Same check — if there are `paths:` filters that exclude `.github/workflows/`, the push won't test it. If there are NO path filters on push, the action will be tested when merged (but not on the PR itself).
4. **For `workflow_call` (reusable workflows)**: Trace to the caller workflow(s) and apply the same trigger analysis to the caller.
5. **For `workflow_dispatch`**: Only tested if manually triggered.

Classify each action in each workflow as:
- **Tested by CI** — a workflow with this action will run on this PR (via `pull_request` without restrictive path filters)
- **Tested on merge** — a workflow will run on `push` to the target branch (no path filters), but NOT on the PR itself
- **Not tested by CI** — no workflow exercising this action will run automatically

## Step 8: Output the safety summary

Produce one block per updated action. Use this exact structure:

---

### `<owner>/<action>` — `<old_version>` → `<new_version>`

**SHA verification:**
<State the result of Step 3. Example: "✅ Verified — SHA `fbd0ab8...` matches tag `v4.0.1` on `dorny/paths-filter`. Commit exists on upstream." or "❌ FAILED — see security finding above.">

**Releases spanned:** <list the release tags in range, e.g. v4.0.0, v4.1.0, v4.2.1>

**Breaking changes in release notes:**
<Either paste the relevant excerpts verbatim, or write "None found.">

**Current usage in this repo** (`<workflow_file>:<line>`):
```yaml
<paste the uses: block with its with:, env:, and output consumers>
```

**Impact on current usage:**
<Explain concisely whether any of the breaking changes affect what this repo is doing. Be specific: "Input `persist-credentials` still accepted and unchanged." or "Input `submodules: recursive` — behavior changed in v4.1.0, see excerpt above.">

**CI coverage:**
<For each workflow using this action, state: "Tested by CI", "Tested on merge", or "Not tested by CI", with a brief explanation of why (e.g., "pull_request trigger has paths: [workspaces/**] — won't fire for .github/workflows/ changes")>

**Verdict:** ✅ Safe to merge / ⚠️ Review needed — see impact above / ❌ Workflow update required before merging / ❌ DO NOT MERGE — SHA provenance check failed

---

Repeat for every updated action. If all actions are safe, add a one-line summary at the end:

> All `N` action updates look safe to merge. No workflow changes needed.

If any are not safe, list the required workflow changes explicitly.

### Verdict guidelines

**SHA provenance is a hard gate.** If SHA verification (Step 3) fails, the verdict is always `❌ DO NOT MERGE` regardless of all other factors. The matrix below only applies when SHA verification passes.

| SHA Verified? | Breaking Changes? | CI Coverage | Verdict |
|---|---|---|---|
| ❌ Failed | Any | Any | ❌ DO NOT MERGE — SHA provenance check failed |
| ✅ Verified | None found | Tested by CI | ✅ Safe to merge |
| ✅ Verified | None found | Tested on merge | ✅ Safe to merge (will be validated on push to target branch) |
| ✅ Verified | None found | Not tested by CI | ⚠️ Review needed — action not exercised by CI |
| ✅ Verified | Minor / non-impacting | Tested by CI | ✅ Safe to merge |
| ✅ Verified | Minor / non-impacting | Not tested by CI | ⚠️ Review needed — breaking changes exist but appear non-impacting; no CI coverage to confirm |
| ✅ Verified | Impacting current usage | Any | ❌ Workflow update required before merging |

## Notes

- If the action repo is private or rate-limited, note that release notes could not be fetched and recommend the reviewer check manually.
- When the version jump crosses a major version boundary (e.g., v3 → v4), be extra thorough — major bumps are where breaking changes are intentionally placed.
- Prefer quoting the release notes verbatim over summarizing, so the reviewer can judge intent rather than your interpretation.
- Do not approve or block the PR — the goal is to equip the human reviewer with exactly the information they need to make the call themselves.
- **Node.js runtime upgrades are harmless for callers.** Many actions label a Node 16→20 or Node 20→24 runtime bump as a "Breaking Change" because it raises the minimum runner version. Treat this as a non-issue for any job using a GitHub-hosted runner (e.g. `ubuntu-latest`, `macos-latest`, `windows-latest`) — those are always up to date. Only flag it if the workflow uses a self-hosted runner, in which case mention the minimum runner version requirement so the reviewer can verify. Do not let a Node runtime bump inflate the verdict from ✅ to ⚠️ for hosted runners.
