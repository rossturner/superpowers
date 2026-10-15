# Superpowers (Ross's fork)

Ross's personal fork of [obra/superpowers](https://github.com/obra/superpowers) for Claude Code, tuned to a single-developer workflow. The git remote `upstream` is obra.

The workflow lives in `skills/`: `brainstorming` → `writing-plans` → `subagent-driven-development` or `executing-plans` → `finishing-a-development-branch`, with the supporting skills around them. Read those to understand how the plugin behaves.

This fork is not a source of upstream PRs. Everything that differs from obra is fork-specific by design.

## Divergence from upstream

The README's "Divergence from upstream" section is the map: what each skill does differently, what stays deleted, and the conflict policy for `git merge upstream/main`. `git diff upstream/main..main` is the authoritative diff. In short:

- obra's structure is the base; the fork's behaviours are re-applied on top of upstream rewrites. `finishing-a-development-branch` is the exception: the fork's file replaces obra's.
- Worktrees, every non-Claude-Code harness, and obra's combined `task-reviewer-prompt.md` stay deleted. SDD's task review is two parallel reviewers (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`); port upstream edits to the combined reviewer into them by hand.
- obra's historical files (`RELEASE-NOTES.md`, `docs/plans/`, obra's `docs/superpowers/{specs,plans}/`) stay byte-identical to upstream. Do not sweep or edit them.
- Versions are `<obra version>-ross.<N>`; bump with `scripts/bump-version.sh`. Upstream's version number never wins a conflict.
- After a merge, re-apply the `superpowers-ross:` prefix with the sweep command in the README, then run `tests/claude-code/test-fork-validation.sh`.

## Changing skills

Skills are not prose — they are code that shapes agent behavior. Use `superpowers-ross:writing-skills` to develop and test changes, and do not casually rewrite carefully-tuned content (Red Flags tables, rationalization lists, "your human partner" language): the wording is tuned against observed agent behavior, not style preference.

Skill-behavior evals live in [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned into `evals/` — see `evals/README.md` for setup. Plugin-infrastructure tests live at `tests/`. `tests/claude-code/test-fork-validation.sh`, the hook tests and the script tests are fast and LLM-free; `test-subagent-driven-development.sh` and the integration tests drive a real Claude session and are slow.
