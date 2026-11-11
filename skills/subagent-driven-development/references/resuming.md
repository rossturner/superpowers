# Resuming From an Existing Ledger

Part of superpowers-ross:subagent-driven-development. This plan's workspace already has a ledger at `<workspace>/progress.md`.

If the ledger's first line names your plan file, a task is DONE when the ledger has a `Task <N>: complete` line, a `Task <N>: Ruling: abandoned` line, or a `Task <N>: Ruling: unverified` line that ends with `(commits …)` — do not re-dispatch it; resume at the first task with none of these. The ledger is shared with superpowers-ross:executing-plans, so honour all three whichever executor wrote them. A task whose last line is a fix round is mid-loop: resume the loop at the next round. A ledger whose first line names a different plan file — or a stray ledger at the old flat path `.superpowers/sdd/progress.md` — is another plan's progress: leave it in place and start your own, fresh.

`Base:` is already there: never rewrite it. On resume, find the most recent `## Steps` block: if it is another executor's (the plan changed executors) or there is none (a ledger from before step lists), append this skill's block before anything else. The ledger stays append-only.

`task-brief` rewrites a brief from the plan, so re-apply any `Task <N>: Ruling: amended` line to the regenerated brief before dispatching that task.

`git clean -fdx` destroys the workspace (it's git-ignored scratch); if that has happened, recover from `git log`.
