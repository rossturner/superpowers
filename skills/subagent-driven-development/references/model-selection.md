# Model Selection

Part of superpowers-ross:subagent-driven-development. Read this before your first dispatch, and again after any compaction.

**Always pass `model` explicitly when dispatching a subagent** — `haiku`, `sonnet` or `opus`. An omitted model inherits your session's model — often the most capable and most expensive — which silently defeats this section.

The tier follows how much judgment the task's steps leave open — never how many files the task touches or how large it is. A rename swept across twenty files leaves nothing to decide; a one-function change to a lock protocol leaves a great deal.

**Implementer:**
- `sonnet` by default.
- `haiku` when the steps leave essentially nothing to decide: pinned signatures with pinned tests and obvious bodies, config or rename sweeps, batched same-shape edits.
- `opus` for a design-heavy task, or after a `sonnet` implementer returns BLOCKED.

**Spec and quality reviewers:** the orchestrator's own model — `opus` when this session runs on Opus, `sonnet` when it runs on Sonnet — for both, on every task, whatever tier the implementer got. Pass it explicitly.

**Scoped re-reviews:** the orchestrator's own model when the round carried a spec or invariant finding (the re-review re-runs the invariant search); otherwise `haiku` or `sonnet`, scaled to the fix diff.

**Fix-loop escalation (rounds 4-5):** at least one tier above the implementer that got stuck.

**Final whole-branch review:** `opus`.

**Turn count beats token price.** Wall-clock and context cost scale with how many turns a subagent takes, and the cheapest models routinely take 2-3× the turns on work that needs judgment — costing more overall. That is why `haiku` is kept for steps that leave nothing to decide.
