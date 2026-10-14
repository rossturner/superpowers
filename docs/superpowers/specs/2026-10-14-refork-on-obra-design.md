# Re-fork on obra/superpowers v7.0.0 — Design

## Intent

The fork today descends from obra through pcvelz/superpowers (`superpowers-extended-cc`), and carries pcvelz's additions (native-task persistence, routing/user-gate/commit-strategy hooks, `/onboard`, command wrappers) underneath its own changes. Ross wants the fork rebased directly on obra/superpowers v7.0.0 (tag `v7.0.0`, commit `bb92a77`), taking obra's newer machinery (rebuilt brainstorming front, leaner plans, combined task reviewer, "rulings, not stalls", Native executor) and re-applying only the fork behaviours listed below. None of the pcvelz additions return.

Success: `git diff upstream/main..main` (with `upstream` = obra), excluding the transient `docs/superpowers/{specs,plans}/` files that later features add, shows exactly the fork's divergence; the workflow skills behave as below; future syncs are a plain `git merge upstream/main` resolved with the policy in the README.

Anti-goals: keeping any pcvelz-only feature; any worktree use; any point where an execution skill (SDD or Native) asks the user mid-run (Claude Code permission prompts are the harness's, outside the skills' control); any skill that offers a merge/PR/keep menu.

## Constraints

- Claude Code only. Single developer, works on the current branch.
- Skills are behaviour-shaping code; obra's tuned wording (Red Flags tables, rationalization lists, "your human partner") is kept except where a fork behaviour requires a change.
- The GitHub repo `rossturner/superpowers` stays (it is already in obra's fork network via pcvelz). The "forked from pcvelz" label is cosmetic and left alone.
- Pushing the archive tag and force-pushing `main` each need Ross's explicit OK at that moment.
- obra's historical files — `RELEASE-NOTES.md`, `docs/plans/`, obra's own `docs/superpowers/{specs,plans}/` — stay byte-identical to obra. They are excluded from the rename sweep and from the fork-validation greps, so they never become merge-conflict surface.

## 1. Repository, history, identity, removals

**History.**
1. Tag the current `main` as `archive/pcvelz-7.2.0`; push it with `git push origin refs/tags/archive/pcvelz-7.2.0` and confirm it exists on the remote.
2. `git remote set-url upstream https://github.com/obra/superpowers.git`, then `git fetch upstream --tags --prune`; remove the temporary `obra` remote.
3. Create branch `refork` from tag `v7.0.0` and verify its tip is `bb92a77`. Apply the fork as themed commits, in this order: strip non-Claude-Code harness → identity → remove worktrees → brainstorming → writing-plans → subagent-driven-development → executing-plans → finishing → remaining skill touch-ups → tests → docs.
4. Force-push `refork` as `main`, then delete `refork`.
5. Migrate installed copies: `/plugin marketplace remove superpowers-ross-marketplace`, re-add it, install `superpowers-ross`, and confirm a `7.0.0-ross.1` cache directory appears. The rewritten history may not fast-forward an existing marketplace clone, and `7.0.0-ross.1` sorts below the installed `7.2.0` under semver, so an in-place update is not relied on.

**Executing this spec (bootstrapping).** The installed plugin during execution is the old 7.2.0 fork, whose SDD works only on the current branch and whose finishing auto-squashes. So:
- Steps 1–3's setup (tag, remote, fetch, branch creation, checkout of `refork`) are preconditions done in the main conversation before SDD starts. The tag push needs Ross's OK.
- This spec and its plan are copied onto `refork` **untracked** (`docs/superpowers/{specs,plans}/` paths) and are never committed there. The plan's `Spec:` line resolves; neither file enters the new line's history.
- SDD runs on `refork` with one task per themed outcome, each committing its own commits, so the themed series is preserved.
- The run must not be squashed: after SDD, finishing is either not invoked, or invoked with explicit instruction to skip the squash. Steps 4–5 are manual follow-ups after Ross reviews `git log upstream/main..refork`.

**Identity and version.**
- Plugin `superpowers-ross`, marketplace `superpowers-ross-marketplace`, display name "Superpowers (Ross's fork)", skill prefix `superpowers-ross:`.
- Rename sweep scope: `skills/`, `hooks/`, `tests/`, `scripts/`, `.claude-plugin/`, `package.json`, `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/testing.md`. Historical files (Constraints) are not swept.
- Version `<obra version>-ross.<N>`: first release `7.0.0-ross.1`; N increments per fork release and resets to 1 when the obra base changes. Git tags `v<version>` (`v7.0.0-ross.1`), which cannot collide with obra's `v7.0.0`. `.version-bump.json` lists only the Claude manifests; `scripts/bump-version.sh` produces and validates the `-ross.N` format and never uses semver ordering to check that a version went up.
- Visual companion branding (`brainstorming/scripts/server.cjs`, `tests/brainstorm-server/branding.test.js`) is left as obra's. The fork is not rebranded there. *(My call: least divergence.)*

**Removed.** Everything harness-specific that is not Claude Code, including at least:
- `.agents/`, `.antigravity-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.devin-plugin/`, `.hermes-plugin/`, `.kimi-plugin/`, `.muse-plugin/`, `.opencode/`, `.pi/`, `GEMINI.md`, `gemini-extension.json`, `index.js`;
- `package.json`'s `main`, `pi` and `pi-package` keyword (keep `"type": "module"`, which `render-graphs.js` needs);
- `hooks/hooks-cursor.json` and the Cursor/Copilot/Muse branches of `hooks/session-start`;
- `scripts/{package-codex-plugin,sync-to-codex-plugin,render-antigravity-logo}.sh`, `assets/antigravity-logo.png`;
- `docs/README.kimi.md`, `docs/README.opencode.md`, `docs/porting-to-a-new-harness.md`, `.github/ISSUE_TEMPLATE/platform_support.md`;
- `skills/using-superpowers/references/*-tools.md` except `claude-code-tools.md`, and the link to the deleted references at `skills/writing-skills/SKILL.md:12`;
- `tests/{antigravity,codex,codex-plugin-sync,devin,hermes,kimi,opencode,pi}/`.

Windows support for Claude Code (`run-hook.cmd` and its tests) stays. The Codex/Gemini/Copilot notes in `visual-companion.md` and the Codex fallback in `server.cjs` stay (harmless, less divergence).

**Worktrees removed:** `skills/using-git-worktrees/` and every reference to it in the swept scope. The read-only `git worktree add` that `requesting-code-review/code-reviewer.md` uses for a review checkout stays.

**pcvelz-era fork files:** none are carried (no `commands/`, `skills/shared/`, `checking-gates`/`specifying-gates`, routing/gate/commit-strategy hooks, `hooks/examples/`, `.tasks.json`, old fork specs, `docs/{model-routing,user-gate,workflow-config}-flow.md`).

**Kept from obra, prefix-renamed only:** every other skill, including `diagnosing-superpowers`. Its issue search/creation target in `skills/diagnosing-superpowers/references/github-issues.md` points at `rossturner/superpowers`. `.github/ISSUE_TEMPLATE/diagnosis_report.md` is kept because that file depends on it.

## 2. brainstorming

Base: obra v7.0.0 `skills/brainstorming/SKILL.md`.

**Front half — obra's, one change.** Keep triage ("What do you actually know?"), the skip-the-questions line, one question per message, "how it gets made", thinking wide privately, spikes, the visual companion, playbacks (~200–300 words, guesses marked), and sizing (quick task / small change / project). Change: **recon is automatic.** When looking would help, the agent reads the codebase or project and searches the web without asking first, then briefly reports what it looked for and found. Files outside the project are read only where the user has pointed to them. *(Boundary is my call.)*

**Gate.** Nothing is built until the user has approved the design as played back in conversation (for a small change, the chat description). There is no separate approval of the written document. These are reworded accordingly:
- the HARD-GATE ("approves the full description: in chat for a small change, the document for a project" and "After a project's document is approved");
- the Red Flag "A description you haven't written isn't approved".

Spike and skip-the-questions exceptions stay as obra wrote them.

**Back half — replaces the builder check** (software projects; for non-software projects the document goes where the user says and the panel still runs, but no writing-plans hand-off):
1. Write the design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit. No self-review step.
2. Adversarial panel: parallel reviewer subagents at the session's model tier (no model override). The **builder lens is always included** (obra's builder-check framing: a talented builder in the domain who must plan from the document and cannot ask). The agent adds 1–3 further lenses chosen to fit the spec. `builder-check-prompt.md` is generalised into the per-lens template `spec-panel-prompt.md`, with the builder lens as its default fill. Without a subagent tool, the agent reads the document through each lens itself; this is the panel's fallback, not a self-review step.
3. Fold findings with obra's three piles:
   - **Answered already** → write into the doc.
   - **Minor** → the agent settles it and marks it in the doc as its call.
   - **Theirs** → one `AskUserQuestion` round, most important first, at most four questions. Anything beyond four is settled as the agent's call and marked.
   - Clear errors and contradictions are fixed directly.
4. Commit the revisions as a second commit (not an amend).
5. Report the short list of calls the agent made, then invoke `superpowers-ross:writing-plans`. No "please review the document" stop.

**Transient artifact.** The spec is a working document. Nothing outside `docs/superpowers/` links to it, and no later work updates it. It goes stale or is deleted after the feature ships.

## 3. writing-plans

Base: obra v7.0.0 `skills/writing-plans/SKILL.md`. Keep:
- leaner plans ("What a Step Contains");
- the Interfaces block;
- the Review Focus header section;
- the `Spec:` header line;
- the five-point inline Self-Review (spec coverage, placeholders, type consistency, Review Focus, Proportion).

**Task granularity** replaces "Task Right-Sizing":
- One task per outcome. The plan's Architecture paragraph names the outcomes and is the authority on what one outcome is.
- Merge test: a task that cannot be verified on its own serves another task's outcome and merges into it.
- Split test: a task whose Goal needs more than one sentence holds two outcomes and splits.
- No size cap: a task spans as many files and commits as its outcome takes. Neither size, file count nor commit count bounds it. TDD cycles happen within a task.
- Cost statement: every task costs a brief, an implementer dispatch, a review package and a reviewer dispatch in series, plus a fix dispatch and scoped re-review per round of findings. A decomposition finer than the outcomes buys only wall-clock time and repeated context.
- The Overview loses "bite-sized" and "Frequent commits". No Merge Pass section.

**Transient artifacts.** Nothing outside `docs/superpowers/` references the spec or plan (the plan's own `Spec:` line is inside it and fine). The final task updates durable documentation (README, `docs/` outside `docs/superpowers/`, docstrings) when the feature needs it; otherwise the plan says no durable docs change.

**Open decisions.** A plan never schedules a question for the user at execution time. What is left open goes under what's left to the builder, and the executor rules on it (Section 4).

**Ending** replaces obra's Execution Handoff:
1. Commit the plan.
2. Stop with one message: "Plan committed to `<path>`. Recommend `/compact`, then invoke `superpowers-ross:subagent-driven-development` | `superpowers-ross:executing-plans` — <one sentence why>."
   - The agent recommends exactly one.
   - Native fits a few tightly coupled tasks where a shipped mistake is cheap and per-task review adds little; otherwise SDD.
   - No "please review the plan", no menu.

The worktree context line is removed.

## 4. subagent-driven-development and executing-plans

Base: obra v7.0.0 SDD. Kept:
- the plan-scoped `.superpowers/sdd/<plan>` workspace and ledger;
- `scripts/{sdd-workspace,task-brief,review-package}`;
- the combined spec+quality task reviewer (`task-reviewer-prompt.md`);
- the five-round fix loop with breaker and adjudication, and the scoped re-review;
- "Rulings, not stalls";
- the final whole-branch review with one fix wave;
- the "Rulings I made" list;
- "Batch small same-shape work", kept as a fallback for plans that still contain such tasks.

Changes:

1. **Current branch only.**
   - Remove worktree setup, the "never start on main/master without consent" gate, "outside this worktree" wording, and `[Setup: worktree verified]` in both skills' examples.
   - `Base: <sha>` (HEAD before any work) is written into the ledger **once, when the ledger is created**, before any task or `task-done` call. It is never rewritten on resume.
   - The final review packages `Base..HEAD`. Every `MERGE_BASE`/`git merge-base main HEAD` reference in both skills is replaced.
2. **Never stops.** Every stop rule is rewritten, not only obra's "four stop classes" paragraph. That covers SDD's continuous-execution line ("The only reasons to stop are the four named below"), the four-classes paragraph, the dot node "Rule and continue; stop only if every path forward is a guess", "Stop only when the defect leaves every path forward a guess", "Only the four classes above stop you here", and executing-plans' "Only the four stops stop you." They become:
   - **Unrecoverable actions** are not taken: anything not recoverable from git history (`git clean`, `reset --hard`, deleting untracked or ignored data, data outside the repo), security-sensitive actions, and outward-facing actions (push, merge, publish). Everything else proceeds; log `Ruling: left for you — <action> — <why>` and continue.
   - **A task whose verification needs such an action** is marked unverified; its dependents proceed and are flagged in the Rulings list. *(My call.)*
   - **A plan broken past guessing:** rule on the most defensible reading; if no path works, abandon the task.
   - **BLOCKED ladder (SDD):**
     1. More context, same model.
     2. One model tier up.
     3. Amend the task once: write the amendment into the brief and ledger it; never edit the plan file or renumber.
     4. Abandon: ledger `Task <N>: Ruling: abandoned — <why> — dependents: <each amended to stand alone, or abandoned too>`.
     
     obra's "break into smaller pieces" step is removed.
   - **Native has no implementer subagent:** its ladder is rule → amend once → abandon.
   - **Items the plan leaves to the builder** are ruled and ledgered the same way.
   - **"Rulings I made"** stays exhaustive. Abandoned tasks, "left for you" actions, unverified tasks, and residual load-bearing findings are listed first. This replaces "residual load-bearing findings surface … when finishing presents the options", and Native's "your human partner decides whether that is enough before merge".
   - `task-reviewer-prompt.md`'s "the human decides" for plan-mandated defects becomes "the controller rules".
3. **Implementer prompt.** Every question-asking instruction in `implementer-prompt.md` is replaced:
   - "Before You Begin" ask-now;
   - "ask questions … Don't guess or make assumptions" while working;
   - the escalate-on-uncertainty / multiple-approaches list;
   - "break the task into smaller pieces".

   The new rule: make the calls the brief leaves open from the brief, plan context and codebase, and record each under a new **Decisions** section of the report. Escalate (BLOCKED / NEEDS_CONTEXT) only for information missing from both brief and repo, a brief that contradicts the code, or repeated failure. Never invent external facts (credentials, accounts, unnamed third-party services).

   SDD's "Implementer asks questions? → Answer questions" nodes, its "If the implementer asks questions" paragraph, and the example where the implementer opens with a question are retargeted: the controller answers from spec, plan and code itself, and never relays the question to the user.
4. **Model selection (Agent-tool aliases `haiku` / `sonnet` / `opus`, no hooks).** Always pass `model` explicitly. Tier follows how much judgment the task's steps leave open, never file count or task size:
   - **Implementer and task reviewer, same rule:**
     - `sonnet` by default.
     - `haiku` when the steps leave essentially nothing to decide (pinned signatures with pinned tests and obvious bodies, config or rename sweeps, batched same-shape edits).
     - `opus` for a design-heavy task, or after `sonnet` returns BLOCKED.
     - The task reviewer is at least `sonnet` when its package exceeds 3,000 lines. *(My call: room to hold a large package coherently.)*
   - Scoped re-reviews: `haiku` or `sonnet`, scaled to the fix diff.
   - Fix-loop escalation (rounds 4–5): at least one tier above the implementer that got stuck (obra's rule).
   - Final whole-branch review: `opus`. Native without a subagent tool reviews in-session.
5. **Line-count header and chunked reads** (obra's `review-package` has no cap to remove).
   - `review-package` writes the total line count into line 1 (`# Review package: BASE..HEAD (<L> lines)`). It keeps its stdout form `wrote <path>: …`, which `test-sdd-workspace.sh` parses.
   - `PLAN_FILE` becomes optional. Without it, the package is written to a `mktemp` file outside the repo.
   - The task reviewer, re-reviewer and final reviewer (`requesting-code-review/code-reviewer.md`) read the package in ~1,000-line chunks via `offset` until the end, and state they read through line L.
   - A report without that statement is re-dispatched once. If the second report also lacks it, the controller rules and ledgers the ruling.
   - `code-reviewer.md` gains a `[DIFF_FILE]` input (added to the placeholder list in `requesting-code-review/SKILL.md`). When none is given, it runs `../subagent-driven-development/scripts/review-package` without a plan.
6. **Hand-off.**
   - The final message carries "Rulings I made" and the plan path.
   - The workspace is **not** deleted. `superpowers-ross:finishing-a-development-branch` is invoked, reads `Base:` and the per-task ranges from the ledger, and deletes the workspace when it is done.
   - The nested-orchestrator section of `claude-code-tools.md` carries the plan path too.

**executing-plans (Native)** gets changes 1, 2 (with its own ladder), 5 and 6, and its final reviewer runs on `opus`. It stays in the repo and writing-plans recommends it when it fits. To match:
- its description and "When to use" are rewritten to the writing-plans criterion (few, coupled tasks; a shipped mistake is cheap; recommended by writing-plans), replacing "your human partner chose inline execution" and "tasks are mostly independent";
- SDD's when-to-use flowchart routes "tightly coupled" to executing-plans.

## 5. finishing-a-development-branch

Replaces obra's worktree-and-menu skill. Invoked after SDD or Native, which already ran the whole-branch review; finishing does no review of its own. It works from a fresh session too, given the plan path.

1. **Tests.** Run the full suite. On failure, report and stop; no squash.
2. **Base.** Read `Base:` from the plan's ledger (`.superpowers/sdd/<plan>/progress.md`). If there is no ledger (e.g. invoked by hand without an executor run), never guess: skip the squash and say why.
3. **Squash or not — no question.** Squash `Base..HEAD` into one commit (`git reset --soft <Base>`, one commit) only when all of these hold:
   - the index and working tree are clean;
   - the range has no merge commits;
   - nothing is interleaved: the ledger's per-task ranges and final-fix range chain contiguously from `Base` to `HEAD`;
   - no commit in the range is on any remote branch (`git branch -r --contains`).

   Otherwise leave history as is and state which check failed. The squash message is derived from the plan's goal and the work done, and names abandoned tasks as not built. Never push or force-push. The spec and plan commits made before `Base` stay outside the squash; this is intended.
4. **Clean up and summarize.** Delete the plan's workspace. Report what was built, key changes, the final commit (or range), and the Rulings list. Stop: no menu, no push/PR offer.

Rationalizations kept from obra: "tests passed earlier", "a rejected push means force-push". Added: "I can infer the base", "the range is close enough to linear". Worktree and menu rows are dropped.

## 6. Other adjustments, tests, docs

- `requesting-code-review`: the BASE_SHA hint `git merge-base origin/main HEAD` is wrong on main. It says to use the executor's recorded `Base:`, or for an ad-hoc review the commit before the work began as stated by the caller.
- `using-superpowers`: prefix rename; keep only the Claude Code tools reference; its skill-flow guidance shows writing-plans → SDD or Native.
- `AGENTS.md`: replaced by a short pointer to `CLAUDE.md` (obra's contributor guidance concerns PRs to obra, which this fork never sends).
- Tests — kept, adjusted:
  - Keep `tests/claude-code`, `tests/hooks`, `tests/brainstorm-server`, the SDD script tests, `tests/version-bump`, `tests/shell-lint`, `tests/writing-skills`, `tests/systematic-debugging`, `tests/diagnosing-superpowers`, `tests/explicit-skill-requests`.
  - `tests/hooks/test-session-start.sh`: delete the Cursor and Copilot cases.
  - `tests/version-bump/test-bump-version.sh`: rewrite for the JSON-only manifests and the `-ross.N` format, with no Hermes/YAML path.
  - `tests/claude-code/test-subagent-driven-development.sh`: remove Test 8 (worktree prerequisite) and invert Test 9 (it now asserts SDD does *not* warn against starting on main).
- Tests — deleted: the worktree tests (and their entry in `run-skill-tests.sh`), and other-harness tests.
- Tests — new: `tests/claude-code/test-fork-validation.sh`, fast and LLM-free, grepping only the swept scope. It pins:
  - no reference to `using-git-worktrees`;
  - writing-plans: no "bite-sized"/"Frequent commits", one-task-per-outcome text present, ends with a single recommendation and no "please review";
  - SDD and executing-plans: no "stop and ask", no "stop only", no `merge-base main`, `Base:` ledger line present;
  - brainstorming: mandatory builder lens, no "please review the document" stop;
  - finishing: no merge/PR/keep menu, no push;
  - `review-package` line-count header;
  - `superpowers-ross` name and `*-ross.N` version consistent across manifests.
- Docs:
  - Rewrite `CLAUDE.md` for the obra base.
  - README = obra's README trimmed to Claude Code plus fork install and the migration step (§1.5), with a rewritten "Divergence from upstream" section. That section gives the per-area conflict policy: re-apply the behaviours above onto obra's structure; finishing is a replacement; removals stay removed; historical files stay obra's. It also carries the rename sweep command with its `:no-sweep:` guard and the sweep scope.
- `evals/` (superpowers-evals checkout) is out of scope.

## Left to the builder

Exact commit boundaries within the ordered series in Section 1; wording of rewritten passages, as long as obra's tuned prose is otherwise preserved; how `bump-version.sh` parses the suffix; exact ledger line format for per-task ranges, as long as finishing can chain them.
