---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## CRITICAL CONSTRAINTS — Read Before Anything Else

**You MUST NOT call `EnterPlanMode` or `ExitPlanMode` at any point during this skill.** This skill operates in normal mode. Calling `EnterPlanMode` traps the session in plan mode where Write/Edit are restricted. Calling `ExitPlanMode` breaks the workflow. If you feel the urge to call either, STOP — follow this skill's instructions instead.

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as the largest coherent units of work. DRY. YAGNI. TDD.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Transient Artifacts

The spec and the plan are transient working documents — typically deleted shortly after the feature ships. Two rules follow:

- Nothing outside `docs/superpowers/` may reference the spec or plan. Do not point shipped code, comments, docstrings, README, or durable docs at these files. References *within* `docs/superpowers/` (e.g. the plan header pointing at its own execution skill) are fine.
- The spec and plan are never the feature's documentation. When a feature needs durable documentation, it lives in the README, in `docs/` outside `docs/superpowers/`, or in the code itself.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Granularity

**Each task is one outcome.** The Architecture paragraph of your plan header names the plan's outcomes, and it is the authority on what counts as one. The File Structure section above lists the files each outcome touches.

See `skills/shared/task-format-reference.md` for the full granularity guide.

Key principle: TDD cycles happen WITHIN tasks, not as separate tasks. A task is "Implement X with tests" — the red-green-refactor steps are execution detail inside the task, not task boundaries.

**Two tests:**

1. **Merge.** Adjacent tasks serving one outcome are one task. A task that cannot be verified on its own serves another task's outcome, and it merges into that task.
2. **Split.** A task holding two outcomes is two tasks, where each outcome stands on its own and the plan makes sense with either one built alone. A Goal that needs more than one sentence to state the outcome is holding two outcomes.

A task spans as many files and as many commits as its outcome takes. Neither size, file count nor commit count bounds a task.

**What a task costs to run.** `subagent-driven-development` executes every task as a brief file, an implementer dispatch, a review package and two reviewer dispatches, and those dispatches run in series because a reviewer reads a diff that exists only once the implementer has committed. Each round of review findings adds a fix dispatch and a scoped re-review. A plan of thirteen tasks costs at least thirty-nine dispatches before its final whole-branch review. Decompose to the plan's outcomes and stop there.

## Final Task: Documentation

The final task of a plan is generally to update any relevant durable documentation. Most features need none — when that is the case, say so explicitly rather than inventing a documentation task. When documentation is warranted, the final task names exactly which durable location to update (README, `docs/` outside `docs/superpowers/`, code docstrings) and never points at the spec or plan.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-ross:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach, naming the outcomes this plan produces. Task Granularity treats this paragraph as the authority on what one outcome is, so name each one here and nowhere else.]

**Tech Stack:** [Key technologies/libraries]

**Global Constraints:** [Binding requirements every task must respect — exact values, formats, cross-component relationships ("same layout as X", "matches Y"). Execution controllers hand these to every reviewer. "none" if none.]

**User decisions (already made):** [One line per decision the user made during brainstorming/planning, quotable. "none" if none.]

---
```

### Deferred decisions

A plan does not schedule questions for the user at execution time: `subagent-driven-development` never stops mid-run to ask. A decision the plan leaves open states the default the controller applies, and the controller logs it. Each one MUST:
- Cite why it is still open despite the header decisions. If a recorded decision answers it, answer from the record — do not leave it open.
- Name the artifact AND its role/state (e.g. "stale GitHub mirror, last push 2026-03-25 — separate from your local-tools dev home"), and state what the default changes and what it leaves alone.
- Default to nothing that contradicts a recorded decision. That is a plan failure (same severity as No Placeholders).

## Task Structure

````markdown
### Task N: [Component Name]

**Goal:** [One sentence — what this task produces]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Acceptance Criteria:**
- [ ] [Concrete, testable criterion]
- [ ] [Another criterion]

**Verify:** `exact test command` → expected output

**Steps:**

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

The steps above are one TDD cycle. A task covering an outcome that takes several cycles holds all of them, each ending in its own commit. `subagent-driven-development` records the commit before dispatching an implementer and reviews the whole `BASE..HEAD` range, so a task that commits more than once is reviewed as one change.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## The Merge Pass

Run this pass once every task is written, before Self-Review. A planner deciding boundaries while it decomposes has no view of the decomposition as a whole, so the pass reads the finished list.

1. Read each task's **Goal** line in order and name the outcome that task serves. The pass compares adjacent pairs only, so when two tasks serving one outcome sit either side of an unrelated third, reorder them together now.
2. Merge an adjacent pair when both serve the same outcome. The merged task carries a Goal of one new sentence naming the shared outcome, the union of both **Acceptance Criteria** lists, the union of both **Files** lists, the steps of both in order, and a **Verify** command covering the whole outcome. All four section headers are required — `subagent-driven-development` copies them verbatim into the task description under a self-check that fails when one is missing.
3. Repeat from step 1 until no adjacent pair merges.
4. Renumber the surviving task headings contiguously from 1, and repair any plan text that refers to a task by number. `subagent-driven-development`'s `scripts/task-brief` resolves a task by matching the heading `Task N` and fails when the number is absent.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Finish: Commit and Halt

The plan is a document. Task creation belongs to `subagent-driven-development`, which builds the task list from the plan at execution time. The plan `.md` records any user-gate intent in prose so that skill can act on it.

When the plan and Self-Review are complete:

1. **Commit** the plan document.
2. **Stop**, with a short message:

> Plan written and committed to `docs/superpowers/plans/<filename>.md`. Recommend `/compact`, then invoke `subagent-driven-development` to execute it.

Stay stopped here — the next move is the user's.
