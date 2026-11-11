---
name: executing-plans
description: Use when executing an implementation plan in the current session as the implementer yourself — superpowers-ross:writing-plans recommended it (few, tightly coupled tasks where a shipped mistake is cheap and per-task review adds little), or no subagent tool is available
---

# Executing Plans

Execute the plan yourself, task by task, in this session: no implementer subagent per task, no reviewer per task. One fresh-context review of the whole branch at the end.

**Why inline:** Subagent-driven development pays for a fresh implementer and a fresh reviewer on every task, each re-reading the codebase from zero. Executing inline pays for one context (yours) plus one reviewer at the end. What it gives up is a fresh context per task and a second pair of eyes per task. This skill keeps what those two things bought, by other means: the brief is the spec, the ledger is your memory, TDD is the per-task gate, and the final reviewer is the second pair of eyes.

**Core principle:** The plan already did the thinking. Execute it exactly, prove each step with a test you watched fail and then pass, and leave a record that survives your own forgetting.

**Narration:** between tool calls, narrate at most one short line — the ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. This skill runs to spend less, not to have them answer "should I continue?" after every task. Execute all tasks from the plan to the end; nothing below waits on them.

**Rulings, not stalls.** Conflicts, ambiguities, plan defects — decide them. The spec is the binding authority, the plan is its argument, and your judgment settles what neither answers. Record every decision in the ledger as `Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep going. Deviating from the plan without a ledgered ruling is a decision made in secret.

Nothing pauses the run. Each case below is ruled and ledgered, and the run goes on:

- **Unrecoverable actions are not taken.** Anything not recoverable from git history (`git clean`, `reset --hard`, deleting untracked or ignored data, touching data outside the repo), anything security-sensitive, and anything outward-facing (push, merge, publish). Ledger `Ruling: left for you — <action> — <why>` and continue with the rest. Everything else proceeds.
- **A task whose verification needs such an action** is done as far as it can be, closed with `task-done` on the tests that can run, and marked unverified: `Task <N>: Ruling: unverified — <the verification not run> — dependents: <...>`. When no test can run, there is no `task-done` line, so the ruling ends with ` (commits <BASE7>..<HEAD7>)` to keep the ledger's ranges chained. Its dependents proceed, and each is flagged in "Rulings I made".
- **A plan broken past guessing** gets a ruling on its most defensible reading. If no reading gives a path that works, the task goes down the ladder: rule → amend once → abandon (see [references/ladder.md](references/ladder.md)).
- **Items the plan leaves to the builder** are ruled and ledgered the same way.

## The Steps

Your FIRST action on invoking this skill, before reading the plan: write this skill's step list into the ledger (see Setup for where). It keeps the final review and its fix pass from being skipped under load, and it survives compaction where your memory of this skill does not. Copy it exactly; do not paraphrase or shorten it.

```
## Steps (executing-plans)
Step 1. Resolve the workspace and check the ledger. Record Base and this step list.
Step 2. Read the plan and its spec. Run the pre-flight scan. Make sure an invariants list exists, with a search anchor on every line.
Step 3. For each task: task-start; read the brief; work the steps with TDD, comparing every Expected line; commit; task-done.
Step 4. Run the final whole-branch review on opus with the invariants.
Step 5. One fix pass fixes every finding at every grade, Minor included. Anything left unfixed needs a ruling.
Step 6. List the rulings I made, then run finishing-a-development-branch.
```

Before each task and after any compaction, re-read the most recent `## Steps` block in the ledger and check where you are against it.

## When to Use

- superpowers-ross:writing-plans recommended this skill: the plan has few tasks, they are tightly coupled (each consumes what the last produced, so a fresh implementer per task would re-learn the same context), and a mistake that ships is cheap to find and fix — per-task review would add little the final review does not.
- Your harness has no subagent tool (see `../using-superpowers/references/claude-code-tools.md`). Never fabricate a dispatch; run the plan here.

A fully specified plan makes executing it here transcription plus testing: it runs well on a mid-tier session model, and the one place the most capable model earns its cost is the final review, which this skill dispatches separately on `opus`.

Prefer superpowers-ross:subagent-driven-development when the plan has many or loosely coupled tasks, when a shipped mistake would be expensive enough to want a review gate on every task, or when the plan is long enough that its later tasks would run on a compacted context. Running a long plan here still works — the ledger is what makes it recoverable — but the last tasks get the least of you.

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "task-start: brief + BASE; read the brief" [shape=box];
        "Work the steps in order: TDD, run every verification, read every output" [shape=box];
        "Step output matches plan's Expected?" [shape=diamond];
        "Plan wrong? Rule → amend once → abandon, ledgered. Code wrong? systematic-debugging" [shape=box];
        "Commit as the plan's commit steps say" [shape=box];
        "Completion contract met?" [shape=diamond];
        "task-done: run tests, ledger the result; mark todo complete" [shape=box];
    }

    "Setup: current branch; workspace + ledger with Base: + Steps, read plan + spec, invariants, pre-flight scan" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Final whole-branch review of Base..HEAD (fresh opus reviewer if you have one)" [shape=box];
    "ONE fix pass over every finding, Minor included: behaviour fixes RED→GREEN, others suite green; unfixed → ruling" [shape=box];
    "Final message: Rulings I made, plan path (workspace kept)" [shape=box];
    "Use superpowers-ross:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Setup: current branch; workspace + ledger with Base: + Steps, read plan + spec, invariants, pre-flight scan" -> "task-start: brief + BASE; read the brief";
    "task-start: brief + BASE; read the brief" -> "Work the steps in order: TDD, run every verification, read every output";
    "Work the steps in order: TDD, run every verification, read every output" -> "Step output matches plan's Expected?";
    "Step output matches plan's Expected?" -> "Plan wrong? Rule → amend once → abandon, ledgered. Code wrong? systematic-debugging" [label="no"];
    "Plan wrong? Rule → amend once → abandon, ledgered. Code wrong? systematic-debugging" -> "Work the steps in order: TDD, run every verification, read every output";
    "Step output matches plan's Expected?" -> "Commit as the plan's commit steps say" [label="yes, last step"];
    "Commit as the plan's commit steps say" -> "Completion contract met?";
    "Completion contract met?" -> "Work the steps in order: TDD, run every verification, read every output" [label="no - finish the task"];
    "Completion contract met?" -> "task-done: run tests, ledger the result; mark todo complete" [label="yes"];
    "task-done: run tests, ledger the result; mark todo complete" -> "More tasks remain?";
    "More tasks remain?" -> "task-start: brief + BASE; read the brief" [label="yes"];
    "More tasks remain?" -> "Final whole-branch review of Base..HEAD (fresh opus reviewer if you have one)" [label="no"];
    "Final whole-branch review of Base..HEAD (fresh opus reviewer if you have one)" -> "ONE fix pass over every finding, Minor included: behaviour fixes RED→GREEN, others suite green; unfixed → ruling";
    "ONE fix pass over every finding, Minor included: behaviour fixes RED→GREEN, others suite green; unfixed → ruling" -> "Final message: Rulings I made, plan path (workspace kept)";
    "Final message: Rulings I made, plan path (workspace kept)" -> "Use superpowers-ross:finishing-a-development-branch";
}
```

## Setup

Work on the current branch, whatever it is. Do not switch branches or create one.

Conversation memory does not survive compaction. An inline executor that loses its place re-implements tasks whose commits already exist — the same failure as a controller re-dispatching them, paid for in your own context. Track progress in a ledger file, not only in todos. Harness todos are a live view; the ledger is the record.

The workspace and ledger are shared with superpowers-ross:subagent-driven-development — same directory, same format — so a plan can change executors mid-flight and the new one resumes from the same ledger.

- Each plan owns a workspace: at skill start, run `../subagent-driven-development/scripts/sdd-workspace PLAN_FILE` by its absolute path, from the working tree you're executing in — it prints the plan's git-ignored directory (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to every artifact for THIS plan: ledger, briefs, review packages. Another plan's directory is never yours to read or write.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first line names your plan file, a task is DONE when the ledger has a `Task <N>: complete` line, a `Task <N>: Ruling: abandoned` line, or a `Task <N>: Ruling: unverified` line that ends with `(commits …)` — do not redo it; resume at the first task with none of these. The ledger is shared with superpowers-ross:subagent-driven-development, so honour all three whichever executor wrote them. Their commits exist in git even when your context no longer remembers making them: after compaction, trust the ledger and `git log` over your own recollection. A ledger whose first line names a different plan file is another plan's progress: leave it and start your own, fresh.
- With no ledger of your own, create it now, before any `task-start` or `task-done`, with its identity as the first line and the commit the work starts from as the second:
  ```
  # SDD ledger — plan: <plan file path>
  Base: <git rev-parse HEAD, full sha>
  ```
  `Base:` is written once, here. On resume it is already there; never rewrite it. `task-done` refuses to run against a ledger without it, and the final review and superpowers-ross:finishing-a-development-branch both cut their range from it.
- Straight after `Base:`, append the `## Steps (executing-plans)` block from The Steps above. The first two lines stay the identity and `Base:`. On resume, find the most recent `## Steps` block: if it is another executor's (the plan changed executors) or there is none (a ledger from before step lists), append this skill's block before anything else. The ledger stays append-only.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if that happens, recover from `git log`.

Read the plan once, note its context and Global Constraints, and create a todo per task. If the plan names a Spec, read that too: the spec is the authority the plan argues from, and conflicts inside the plan resolve against it. A plan with no reachable spec gets a ledger note saying so — rulings made without one are provisional.

**REQUIRED SUB-SKILL:** load superpowers-ross:test-driven-development now, before Task 1. It governs every step of every task below; a plan whose steps already say "write the failing test first" does not exempt you from reading it.

Before Task 1, scan the plan for conflicts between tasks. The plan's Interfaces blocks tell you where to look: for every task that consumes what an earlier task produces, one ledger row — the two tasks, what one produces against what the other consumes, and what you found. Tasks that share nothing get no row; a plan whose tasks share nothing gets the single line `Pre-flight: no shared interfaces`. Rule on each conflict a row surfaces with the spec as the binding authority, record the ruling beside its row, and start Task 1. Each task's own text is checked when you read its brief, not here.

**Invariants.** During the pre-flight scan, read [references/plan-invariants.md](references/plan-invariants.md) and follow it: every invariant needs a search anchor, and a plan without an Invariants section gets a list written to `<workspace>/invariants.md`. The final reviewer checks each one across the whole codebase.

## The Task Loop

Everything you print, and every tool result, stays resident in your context for the rest of the session. Redirect long test output to a file in the workspace and read its tail; read a brief, not the whole plan.

### 1. Take the task

- Run this skill's `scripts/task-start PLAN_FILE N` by its absolute path, from the working tree you're executing in. It prints the brief path and BASE (the commit the task's range is cut from) in one call. Read the brief for every task, including ones you remember from setup: what you remember is a summary, the brief has the exact values, signatures, and test cases.
- Mark the task's todo in_progress.

Every tool call is a turn that re-reads your whole context. Bookkeeping rides along with work — a ledger append in the same call as the commit, never in a call of its own.

### 2. Work the steps

The plan's steps are already in RED-GREEN order; follow them in that order under superpowers-ross:test-driven-development, loaded at setup. A test step's code is written first and run first. Watching it fail is a step, not a formality — a test that passes before the implementation exists is a finding about the test.

Every step that runs a command has an `Expected:` line. Run the command, read its output, and compare. Three outcomes:

- **Matches.** Next step.
- **The code is wrong.** Use superpowers-ross:systematic-debugging. Find the cause; never patch the symptom to make the step's output match.
- **The plan is wrong** — a step contradicts the spec, an interface from an earlier task doesn't match what this task consumes, a command that cannot work. Rule on the smallest change that satisfies the spec, ledger it as `Task <N>: Ruling: <finding> — <what you decided and why>`, and continue. The ruling is carried, not remembered: later tasks that touch the same interface read it from the ledger.

When no ruling gives the task a path that works, read [references/ladder.md](references/ladder.md) and climb it: rule → amend once → abandon, each ledgered. The run goes on either way.

Commit as the plan's commit steps say. A task that spans several commits is fine; BASE is what the review range is cut from, never `HEAD~1`.

### 3. The completion contract

Before a task's ledger line, all of the following are true, with evidence in this session — not inferred from the diff looking right:

- Every test the brief names exists and ran in this task, and you read the output.
- The final test run for the task passed — `task-done` is that run, and it writes the command and result into the ledger line.
- Every `Expected:` line in the brief was compared against real output.
- Every deviation from the brief has a `Ruling:` line in the ledger.

**REQUIRED SUB-SKILL:** superpowers-ross:verification-before-completion governs the claim. If any item is missing, the task is not complete: finish it.

### 4. Complete the task

Run this skill's `scripts/task-done PLAN_FILE N BASE -- <test command>` by its absolute path, from the working tree you're executing in, with the test command the brief names for the whole task. It runs the tests, keeps the full output in the workspace, prints the tail, and — only if they pass — appends the completion line to the ledger:

`Task <N>: complete (commits <base7>..<head7>, tests: <command> → <result>)`

A failing run records nothing; the task is not complete. When it records, mark the todo complete and take the next task.

## Final Review and Finish

When every task has its ledger line, read [references/final-review.md](references/final-review.md) and follow it, even if you read it earlier in this session. It covers the whole-branch review on `opus` with the invariants, the ONE fix pass that fixes every finding at every grade, the `not fixed — ` ruling an unfixed finding needs (a fix with no behaviour change is verified by a green suite), and how you finish: the "Rulings I made" list, then superpowers-ross:finishing-a-development-branch. The run is not over until that file's last step is done.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I remember what Task N says" | You remember a summary. The brief has the exact values. Read it. |
| "The plan's code is right, skip watching the test fail" | A test you never saw fail proves nothing. It is one step. Run it. |
| "I'll run the full suite at the end instead of per step" | Per-step runs are how you learn which step broke it. The end-of-task run is the contract, not a substitute. |
| "The plan is wrong here, I'll just do the right thing" | Do the right thing and ledger the ruling. Unledgered deviation is a decision made in secret. |
| "I'll write the ledger lines after a few tasks" | Compaction does not wait for a convenient moment. One line per task, in the same message as the commit. |
| "Let me check in before the next task" | This skill runs to spend less. Progress prompts spend their time instead. Nothing pauses the run: rule, ledger, continue. |
| "This needs a push / a `reset --hard` / a deploy — I'll wait for them" | Don't take it and don't wait. Ledger `Ruling: left for you`, mark what it leaves unverified, and continue. |
| "The plan is too broken; better to hand it back" | Rule on the most defensible reading, amend once, or abandon the task. Each is ledgered; the run goes on. |
| "I read my own diff carefully; the final reviewer is redundant" | Same author, same blind spots. The reviewer is the only fresh context this run buys. |
| "Tests should pass, the change was trivial" | "Should" is not evidence. The contract requires the command and its output. |
| "Subagents are slow and expensive, I'll skip the final review too" | Inline already removed the per-task reviewers. One review of the whole branch is the floor, not the ceiling. |
| "The reviewer said Minor, so it's Minor" | The label graded the spec's silence. Grade what the person gets. Re-grade, then gate. |
| "The fix is obvious, no need for a failing test first" | The failing test is the only proof the finding was real and is now gone. Without it you have a diff and a hope. |
| "Minors can wait for another day" | No later pass exists. Fix them in this pass, or rule each one not fixed with a real reason. |
| "This Minor has no test, so I can't fix it properly" | A no-behaviour fix is verified by the suite staying green. Fix it and ledger that. |
| "I know the steps, no need to write them to the ledger" | The step list is for after compaction, when you don't. Write it first, re-read it before each task. |
