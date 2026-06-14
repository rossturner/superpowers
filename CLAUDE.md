# Superpowers (Ross's fork)

Ross's personal fork of [obra/superpowers](https://github.com/obra/superpowers), tracking immediate upstream [pcvelz/superpowers](https://github.com/pcvelz/superpowers), tuned to a single-developer workflow.

The workflow lives in `skills/`: `brainstorming` → `writing-plans` → `subagent-driven-development`, with the supporting skills around them. Read those to understand how the plugin behaves.

## Divergence from upstream

When merging upstream (`git fetch upstream && git merge upstream/main`), resolve conflicts with the policy below. Full file list and rationale: the README "Divergence from Upstream" section. `git diff --stat upstream/main..HEAD` is the authoritative diff.

**Behavioral — keep this fork's version; reconcile genuine upstream improvements by hand:**
- **brainstorming** — adversarial spec review (parallel subagents, spec-writer picks perspectives, main tier) replaces manual user spec-review; no task creation here.
- **writing-plans** — write → commit → halt; no native tasks, no `.tasks.json`; plan and spec are transient.
- **subagent-driven-development** — self-summary at start; capture base SHA; build the task list here; current branch only (never switch); parallel spec (haiku) + code (orchestrator) reviewers; re-run only the addressed reviewer; dispatch a subagent for follow-up; run autonomously to completion.
- **finishing-a-development-branch** — read `baseSha`, auto-squash when commits are linear/unpushed, else ask.

**Removed — keep deleted; discard upstream edits to these:**
- Git worktrees entirely (`skills/using-git-worktrees/`, worktree tests).
- `skills/executing-plans/` — task creation absorbed into subagent-driven-development; references repointed.
- `hooks/pre-askuser-handoff-guard` — reviewers exempt from routing via the `[sdd-review]` marker in `hooks/pre-agent-model-routing`.

**Identity — keep this fork's values; re-apply the rename after any merge:**
- Plugin/marketplace renamed to `superpowers-ross` / `superpowers-ross-marketplace`; the name is also the `superpowers-ross:` skill prefix used throughout. Re-sweep with:
  `git grep -Il 'superpowers-extended-cc' | xargs sed -i 's/superpowers-extended-cc/superpowers-ross/g'`
