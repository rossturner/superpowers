# Superpowers (Ross's fork)

Ross's personal fork of [obra/superpowers](https://github.com/obra/superpowers), for Claude Code only, tuned to a single-developer workflow. Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them. What this fork changes is listed under [Divergence from upstream](#divergence-from-upstream).

## Table of Contents

- [How it works](#how-it-works)
- [Installation](#installation)
- [The Basic Workflow](#the-basic-workflow)
- [When Something Goes Wrong](#when-something-goes-wrong)
- [What's Inside](#whats-inside)
- [Philosophy](#philosophy)
- [Development](#development)
- [Updating](#updating)
- [Divergence from upstream](#divergence-from-upstream)
- [License](#license)
- [Visual companion telemetry](#visual-companion-telemetry)

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for your agent to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Installation

```bash
/plugin marketplace add rossturner/superpowers
/plugin install superpowers-ross@superpowers-ross-marketplace
```

Restart Claude Code afterwards so the `SessionStart` hook takes effect. If the original `superpowers` plugin is also installed, uninstall it: both register the same skills under different prefixes.

**Moving from a 7.2.0 or earlier install.** Versions up to 7.2.0 were built on pcvelz/superpowers. This fork was rebuilt on obra/superpowers v7.0.0 with rewritten history and versions of the form `7.0.0-ross.N`, which sort below 7.2.0, so an in-place update is not reliable. Reinstall once:

```bash
/plugin marketplace remove superpowers-ross-marketplace
/plugin marketplace add rossturner/superpowers
/plugin install superpowers-ross@superpowers-ross-marketplace
```

Then check that `~/.claude/plugins/cache/superpowers-ross-marketplace/superpowers-ross/` holds a `7.0.0-ross.N` directory.

## The Basic Workflow

1. **brainstorming** - Activates before building anything. Draws out what you actually want, and why, through questions that get you describing it, looks at the code and the web on its own when that helps, then plays its understanding back for correction. Small changes get agreed in chat; projects get a written design document, which a panel of parallel adversarial reviewers attacks before planning starts.

2. **writing-plans** - Activates with the design. Breaks work into one task per outcome, each with exact file paths, code, tests and verification steps. Commits the plan and recommends `/compact` followed by one of the two executors.

3. **subagent-driven-development** or **executing-plans** - Activates with plan. Either dispatches a fresh subagent per task with a review after each (most thorough), or implements every task inline in the current session (cheapest). Both run on the current branch to completion without stopping to ask, log every judgement call, and end with a whole-branch review.

4. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

5. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

6. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, squashes the work into one commit when it is safe to, and summarizes what was done.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## When Something Goes Wrong

Sometimes a session misbehaves: a skill fires when it shouldn't, stays silent when it should, or the agent ignores its plan, repeats work, or burns more tokens than you'd expect. Ask your coding agent to "figure out what went wrong with superpowers in this session" and it will invoke the **diagnosing-superpowers** skill. To examine an earlier session, name it: "figure out what went wrong with superpowers in session `<id>`".

The skill reads the session transcript, reports what happened with line-level evidence, and, if you want, packages a scrubbed bundle for a bug report.

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues (upstream)**: https://github.com/obra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed
- **diagnosing-superpowers** - Work out what went wrong in a session, with evidence; export a scrubbed bundle or file an issue

**Collaboration** 
- **brainstorming** - Drawing out intent before building
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Inline plan execution: one context, one final review
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **finishing-a-development-branch** - Test, squash when safe, summarize
- **subagent-driven-development** - A fresh subagent per task, a combined spec and quality review after each, a whole-branch review at the end

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Development

This fork does not accept contributions and never sends PRs upstream. See `CLAUDE.md` for how to work on it.

Skill-behavior tests use the drill eval harness from [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/), cloned into `evals/` — see `evals/README.md` for setup. Plugin-infrastructure tests live at `tests/` and run via the relevant `run-*.sh` or `npm test`.

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Enable auto-update for the `superpowers-ross-marketplace` marketplace in `/plugin`, or run `/plugin marketplace update superpowers-ross-marketplace`.

## Divergence from upstream

The upstream is [obra/superpowers](https://github.com/obra/superpowers). `git diff upstream/main..main` is the whole divergence; this section is the map. Releases are versioned `<obra version>-ross.<N>`: N counts fork releases on one obra base and resets to 1 when the base moves. Tags are `v<version>`.

To sync:

```bash
git fetch upstream
git merge upstream/main   # resolve conflicts with the policy below
```

**Resolution stance.** obra's structure is the base. When upstream reworks a skill this fork has diverged on, take their rewrite and re-apply the fork behaviours below onto it. The exception is `finishing-a-development-branch`, which is a replacement: keep the fork's file and graft across only rationalizations that still apply. obra's historical files (`RELEASE-NOTES.md`, `docs/plans/`, obra's `docs/superpowers/{specs,plans}/`) stay exactly as upstream has them.

### Behaviours re-applied on top of upstream

**brainstorming** (`skills/brainstorming/`). Recon is automatic: the agent looks at the code and the web without asking first. Approval is of the design as played back in conversation, not of the written document. obra's builder check is replaced by a panel of parallel adversarial reviewers (`spec-panel-prompt.md`): the builder lens always runs, plus lenses chosen for the spec. Findings are sorted into obra's three piles, with one `AskUserQuestion` round for the user's pile. Revisions are committed as a second commit and the skill moves straight to writing-plans. The spec is a transient artifact that nothing outside `docs/superpowers/` links to.

**writing-plans** (`skills/writing-plans/SKILL.md`). One task per outcome, as named by the plan's Architecture paragraph, with no size cap and a statement of what each task costs to run; the word "bite-sized" stays out. Spec and plan are transient. Plans never schedule questions for execution time. The skill commits the plan and stops, recommending `/compact` and exactly one executor; there is no handoff menu. obra's v6.4.2 lean-plan change is reverted: no "What a Step Contains", no Proportion self-review item, and code steps carry code blocks and test steps carry test code, as before v6.4.2. Keep it reverted when merging upstream. Large tasks run one red/green cycle per layer, interface changes get their own step before the red test, and self-review checks red order.

**subagent-driven-development and executing-plans.** Current branch only, with `Base:` recorded in the ledger at setup. They never stop to ask: unrecoverable, security-sensitive and outward-facing actions are left for the user and logged; BLOCKED tasks climb a ladder that ends in amending once, then abandoning; every ruling is reported at the end. The implementer records its own decisions instead of asking. Implementer models are chosen by how much judgment a task's steps leave open (`haiku` / `sonnet` / `opus`), never by file count, and the whole-branch review runs on `opus`. `review-package` puts the line count on line 1 and reviewers read packages in chunks to the end. The workspace is left for finishing to read and delete.

**Review rigour (SDD and executing-plans).** Each executor's first action is to append its fixed `## Steps (<executor>)` list to the ledger after `Base:`, and it re-reads that list before each task and after compaction. Plans carry an `## Invariants` section (written by writing-plans and listed to the user at its end): rules that must hold in code no task touches, each with a search anchor. SDD replaces obra's combined task reviewer with two parallel reviewers on the orchestrator's own model: `spec-reviewer-prompt.md`, which treats the spec as the authority over the brief and searches the whole codebase for every path the task's invariants govern, and `code-quality-reviewer-prompt.md`. A finding that breaches a spec rule or invariant enters the fix loop whatever its grade, including breaches that predate the branch. Remaining Minors are deferred to the final review, whose single fix wave (or Native's fix pass) fixes them along with everything else; an unfixed item needs a `not fixed` ruling with a real reason. The final reviewer (`code-reviewer.md`) also gets the invariants and the deferred work. SDD implementers load test-driven-development unconditionally and report RED for every test they write.

**finishing-a-development-branch.** Runs tests, reads `Base:` and the task ranges from the ledger, squashes `Base..HEAD` when the tree is clean, the range is linear, nothing is interleaved and nothing is on a remote, otherwise leaves the commits as they are without asking, then summarizes. No worktree teardown and no merge/PR/keep menu.

### Removed — keep deleted

- `skills/subagent-driven-development/task-reviewer-prompt.md`, obra's combined task reviewer. When upstream edits it, port the change by hand into `spec-reviewer-prompt.md` or `code-quality-reviewer-prompt.md`, whichever owns that part.
- Git worktrees: `skills/using-git-worktrees/` and every reference to it.
- All non-Claude-Code harness surface: other plugin manifests, `GEMINI.md`, `gemini-extension.json`, `index.js`, `hooks/hooks-cursor.json`, non-Claude branches of `hooks/session-start`, Codex and Antigravity scripts, other harnesses' references, docs and tests.

### Identity

The plugin is `superpowers-ross` in the `superpowers-ross-marketplace` marketplace, and `superpowers-ross:` is the skill prefix. After a merge, re-apply the prefix in the swept scope. The upstream prefix is written below with a `:no-sweep:` marker spliced in so that the sweep cannot rewrite this instruction into a no-op; strip the marker before running:

```bash
# remove ':no-sweep:' before running
OLD='superpowers:no-sweep::'; OLD=${OLD/:no-sweep:/}
git grep -Il "${OLD}[a-z]" -- skills hooks tests scripts .claude-plugin package.json README.md CLAUDE.md AGENTS.md docs/testing.md \
  | xargs sed -i "s/\b${OLD}\([a-z]\)/superpowers-ross:\1/g"
```

After sweeping, `grep -n 'no-sweep' README.md` must still return these lines. `tests/claude-code/test-fork-validation.sh` pins the behaviours above.

## License

MIT License - see LICENSE file for details

## Visual companion telemetry

Because skills and plugins don't provide any feedback to creators, we have no idea how many of you are using Superpowers. By default, the Prime Radiant logo on brainstorming's optional visual companion feature is loaded from our website. It includes the version of Superpowers in use. It does not include any details about your project, prompt, or coding agent. We don't see your clicks or anything about what you're building. This helps us have a rough idea of how many folks are using Superpowers and which version of Superpowers they're using. It's 100% optional. To disable this, set the environment variable `SUPERPOWERS_DISABLE_TELEMETRY` to any true value. Superpowers also honors Claude Code's `DISABLE_TELEMETRY` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` opt-outs.
