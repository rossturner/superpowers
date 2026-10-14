# Re-fork on obra/superpowers v7.0.0 — Design

## Intent

The fork today descends from obra through pcvelz/superpowers (`superpowers-extended-cc`), and carries pcvelz's additions (native-task persistence, routing/user-gate/commit-strategy hooks, `/onboard`, command wrappers) underneath its own changes. Ross wants the fork rebased directly on the latest obra/superpowers (v7.0.0, `bb92a77`), taking obra's newer machinery (rebuilt brainstorming front, leaner plans, combined task reviewer, "rulings, not stalls", Native executor) and re-applying only the fork behaviours listed below. None of the pcvelz additions return.

Success: `git diff upstream/main..main` (with `upstream` = obra) shows exactly the fork's divergence and nothing else; the four workflow skills behave as below; future syncs are a plain `git merge upstream/main` resolved with the policy in the README.

Anti-goals: keeping any pcvelz-only feature; any worktree use; any point where execution (SDD or Native) stops to ask the user mid-run; any skill that offers a merge/PR/keep menu.

## Constraints

- Claude Code only. Single developer, works on the current branch.
- Skills are behaviour-shaping code; obra's tuned wording (Red Flags tables, rationalization lists, "your human partner") is kept except where a fork behaviour requires a change.
- The GitHub repo `rossturner/superpowers` stays (it is already in obra's fork network via pcvelz). The "forked from pcvelz" label is cosmetic and left alone.
- Force-pushing `main` needs Ross's explicit OK at the moment of pushing.

## 1. Repository, history, identity, removals

**History.**
1. Tag the current `main` as `archive/pcvelz-7.2.0` and push the tag.
2. `git remote set-url upstream https://github.com/obra/superpowers.git`; remove the temporary `obra` remote.
3. Create a branch from `upstream/main` (v7.0.0) and apply the fork as themed commits, in this order: strip non-Claude-Code harness → identity → remove worktrees → brainstorming → writing-plans → subagent-driven-development → executing-plans → finishing → remaining skill touch-ups → tests → docs.
4. Force-push that branch as `main` (after Ross's OK).

This spec is committed on the current `main` and therefore lives only in the archive line; the new line does not carry it (consistent with specs being transient). The implementation plan copies whatever it needs.

**Identity and version.**
- Plugin `superpowers-ross`, marketplace `superpowers-ross-marketplace`, display name "Superpowers (Ross's fork)", skill prefix `superpowers-ross:` everywhere obra writes `superpowers:`.
- Version scheme `<obra version>-ross.<N>`: first release `7.0.0-ross.1`; N increments per fork release and resets to 1 when the obra base version changes. `.version-bump.json` / `scripts/bump-version.sh` are adjusted to produce and validate this format across all manifests.

**Removed.**
- All non-Claude-Code harness surface: `.agents/`, `.antigravity-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.devin-plugin/`, `.hermes-plugin/`, `.kimi-plugin/`, `.muse-plugin/`, `.opencode/`, `.pi/`, `GEMINI.md`, `gemini-extension.json`, `index.js` and the non-Claude `package.json` entry fields, `hooks/hooks-cursor.json` and the non-Claude branches of `hooks/session-start`, `scripts/{package-codex-plugin,sync-to-codex-plugin,render-antigravity-logo}.sh`, `skills/using-superpowers/references/*-tools.md` except `claude-code-tools.md`, `tests/{antigravity,codex,codex-plugin-sync,devin,hermes,kimi,opencode,pi}/`. Windows support for Claude Code (`run-hook.cmd` and its tests) stays.
- Worktrees: `skills/using-git-worktrees/` and every reference to it (writing-plans, SDD, executing-plans, finishing, `task-brief` comment, tests, README, docs). The read-only `git worktree add` that `requesting-code-review/code-reviewer.md` uses for a review checkout stays.
- pcvelz-era fork files: none are carried (no `commands/`, no `skills/shared/`, no `checking-gates`/`specifying-gates`, no routing/gate/commit-strategy hooks, no `hooks/examples/`, no `.tasks.json`, no old fork specs, no `docs/{model-routing,user-gate,workflow-config}-flow.md`).

**Kept from obra, prefix-renamed only:** every other skill, including `diagnosing-superpowers`, obra's Windows hook fixes, TDD's whole-suite rule, the `code-reviewer.md` additions. `diagnosing-superpowers`' issue template targets `rossturner/superpowers`.

## 2. brainstorming

Base: obra v7.0.0 `skills/brainstorming/SKILL.md`.

**Front half — obra's, one change.** Keep triage ("What do you actually know?"), the skip-the-questions line, one question per message, "how it gets made", thinking wide privately, spikes, the visual companion, playbacks (~200–300 words, guesses marked), and sizing (quick task / small change / project). Change: **recon is automatic** — when looking at the codebase, the user's files, or the web would help, the agent does it and briefly reports what it looked for and found; it does not offer and wait.

**Gate.** Nothing is built until the user has approved the design as played back in conversation (for a small change, the chat description). There is no separate approval of the written document. obra's Red Flag "A description you haven't written isn't approved" is reworded so approval covers what was played back and the document only records that. Spike and skip-the-questions exceptions stay as obra wrote them.

**Back half — replaces the builder check.**
1. Write the design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit. No self-review step of any kind.
2. Adversarial panel: parallel reviewer subagents at the session's model tier (no model override). The **builder lens is always included** (obra's builder-check framing: a talented builder in the domain who must plan from the document and cannot ask). The agent adds 1–3 further lenses chosen to fit the spec. `builder-check-prompt.md` is generalised into the per-lens template (renamed `spec-reviewer-prompt.md`); the builder lens is its default fill.
3. Fold findings with obra's three piles: **Answered already** → write into the doc; **Minor** → the agent settles it and marks it in the doc as its call; **Theirs** → one `AskUserQuestion` round, most important first. Clear errors and contradictions are fixed directly.
4. Commit the revisions as a second commit (not an amend).
5. Report the short list of calls the agent made, then invoke `superpowers-ross:writing-plans`. No "please review the document" stop.

Without a subagent tool, the agent reads the document through each lens itself.

**Transient artifact.** The spec is a working document: nothing outside `docs/superpowers/` links to it, and no later work updates it. It goes stale or is deleted after the feature ships.

## 3. writing-plans

Base: obra v7.0.0 `skills/writing-plans/SKILL.md`, keeping leaner plans ("What a Step Contains"), the Interfaces block, the Review Focus header section, the `Spec:` header line, and the five-point inline Self-Review (spec coverage, placeholders, type consistency, Review Focus, Proportion).

**Task granularity** replaces "Task Right-Sizing":
- One task per outcome. The plan's Architecture paragraph names the outcomes and is the authority on what one outcome is.
- Merge test: a task that cannot be verified on its own serves another task's outcome and merges into it. Split test: a task whose Goal needs more than one sentence holds two outcomes and splits.
- No size cap: a task spans as many files and commits as its outcome takes; neither size, file count nor commit count bounds it. TDD cycles happen within a task.
- Cost statement: every task costs a brief, an implementer dispatch, a review package and a reviewer dispatch in series, plus a fix dispatch and scoped re-review per round of findings; a decomposition finer than the outcomes buys only wall-clock time and repeated context.
- The Overview loses "bite-sized" and "Frequent commits". No Merge Pass section.

**Transient artifacts.** Nothing outside `docs/superpowers/` references the spec or plan (the plan's own `Spec:` line is inside it and fine). The final task updates durable documentation (README, `docs/` outside `docs/superpowers/`, docstrings) when the feature needs it; otherwise the plan says no durable docs change.

**Open decisions.** A plan never schedules a question for the user at execution time. What is left open goes under what's left to the builder; the executor rules on it (Section 4).

**Ending** replaces obra's Execution Handoff:
1. Commit the plan.
2. Stop with one message: "Plan committed to `<path>`. Recommend `/compact`, then invoke `superpowers-ross:subagent-driven-development` | `superpowers-ross:executing-plans` — <one sentence why>." The agent recommends exactly one. Native fits a few tightly coupled tasks where a shipped mistake is cheap and per-task review adds little; otherwise SDD. No "please review the plan", no menu.

The worktree context line is removed.

## 4. subagent-driven-development and executing-plans

Base: obra v7.0.0 SDD — plan-scoped `.superpowers/sdd/<plan>` workspace and ledger, `scripts/{sdd-workspace,task-brief,review-package}`, the combined spec+quality task reviewer (`task-reviewer-prompt.md`), the five-round fix loop with breaker and adjudication, scoped re-review, batching small same-shape work, "Rulings, not stalls", the final whole-branch review with one fix wave, and the "Rulings I made" list.

Changes:

1. **Current branch only.** Remove worktree setup, the "never start on main/master without consent" gate, and "outside this worktree" wording. At start, record `Base: <sha>` (HEAD before any work) in the ledger. The final review packages `Base..HEAD`, not `git merge-base main HEAD`.
2. **Never stops.** obra's four stop classes become:
   - Irreversible, security-sensitive, or outward-facing actions (push, merge, publish, destroying data outside the repo): not taken. Everything else proceeds; log `Ruling: left for you — <action> — <why>` and continue.
   - A plan broken past guessing: rule on the most defensible reading; if no path works, abandon the task.
   - BLOCKED ladder: (1) more context, same model; (2) one model tier up; (3) amend the task once — write the amendment into the brief and ledger it, never edit the plan file or renumber; (4) abandon — ledger it with how each dependent was handled (amended to stand alone, or abandoned too). obra's "break into smaller pieces" step is removed.
   - Items the plan leaves to the builder: ruled and ledgered the same way.
   - "Rulings I made" stays exhaustive; abandoned tasks and "left for you" actions are listed first.
3. **Implementer prompt.** "Ask before you begin" becomes: make the calls the brief leaves open from the brief, plan context and codebase, and record each under **Decisions** in the report; escalate (BLOCKED / NEEDS_CONTEXT) only for information missing from brief and repo, a brief that contradicts the code, or repeated failure. Never invent external facts (credentials, accounts, unnamed third-party services). The controller answers any implementer question itself and never relays it to the user.
4. **Model selection (named models, no hooks).** Always pass `model` explicitly. Tier follows how much judgment the task's steps leave open — never file count or task size:
   - Implementer and task reviewer, same rule: **Sonnet** by default; **Haiku** when the steps leave essentially nothing to decide (pinned signatures with pinned tests and obvious bodies, config or rename sweeps, batched same-shape edits); **Opus** for a design-heavy task, or after Sonnet returns BLOCKED.
   - Scoped re-reviews: Haiku or Sonnet, scaled to the fix diff.
   - Fix-loop escalation (rounds 4–5): at least one tier above the implementer that got stuck (obra's rule).
   - Final whole-branch review: **Opus**.
5. **No package size limit.** `review-package` writes the package's total line count into its first line (`# Review package: BASE..HEAD (<L> lines)`) and prints it. The task reviewer, re-reviewer and final reviewer (`requesting-code-review/code-reviewer.md`) read the package in ~1,000-line chunks via `offset` until the end, and state in their report that they read through line L. A report without that statement is re-dispatched. `code-reviewer.md` gains a `[DIFF_FILE]` input and writes its own package when none is given.
6. **Hand-off.** The final message carries the base SHA and "Rulings I made", then the workspace is deleted and `superpowers-ross:finishing-a-development-branch` is invoked.

**executing-plans (Native)** gets changes 1, 2, 5 and 6, and its single final reviewer runs on Opus. It stays in the repo and is recommended by writing-plans when it fits.

## 5. finishing-a-development-branch

Replaces obra's worktree-and-menu skill. Invoked after SDD or Native, which already ran the whole-branch review; finishing does no review of its own.

1. **Tests.** Run the full suite. On failure, report and stop; no squash.
2. **Base.** Use the base SHA from the executor's hand-off. If none is available (e.g. invoked by hand), never guess: skip the squash and say why.
3. **Squash or not — no question.** Squash `base..HEAD` into one commit (`git reset --soft <base>`, one commit) only when all hold: the range has no merge commits; every commit in it is this work's (nothing interleaved or foreign); none of it is on `@{upstream}` when one exists. Otherwise leave history as is and state which check failed. The message is derived from the plan's goal and the work done, and names abandoned tasks as not built. Never push or force-push.
4. **Summarize.** What was built, key changes, the final commit (or range), and the Rulings list carried over. Stop — no menu, no push/PR offer.

Rationalizations kept from obra: "tests passed earlier", "a rejected push means force-push". Added: "I can infer the base", "the range is close enough to linear". Worktree and menu rows are dropped.

## 6. Other adjustments, tests, docs

- `requesting-code-review`: the BASE_SHA hint `git merge-base origin/main HEAD` is wrong when working on main; it says to use the executor's recorded base, or for an ad-hoc review the commit before the work began as stated by the caller.
- `using-superpowers`: prefix rename; keep only the Claude Code tools reference; its skill-flow guidance shows writing-plans → SDD or Native.
- `AGENTS.md`: replaced by a short pointer to `CLAUDE.md` (obra's contributor guidance concerns PRs to obra, which this fork never sends).
- Tests: keep obra's Claude Code tests (`tests/claude-code`, `tests/hooks`, `tests/brainstorm-server`, SDD script tests), stripped of worktree assertions; delete worktree and other-harness tests. New `tests/claude-code/test-fork-validation.sh` (fast, LLM-free) pins: no reference to `using-git-worktrees`; no "bite-sized"/"Frequent commits" in writing-plans; one-task-per-outcome text present; no "stop and ask" in SDD or executing-plans; the brainstorming panel's mandatory builder lens; `review-package` line-count header; `superpowers-ross` name and `*-ross.N` version consistent across manifests.
- Docs: rewrite `CLAUDE.md` for the obra base. README = obra's README trimmed to Claude Code plus fork install, with a rewritten "Divergence from upstream" section giving per-area conflict policy (re-apply the behaviours above onto obra's structure; finishing is a replacement; removals stay removed) and the rename sweep command with its `:no-sweep:` guard.
- `evals/` (superpowers-evals checkout) is out of scope.

## Left to the builder

Exact commit boundaries within the ordered series in Section 1; wording of the rewritten sections, as long as obra's tuned prose is otherwise preserved; how `bump-version.sh` parses the suffix.
