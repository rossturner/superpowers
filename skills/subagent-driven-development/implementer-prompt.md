# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    **Goal:** [from task description or metadata]

    **Files:**
    [from task metadata.files or description Files section]

    **Acceptance Criteria:**
    [from task metadata.acceptanceCriteria or description]

    **Verify:** [from task metadata.verifyCommand or description]

    **Steps:**
    [from task description Steps section]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    Make the calls the task leaves open yourself — approach, naming, where
    something lives, which of several valid designs to use — from the brief,
    the plan context above and the codebase. Record each one under
    **Decisions** in your report. Ask the controller only when the brief
    contradicts the codebase, or leaves out something you cannot find in
    the repo.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** When something is unexpected or unclear, look in the
    repo first, then make the call a senior engineer on this project would make
    and record it under **Decisions**. Do not invent external facts — a
    credential, an account, a third-party service the brief does not name.

    ## Code Organization

    You reason best about code you can hold in context at once, and your edits are more
    reliable when files are focused. Keep this in mind:
    - Follow the file structure defined in the plan
    - Each file should have one clear responsibility with a well-defined interface
    - If a file you're creating is growing beyond the plan's intent, stop and report
      it as DONE_WITH_CONCERNS — don't split files on your own without plan guidance
    - If an existing file you're modifying is already large or tangled, work carefully
      and note it as a concern in your report
    - In existing codebases, follow established patterns. Improve code you're touching
      the way a good developer would, but don't restructure things outside your task.

    ## When You're in Over Your Head

    Uncertainty and several valid approaches are not reasons to stop: pick one,
    record it under **Decisions**, and keep going. Bad work is still worse than
    no work, so escalate when you genuinely cannot proceed:
    - Information the task needs is missing from the brief and the repo
    - The brief contradicts the codebase and you cannot tell which is right
    - You've tried repeatedly and the work still fails
    - You've been reading file after file trying to understand the system without progress

    **How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT. Describe
    specifically what you're stuck on, what you've tried, and what kind of help you need.
    The controller can provide more context, re-dispatch with a more capable model,
    or amend the task.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## After Review Findings

    If the task review finds issues, you will be resumed with the findings.
    Fix them, re-run the tests that cover the amended code, and append a fix
    report to your report file: what you changed, the covering tests you
    ran, the command, and the output. Reviewers will not re-run tests for
    you — your report is the test evidence. Then reply with the same short
    status contract as your first report.

    Each fix report is a DELTA, not a cumulative account. Paste output only
    for the tests covering this round's changes; never re-paste a full
    suite run whose earlier lines already appear in the report, and never
    re-verify a result that did not change — one line ("ranking unchanged
    since round 2") covers it. What you tried and reverted IS worth
    recording — that history is what a future implementer needs. Proposals
    for work you did not do this round are not: if something seems worth
    doing later, one line under concerns is the ceiling. Every reviewer
    after you must read everything you append.

    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - **Files changed:** [list actual files]
    - **Acceptance criteria status:**
      - [criterion 1]: PASS/FAIL
      - [criterion 2]: PASS/FAIL
    - **Verify command output:** [paste actual output of verify command]
    - What you tested and test results
    - Self-review findings (if any)
    - **Decisions:** each call you made that the brief left open, with a one-line reason
    - Any issues or concerns

    Routine decisions belong under Decisions and do not make a report DONE_WITH_CONCERNS.
    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. Never silently produce work you're unsure about.
```
