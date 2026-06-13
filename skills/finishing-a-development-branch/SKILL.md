---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass, to squash the work into a single commit and summarize what was done
---

# Finishing a Development Branch

## Overview

Complete development work on the current branch: verify tests, squash the work into a single commit, and summarize what was done.

**Core principle:** Verify tests → resolve base SHA → squash (safely) → summarize.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify Tests

Run the project's test suite. If anything fails, stop and report the failures — do not squash:

```
Tests failing (<N> failures). Fix before completing:
[show failures]
```

If tests pass, continue.

## Step 2: Resolve the Base SHA

The base SHA is the squash anchor — HEAD before the work began. Read it from the `"baseSha"` field of the plan's `.tasks.json` (passed in by the caller). If it is absent, ask the user for the starting point or skip the squash — never guess.

The work's commits are `baseSha..HEAD`.

## Step 3: Squash

**Auto-squash** `baseSha..HEAD` into a single commit — via `git reset --soft <baseSha>` then one commit — ONLY when all of these hold:

- The range is **linear** (no merge commits), AND
- it contains **only this work's commits** (nothing foreign or interleaved), AND
- **no commit in the range is already on the upstream tracking ref.** Check against `@{upstream}` when one exists:

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null   # is there an upstream?
git merge-base --is-ancestor <baseSha> @{upstream}                        # are work commits already pushed?
```

Squashing commits that are already published would rewrite shared history.

The squash commit message is derived from the spec/plan passed in by the caller.

**Otherwise** — interleaved or foreign commits, or work already on the upstream — ask the user:

```yaml
AskUserQuestion:
  question: "The work commits aren't a clean, unpushed, linear range. How should I finish?"
  header: "Squash"
  options:
    - label: "Squash anyway"
      description: "Collapse the work into one commit; mention the other commits in the message"
    - label: "Squash, don't mention others"
      description: "Collapse the work into one commit; message covers only this work"
    - label: "Leave commits as-is"
      description: "No squash; keep history exactly as it is"
```

**Never force-push** as part of this skill without an explicit request from the user.

## Step 4: Summarize

Summarize what was done overall — the feature, the key changes, and the final commit. Nothing else: no menu, no push offer, no further prompts.

## Red Flags

**Never:**
- Proceed with failing tests
- Squash commits already on the upstream tracking ref without asking
- Force-push without an explicit request
- Guess the base SHA
- Add a merge/PR/keep/discard menu, or any prompt beyond the squash question above
