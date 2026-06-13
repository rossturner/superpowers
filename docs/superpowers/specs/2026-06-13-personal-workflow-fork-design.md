# Personal-Workflow Fork of Superpowers — Design

**Status:** Approved for planning
**Date:** 2026-06-13
**Author:** Ross (with Claude)

## Goal

Adapt this fork of `pcvelz/superpowers` (itself a fork of `obra/superpowers`) to match the
maintainer's actual single-developer workflow. The changes remove the cross-platform / multi-user
machinery that does not apply (git worktrees, parallel-session execution, manual spec review,
upstream-contribution rules) and bake in the behaviors the maintainer repeatedly instructs by hand
(adversarial spec review, parallel per-task review, autonomous execution, squash-on-finish).

This is a personal fork. There is no PR/upstream obligation. Work happens directly on `master`
(or `main`) unless the user has manually switched to a branch.

## Non-Goals

- No new third-party dependencies.
- No change to the `test-driven-development`, `systematic-debugging`, `dispatching-parallel-agents`,
  `requesting-code-review`, `receiving-code-review`, `writing-skills`, `using-superpowers`, or the
  user-gate skills (`checking-gates`, `specifying-gates`) beyond reference cleanup.
- The `systematic-debugging` "WorktreeManager" mentions are illustrative example code in a debugging
  walkthrough — they are NOT the git-worktree workflow and must be left untouched.

---

## Change 1 — `brainstorming`: adversarial spec review replaces manual review

**File:** `skills/brainstorming/SKILL.md`, plus the reviewer prompt template.

The conversational design phase (explore → clarify → propose approaches → present design sections for
approval) is unchanged. The change is everything after the spec is written.

### New flow after design approval

1. Write the spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and **commit it**.
2. **Adversarial spec review (new — replaces the "User reviews written spec" gate):**
   - Dispatch **multiple subagents in parallel**, each attacking the spec from a **different
     adversarial perspective**.
   - The agent **chooses the set of adversaries itself** to fit the spec at hand. Do NOT hardcode a
     fixed panel. (Typical perspectives: completeness/consistency, hidden-assumptions/failure-modes,
     scope/YAGNI/over-engineering, integration-with-existing-code — but the agent selects what fits.)
   - Each reviewer runs at the **same model tier as the main conversation** (no model override).
   - These reviewers are read-only → parallel dispatch is safe.
3. **Fold findings back:**
   - Where a reviewer surfaces a **clear error, gap, or contradiction** → fix the spec directly.
   - Where a reviewer surfaces a **genuine open decision** → pose it to the user via `AskUserQuestion`.
4. **Commit the revisions** as a second commit (not an amend — keep the review trail visible).
5. Proceed directly to the `writing-plans` skill. There is **no manual user-review prompt** anywhere
   in this flow.

### Removals

- Delete the **"Native Task Integration"** section (the `TaskCreate`-during-design block). Task
  creation moves entirely to `subagent-driven-development` (Change 3).
- Delete the **"User Review Gate"** prose block and the step-8 checklist item ("User reviews written
  spec"). The "Spec Self-Review" inline check (step 7) may remain as a cheap pre-dispatch pass, or be
  folded into the adversarial review — implementer's choice during planning.

### Reviewer prompt template

Generalize `skills/brainstorming/spec-document-reviewer-prompt.md` (currently a single neutral
reviewer) into an **adversarial reviewer prompt parameterized by perspective**, or add a sibling
template. The prompt instructs the subagent to attack the spec from its assigned perspective and
return structured findings (clear-errors vs. decisions-needed) so the orchestrator can route them.

### Updated checklist (brainstorming)

1. Explore project context
2. Offer visual companion (if visual questions ahead)
3. Ask clarifying questions
4. Propose 2-3 approaches
5. Present design sections, get approval
6. Write design doc and commit
7. Adversarial spec review (parallel, agent-chosen perspectives, main tier) → fold fixes / surface
   decisions → commit revisions
8. Transition to `writing-plans`

---

## Change 2 — `writing-plans`: write, commit, halt

**File:** `skills/writing-plans/SKILL.md`

### Removals

- **"REQUIRED FIRST STEP: Initialize Task Tracking"** (the `TaskList`/`TaskCreate` gate) — removed.
- The entire **"Native Task Integration Reference"** section (per-task `TaskCreate`, embedded
  `json:metadata`, dependency setup) — removed (relocated to SDD).
- The **"Task Persistence"** section (`.tasks.json` writing) — removed (relocated to SDD).
- The **"Execution Handoff"** `AskUserQuestion` (Subagent-Driven vs. Parallel Session) — removed.
- The **"Gate enforcement note"** and **user-gate mechanical-detection/tagging** content — relocated
  to SDD's task-creation step (Change 3), since it is part of `TaskCreate`.

### New terminal behavior

After writing the plan document:
1. **Commit** the plan doc.
2. **STOP** with a short message, e.g.:
   > Plan written and committed to `<path>`. Recommend `/compact`, then invoke
   > `subagent-driven-development` to execute it.

No task creation, no `.tasks.json`, no execution-method question. The plan `.md` records gate intent
in prose so SDD can act on it during task creation.

### Header note

Remove the "If working in an isolated worktree…" context line. Plans always execute on the current
branch.

---

## Change 3 — `subagent-driven-development`: the core rework

**File:** `skills/subagent-driven-development/SKILL.md`

### 3a. Start-of-skill self-summary

The first action on invoking SDD is to **read the skill and print a concise numbered summary of the
full loop to itself** before doing anything else. This is an explicit anti-forgetting measure (the
observed failure mode is the orchestrator diving into implementation and skipping the review steps).
The summary must enumerate: create tasks → per-task (implement → parallel spec+code review → dispatch
fixes → mark complete) → final review → squash → summary.

### 3b. Task creation (relocated from writing-plans)

Immediately after the self-summary, SDD **creates the native tasks** from the plan document:
- `TaskCreate` for each task with the full structured body (Goal / Files / Acceptance Criteria /
  Verify) and the embedded `json:metadata` fence.
- Apply the **user-gate mechanical detection + tagging** logic (moved verbatim from writing-plans).
- Set `blockedBy` dependencies.
- Write the co-located `<plan-path>.tasks.json` persistence file.

This is the single point where tasks now come into existence.

### 3c. Branch handling

- Work on the **current branch**, whatever it is (usually `master`/`main`).
- **Never switch branches.** If work belongs on a different branch, assume the user switched to it
  manually before invoking SDD.
- **Remove** the red flag *"Start implementation on main/master branch without explicit user
  consent"* — committing to master is now the default, not a violation.
- **Remove** the `using-git-worktrees` "REQUIRED: Set up isolated workspace" integration line.

### 3d. Parallel per-task review (replaces sequential spec-then-code gate)

After the implementer subagent reports `DONE`:
- Dispatch the **spec compliance reviewer** and the **code quality reviewer** **concurrently** (both
  are read-only → parallel-safe).
- **Spec reviewer model tier:** always the cheap / mechanical / haiku tier (explicit model override
  at dispatch).
- **Code reviewer model tier:** the **same tier as the orchestrator / main conversation** (no model
  override — inherit). The code reviewer **may be downgraded or skipped entirely** for small,
  mechanical, or otherwise trivial tasks, at the orchestrator's judgment.
- **Remove** the red flags and prose enforcing spec-before-code ordering
  (*"Start code quality review before spec compliance is ✅ (wrong order)"* and the strict sequencing
  in the process diagram). The two reviews are now concurrent.
- Collect findings from both reviews.

### 3e. Follow-up work always goes to a subagent

Any follow-up work required by either review is **dispatched to a subagent** — the orchestrator never
performs review follow-up itself **unless it is truly tiny and mechanical**. After fixes, re-dispatch
the relevant reviewer(s) and repeat until clean. Then `TaskUpdate` → completed and sync `.tasks.json`.

### 3f. Autonomy

Execute all tasks start-to-finish without check-ins. The only reasons to stop are: a `BLOCKED` status
that cannot be resolved, or a genuinely critical question that prevents further progress. (Existing
"continuous execution" language is kept and strengthened.)

### 3g. End of run

After the last task:
1. Record the **base SHA** captured at the start of the run (HEAD before task 1) — needed for the
   squash in Change 4.
2. Dispatch the **final whole-implementation code reviewer**.
3. Fold any final-review fixes **via a subagent**.
4. Hand off to `finishing-a-development-branch` (Change 4), which performs the squash and summary.

### 3h. Parallelism red-flag reconciliation

The existing "never dispatch parallel implementers with overlapping files" rule **stays** — it is
about *writers*. The new parallel **reviewers** are read-only and explicitly permitted, consistent
with the existing "Bounded Parallel Dispatch / read-only agents are always parallel-safe" section.

---

## Change 4 — `finishing-a-development-branch`: squash + summary only

**File:** `skills/finishing-a-development-branch/SKILL.md`

Gut the current skill (merge/PR/keep/discard menu, environment/worktree detection, base-branch
detection, worktree cleanup). Replace with:

1. **Verify tests pass.** If failing, stop and report — do not squash.
2. **Squash logic:**
   - The base SHA is the HEAD recorded at SDD start. The work's commits are `base..HEAD`.
   - If `base..HEAD` is **linear and contains only this work's commits** (nothing interleaved — no
     foreign commits, no merge commits introduced mid-run) → **auto-squash into a single commit**
     via soft reset, with a message derived from the spec/plan.
   - If **other / interleaved commits exist** → ask the user two things via `AskUserQuestion`:
     (a) perform the squash anyway? and (b) should the squashed commit message mention the other work?
3. **Summarize what was done overall. Nothing else.** No menu, no push offer, no further prompts.

The skill is **kept** (not deleted) because both SDD and the documented main workflow reference it.

---

## Change 5 — Remove git worktrees everywhere

### Deletions

- `skills/using-git-worktrees/` — entire skill.
- `skills/executing-plans/` — entire skill (the parallel-session path; SDD is now the sole execution
  path).
- `tests/claude-code/test-worktree-native-preference.sh` — entire test.

### Reference scrubbing

- `README.md` — remove the `using-git-worktrees` workflow step and skill-list entries; update the
  `finishing-a-development-branch` description (no worktree cleanup). (Subsumed by Change 6.)
- `hooks/pre-askuser-handoff-guard` — remove/adjust the worktree + executing-plans handoff branch
  (the guard references the now-deleted "Open new session in worktree" option; since writing-plans no
  longer emits that `AskUserQuestion`, reconcile the guard accordingly).
- `docs/model-routing-flow.md` — remove the worktree reference.
- `scripts/sync-to-codex-plugin.sh` — remove the `"/.worktrees/"` exclude entry.
- `skills/using-superpowers/references/codex-tools.md` — remove the `using-git-worktrees` reference.
- `.gitignore` — remove the worktree-related entry.

### Command wrapper

- `commands/execute-plan.md` — currently invokes `executing-plans`. **Repoint** it to
  `subagent-driven-development` (or delete it if redundant with direct skill invocation).

### Tests to update

- `tests/claude-code/test-subagent-driven-development.sh` — drop the worktree-requirement assertion;
  add an assertion for parallel spec+code review behavior.
- `tests/claude-code/test-handoff-guard.sh` — reconcile with the removed handoff `AskUserQuestion`.

### Cross-reference sweep

After deletions, grep the repo for `using-git-worktrees`, `executing-plans`, and `worktree` and fix
every remaining reference (excluding the `systematic-debugging` illustrative examples).

---

## Change 6 — Documentation rewrite

### `README.md` — full personal-fork rewrite

- Reframe "Why this fork exists" around the maintainer's personal workflow (not the public
  vanilla-vs-extended comparison).
- Rewrite "The Basic Workflow" to the new flow:
  brainstorm → adversarial spec review → write-plan (commit + halt) → `/compact` →
  subagent-driven-development (task creation + parallel per-task review) → final review →
  squash + summary.
- Keep install instructions, pointing at this fork.
- Drop the vanilla-vs-extended comparison table and all upstream-contribution sections.
- **Keep MIT attribution** to `obra/superpowers` and `pcvelz/superpowers`.

### `CLAUDE.md` — minimal identifier

Replace the entire contents (PR template rules, 94%-rejection warning, `dev`-branch targeting,
"what we won't accept", new-harness rules, etc.) with a **minimal identifier**: a short statement
that this is the maintainer's personal fork of superpowers, and a pointer to the `skills/` directory.
No contribution rules, no PR machinery, no workflow conventions. `AGENTS.md` is a symlink to
`CLAUDE.md` and follows automatically.

### Version bump

Bump the plugin version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

---

## Model-tier mechanism (cross-cutting reference)

Reviewer model tiers are set **at dispatch time** via the agent/Task `model` parameter, not via the
task-metadata routing hooks:

| Reviewer | Where | Model tier |
|----------|-------|-----------|
| Adversarial spec reviewers | brainstorming, parallel | Same as main conversation (inherit) |
| Per-task spec compliance reviewer | SDD, per task | Cheap / mechanical / haiku (explicit override) |
| Per-task code quality reviewer | SDD, per task | Same as orchestrator (inherit); may downgrade/skip if trivial |
| Final code reviewer | SDD, end of run | Same as orchestrator (inherit) |

The existing `pre-agent-model-routing` / `pre-taskcreate-model-tier` hooks (which route *plan tasks*
by `modelTier` metadata) are unaffected — they govern implementers, not these directly-dispatched
reviewers.

---

## Affected files (summary)

**Skills:** `brainstorming/SKILL.md`, `brainstorming/spec-document-reviewer-prompt.md`,
`writing-plans/SKILL.md`, `subagent-driven-development/SKILL.md`,
`finishing-a-development-branch/SKILL.md`, `using-superpowers/references/codex-tools.md`.
**Deleted:** `skills/using-git-worktrees/`, `skills/executing-plans/`,
`tests/claude-code/test-worktree-native-preference.sh`.
**Hooks:** `hooks/pre-askuser-handoff-guard`.
**Docs:** `README.md`, `CLAUDE.md`, `docs/model-routing-flow.md`.
**Scripts:** `scripts/sync-to-codex-plugin.sh`.
**Commands:** `commands/execute-plan.md`.
**Config:** `.gitignore`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
**Tests:** `tests/claude-code/test-subagent-driven-development.sh`,
`tests/claude-code/test-handoff-guard.sh`.

## Open risks / verification

- The `pre-askuser-handoff-guard` hook and `test-handoff-guard.sh` are coupled to the removed
  writing-plans handoff `AskUserQuestion`. Implementation must read the hook carefully and ensure the
  test suite passes after reconciliation.
- Squash base-SHA detection: SDD must record HEAD at run start; verify the "interleaved commits"
  branch triggers the user prompt correctly.
- After all reference scrubbing, `grep -rn 'worktree\|executing-plans\|using-git-worktrees'` should
  return only the `systematic-debugging` illustrative examples.
