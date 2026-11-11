# The Ladder: a task with no path that works

When no ruling gives the task a path that works, climb the ladder — there is no implementer to re-dispatch, so it is short:

1. **Rule** on the most defensible reading, as above.
2. **Amend the task once.** Write the amendment into the task's brief in the workspace and ledger it as `Task <N>: Ruling: amended — <what changed> — <why>`. Never edit the plan file and never renumber tasks. One amendment; not a second. `task-start` rewrites the brief from the plan, so on resume re-apply any `Task <N>: Ruling: amended` line to the regenerated brief before working it.
3. **Abandon.** If the task left uncommitted changes, commit them as `wip: abandoned Task <N>` — never reset or clean them away. Then ledger `Task <N>: Ruling: abandoned — <why> — dependents: <each amended to stand alone, or abandoned too>`, ending with ` (commits <a7>..<b7>)` when the task left commits (the range runs from its BASE to HEAD, covering the `wip:` commit, so the ledger's ranges still chain). Then take the next task.
