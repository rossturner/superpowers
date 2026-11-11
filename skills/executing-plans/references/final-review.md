# Final Review and Finish

Read this when every task has its ledger line. It covers the whole-branch review, its one fix pass, and how you finish.

## Final Review

Run `../../subagent-driven-development/scripts/review-package PLAN_FILE <Base> HEAD` by its absolute path, from the working tree you're executing in (`<Base>` = the ledger's `Base:` line) and review from the file it prints. Its first line gives the package's total line count.

**With a subagent tool:** dispatch the reviewer with `model: "opus"` — the whole-branch review is a judgment task — using superpowers-ross:requesting-code-review's [code-reviewer.md](../../requesting-code-review/code-reviewer.md), with the package path, the plan and spec paths, the invariants list verbatim (it checks each across the whole codebase, not only the diff, and reports the search terms, hit count and files read), the plan's Review Focus section verbatim if it has one (the input classes and failure modes the plan's tests do not exercise — the reviewer checks each deliberately), and a pointer to the ledger's `Ruling:` lines so it can weigh the calls you made. Specify the model explicitly; an omitted model inherits the session's, which may not be the most capable. This is the one fresh context the whole run buys. Do not skip it, and do not replace it with your own read of the diff.

The reviewer reads the package in ~1,000-line chunks with Read's `offset` until a Read returns the end, halving the chunk if a Read fails on size, reading each part once, and states "read through line L". A report without that statement is re-dispatched once; if the second also lacks it, rule on what to do with it and ledger the ruling.

**Without a subagent tool:** read code-reviewer.md and perform that review yourself against the package in the same chunks, as a separate pass after the last task's ledger line. Ledger `Final: Ruling: self-review only — no subagent tool — the author's blind spots went unchecked` and list it first in "Rulings I made": a self-review by the author is weaker than a fresh reviewer, and your human partner should know which review the branch got.

Sort the findings before you act on any of them. The reviewer's severity labels are advice; the gate is yours. Its "Declined to judge" list is yours too: every line there is a ruling you make and ledger, exactly like a plan conflict — `Final: Ruling: <behavior the reviewer set aside> — <what a reasonable person using this software gets, and why that stands or why it is now a finding> — <cost if wrong>`. Re-grade first, by effect: the spec is a vision document, and a finding's grade is what a reasonable person using this software gets if it ships, not whether the spec names the input that triggers it — a reviewer who set a finding at Minor because the spec was silent has graded the spec, not the effect. Then:

- **Every finding enters the fix pass**, Critical through Minor. A Minor left for later is never picked up: this pass is the last one.

Fix them yourself — you are the implementer here — in ONE pass:

- **A fix that changes behaviour** is verified by TDD, not by a second reviewer: write the test that reproduces the finding, watch it fail, make it pass, then run the whole suite. Ledger `Final: fixed <finding> — <test name> RED→GREEN, suite <N>/<N>`.
- **A fix that changes no behaviour** (naming, duplication, structure, docs) has no failing test to write. It is verified by the whole suite staying green. Ledger `Final: fixed <finding> — no behaviour change, suite <N>/<N>`. When the pass is over, ledger the wave as `Final review: fixes (commits <a7>..<b7>)`, from the HEAD before the first fix to the HEAD after the last — or `Final review: clean` when there was nothing to fix. A fix without a test that failed first is not verified; a suite that is not green after the pass means the pass is not over. Do not dispatch a re-review: it would re-read a diff whose covering tests already answer "addressed" and whose suite run already answers "broke nothing".

A finding you do not fix is a ruling — `Final: Ruling: not fixed — <finding> — <wrong: why | not a code change | fix failed: what was tried> — <cost if wrong>` — and reaches your human partner in the rulings list. "Not worth it", "polish" and "can wait" are not reasons. There is no second fix pass.

## Finish

Collect every ledger line containing `Ruling:` into your final message under "Rulings I made", each with what it costs if wrong. List first, in this order: abandoned tasks, "left for you" actions, unverified tasks (with the dependents flagged under each), and residual load-bearing findings — final-review findings you ruled not to fix. Then every other ruling, in the order you made them. The list is exhaustive. Your final message is the only place the decisions you took on your human partner's behalf — and the findings you did not fix — reach them. End it with the plan path.

Do not delete the workspace: superpowers-ross:finishing-a-development-branch reads `Base:` and the chained commit ranges from the ledger, and deletes the workspace when it is done.

Use superpowers-ross:finishing-a-development-branch.
