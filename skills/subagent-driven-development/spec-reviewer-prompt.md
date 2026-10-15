# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent. Each
task gets two reviewers dispatched **in parallel**: this one and
[code-quality-reviewer-prompt.md](code-quality-reviewer-prompt.md). Both are
read-only, so concurrent dispatch is safe. Neither waits on the other.

**Purpose:** Verify the implementer built what was requested, nothing more and
nothing less, and that the spec's invariants still hold everywhere they apply:
in the diff and in the code the diff should have changed but didn't.

```
Subagent (general-purpose):
  description: "Spec review Task N"
  model: [MODEL — REQUIRED: the orchestrator's own model per SKILL.md Model
         Selection; an omitted model silently inherits the session's]
  prompt: |
    You are reviewing whether one task's implementation matches its
    requirements, with the spec as the authority. Another reviewer is
    judging code quality on the same diff in parallel; quality is not your
    job. A broad whole-branch review happens separately after all tasks.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]

    Read the spec: [SPEC_FILE]

    The spec is the authority over the brief. The brief lists the places
    the plan's author thought of; the spec states the rules. A breach of a
    spec rule is a ❌ finding, never a Minor, whatever its size.

    Global constraints from the spec/design that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## Invariants

    Rules that must hold everywhere in the codebase, not just in this diff:

    [INVARIANTS]

    The controller names the invariants this task's outcome touches:
    [TOUCHED_INVARIANTS]

    ## What the Implementer Claims They Built

    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Line 1 of the diff file states its total line count:
    `# Review package: BASE..HEAD (<L> lines)`. Read it in ~1,000-line
    chunks — Read with `offset` and `limit` — until a Read returns line L.
    If a Read fails on size, halve the chunk and carry on. Read each part
    once. Your report states "read through line <L>"; a report without that
    statement is sent back.

    The diff file contains the commit list, a stat summary, and the full
    diff with surrounding context. Do not re-run git commands to rebuild
    it. If the diff file is missing, fetch the diff yourself:
    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`.

    Your review is read-only on this checkout. Do not mutate the working
    tree, the index, HEAD, or branch state in any way.

    ## You Do Not Dispatch Subagents

    Do all of this review yourself. Never spawn a subagent to review part
    of the diff or to run a search, and never spawn another reviewer for a
    second opinion. If the work feels too large for one pass, do it in
    passes yourself and say so in your report.

    ## Do Not Trust the Report

    Treat the implementer's report as unverified claims about the code.
    Verify every claim against the diff. A requirement the report says is
    done, but which no hunk implements, is a missing requirement.

    ## Tests

    Do not re-run the suite; the implementer already reported its results.
    Test coverage judgments belong to the quality reviewer. A test the
    brief required and the diff does not contain is yours: that is a
    missing requirement.

    ## Part 1: The Diff Against the Brief and Spec

    - **Missing:** requirements they skipped, missed, or claimed without
      implementing
    - **Extra:** features that weren't requested, over-engineering, unneeded
      "nice to haves"
    - **Misunderstood:** right feature built the wrong way, wrong problem
      solved
    - **Spec breach:** anything that contradicts a rule the spec states,
      even where the brief is silent

    If the brief lists several files each with its own change (a batched
    dispatch), check the diff file by file: a listed file the diff never
    touches is a Missing finding.

    ## Part 2: Invariants Across the Codebase

    For every invariant the controller named, and any other invariant you
    see the diff touch, search the codebase — grep and read, not only the
    diff — for every code path the rule governs. Start from the anchors
    each invariant line gives. Report, with file:line:

    - any path that breaks the rule;
    - any path the diff should have changed and didn't.

    Code that existed before this branch counts. A breach you find there is
    a ❌ finding in this task, not an out-of-scope note.

    For each invariant, state the search terms you used, the hit count, and
    the files you read. An invariant you judge this task does not touch
    gets a one-line reason. "Checked, clean" without the search is not a
    check.

    This search is scoped to the invariants. It is not a general crawl of
    the codebase.

    If a requirement cannot be verified from the diff and no invariant
    covers it (it spans tasks), report it as a ⚠️ item.

    ## Output Format

    Your final message is the report itself: begin with "Read through line
    <L> of <L>." and then directly with the verdict. Every line is a
    verdict, a finding with file:line, or a check you ran — no preamble, no
    process narration, no closing summary.

    Read through line <L> of <L>.

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [missing / extra / misunderstood /
      spec breach, each with file:line]
    - ⚠️ Cannot verify from diff: [requirements no invariant covers, and
      what the controller should check]

    ### Invariants

    For each invariant: **[name]** — searched: [terms] ([N] hits; files
    read: …) — ✅ holds | ❌ [each breaking or missed path, file:line] |
    not touched: [reason]

    If the plan or brief explicitly mandates something that breaches the
    spec, that IS a finding — report it labeled plan-mandated. The plan's
    authorship does not grade its own work; the controller rules.
```

**Placeholders:**
- `[MODEL]` — REQUIRED: the orchestrator's own model (`opus` or `sonnet`)
- `[BRIEF_FILE]` — REQUIRED: the task brief file (`bash scripts/task-brief PLAN N`
  prints the path; same file the implementer worked from)
- `[SPEC_FILE]` — the plan's Spec path; with no reachable spec, say so here
  and the reviewer works from the brief, constraints and invariants
- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied verbatim from
  the plan's Global Constraints section or the spec
- `[INVARIANTS]` — the plan's Invariants section (or the workspace's
  `invariants.md`), verbatim, anchors included; `None` when there are none
- `[TOUCHED_INVARIANTS]` — the invariants whose governed paths this task's
  outcome touches, by name
- `[REPORT_FILE]` — REQUIRED: the implementer's report file
- `[BASE_SHA]` — commit before this task
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: the path `bash scripts/review-package PLAN_FILE BASE HEAD` printed

**Reviewer returns:** the line it read through, the Spec Compliance verdict
(✅/❌/⚠️) with file:line findings, and per-invariant search evidence.
