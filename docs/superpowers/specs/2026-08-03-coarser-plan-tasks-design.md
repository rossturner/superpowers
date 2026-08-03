# Coarser Tasks in Implementation Plans

**Goal:** Implementation plans define fewer tasks, each covering one outcome the plan names, so that a plan runs in fewer subagent dispatches.

## The problem

A task in `subagent-driven-development` costs a brief file, an implementer dispatch, a review package and two reviewer dispatches. Those dispatches run in series, because a reviewer reads a diff that exists only after the implementer commits. A round of review findings adds a fix dispatch and a scoped re-review. A plan of thirteen tasks costs at least thirty-nine dispatches before its final whole-branch review.

Four statements in the current skills produce tasks smaller than that cost justifies.

`skills/shared/task-format-reference.md:147` states that each task produces exactly one commit and that a task needing more than one commit is split. `skills/shared/task-format-reference.md:126` states that a task whose commit message needs bullet points is too big. Together those two sentences make commit size the limit on task size. This fork squashes a plan's commits when the branch finishes, so per-task commit size has no effect once the plan completes.

`skills/shared/task-format-reference.md:125` asks whether a task touches more than one concern and calls it too big when it does. That question is the only upward check in the scope test, and "concern" reads narrowly enough to separate tasks that serve one outcome.

`skills/writing-plans/SKILL.md:14` asks for bite-sized tasks.

`skills/writing-plans/SKILL.md` states no execution cost, so its author decides granularity without knowing what a task costs to run.

## The size rule

A task is one outcome the plan names. A task produces one commit. The commit's size places no limit on the task.

Three tests replace the scope test.

**Merge.** Adjacent tasks serving one outcome are one task. A plan names its outcomes in its Architecture paragraph and its File Structure section.

**Split.** A task holding two outcomes is two tasks, where each outcome stands on its own and the plan makes sense with either one built alone.

**Ceiling.** A task is too large when a reviewer would have to skim its diff to judge whether the outcome was reached. No file count or line count sets this limit.

## Where the rules are written

`skills/shared/task-format-reference.md` holds the Task Granularity section at lines 117 to 147. That section is rewritten to state the three tests and to describe the right scope in prose. The examples table is removed. The sentence about bullet points in a commit message is removed. The Commit Boundary section keeps one commit per task and drops the sentence that infers task size from commit size.

`skills/writing-plans/SKILL.md` holds a second copy of the scope test at lines 45 to 56. Line 14 asks for the largest coherent unit of work. Lines 45 to 56 carry the three tests and point at the shared reference.

## The merge pass

`writing-plans` gains a section that runs after every task is written and before Self-Review. The pass reads each task's Goal line in order, names the outcome each task serves, and merges an adjacent pair when both serve the same outcome. A merged task takes the steps of both in order, the union of their files, and a verify command covering the whole outcome. The pass repeats until no pair merges.

The pass reads a written list because a planner deciding boundaries while it decomposes has no view of the decomposition as a whole.

## What a task costs

`writing-plans` states the execution cost in its Task Granularity section. The statement names the brief file, the implementer dispatch, the review package, the two reviewer dispatches, and the fix dispatch and re-review that each round of findings adds. The author reads the cost where the granularity decision is made.

## Model tiers

`skills/subagent-driven-development/SKILL.md` lines 298 to 301 select an implementer's model by how many files the task touches. Line 313 selects it by whether the plan's steps hold the code to write. Lines 298 to 301 are rewritten to select by content. A task whose steps hold the code to write takes the cheap tier at any size. A task whose steps describe the change in prose takes sonnet. A task requiring design judgment takes sonnet, and escalates when sonnet returns BLOCKED.

## What does not change

The reviewers, the fix loop, the progress ledger, the plan-scoped workspace and the `.tasks.json` persistence file are untouched. One commit per task stays. The final documentation task keeps its own section in `writing-plans`.

## Testing

`tests/claude-code/test-fork-validation.sh` runs without an LLM and asserts fork invariants by grep. A check is added there for the sentences this change removes, so a later upstream merge that restores them fails the suite.
