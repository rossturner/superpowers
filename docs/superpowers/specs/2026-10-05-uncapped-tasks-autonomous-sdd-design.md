# Uncapped Tasks and Autonomous SDD

## Problem

Two behaviours of the current workflow cost the user time.

1. **Tasks are split to fit a read limit.** `writing-plans` caps a task at roughly 600 lines of code (the Ceiling test), and `subagent-driven-development` stops and reports to the user when a review package passes 2000 lines. Both rules exist because a reviewer reads its package once, and Read returns 2000 lines by default, so a reviewer of a long package returns a verdict on the first part with no sign the rest existed. The risk is real; the remedy is wrong. Read pages with `offset`, and the agents hold far more than 2000 lines in context. Capping task size makes plans split outcomes into pieces that later have to be stitched back together.
2. **SDD stops to ask.** The controller stops for plan-vs-finding conflicts, a too-large BLOCKED, a wrong plan, a load-bearing finding at the fix-loop breaker, and an oversize package. The implementer prompt tells subagents to stop whenever they are uncertain or face several valid approaches, and those escalations end in a stop. The user wants SDD to use its own judgement and never stop mid-run.

## Decisions

- No size cap on a task. A task is one outcome named in the plan's Architecture paragraph, however large.
- Every reviewer reads its whole package in chunks and confirms it reached the end.
- SDD never stops mid-run to ask the user. The controller makes every decision, logs it, and reports it at the end.
- The controller never splits a task. It may amend a task once; a task that still cannot be done is abandoned.
- Finishing asks once before squashing when the run abandoned a task or parked a load-bearing finding. A clean run auto-squashes as today.
- User-gate tasks are unchanged. They are dormant unless the user registers the opt-in hook and explicitly asks for a gate.
- The change is made directly in the skills, with no configuration switch and no implementation plan.

## Section 1: Task size and complete reviews

### Granularity

`skills/writing-plans/SKILL.md` (Task Granularity) and `skills/shared/task-format-reference.md` (The Right Scope):
- Delete the Ceiling test. "Three tests" becomes "Two tests".
- Split gains the sentence: "A Goal that needs more than one sentence to state the outcome is holding two outcomes."
- "Neither file count nor commit count bounds a task" becomes "Neither size, file count nor commit count bounds a task."
- The paragraph on what a task costs to run stays.

### Review package

`skills/subagent-driven-development/scripts/review-package`:
- Write the body to a temp file, count its lines, and prepend the header `# Review package: <base>..<head> (<L> lines)`, where L counts the header too.
- The printed summary becomes `wrote <path>: <N> commit(s), <L> lines`. `tests/claude-code/test-sdd-workspace.sh` parses `^wrote \(.*\): [0-9]` and keeps passing.
- The header comment drops "the reviewer reads in one call".

### The read rule

Every reviewer template carries the same rule, with the phrase `read through line` so the test can find it:

> Read the whole package in chunks of about 1,000 lines using `offset`, until a Read returns the end of the file. If a Read fails on size, halve the chunk and continue. Read each part once. The first line gives the total as `(<L> lines)` when the package came from `review-package`; in your report, state that you read through line L (or through the last line, when no total is given).

Templates changed:
- `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md` and `re-review-prompt.md`: "Read the diff file once" is replaced by the rule. Their fallback for a missing diff file becomes "run `review-package` to a file, then read it by the rule", instead of a raw `git diff`. The rules against re-running git, re-reading changed files and crawling the codebase stay.
- `skills/requesting-code-review/code-reviewer.md`: it currently tells the reviewer to run `git diff` itself, though SDD's final review passes it a package. It gains a package section: when a package path is given, read it by the rule; otherwise run `review-package` (or `git diff` redirected to a file) and read that file by the rule. Raw `git diff` into Bash output is no longer the reading method, because long output is truncated.

### SDD step 3

`skills/subagent-driven-development/SKILL.md`, Reviewer inputs:
- Remove the `wc -l` check and the oversize-package stop.
- "each reviewer sees the commit list, stat summary, and full diff with context in one Read call" becomes "in one file, read in chunks".
- In Model Selection, the spec reviewer runs at sonnet rather than haiku when the package is over 3,000 lines, so the reviewer has room for the package plus the brief and the report.

### Implementer prompt

Remove "or break the task into smaller pieces" from the escalation paragraph.

## Section 2: SDD runs to completion without asking

### The rule

SDD never stops mid-run to ask the user. The controller decides every question from the plan's "User decisions" header, the spec, the plan text and the codebase. Questions a plan scripts for execution are decided the same way. The only exception is a user-gate task, when that feature is enabled.

The controller may make product and design calls. It never invents an external fact (a credential, an account, a third-party service choice the spec does not make); a task that needs one is abandoned.

### Ledger

The list of ledger line forms (`SKILL.md`, "one line per event") becomes: dispatch, fix round, complete, minor, parked, decision, amended, abandoned. `BLOCKED` is removed.

- `Task <N>: decision — <question> — ruling: <choice, why>`
- `Task <N>: amended — <what changed> — <why>`
- `Task <N>: abandoned — <reason>; dependents: <how each was handled>`
- `Task <N>: parked — <finding> — ruling: <why the code stands>`, and `Task <N>: parked (load-bearing) — …` for a finding a later task builds on.

Resume treats `complete` and `abandoned` as terminal. A task with either line is never re-dispatched.

### Deciding instead of asking

`skills/subagent-driven-development/SKILL.md`:
- **Continuous execution** (top of the skill): the stop reasons are replaced by "Never stop mid-run: decide, log, continue." The matching row in **Common Rationalizations** gets the same reality column. The rest of that table is unchanged.
- **"Escalating Questions to Your Human Partner"** becomes **"Deciding Questions Yourself"**: check the plan's User decisions, decide from plan, spec and codebase, log a `decision` line. Implementer questions are answered by the controller and never relayed.
- **Plan-vs-finding conflict** (fix loop, "is the human's decision… ask which governs"): the controller rules. The plan governs unless the finding shows that following it produces broken or incorrect code; then the fix proceeds. Either way it logs a `decision` line.
- **BLOCKED** (all four items, including "escalate to the human"):
  1. Missing context: the controller supplies it.
  2. Needs more reasoning: re-dispatch one tier up, as far as opus. Before the dispatch, TaskUpdate the task's `modelTier` to the new tier and log it, so `hooks/pre-agent-model-routing` admits the dispatch.
  3. Still blocked on opus, or the plan is wrong for this task: amend the task once. The amendment goes into the native task description (TaskUpdate), the task's brief file in the workspace, and an `amended` ledger line. The plan file is never edited, and the task keeps its number. Re-dispatch.
  4. Blocked again after an amendment, or impossible: abandon it. Log `abandoned`, set the native task completed with its description shrunk to its Goal plus `ABANDONED — see ledger`, and set its `.tasks.json` status to `"abandoned"`. Native completion keeps `blockedBy` from holding dependents forever. For each dependent, the controller either amends it to stand without the abandoned work or abandons it too.
- **Breaker** (load-bearing finding open at round 5): the controller amends a later task to account for the finding, or parks it as `parked (load-bearing)`. It never halts.
- **Final review**: residual findings are parked with rulings, load-bearing ones included. "stop on load-bearing ones" and "surface to your human partner when finishing-a-development-branch presents the options" go.
- **Flowchart**: "Implementer asks questions?" and "Answer questions, provide context" stay, since the controller still answers implementer questions. "Ask human partner which governs" and "STOP: report BLOCKED to human partner" become "Rule and log" and "Amend once, else abandon".
- **Example Workflow**: the implementer no longer asks "should the hook be installed at user or system level?". It decides, and the decision appears in its report.

### Decisions made

At Finish, before deleting the workspace, the controller compiles **Decisions made** from the ledger: every decision, amendment, abandoned task and parked finding, one line each. It prints the list in its final message and passes it to `finishing-a-development-branch` with the base SHA and plan path.

`skills/finishing-a-development-branch/SKILL.md`:
- Step 3: when the Decisions made list contains an abandoned task or a `parked (load-bearing)` finding, ask once before squashing, even when the range is linear and unpushed. Options: "Squash" and "Leave commits unsquashed". Otherwise auto-squash as today. The Red Flags list allows this question alongside the existing one.
- The squash message names abandoned tasks, so it does not describe work that was never built.
- Step 4's summary includes the Decisions made list.

### Implementer prompt

`skills/subagent-driven-development/implementer-prompt.md`:
- "Before You Begin… Ask them now" and "While you work… ask questions. It's always OK to pause and clarify. Don't guess or make assumptions" become: ask the controller only when the brief contradicts the codebase or leaves out something you cannot find in the repo. Otherwise make the call and record it.
- "It is always OK to stop and say 'this is too hard for me'… You will not be penalized for escalating" and the "STOP and escalate when" list shrink to genuine inability: information missing from the repo, or repeated failure. Uncertainty and multiple valid approaches are not reasons to escalate.
- The report format gains a **Decisions** field, separate from concerns, so routine choices do not turn every report into DONE_WITH_CONCERNS.
- NEEDS_CONTEXT and BLOCKED remain statuses, answered by the controller.

### writing-plans

"Deferred decisions" changes: a plan does not schedule questions for the user at execution time. A decision the plan leaves open states the default the controller applies, and the controller logs it.

### Unchanged

- User-gate tagging, `checking-gates`, `specifying-gates`.
- Fix-loop mechanics and reviewer roles.
- Hooks. `hooks/pre-agent-model-routing` still mentions AskUserQuestion as one way past a blocked dispatch, but the `modelTier` update keeps it from firing on escalation. The opt-in `hooks/examples/pre-task-blockedby-enforce.sh` sees abandoned tasks as completed.

## Testing

`tests/claude-code/test-fork-validation.sh`:
- **Test 7:**
  - Drop `**Ceiling.**` from the must-be-present loop.
  - Assert `**Ceiling.**` and `600 lines` are absent from `writing-plans/SKILL.md` and `task-format-reference.md`.
  - Assert the new Split sentence is present.
  - Assert `read through line` is in all four reviewer templates.
  - Update the test's header comment.
- **New Test 8:** assert that these short, single-line phrases are absent:
  - From the SDD skill: `which governs`, `escalate to the human`, `report BLOCKED`, `oversize package`.
  - From the implementer prompt: `Ask them now`, `Don't guess`.

  Also assert `Never stop mid-run` is present in the SDD skill.

Run the fast suites (`test-fork-validation.sh`, `test-sdd-workspace.sh`) and run `review-package` on a real range to check the header and summary.

## Documentation

- **README:** update the Divergence lines that describe granularity as "bounded by three tests (Merge, Split, Ceiling)" and SDD as answering "a too-large BLOCKED by reporting to the human". Update the finishing paragraph for the end-of-run question.
- **Project `CLAUDE.md`:** update the matching lines: "bounded by Merge/Split/Ceiling", "answer a too-large BLOCKED by reporting to the user", and the finishing bullet.
