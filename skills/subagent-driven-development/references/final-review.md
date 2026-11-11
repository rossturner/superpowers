# Final Review and Finish

Part of superpowers-ross:subagent-driven-development. Every task in the plan is complete, abandoned or unverified in the ledger.

## Final Review

The final whole-branch review gets a package too: run `bash scripts/review-package PLAN_FILE BASE HEAD` by its absolute path, from the working tree you're executing in (BASE = the ledger's `Base:` line, the commit HEAD was on before any task ran) and include the printed path in the final review dispatch, so the final reviewer reads one file instead of re-deriving the branch diff with git commands. Dispatch on `opus` (see [model-selection.md](model-selection.md)), using superpowers-ross:requesting-code-review's [code-reviewer.md](../../requesting-code-review/code-reviewer.md). Give it the invariants list verbatim — it checks each across the whole codebase and reports its search evidence — and the ledger's `minor (deferred)` and `parked` lines as work to be fixed, not triaged: "these get fixed; flag any you believe are wrong, with why".

Dispatch ONE fix subagent with everything left: the final reviewer's findings at every grade, Minor included, plus every deferred Minor and every parked finding it did not show to be wrong — not one fixer per finding. Per-finding fixers each rebuild context and re-run suites; a real session's final-review fix wave cost more than all its tasks combined. Then run a scoped re-review of the fix wave (`bash scripts/review-package PLAN_FILE FIX_BASE HEAD` by its absolute path, from the working tree you're executing in, over the wave's range, [re-review-prompt.md](../re-review-prompt.md)).

**Further waves, 3 waves at most.** When the re-review leaves anything open — an item NOT ADDRESSED, or breakage the wave made in its own diff, at any grade — run the next wave: resume the same fix subagent with exactly those items, then a scoped re-review over that wave's range. Issues the re-reviewer noticed outside the wave's diff ride along when a next wave runs; they never start one. A later wave carries only what the previous re-review left open, never a fresh sweep of the branch. After each wave, ledger `Final: fix wave <W>/3 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`.

When wave 3's re-review still leaves items open, stop dispatching. Every item no wave fixed — still open after the last wave, or excluded by you before dispatch — gets a ruling: `Final: Ruling: not fixed — <finding> — <wrong: why | not a code change | fix failed after <W> waves: what was tried> — <cost if wrong>`. "Not worth it", "polish" and "can wait" are not reasons: nothing after the last wave will pick the item up. Residual load-bearing findings go at the top of Rulings I made.

Then ledger the outcome: `Final review: fixes (commits <a7>..<b7>)` over the range of all the waves, from the first wave's FIX_BASE to the last wave's head, or `Final review: clean` when there was nothing to fix.

The read-through check in [task-review.md](task-review.md) applies to the final reviewer's report and to every wave's re-review.

## Finish

Collect every ledger line containing `Ruling:` — preflight rulings, parked findings, breaker adjudications, amendments, all of them — into your final message under "Rulings I made". List these first: abandoned tasks and the dependents they took with them; "left for you" actions; unverified tasks and the dependents flagged with them; residual load-bearing findings from the final review. Then every other ruling, in the order you made them, each with what it costs if wrong. The list is exhaustive: if the ledger holds a ruling, the list holds it. That list is the only place the decisions you took on your human partner's behalf reach them — they read it and rework whatever you got wrong. A ruling that dies with the workspace was a decision made in secret.

Put the plan file path in the same message. Do not delete this plan's workspace: superpowers-ross:finishing-a-development-branch reads `Base:` and the chained commit ranges from its ledger, and deletes it when it is done. Sibling directories belong to other plans; leave them alone.

Use superpowers-ross:finishing-a-development-branch.
