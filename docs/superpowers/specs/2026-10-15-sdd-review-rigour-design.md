# SDD review rigour — design

## Why

Ross ran the fork's subagent-driven-development (SDD) on a 10-task build in
prentora/api (online-safety moderation, 15 Oct 2026). Every step ran, but the
reviews changed almost nothing: about 25 findings across five tasks were graded
Minor and parked, and only one was fixed before the next task. Some of the
parked "Minors" broke rules in the spec, such as error codes that revealed a
restriction the spec says must stay invisible to its author. Ross had to ask
why nothing was being fixed. The controller then improvised three things:

- a list of invariants, rules that must hold everywhere in the codebase;
- reviews that treat the spec as the authority and search unchanged code for
  every path an invariant governs;
- a retroactive audit of Tasks 1–5.

The audit found about 4 Important and 15 Minor gaps that the per-task reviews
had missed.

Two failures, one root:

1. **Steps get dropped.** Before the rebase onto obra v7.0.0, Ross often had to
   tell SDD to list its steps first, or it would skip the review step. The
   archived fork (`archive/pcvelz-7.2.0`) made "print a numbered summary of the
   loop" the controller's first action. The rebase lost it.
2. **Review output isn't acted on.** obra's skill caps reviewer scope ("do not
   crawl the broader codebase") and parks Minor findings for the final review,
   which only triages them. Ross: anything left "as a minor for later" will
   never be actioned, and that is the agent being lazy, not effective.

The goal is not more process. It is that every step happens and the review
output changes what ships.

## Goals

- SDD writes its step list into the ledger before any other work, and re-reads
  it on resume. executing-plans (Native) does the same with its own list.
- Each SDD task gets two focused reviewers in parallel, spec and quality, both
  on the orchestrator's model.
- The spec reviewer treats the spec as the authority. It checks the plan's
  invariants against the whole codebase, including unchanged code, for every
  invariant the task touches.
- Critical, Important and spec ❌ findings are fixed before the next task.
- Minor findings are deferred to the final whole-branch review, and the final
  fix wave fixes all of them. The only exception is a Minor the controller rules
  wrong, with its reason ledgered.
- writing-plans writes an Invariants section into every plan.

## Non-goals

- No task size cap. Ross decided this: writing-plans keeps one task per outcome
  with no size limit. Large diffs are handled by the two focused reviewers and
  the invariant search, not by splitting tasks.
- No change to implementer model selection. The judgment-based tier rule stays
  for implementers.
- No general codebase crawl by task reviewers. The search outside the diff is
  scoped to the invariants the task touches, plus the existing "check call sites
  when a shared contract changes" rule.
- No change to brainstorming, finishing, the ledger's commit-range contract, or
  the 5-round fix-loop cap.

## Anti-goals

- A Minor that is "deferred" and then never fixed. If the final wave doesn't fix
  it, a ledgered ruling must say why it is wrong.
- A spec-rule breach graded Minor because it looks small.
- A step list the controller improvises fresh each run. The list is fixed text
  in the skill.

## The design

### 1. Step list (SDD and Native)

The controller's first action, before reading the plan, is to write the run's
numbered steps into the ledger. They go directly under the `Base:` line, so
they survive compaction and are re-read on every resume. The skill holds the
list as fixed text; the controller copies it and does not paraphrase it. On
resume, the controller re-reads the step list along with the task lines.

The ledger's first two lines stay `# SDD ledger — plan: …` and `Base: <sha>`.
finishing and the resume rules read these by position, so the step list goes
after them.

SDD's list:

1. Resolve the workspace and check the ledger. Record `Base:` and this step list.
2. Read the plan and its spec. Run the pre-flight conflict scan. Make sure an
   invariants list exists: the plan's, or one written from the spec.
3. For each task:
   - record BASE
   - dispatch the implementer
   - build the review package
   - run the spec and quality reviewers in parallel, both on the orchestrator's
     model
   - fix every Critical, Important and ❌ finding, then re-review with only the
     reviewer whose findings were addressed (5 rounds at most)
   - log each Minor as deferred
   - write the completion line to the ledger
4. Run the final whole-branch review on Opus, with the invariants and every
   deferred Minor. A single fix wave fixes all of them, apart from any Minor
   ruled wrong. Then one scoped re-review.
5. List "Rulings I made", then run finishing.

Native gets its own shorter list in the same position, matching its existing
flow: tasks done in-session with TDD, then the Opus final review with the
invariants, a fix pass that includes every Minor, then Rulings and finishing.

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
  and sweepers.
- **Links only via FrontendUrls.** This is a codebase convention, not a spec rule.

**writing-plans** adds an `## Invariants` section to the plan header, after
Global Constraints. Each line names the rule and the kinds of code path it
governs, so a reviewer knows where to search. The planner writes it with the
spec open. It includes the codebase conventions it found while exploring, and
the ones the project's CLAUDE.md states. A plan with no cross-cutting rules
says `None`. It does not omit the section.

**SDD and Native**, during setup: if the plan has no Invariants section (an
older plan), the controller writes one from the spec into the workspace as
`invariants.md`, and ledgers that it did. If the section says `None`, there is
nothing to search.

### 3. Two reviewers per task, in parallel

The combined reviewer `task-reviewer-prompt.md` is replaced by two templates,
`spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md`. They are
dispatched in one message, both read-only, and both read the same review
package. Both keep the current read-through contract ("read through line L") and
the no-subagents rule.

**Model:** both reviewers run on the orchestrator's own model: `opus` if the
session is Opus, `sonnet` if it is Sonnet. The controller still passes `model`
explicitly. This replaces the current "same tier rule as the implementer" rule
and the >3,000-line floor for task reviewers. Scoped re-reviews keep their
current rule (`haiku` or `sonnet`, scaled to the fix diff). The final review
stays on `opus`.

**Spec reviewer** gets:

- the brief
- the spec path
- the global constraints
- the invariants
- the report
- the package

Its rules:

- The spec is the authority over the brief. A breach of a spec rule is ❌, never
  Minor, whatever its size.
- For each invariant the task touches, it searches the codebase (grep and read,
  not only the diff) for every path the invariant governs. It reports any path
  that breaks the rule, or that the diff should have changed and didn't, with
  file:line. For each invariant it touched, it states what it searched and what
  it found.
- The search is scoped to the invariants. It is not a general crawl.
- ⚠️ "Cannot verify from diff" remains for requirements that span tasks and
  that no invariant covers.

**Quality reviewer:** the current task reviewer's quality rubric (Part 2),
calibration, and output format, unchanged. It keeps the named-risk rule for
looking outside the diff.

### 4. Fix loop

- Critical, Important and ❌ findings from both reviewers form one open list,
  and enter the existing loop with its 5-round cap per task.
- After a fix round, only the reviewer whose findings were addressed gets a
  scoped re-review. When both reviewers had findings, the archive's rule
  applies: each gets its own fix round and re-review, all counted against the
  same cap.
- The plan-mandated and plan-conflict rulings work as they do today.

### 5. Minors

- During the task loop, Minors from either reviewer are ledgered as
  `Task <N>: minor (deferred): <one-liner>`, as today.
- Out-of-scope observations from re-reviews are ledgered the same way.
- **SDD final review:** the final reviewer gets the deferred-Minor list as work
  to fix, not to triage: "these get fixed; flag any you believe are wrong". The
  single fix dispatch carries the final reviewer's findings and every deferred
  Minor. The controller may exclude a Minor only with
  `Final: Ruling: minor not fixed — <finding> — <why it is wrong> — <cost if wrong>`,
  which reaches Rulings I made.
- The final reviewer's own Minors join the same fix wave.
- **Native final review:** the same rule. Minors enter the fix pass instead of
  going to "Deferred minors". A Minor not fixed is a ruling with its reason. The
  "never become rulings" sentence goes.

### 6. Final review inputs

The final reviewer (`requesting-code-review/code-reviewer.md`), in both SDD and
Native, also gets the invariants. For each invariant, it checks the whole branch
against the rule across the codebase, as the spec reviewer does per task.

### 7. Tests

`tests/claude-code/test-fork-validation.sh` pins the new behaviour, so an
upstream merge that reverts it fails:

- SDD has `spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md`, and no
  `task-reviewer-prompt.md`.
- SDD and Native carry the step list and say to write it to the ledger.
- writing-plans' header has an `## Invariants` section.
- The spec reviewer prompt names invariants and searching unchanged code.
- Neither SDD nor Native says Minors "never enter" the final fix pass.
- The reviewers' model is the orchestrator's model.

## What's left to the builder

- Exact wording of the step lists and reviewer prompts, within the rules above.
  writing-skills applies: Red Flags and rationalization tables are tuned
  content. Add rows (for example "this Minor can wait"); don't rewrite existing
  ones.
- How to rework the dot graphs and the Example Workflow sections to show two
  reviewers.
- README "Divergence from upstream" and CLAUDE.md updates describing the change.
- The version bump (`-ross.2`).
