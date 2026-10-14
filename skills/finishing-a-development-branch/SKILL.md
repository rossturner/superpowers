---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass, to squash the work into one commit when it is safe and summarize what was done
---

# Finishing a Development Branch

## Overview

**Core principle:** Verify tests → Read the base → Squash only when every check passes → Clean up → Summarize and stop.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

This runs after subagent-driven-development or executing-plans, which already
ran the whole-branch review. Do no review here. Everything needed comes from
the plan path and its ledger, so this works from a fresh session too.

**Plan path:** from the executor's final message, or from your human partner.
Without one there is no ledger to read — treat it as "no ledger" in Step 2.

## Step 1: Verify Tests

Run the project's full test suite (`npm test` / `cargo test` / `pytest` / `go test ./...`).

**If tests fail**, report the failures and stop — no squash, no cleanup:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

**If tests pass:** continue to Step 2.

## Step 2: Read the Base

Run `../subagent-driven-development/scripts/sdd-workspace PLAN_FILE`, relative
to this skill's directory, from the project's working directory:

```bash
WS=$(bash <this skill's directory>/../subagent-driven-development/scripts/sdd-workspace PLAN_FILE)
LEDGER="$WS/progress.md"
```

Line 2 of the ledger is `Base: <40-char sha>`.

**If there is no ledger, or it has no `Base:` line, or that sha does not
resolve** (`git rev-parse --verify <Base>^{commit}` fails): never guess the
base. Skip Steps 3–4, state why ("no ledger for <plan>, squash skipped"), and
go to Step 5. `sdd-workspace` creates the directory if it was missing, so
Step 5 still removes it.

Read the whole ledger now — Step 5 deletes it, and the summary needs its task
lines and every `Ruling:` line.

## Step 3: Squash Checks

Run every check, in order. The first that fails decides: leave history as is,
and name the failed check in the summary.

1. **Base is an ancestor of HEAD:** `git merge-base --is-ancestor <Base> HEAD`.
   Fails → history was rewritten under the ledger.
2. **Something to squash:** `git rev-list --count <Base>..HEAD` is 2 or more.
   0 → nothing was committed; 1 → already one commit. Either way, no squash
   (not a failure; say so).
3. **Clean tree:** `git diff --quiet && git diff --cached --quiet`. This covers
   tracked files only. Untracked files are not a blocker: `git reset --soft`
   leaves them untracked and the commit in Step 4 takes the index as is, with
   no `git add`, so they cannot be swept in. List any in the summary
   (`git status --porcelain` lines starting `??`) so they are not forgotten.
4. **No merge commits:** `git rev-list --merges <Base>..HEAD` prints nothing.
5. **Nothing interleaved (chain rule):** take every `(commits <a>..<b>` range
   in the ledger, in ledger order — task completions, abandoned tasks that
   left commits, and the `Final review: fixes` line. Then:
   - `prev = <Base>`;
   - for each range: `git rev-parse <a>` must equal `git rev-parse <prev>`;
     then `prev = <b>`;
   - finally `git rev-parse <prev>` must equal `git rev-parse HEAD`.

   Ranges where `a == b` are fine. Any mismatch, or a short sha that does not
   resolve, fails the check: commits exist in the range that no task accounts
   for (work made outside the run), and squashing would bury them.
6. **Nothing pushed:** `git branch -r --contains <oldest>` prints nothing,
   where `<oldest>` is `git rev-list --reverse <Base>..HEAD | head -1`. Checking
   the oldest suffices: check 4 made the range linear, so every commit in it
   descends from `<oldest>`, and any remote branch holding a later commit also
   holds `<oldest>`. Run `git fetch` first only if it needs no credentials
   prompt; otherwise use the remote-tracking refs as they are and say so.

## Step 4: Squash

Only when all checks in Step 3 passed:

```bash
git reset --soft <Base>
git commit -F - <<'EOF'
<subject: the plan's Goal, as a commit subject>

<what was built, one line per completed task or outcome>

Not built: Task <N> (<name>) — abandoned: <why>
EOF
```

Derive the message from the plan's `**Goal:**` line and the ledger's completed
tasks. Name every abandoned task as not built; omit the line when there are
none. Follow the repo's commit-message conventions.

The spec and plan commits made before `Base` stay outside the squash. That is
intended — do not widen the range to include them.

**Never push or force-push.** The commit stays local.

## Step 5: Clean Up

```bash
rm -rf "$WS"
```

Delete only this plan's workspace directory — never `.superpowers/sdd/`
itself, its `.gitignore`, or another plan's directory.

## Step 6: Summarize and Stop

Report:

- **What was built:** the plan's goal and the completed tasks.
- **Key changes:** the main files and behaviours touched.
- **Final commit:** the squash commit's sha and subject — or, when the squash
  was skipped, the range `<Base7>..<HEAD7>` and which check failed (or why
  there was no ledger).
- **Rulings:** the executor's "Rulings I made" list, verbatim when you have
  it; from a fresh session, every `Ruling:` line from the ledger. Abandoned
  tasks, "left for you" actions, unverified tasks and residual load-bearing
  findings first.
- **Untracked files**, if Step 3 found any.

Then stop. No menu, no push or PR offer, no question.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to squash. A green run only proves the tree it ran on. |
| "I can infer the base" | The ledger's `Base:` is the only base. A guessed base squashes commits that were never part of this run. No ledger, no squash. |
| "The range is close enough to linear" | A merge commit or a broken chain means commits no task accounts for. Squashing buries them. Leave history as is and say which check failed. |
| "The push was rejected — force-push will fix it" | This skill never pushes. A rejected push in any later step means the remote moved; investigate, and force-push only on your human partner's explicit request. |

## Red Flags

**Never:**
- Guess the base, or squash without a `Base:` from the ledger
- Squash with failing tests
- Squash when any Step 3 check failed
- `git add` anything before the squash commit
- Push or force-push
- Ask your human partner whether to squash
- End with a menu, a push/PR offer, or a question
- Delete anything beyond this plan's workspace directory
