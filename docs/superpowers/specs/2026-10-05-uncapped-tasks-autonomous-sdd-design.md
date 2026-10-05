# Uncapped Tasks and Autonomous SDD

## Problem

Two behaviours of the current workflow cost the user time.

1. **Tasks are split to fit a read limit.** `writing-plans` caps a task at roughly 600 lines of code (the Ceiling test), and `subagent-driven-development` stops and reports to the user when a review package passes 2000 lines. Both rules exist because a reviewer reads its package once, and Read returns 2000 lines by default, so a reviewer of a long package returns a verdict on the first part with no sign the rest existed. The risk is real; the remedy is wrong. Read pages with `offset`, and the agents hold far more than 2000 lines in context. Capping task size makes plans split outcomes into pieces that later have to be stitched back together.
2. **SDD stops to ask.** The controller stops for plan-vs-finding conflicts, a too-large BLOCKED, a wrong plan, a load-bearing finding at the fix-loop breaker, and an oversize package. The implementer prompt tells subagents to stop whenever they are uncertain or face several valid approaches, and those escalations reach the user. The user wants SDD to use its own judgement and never stop mid-run.

## Decisions

- No size cap on a task. A task is one outcome named in the plan's Architecture paragraph, however large.
- Reviewers read the whole package in chunks and confirm they reached the end.
- SDD never stops mid-run to ask the user. Every decision is made by the controller, logged, and reported at the end.
- User-gate tasks are unchanged. They are dormant unless the user registers the opt-in hook and explicitly asks for a gate.
- The change is made directly in the skills. No configuration switch.

## Section 1: Task size and complete reviews

**writing-plans** (`skills/writing-plans/SKILL.md`, Task Granularity) and **`skills/shared/task-format-reference.md`**:
- Delete the Ceiling test, leaving Merge and Split.
- Split gains the sentence: "A Goal that needs more than one sentence to state the outcome is holding two outcomes."
- "Neither file count nor commit count bounds a task" becomes "Neither size, file count nor commit count bounds a task."
- The paragraph on what a task costs to run stays.

**`skills/subagent-driven-development/scripts/review-package`**:
- The package's first line becomes `# Review package: <base>..<head> (<L> lines)`.
- The printed summary becomes `wrote <path>: <N> commit(s), <L> lines`.
- L is the package's total line count, header included.

**Reviewer templates** (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`, `re-review-prompt.md`, and `skills/requesting-code-review/code-reviewer.md` if it reads a package once):
- "Read the diff file once" becomes: read the whole diff file in chunks of about 1,500 lines using `offset`, until you reach line L given in its first line; read each part once; state in your report that you read through line L.
- The rules against re-running git, re-reading changed files and crawling the codebase stay.

**SDD step 3** (`skills/subagent-driven-development/SKILL.md`): remove the `wc -l` check and the oversize-package stop.

**Implementer prompt**: remove "or break the task into smaller pieces" from the escalation paragraph.

## Section 2: SDD runs to completion without asking

**Rule.** SDD never stops mid-run to ask the user. The controller decides every question from the plan's "User decisions" header, the spec, the plan text and the codebase, and appends `Task <N>: decision — <question> — ruling: <choice, why>` to the ledger. Its final report to `finishing-a-development-branch` carries a **Decisions made** section listing every ruling, plan amendment, abandoned task and parked finding. User-gate tasks are the only exception, and only when that feature is enabled.

**`skills/subagent-driven-development/SKILL.md`**:
- **Continuous execution** paragraph and its Red Flags row: the stop reasons are replaced with "Never stop mid-run: decide, log, continue."
- **"Escalating Questions to Your Human Partner"** becomes **"Deciding Questions Yourself"**: check the plan's User decisions, decide from plan, spec and codebase, log the ruling. Implementer questions are answered by the controller and never relayed.
- **Plan-vs-finding conflict**: the controller rules. The plan governs unless the finding shows that following it produces broken or incorrect code; then the fix proceeds and the deviation is logged.
- **BLOCKED**:
  - Missing context → the controller supplies it.
  - Needs more reasoning → re-dispatch one tier up, as far as opus.
  - Still blocked on opus, or the plan is wrong → the controller amends the plan for this and later tasks (it may split the task), logs the amendment, and continues.
  - Truly impossible → `Task <N>: abandoned — <reason>`. Dependent tasks are adjusted or skipped with logged reasons, and the gap is reported at the end.
- **Breaker** (load-bearing finding open at round 5): the controller applies a plan amendment or parks the finding with a ruling. It never halts.
- **Final review residuals**: parked and listed in Decisions made.
- **Flowchart**: "Ask human partner which governs" and "STOP: report BLOCKED to human partner" become "Rule and log" nodes.

**`implementer-prompt.md`**:
- "Ask them now" and "ask questions… Don't guess or make assumptions" become: make reasonable decisions from the brief, the plan and the codebase, and record each under concerns in your report.
- "STOP and escalate when" shrinks to genuine inability: information missing from the repo, or repeated failure. Uncertainty and multiple valid approaches are not reasons to escalate; pick one and note it.
- NEEDS_CONTEXT and BLOCKED remain statuses, answered by the controller.

**Unchanged**: user-gate tagging, `checking-gates`, `specifying-gates`, fix-loop mechanics, reviewer roles.

## Testing

`tests/claude-code/test-fork-validation.sh`:
- Test 7 asserts the Ceiling test and the 600-line figure are absent from `writing-plans` and `task-format-reference.md`, and that each reviewer template requires reading the package through to its last line.
- A new Test 8 asserts the SDD skill no longer contains "report the task to your human partner", "Ask human partner which governs" or "STOP: report BLOCKED", and the implementer prompt no longer contains "Don't guess".

A manual check runs `review-package` on a real range and confirms the header and summary carry the line count.

## Documentation

The README "Divergence from Upstream" section and the project `CLAUDE.md` describe the granularity rule as "bounded by Merge/Split/Ceiling" and SDD as answering "a too-large BLOCKED by reporting to the user". Both are updated to the new behaviour.
