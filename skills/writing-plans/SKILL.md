---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. Give them the whole plan as one task per outcome. DRY. YAGNI. TDD.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task delivers one outcome that can be verified on its own.

## Task Granularity

**One task per outcome.** The plan's Architecture paragraph names the
outcomes, and it is the authority on what one outcome is. Draw task
boundaries from it, then apply two tests:

- **Merge test:** a task that cannot be verified on its own serves another
  task's outcome and merges into it. Setup, configuration, scaffolding and
  documentation steps fold into the task whose outcome needs them.
- **Split test:** a task whose Goal needs more than one sentence holds two
  outcomes and splits.

**No size cap.** A task spans as many files and commits as its outcome
takes. Neither size, file count nor commit count bounds it. TDD cycles
(failing test, implementation, passing test, commit) repeat within a task;
they are steps, not tasks.

**What a task costs.** Every task costs a brief, an implementer dispatch, a
review package and a reviewer dispatch, in series, plus a fix dispatch and
a scoped re-review for each round of findings. A decomposition finer than
the outcomes buys only wall-clock time and repeated context.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

A task repeats this cycle as many times as its outcome needs.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-ross:subagent-driven-development or superpowers-ross:executing-plans, whichever the plan's author recommended, to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach, naming the outcomes the
work delivers. This paragraph is the authority on what one task is: one
task per outcome named here.]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Invariants

[Rules that must hold in code no task was asked to touch, one per line:
the rule, the kinds of code path it governs, and at least one search
anchor — an existing symbol, pattern or file a grep finds, or the name of
the thing this plan creates. Take them from the spec's cross-cutting rules
("a withheld restriction is invisible to its author", "a hidden item
answers exactly like a missing one") and from the codebase's conventions
you found exploring or the project's CLAUDE.md states ("links are built
only through FrontendUrls"). Reviewers search the whole codebase for every
path each line governs; an unanchored line is one they cannot search.
Write `None` when the work has no cross-cutting rule; never omit the
section.]

## Review Focus

[The five input classes or failure modes the spec implies but no task's
tests exercise that are most likely to bite a person using this software
— one line each, naming the input or condition and the behavior a
reasonable person would expect, most likely first. The spec is a vision
document: it says what the software must do, not everything it will
meet, and its silence on an input is not permission for that input to
break the program. Write the list here, once, with the spec in front of
you. Then, for each line, add the test that pins it to the task that
owns the code, in that task's own step style.]

## Left to the Builder

[Every decision the plan leaves open, one line each, with the options and
what should decide between them. The executor rules on each and logs the
ruling; nothing here is a question for the user.]

---
```

## Task Structure

````markdown
### Task N: [Outcome]

**Goal:** [One sentence: the outcome this task delivers]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command to run and the output that means it
  passed.
- **A reference to another task:** that task's Interfaces block says what
  to use; the plan does not repeat that task's code.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing ("TBD", "handle edge cases", "add appropriate validation",
"write tests for the above", a type or function no task defines) are the
opposite failure, and the self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.

**5. Invariants:** For each rule the spec states as holding everywhere — and each codebase convention the tasks' code must follow — is there an Invariants line with an anchor a grep would find? A rule only some tasks' briefs mention is the one a reviewer misses in the code no task touches.

**6. Proportion:** Compare the plan's length to the spec's. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of the document, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Open Decisions

A plan never schedules a question for the user at execution time. No step
says "ask the user", "confirm with your human partner" or "check before
proceeding". Anything still open goes under Left to the Builder, and the
executor rules on it.

## Transient Artifacts

The spec and the plan are working documents, never the feature's
documentation.

- Nothing outside `docs/superpowers/` references the spec or the plan: no
  code comment, README line, docstring or commit message points at them.
  The plan's own `Spec:` line is inside `docs/superpowers/` and is fine.
- The final task updates durable documentation (README, `docs/` outside
  `docs/superpowers/`, docstrings) when the feature needs it. When it does
  not, the plan says so: "No durable docs change."

## Ending

After saving and self-reviewing the plan:

1. Commit the plan.
2. Stop with exactly one message:

**"Plan committed to `docs/superpowers/plans/<filename>.md`. Recommend `/compact`, then invoke `superpowers-ross:subagent-driven-development` — <one sentence why>."**

or

**"Plan committed to `docs/superpowers/plans/<filename>.md`. Recommend `/compact`, then invoke `superpowers-ross:executing-plans` — <one sentence why>."**

followed by the plan's invariants, one line each under "Invariants
reviewers will check across the codebase:" (or "Invariants: none"), so
your human partner can correct the list before execution starts.

Recommend exactly one. Native (`superpowers-ross:executing-plans`) fits a
few tightly coupled tasks where a shipped mistake is cheap and per-task
review adds little. Otherwise recommend subagent-driven development. The
sentence why comes from the plan: how many tasks there are, how much they
depend on each other's interfaces, what a shipped mistake would cost.

No "please review the plan", no menu of options, no question. The message
is the end of this skill.
