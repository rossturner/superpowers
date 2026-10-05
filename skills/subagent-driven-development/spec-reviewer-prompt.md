# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent. This
fork splits the task review into two reviewers dispatched **in parallel** —
this one and [code-quality-reviewer-prompt.md](code-quality-reviewer-prompt.md).
Both are read-only, so concurrent dispatch is safe. Neither waits on the other.

**Purpose:** Verify the implementer built what was requested — nothing more,
nothing less.

**Tier:** the cheap/mechanical tier. Spec compliance is comparison work, not
judgment work.

```
Subagent (general-purpose):
  description: "[sdd-review] Spec compliance for Task N"
  model: [MODEL — REQUIRED: the cheap/mechanical tier per SKILL.md Model
         Selection; an omitted model silently inherits the session's most
         expensive one]
  prompt: |
    You are reviewing whether one task's implementation matches its
    requirements. This is a task-scoped gate, not a merge review — a broad
    whole-branch review happens separately after all tasks are complete.
    Another reviewer is judging code quality on the same diff in parallel;
    quality is not your job. Judge only what was asked for against what was
    built.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]

    Global constraints from the spec/design that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## What the Implementer Claims They Built

    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    The diff file contains the commit list, a stat summary, and the full
    diff with surrounding context, and it is your view of the change.
    Read the whole diff file in chunks of about 1,000 lines using `offset`,
    until a Read returns the end of the file. If a Read fails on size, halve
    the chunk and continue. Read each part once. The first line gives the
    total as `(<L> lines)`; in your report, state that you read through line
    L (or through the last line, when no total is given). A verdict on part
    of the diff is not a review. The diff's context lines ARE the changed files: do not Read a
    changed file separately unless a hunk you must judge is cut off
    mid-function — and say so in your report. Do not re-run git commands.
    If the diff file is missing, write one yourself and read it by the same
    rule: `{ git log --oneline [BASE_SHA]..[HEAD_SHA]; git diff --stat [BASE_SHA]..[HEAD_SHA];
    git diff -U10 [BASE_SHA]..[HEAD_SHA]; } > <scratch file>`.
    Do not crawl the broader codebase.

    Your review is read-only on this checkout. Do not mutate the working
    tree, the index, HEAD, or branch state in any way.

    ## Do Not Trust the Report

    Treat the implementer's report as unverified claims about the code. It
    may be incomplete, inaccurate, or optimistic. Verify every claim against
    the diff. A requirement the report says is done, but which no hunk in the
    diff implements, is a missing requirement — not a verified one.

    ## Tests

    Do not re-run the suite; the implementer already reported its results.
    Test *coverage* judgments belong to the code-quality reviewer. A test the
    brief required and the diff does not contain is yours: that is a missing
    requirement.

    ## Your Job: Spec Compliance

    Compare the diff against What Was Requested:

    - **Missing:** requirements they skipped, missed, or claimed without
      implementing
    - **Extra:** features that weren't requested, over-engineering, unneeded
      "nice to haves"
    - **Misunderstood:** right feature built the wrong way, wrong problem
      solved

    If a requirement cannot be verified from this diff alone (it lives in
    unchanged code or spans tasks), report it as a ⚠️ item instead of
    broadening your search.

    Your final message is the report itself: begin directly with the verdict.
    Every line is a verdict, a finding with file:line, or a check you ran —
    no preamble, no process narration, no closing summary.

    ## Calibration

    A finding is a real deviation from the brief, cited to file:line. If the
    plan or brief explicitly mandates something you would otherwise call a
    defect, that IS a finding — report it labeled plan-mandated. The plan's
    authorship does not grade its own work; the human decides.

    ## Output Format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood,
      with file:line references]
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]
```

**Placeholders:**
- `[MODEL]` — REQUIRED: the cheap/mechanical tier per SKILL.md Model Selection
- `[BRIEF_FILE]` — REQUIRED: the task brief file (`scripts/task-brief PLAN N`
  prints the path; same file the implementer worked from)
- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied verbatim from
  the plan's Global Constraints section or the spec: exact values, formats,
  and stated relationships between components (not process rules — those
  are already in this template)
- `[REPORT_FILE]` — REQUIRED: the file the implementer wrote its detailed
  report to
- `[BASE_SHA]` — commit before this task
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: the path the controller wrote the review
  package to (`scripts/review-package PLAN_FILE BASE HEAD` prints the unique
  path it wrote; the package never enters the controller's context)

**Reviewer returns:** Spec Compliance verdict (✅/❌/⚠️) with file:line findings.

**Dispatch marker:** the Agent call's `description` must contain `[sdd-review]`
so the model-routing gate exempts this dispatch (see `hooks/pre-agent-model-routing`).
