# Handling a Report That Isn't DONE

Part of superpowers-ross:subagent-driven-development.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Find it yourself in the spec, the plan and the code, and re-dispatch with it. Where none of them answers it, rule on the most defensible answer, ledger the ruling, and carry it in the dispatch. If the only answer is an external fact nobody gave you — a credential, an account, a third-party service the plan does not name — never invent one: go to rung 3 of the BLOCKED ladder.

**BLOCKED:** The implementer cannot complete the task. Climb this ladder in order; skip a rung only when it plainly cannot help (more context for a blocker that is not about context):
1. **More context, same model** — answer the blocker from the spec, plan and code, and re-dispatch.
2. **One model tier up** — re-dispatch on the next tier (`haiku` → `sonnet` → `opus`).
3. **Amend the task once** — write the amendment into the task's brief file, ledger it as `Task <N>: Ruling: amended — <what changed> — <why> — <what it costs if wrong>`, and re-dispatch. Never edit the plan file and never renumber tasks. A task gets one amendment. `task-brief` rewrites the brief from the plan, so on resume re-apply any `Task <N>: Ruling: amended` line to the regenerated brief before dispatching.
4. **Abandon** — if the task left uncommitted changes, commit them as `wip: abandoned Task <N>` (never reset or clean them away). Then ledger `Task <N>: Ruling: abandoned — <why> — dependents: <each amended to stand alone, or abandoned too>`, ending the line with ` (commits <a7>..<b7>)` when the task left commits — from the BASE you recorded before dispatching its implementer to HEAD, so the range covers the `wip:` commit. Before dispatching each dependent, do what that line says: amend it once to stand alone (rung 3's rules), or abandon it in turn.

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

If the implementer asks questions — before starting or mid-task — answer them yourself from the spec, the plan and the code, clearly and completely, and provide additional context if needed. Never relay an implementer's question to your human partner: the run does not wait on a human. A question none of the three answers gets a ruling, ledgered and carried in the dispatch.
