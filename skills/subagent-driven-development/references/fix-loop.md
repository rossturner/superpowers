# The Fix Loop

Part of superpowers-ross:subagent-driven-development. Both task reviews are in.

The loop triggers when the open list is not empty. Once both reports are in, sort every finding into ONE open list:

- every spec ❌ (including invariant breaches, whether this task caused them or the code predates the branch), every Critical and Important from either reviewer, and every ⚠️ item you confirmed as a real gap;
- any finding of any grade — a quality Minor included — that breaches a spec rule or an invariant. A reviewer that graded a spec breach Minor graded its size, not its effect. Ledger `Task <N>: Ruling: regraded — <finding> — breaches <rule>`. Re-grading only ever moves a finding up.

Before the loop starts, three routes leave it:

- **A breach in a path the plan gives to a later task** goes to that task: ledger `Task <N>: Ruling: deferred to Task <M> — <finding> — <why that task owns it>` and carry the finding in Task M's dispatch. Only an explicit plan assignment qualifies; "a later task is near there" does not.
- **Remaining Minors** are deferred, not dropped: ledger each as `Task <N>: minor (deferred): <one-liner>`. The final fix waves fix every one of them (see [final-review.md](final-review.md)). Deferred means "fixed in the final waves", never "maybe later" — nothing after the final waves will pick them up.
- A finding labeled plan-mandated — or any finding that conflicts with what the plan's text requires — is yours to rule on: weigh the finding against the plan text, decide with the spec as the binding authority, and ledger the ruling before you act on it. Do not dismiss the finding because the plan mandates it, and do not dispatch a fix that contradicts the plan without a recorded ruling. Everything else enters the loop. A fix round is one fix dispatch carrying the whole open list, from both reviewers, plus one scoped re-review. Five rounds maximum per task:

**Rounds 1-3 — resume the original implementer.** Send it the open findings verbatim. Its context is intact: it knows the task, the code, and its own choices. If your harness cannot send another message to a live subagent, dispatch a fresh implementer carrying the brief path, the report-file path, and the findings — the report file is the persistent memory either way.

**Rounds 4-5 — dispatch a fresh implementer on a more capable model** (per [model-selection.md](model-selection.md)), with the brief path, the report-file path, the open findings, and this framing: "A prior implementer attempted this task [N] times; you own it now. Read the report file for what was tried." A loop that survives three resumes usually means the implementer cannot see its own problem — fresh eyes and a capability bump in one move.

**Every round, either way:** the implementer fixes, re-runs the tests covering the amended code, appends its fix report to the same report file, and returns the short contract. Before dispatching the re-review, confirm the fix report contains the covering tests, the command run, and the output; dispatch the re-review once all three are present. Name the covering test files in the fix message — a one-line fix does not need the whole suite.

**The re-review is scoped.** Run `bash scripts/review-package PLAN_FILE FIX_BASE HEAD` by its absolute path, from the working tree you're executing in, where FIX_BASE is the head the previous review saw, and dispatch [re-review-prompt.md](../re-review-prompt.md) with the open list, the brief, the report file, and the printed diff path. When the round carried a spec or invariant finding, also pass each breached invariant: the re-reviewer re-runs its search over the codebase, not only the fix diff, and runs on the orchestrator's model (see [model-selection.md](model-selection.md)). The re-reviewer verdicts each finding ADDRESSED or NOT ADDRESSED and flags new breakage in the fix diff. New Critical/Important breakage in the fix diff joins the open findings list. Out-of-scope observations go to the ledger as deferred minors — they never extend the loop.

**After each round,** append to the ledger: `Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)` — the round's own range, FIX_BASE to HEAD. It sits inside the task's completion range, so the chain finishing checks skips it: only completion, abandoned, unverified and `Final review: fixes` ranges are chained.

Never fix findings yourself in the controller session — your context stays clean for coordination, and controller fixes skip review.

**The breaker.** When round 5's re-review still leaves findings open, stop dispatching. Adjudicate each open finding yourself — you hold the plan and the cross-task context the reviewer lacks:

- **The reviewer is wrong, or the point is contestable:** park it — `Task <N>: parked — <finding> — Ruling: <why the code stands>`. The final review sees both sides.
- **Real, but nothing downstream builds on it:** park it the same way, with a ruling that says it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a plan defect: rule on the smallest change that unblocks the dependent work, ledger it as `Task <N>: Ruling: <finding> — <what you decided and why>`, and carry it into the next task's dispatch. Parking a structural failure silently lets every dependent task build on it. When no change unblocks the dependent work, the defect is past guessing: amend each dependent once to stand alone, or abandon it, as the BLOCKED ladder's last rung does ([handling-reports.md](handling-reports.md)).

Adjudicate only at the cap. Adjudicating earlier to end a loop is pre-judging with a different name. Every adjudication is a ledger entry — a silent discard is forbidden.
