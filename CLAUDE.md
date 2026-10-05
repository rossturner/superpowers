# Superpowers (Ross's fork)

Ross's personal fork of [obra/superpowers](https://github.com/obra/superpowers), tracking immediate upstream [pcvelz/superpowers](https://github.com/pcvelz/superpowers), tuned to a single-developer workflow.

The workflow lives in `skills/`: `brainstorming` → `writing-plans` → `subagent-driven-development`, with the supporting skills around them. Read those to understand how the plugin behaves.

This fork is not a source of upstream PRs. Upstream explicitly rejects fork-sync and rebranding PRs, and everything below is fork-specific by design — do not open PRs against `pcvelz/superpowers` from this repo.

## Divergence from upstream

When merging upstream (`git fetch upstream && git merge upstream/main`), resolve conflicts with the policy below. Full file list and rationale: the README "Divergence from Upstream" section. `git diff --stat upstream/main..HEAD` is the authoritative diff.

The fork versions on its own `7.x` line; upstream's version number never wins a conflict.

**Behavioral — upstream's structure is the base; these fork behaviors are re-applied on top of it:**
- **brainstorming** — adversarial spec review (parallel subagents, spec-writer picks perspectives, main tier) replaces manual user spec-review; no task creation here.
- **writing-plans** — write → commit → halt; no native tasks, no `.tasks.json`, no execution-handoff menu; plan and spec are transient. Carries the coarse granularity rule below, a Merge Pass over the finished task list, and a statement of what a task costs to execute.
- **task granularity** — a task is one outcome named by the plan's Architecture paragraph, bounded by Merge/Split. A task is a range of commits, and neither size, file count nor commit count bounds it; reviewers read the whole package in chunks instead. Upstream's `Commit Boundary = Task Boundary` subsection and granularity examples table stay deleted from `skills/shared/task-format-reference.md`; `TDD Within Tasks` stays. The word "bite-sized" stays out of `skills/writing-plans/SKILL.md` and `commands/write-plan.md`. Pinned by Test 7 in `tests/claude-code/test-fork-validation.sh`.
- **subagent-driven-development** — self-summary at start; capture base SHA into `.tasks.json`; build the task list here (including user-gate tagging); current branch only (never switch, never worktree); parallel spec (cheap) + code-quality (orchestrator) reviewers; re-run only the addressed reviewer; dispatch a subagent for follow-up; select the implementer tier on what the task's steps contain, never on file count; record the per-task BASE in the ledger; never stop mid-run to ask — decide, log the ruling in the ledger, report Decisions made at the end (pinned by Test 8); run autonomously to completion. Everything else in this skill is upstream's: the plan-scoped `.superpowers/sdd/<plan>` workspace and ledger, `scripts/{sdd-workspace,task-brief,review-package}`, the five-round fix loop with breaker and adjudication, and the scoped re-review.
- **finishing-a-development-branch** — read `baseSha`, auto-squash when commits are linear/unpushed and Decisions made has no abandoned task or load-bearing parked finding, else ask. No worktree teardown, no merge/PR/keep menu.

**Removed — keep deleted; discard upstream edits to these:**
- Git worktrees entirely (`skills/using-git-worktrees/`, worktree tests).
- `skills/executing-plans/` — task creation absorbed into subagent-driven-development; references repointed.
- `hooks/pre-askuser-handoff-guard` — reviewers exempt from routing via the `[sdd-review]` marker in `hooks/pre-agent-model-routing`. The marker check runs before the routing file is read, so it exempts the effort dial as well as the model dial.
- `skills/subagent-driven-development/task-reviewer-prompt.md` — upstream's merged single reviewer; this fork dispatches the split pair in parallel instead.
- All non-Claude-Code harness surface (`.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `.opencode/`, `references/codex-tools.md`) — dropped in step with upstream.

**Identity — keep this fork's values; re-apply the rename after any merge:**
- Plugin/marketplace renamed to `superpowers-ross` / `superpowers-ross-marketplace`; the name is also the `superpowers-ross:` skill prefix used throughout. Re-sweep with the command in the README's "Identity & branding" section — it is written there with `:no-sweep:` markers so the sweep cannot rewrite its own instructions, which it otherwise does, silently turning the command into a no-op.

## Changing skills

Skills are not prose — they are code that shapes agent behavior. Use `superpowers-ross:writing-skills` to develop and test changes, and do not casually rewrite carefully-tuned content (Red Flags tables, rationalization lists, "your human partner" language): the wording is tuned against observed agent behavior, not style preference.

Skill-behavior evals live in [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned into `evals/` — see `evals/README.md` for setup. The eval tooling drives real tmux sessions of Claude Code and judges skill compliance with an LLM verifier. Plugin-infrastructure tests live at `tests/`. Most of `tests/claude-code/` is fast and LLM-free (hook matrices, fork validation); `test-subagent-driven-development.sh` is the exception — it drives a real Claude session via `run_claude` and is slow.
