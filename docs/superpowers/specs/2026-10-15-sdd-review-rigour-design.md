# SDD review rigour — design

## Why

Ross ran the fork's subagent-driven-development (SDD) on a 10-task build in
prentora/api (online-safety moderation, 15 Oct 2026). Every step ran, but the
reviews changed almost nothing:

- About 25 findings across five tasks were graded Minor and parked. Only one was
  fixed before the next task.
- Some of the parked "Minors" broke rules in the spec, such as error codes that
  revealed a restriction the spec says must stay invisible to its author.

Ross had to ask why nothing was being fixed. The controller then improvised:

- a list of invariants;
- reviews that treat the spec as the authority and search unchanged code for
  every path an invariant governs;
- a retroactive audit of Tasks 1–5.

The audit found about 4 Important and 15 Minor gaps that the per-task reviews
had missed.

There are two failures:

1. **Steps get dropped.** Before the rebase onto obra v7.0.0, Ross often had to
   tell SDD to list its steps first, or it would skip the review step. The
   archived fork (`archive/pcvelz-7.2.0`) made "print a numbered summary of the
   loop" the controller's first action, so that review and bookkeeping steps
   weren't skipped under load. The rebase lost it. The prentora run did not drop
   a step; this one rests on Ross's experience before the rebase, and he asked
   for it.
2. **Review output isn't acted on.** obra's skill caps reviewer scope ("do not
   crawl the broader codebase") and parks Minor findings for the final review,
   which only triages them. Ross: anything left "as a minor for later" will
   never be actioned, and that is the agent being lazy, not effective.

The goal is not more process. It is that every step happens and the review
output changes what ships.

## Goals

- SDD and executing-plans (Native) write their step list into the ledger before
  any other work, and re-read it on resume.
- Each SDD task gets two focused reviewers in parallel, spec and quality, both
  on the orchestrator's model.
- The spec reviewer treats the spec as the authority. It checks the plan's
  invariants against the whole codebase, including unchanged code.
- Critical, Important and spec ❌ findings are fixed before the next task. So is
  any finding that breaches a spec rule or invariant, whatever grade it was
  given.
- Minor findings are deferred to the final whole-branch review, and the final
  fix wave fixes them. A Minor leaves unfixed only by a ledgered ruling that
  says why.
- writing-plans writes an Invariants section into every plan.

## Non-goals

- No task size cap. Ross decided this: writing-plans keeps one task per outcome
  with no size limit. Two reviewers don't shrink the diff each one reads. What
  they change is focus: each reads it for one job.
- No change to implementer model selection. The judgment-based tier rule stays
  for implementers.
- No general codebase crawl by task reviewers. The search outside the diff is
  scoped to invariants, plus the existing "check call sites when a shared
  contract changes" rule.
- No change to brainstorming, finishing, the ledger's commit-range contract, or
  the 5-round fix-loop cap.

## Anti-goals

- A Minor that is "deferred" and then never fixed, with no ruling saying why.
- A spec-rule breach graded Minor because it looks small, and left there.
- A step list the controller improvises fresh each run. The list is fixed text
  in the skill.
- A reviewer that says it checked an invariant without showing what it searched.

## The design

### 1. Step list (SDD and Native)

Each executor's skill holds its step list as fixed text. The controller's first
action, before reading the plan, is to append that list to the ledger, copied,
not paraphrased, under a heading line `## Steps (<executor>)`. On resume it
re-reads the most recent Steps block. If that block belongs to the other
executor, or there is none (a ledger from before this change), it appends its
own first. The ledger stays append-only.

The ledger's first two lines stay `# SDD ledger — plan: …` and `Base: <sha>`,
because finishing and the resume rules read them by position. A new ledger gets
its Steps block straight after `Base:`.

Other contracts read ledger lines by content, so the list's text must never
contain these patterns:

- `Ruling:`, which Finish collects;
- `(commits`, which finishing's chain check parses;
- a line beginning `Task <N>:` or `Final review:`.

SDD's list:

1. Resolve the workspace and check the ledger. Record `Base:` and this step list.
2. Read the plan and its spec. Run the pre-flight conflict scan. Make sure an
   invariants list exists, with a search anchor on every line.
3. For each task:
   - record BASE
   - dispatch the implementer
   - build the review package
   - run the spec and quality reviewers in parallel, both on the orchestrator's
     model
   - fix every Critical, Important and ❌ finding, and every finding that
     breaches a spec rule or invariant, then run a scoped re-review (5 rounds at
     most)
   - log each remaining Minor as deferred
   - write the completion line to the ledger
4. Run the final whole-branch review on Opus, with the invariants, the deferred
   Minors and the parked findings. A single fix wave fixes everything it
   returns, plus the deferred Minors and parked findings. Then one scoped
   re-review. Anything left unfixed needs a ruling.
5. List "Rulings I made", then run finishing.

Native's list follows its own flow:

1. Set up the workspace and ledger, and record the step list.
2. Read the plan and spec, and check the invariants.
3. Do each task in-session with TDD.
4. Run the Opus final review with the invariants.
5. Run the fix pass, which includes every Minor.
6. List the Rulings, then run finishing.

### 2. Invariants

An invariant is a rule that must hold in code no task was asked to touch. It is
not a task requirement. Examples from the prentora run:

- **Withheld is invisible.** While a restriction's statement is withheld,
  nothing the author can see reveals it: views, error codes, notices, emails,
  fields.
- **Not visible = missing.** A report on something the caller can't see gets
  exactly the same 404 as a report on something that doesn't exist.
- **Intake parity.** Every path that stops intake or hides a suspended
  instructor does the same for a restricted class, including candidate queries
  and sweepers. Anchor: callers of `InstructorSuspensionConditions` and
  `InstructorSuspensionGuard`.
- **Links only via FrontendUrls.** This is a codebase convention, not a spec
  rule. Anchor: string-built URLs outside `FrontendUrls`.

**writing-plans** adds an `## Invariants` section to the plan header, after
Global Constraints. Each line gives:

- the rule;
- the kinds of code path it governs;
- at least one search anchor: an existing symbol, pattern or file that a grep
  finds, or the name of the thing the plan creates.

The planner writes the section with the spec open. It includes the codebase
conventions it found while exploring, and the ones the project's CLAUDE.md
states. A plan with no cross-cutting rules says `None` and does not omit the
section.

**Ross sees the list.** Ross wants to know the invariants once the spec is
agreed. writing-plans' closing message lists the plan's invariants, one line
each, next to its executor recommendation, so he can correct them before
execution starts. When SDD or Native writes `invariants.md` itself, it prints
the list in its next message and carries on; it doesn't wait for a reply.

**SDD and Native setup:**

- If the plan has no Invariants section (an older plan), the controller writes
  one from the spec into the workspace as `invariants.md` and ledgers that it
  did.
- When the plan has no reachable spec, invariants come from the plan alone.
- The pre-flight scan checks every invariant line has an anchor and adds one
  where it is missing.
- If the section says `None`, there is nothing to search.

### 3. Two reviewers per task, in parallel

The combined reviewer `task-reviewer-prompt.md` is replaced by two templates,
`spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md`. They are
dispatched in one message, both read-only, and both read the same review
package. Both keep the current read-through contract ("read through line L")
and the no-subagents rule. A task needs both reports before its findings are
sorted.

**Model:** both reviewers run on the orchestrator's own model: `opus` if the
session is Opus, `sonnet` if it is Sonnet. The controller still passes `model`
explicitly. This replaces the current "same tier rule as the implementer" rule
and the >3,000-line floor for task reviewers. The final review stays on `opus`.

**Spec reviewer** owns the ✅/❌/⚠️ Spec Compliance verdict. Its inputs are:

- the brief;
- the spec path;
- the global constraints;
- the invariants, with the controller naming the ones whose paths this task's
  outcome touches;
- the report;
- the package.

Its rules:

- The spec is the authority over the brief. A breach of a spec rule is ❌, never
  Minor, whatever its size.
- For each named invariant, and any other invariant the diff touches, it
  searches the codebase (grep and read, not only the diff) for every path the
  rule governs. It reports any path that breaks the rule, or that the diff should
  have changed and didn't, with file:line.
- That includes breaches in code that existed before this branch: they are ❌
  in this task.
- For each invariant it reports the search terms, the hit count and the files it
  read. An invariant it judges untouched needs a one-line reason.
- The search is scoped to the invariants. It is not a general crawl.
- ⚠️ "Cannot verify from diff" remains for cross-task requirements that no
  invariant covers.

**Quality reviewer** owns the Task quality verdict. It uses the current task
reviewer's quality rubric (Part 2), calibration and Issues format, without the
Spec Compliance section, and keeps the named-risk rule for looking outside the
diff.

### 4. Fix loop

**Sorting.** Once both reports are in, the controller sorts findings into one
open list:

- every Critical, Important and ❌ from either reviewer;
- any finding of any grade that breaches a spec rule or invariant. This
  re-grading only ever moves a finding up, and the controller ledgers it as
  `Task <N>: Ruling: regraded — <finding> — breaches <rule>`.

The one exception is a breach in a path the plan gives to a later task. The
controller sends it to that task, with the ruling `Task <N>: Ruling: deferred to
Task <M> — <finding> — <why that task owns it>`, and carries it in Task M's
dispatch.

The remaining Minors are deferred. Plan-mandated and plan-conflict rulings work
as they do today.

**Rounds.** Each round is one fix dispatch carrying the whole open list, then
one scoped re-review using `re-review-prompt.md`. The 5-round cap, the
resume/fresh-implementer rule and the ledger line format are unchanged.

**Re-review model.** When the round carried a spec or invariant finding, the
re-review re-runs that invariant's search over the codebase, not only the fix
diff, and runs on the orchestrator's model. Otherwise it keeps the current
`haiku`/`sonnet` rule.

**Change from the playback.** This replaces "re-review with only the reviewer
whose findings were addressed". The re-review is a fresh scoped dispatch, not
either reviewer, so one list with one fix per round keeps the full cap, and the
ledger line needs no reviewer field.

### 5. Minors and the final fix wave

**During the task loop**, the remaining Minors are ledgered as
`Task <N>: minor (deferred): <one-liner>`, as today. Out-of-scope observations
from re-reviews are ledgered the same way.

**SDD final review.** The final reviewer gets three things to work on:

- the deferred Minors;
- the parked findings;
- the invariants.

It treats these as work to be fixed, not triaged: "these get fixed; flag any you
believe are wrong". The single fix dispatch carries all of its findings at every
grade, plus every deferred Minor and parked finding. After the one re-review, a
finding still unfixed is ledgered as:

`Final: Ruling: not fixed — <finding> — <wrong | not a code change | fix failed: what was tried> — <cost if wrong>`

That line reaches Rulings I made. "Not worth it" is not a reason. The current
"triage which must be fixed" wording goes.

**Native final review.** The same rule applies: Minors enter the fix pass
instead of going to "Deferred minors".

- **A Minor that changes behaviour** is verified by TDD, as now.
- **A Minor that doesn't** (naming, duplication, docs) is verified by the suite
  staying green, ledgered as
  `Final: fixed <finding> — no behaviour change, suite <N>/<N>`.
- An unfixed Minor gets the same `not fixed` ruling.

The sentence "Minors never enter the fix pass, and never become rulings" goes,
and so does the rationalization row "I'll fix the minors too while I'm in
there". Its replacement says the opposite.

### 6. Final review inputs

The final reviewer (`requesting-code-review/code-reviewer.md`), in both SDD and
Native, also gets the invariants. For each one it checks the whole branch
against the rule across the codebase, and reports the same search evidence as
the spec reviewer.

### 7. Upstream merge policy

`task-reviewer-prompt.md` exists on obra's `upstream/main`. It stays deleted in
this fork, like worktrees. When upstream edits it, port the change by hand into
`spec-reviewer-prompt.md` or `code-quality-reviewer-prompt.md`, whichever owns
that part. The README's "Divergence from upstream" section records this.

### 8. Tests

`tests/claude-code/test-fork-validation.sh` pins the new behaviour, so an
upstream merge that reverts it fails:

- SDD has `spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md`, and no
  `task-reviewer-prompt.md`.
- SDD and Native both contain a `## Steps (` block instruction.
- writing-plans' header has an `## Invariants` section, and its Ending lists the
  invariants.
- The spec reviewer prompt names invariants, searching unchanged code, and
  reporting search terms.
- SDD's Final Review no longer says "triage". Native no longer says Minors
  "never enter the fix pass".
- SDD says the reviewers use the orchestrator's model.

## What's left to the builder

- Exact wording of the step lists and reviewer prompts, within the rules above.
  writing-skills applies: Red Flags and rationalization tables are tuned
  content. Add rows (for example "this Minor can wait"). Change existing rows
  only where this design reverses them, such as Native's "fix the minors" row.
- How to rework the dot graphs and the Example Workflow sections to show two
  reviewers.
- README and CLAUDE.md updates describing the change.
- The version bump (`-ross.2`).
