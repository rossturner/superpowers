# Coarser Tasks in Implementation Plans

**Goal:** Implementation plans define fewer tasks, each covering one outcome the plan names, so that a plan runs in fewer subagent dispatches.

## The problem

A task in `subagent-driven-development` costs a brief file, an implementer dispatch, a review package and two reviewer dispatches. Those dispatches run in series, because a reviewer reads a diff that exists only after the implementer commits. A round of review findings adds a fix dispatch and a scoped re-review. A plan of thirteen tasks costs at least thirty-nine dispatches before its final whole-branch review.

Four statements in the current skills produce tasks smaller than that cost justifies.

`skills/shared/task-format-reference.md:147` states that each task produces exactly one commit and that a task needing more than one commit is split. `skills/shared/task-format-reference.md:126` states that a task whose commit message needs bullet points is too big. Together those two sentences make commit size the limit on task size. This fork squashes a plan's commits when the branch finishes, so per-task commit size has no effect once the plan completes.

`skills/shared/task-format-reference.md:125` asks whether a task touches more than one concern and calls it too big when it does. That question is the only upward check in the scope test, and "concern" reads narrowly enough to separate tasks that serve one outcome.

`skills/writing-plans/SKILL.md:14` asks for bite-sized tasks.

`skills/writing-plans/SKILL.md` states no execution cost, so its author decides granularity without knowing what a task costs to run.

The saving this change buys is a saving in serial dispatches. Merged tasks run longer implementer turns over larger diffs, and merged `files` lists overlap more often, which removes tasks from the bounded parallel dispatch path in `skills/subagent-driven-development/SKILL.md:573-581`. The change is worth making because the serial chain dominates a plan's wall-clock time.

## The size rule

A task is one outcome. A plan names its outcomes in the Architecture paragraph of its header, and that paragraph is the authority. The File Structure section lists the files each outcome touches. The plan header template in `skills/writing-plans/SKILL.md` asks Architecture for two or three sentences about the approach, so it is amended to ask for the outcomes by name.

Three tests replace the scope test.

**Merge.** Adjacent tasks serving one outcome are one task. A task that cannot be verified on its own serves another task's outcome, and it merges into that task.

**Split.** A task holding two outcomes is two tasks, where each outcome stands on its own and the plan makes sense with either one built alone.

**Ceiling.** A task is too large when its Goal needs more than one sentence to state the outcome, or when the code in its steps runs past roughly 600 lines. The plan's steps hold the code, so both are visible while the plan is written. The 600-line figure comes from the reviewer's reading limit: a reviewer reads its diff as one file, `git diff -U10` turns one changed line into about three lines of that file, and Read truncates a file at 2000 lines by default.

`subagent-driven-development` carries the same check where the diff exists. It runs `wc -l` on the path `scripts/review-package` prints, and a package over 2000 lines means the task outgrew what the plan predicted. The controller records the size in the ledger and reports the task to the human before dispatching either reviewer, because a verdict on the first part of a truncated package is worse than no verdict.

## Commits

A task is a range of commits. The implementer commits as it works, and the plan's steps place commits where they belong within the task.

`skills/subagent-driven-development/SKILL.md:321` already records BASE before dispatching an implementer, and `scripts/review-package` already scopes a review to `BASE..HEAD`. Both exist to carry a task that commits more than once.

The `### Commit Boundary = Task Boundary` section at `skills/shared/task-format-reference.md:145-147` is removed.

## Where the rules are written

`skills/shared/task-format-reference.md` holds the Task Granularity section at lines 117 to 147. That section is rewritten to state the three tests and to describe the right scope in prose. The examples table is removed. The `### TDD Within Tasks (Not Across Tasks)` subsection at lines 141 to 143 is kept unchanged, because `skills/writing-plans/SKILL.md:51` cites it and it is what keeps a red-green-refactor step from becoming its own task.

`skills/writing-plans/SKILL.md` holds a second copy of the scope test at lines 45 to 56. Line 14 asks for the largest coherent unit of work and drops the words "bite-sized" and "Frequent commits". Lines 45 to 56 carry the three tests and point at the shared reference.

`commands/write-plan.md:2` carries the command description shown in the command listing. It asks for a detailed implementation plan without naming a task size.

`README.md:69` describes `writing-plans` as breaking work into bite-sized tasks of two to five minutes each. It is rewritten to describe tasks by outcome.

## The merge pass

`writing-plans` gains a section that runs after every task is written and before Self-Review. The pass reads each task's Goal line in order, names the outcome each task serves, and merges an adjacent pair when both serve the same outcome.

A merged task carries a Goal of one new sentence naming the shared outcome, the union of both Acceptance Criteria lists, the union of both Files lists, the steps of both in order, and a verify command covering the whole outcome. The four section headers `**Goal:**`, `**Files:**`, `**Acceptance Criteria:**` and `**Verify:**` are all required, because `skills/subagent-driven-development/SKILL.md:227-231` copies them verbatim into the TaskCreate description under a self-check.

The pass repeats until no adjacent pair merges. It then renumbers the surviving task headings contiguously from 1 and repairs any plan text referring to a task by number. Renumbering is required because `skills/subagent-driven-development/scripts/task-brief` resolves a task by matching the heading `^#+[ \t]+Task[ \t]+N` and exits 3 when it finds none.

The pass compares adjacent pairs only. A planner that finds two tasks serving one outcome separated by a third moves them together first.

The pass reads a written list because a planner deciding boundaries while it decomposes has no view of the decomposition as a whole.

## What a task costs

`writing-plans` states the execution cost in its Task Granularity section. The statement names the brief file, the implementer dispatch, the review package, the two reviewer dispatches, and the fix dispatch and re-review that each round of findings adds. The author reads the cost where the granularity decision is made.

## Model tiers

Five places define the mechanical tier by how many files a task touches. Coarser tasks touch more files, so all five push a well-specified task up a tier and raise the cost of the dispatches that remain.

`skills/subagent-driven-development/SKILL.md:298-301` selects an implementer's model by file count. Lines 298 to 301 and line 313 are rewritten as one statement that selects by content. A task whose steps hold the code to write is transcription and testing, and it takes the cheap tier. A task whose steps describe the change in prose takes sonnet, because cheap models take two to three times the turns on multi-step work described in prose. A task requiring design judgment takes sonnet, and escalates when sonnet returns BLOCKED.

`hooks/session-start:38` injects the tier definitions into every session and defines `"mechanical"` as one or two files. `hooks/pre-taskcreate-model-tier:176` repeats the same definition in the message an agent reads while being told to fix a task. `README.md:184` holds the user-facing tier table. All three restate the tiers by content.

`docs/model-routing-flow.md:40` already states that a task whose steps contain the complete code is mechanical regardless of file count, and it needs no change.

## Execution changes

`skills/subagent-driven-development/SKILL.md:366` answers a BLOCKED return with "If the task is too large, break it into smaller pieces". A plan written under the new rule holds no smaller pieces, so that remedy is replaced. A controller facing a too-large BLOCKED reports the task, the implementer's report file and the plan text to the human, who decides whether to amend the plan.

The ledger's dispatch line records BASE. A task now commits several times, so a compaction partway through a task leaves the controller resuming at a HEAD that already holds part of that task's commits. Recording BASE where the ledger survives compaction keeps the review package covering the whole task.

## Fork divergence documentation

`skills/shared/task-format-reference.md` appears in neither `CLAUDE.md` nor the README "Divergence from Upstream" section, so this change forks that file for the first time. Both documents gain an entry naming the file and stating that the fork's granularity rule, the three tests and the removed Commit Boundary section survive an upstream merge.

The README's `writing-plans` entry at line 528 gains the merge pass and the cost statement. Its `subagent-driven-development` entry at line 531 gains content-based tier selection.

## What does not change

The reviewers, the progress ledger, the plan-scoped workspace and the `.tasks.json` persistence file are untouched. The Final Task: Documentation section in `writing-plans` keeps its own rule.

## Deferred

The five-round fix cap in `skills/subagent-driven-development/SKILL.md:438` is per task and counts rounds across both reviewers. Larger tasks draw more findings per review against a fixed budget, so the cap trips more often. The cap stays at five through this change. One plan runs under the new sizes, and the run decides whether the cap moves.

The cheap tier now applies to a transcription task of any size. Turn count grows with the number of files an implementer writes even when the plan holds the code, so a cheap model on a large transcription task may take enough turns to cost more than a mid-tier one. The same run decides whether the cheap tier needs a size bound after all.

## Testing

`tests/claude-code/test-fork-validation.sh` runs without an LLM and asserts fork invariants by grep. A check is added there for the phrases this change removes, anchored on short strings rather than whole sentences, so a later upstream merge that restores them fails the suite. The check covers `skills/shared/task-format-reference.md`, `skills/writing-plans/SKILL.md` and `commands/write-plan.md`.
