# Personal-Workflow Fork of Superpowers — Design

**Status:** Approved for planning (revised after adversarial spec review)
**Date:** 2026-06-13
**Author:** Ross (with Claude)

## Goal

Adapt this fork of `pcvelz/superpowers` (itself a fork of `obra/superpowers`) to match the
maintainer's actual single-developer workflow. The changes remove the cross-platform / multi-user
machinery that does not apply (git worktrees, parallel-session execution, manual spec review,
upstream-contribution rules) and bake in the behaviors the maintainer repeatedly instructs by hand
(adversarial spec review, parallel per-task review, autonomous execution, squash-on-finish).

This is a personal fork. There is no PR/upstream obligation. Work happens directly on `master`
(or `main`) unless the user has manually switched to a branch.

## User decisions (already made — quotable)

- **executing-plans:** removed entirely; subagent-driven-development (SDD) is the sole execution path.
- **Squash timing:** final whole-implementation review first, *then* squash.
- **Finishing step:** summarize what was done overall — no menu, no push offer.
- **Adversarial spec review:** runs at the main-conversation tier; the agent chooses its own set of
  adversaries (no fixed panel). Haiku/mechanical tier is reserved for the *per-task* spec reviewer.
- **Model routing:** keep the opt-in routing machinery, but exempt directly-dispatched reviewers from
  the routing gate so their tiers always apply.
- **Parallel review convergence:** after a fix, re-run only the reviewer whose issues were addressed
  (not both).
- **CLAUDE.md:** reduce to a minimal personal-fork identifier.
- **README.md:** full personal-fork rewrite, keeping MIT attribution.
- **Transient artifacts + final doc step:** the spec and plan are transient (deleted shortly after a
  feature ships). The final step of a plan is generally to update any relevant *durable*
  documentation — though most features need none. Nothing outside `docs/superpowers/` may reference
  the spec/plan, and they are never the shipped feature's documentation.

## Non-Goals

- No new third-party dependencies.
- No behavioral change to `test-driven-development`, `systematic-debugging`,
  `dispatching-parallel-agents`, `requesting-code-review`, `receiving-code-review`, `writing-skills`,
  `using-superpowers`, or the user-gate skills (`checking-gates`, `specifying-gates`) — but the latter
  two DO get reference cleanup (they point at the deleted `executing-plans`).
- The `systematic-debugging` "WorktreeManager" mentions are illustrative example code in a debugging
  walkthrough — NOT the git-worktree workflow. Leave them untouched.

## Scope: one plan

All changes land in a single implementation plan. They are coupled: the squash base-SHA handshake
ties SDD↔finishing, the task-creation relocation ties brainstorming→writing-plans→SDD, and the
worktree/`executing-plans` scrub touches files the behavioral changes also edit (e.g. SDD's
Integration block). Splitting risks a broken intermediate state.

---

## Change 1 — `brainstorming`: adversarial spec review replaces manual review

**File:** `skills/brainstorming/SKILL.md`, plus the reviewer prompt template.

The conversational design phase (explore → clarify → propose approaches → present design sections for
approval) is unchanged. The change is everything after the spec is written.

### New flow after design approval

1. Write the spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and **commit it**.
2. **(Optional) inline self-review** — the cheap step-7 placeholder/contradiction pass MAY remain as
   a pre-dispatch sanity check, or be folded into the adversarial review. Implementer's choice; the
   checklist and prose must agree on whichever is chosen.
3. **Adversarial spec review (replaces the "User reviews written spec" gate):**
   - Dispatch **multiple subagents in parallel**, each attacking the spec from a **different
     adversarial perspective**.
   - The agent **chooses the set of adversaries itself** to fit the spec. Do NOT hardcode a fixed
     panel. (Typical perspectives: completeness/consistency, hidden-assumptions/failure-modes,
     scope/YAGNI, integration-with-existing-code — but the agent selects what fits.)
   - Each reviewer runs at the **same model tier as the main conversation** (no model override).
   - Read-only → parallel dispatch is safe.
4. **Fold findings back:**
   - Clear error, gap, or contradiction → fix the spec directly.
   - Genuine open decision → pose it to the user via `AskUserQuestion`.
5. **Commit the revisions** as a second commit (not an amend — keep the review trail visible).
6. Proceed directly to `writing-plans`. There is **no manual user-review prompt** anywhere.

### Removals

- Delete the **"Native Task Integration"** section (the `TaskCreate`-during-design block). Task
  creation moves entirely to SDD (Change 3).
- Delete the **"User Review Gate"** prose block and the corresponding checklist item.

### Reviewer prompt template

Generalize `skills/brainstorming/spec-document-reviewer-prompt.md` (currently a single neutral
reviewer) into an **adversarial reviewer prompt parameterized by perspective** (or add a sibling
template). The prompt instructs the subagent to attack from its assigned perspective and return
structured findings split into **clear-errors** (fix directly) vs **decisions-needed** (surface to
user) so the orchestrator can route them.

### Updated checklist (brainstorming)

1. Explore project context
2. Offer visual companion (if visual questions ahead)
3. Ask clarifying questions
4. Propose 2-3 approaches
5. Present design sections, get approval
6. Write design doc and commit
7. (Optional) inline spec self-review
8. Adversarial spec review (parallel, agent-chosen perspectives, main tier) → fold fixes / surface
   decisions → commit revisions
9. Transition to `writing-plans`

---

## Change 2 — `writing-plans`: write, commit, halt

**File:** `skills/writing-plans/SKILL.md`

### Removals (all relocated to SDD, Change 3)

- **"REQUIRED FIRST STEP: Initialize Task Tracking"** (`TaskList`/`TaskCreate` gate).
- The entire **"Native Task Integration Reference"** section.
- The **"Task Persistence"** section (`.tasks.json` writing).
- The **"Execution Handoff"** `AskUserQuestion` (Subagent-Driven vs. Parallel Session).
- The **"Gate enforcement note"** and **user-gate mechanical-detection/tagging** content (part of
  `TaskCreate`).
- The header "If working in an isolated worktree…" context line.
- The generated plan-doc header string (line ~74) that tells workers to use
  "subagent-driven-development (recommended) or executing-plans" → drop the `executing-plans` mention.

### New terminal behavior

After writing the plan document:
1. **Commit** the plan doc.
2. **STOP** with a short message:
   > Plan written and committed to `<path>`. Recommend `/compact`, then invoke
   > `subagent-driven-development` to execute it.

No task creation, no `.tasks.json`, no execution-method question. The plan `.md` records gate intent
in prose so SDD can act on it during task creation.

---

## Change 3 — `subagent-driven-development`: the core rework

**File:** `skills/subagent-driven-development/SKILL.md`

### 3a. Start-of-skill self-summary

First action on invoking SDD: **read the skill and print a concise numbered summary of the full loop
to itself** before doing anything else (explicit anti-forgetting measure — the observed failure mode
is diving into implementation and skipping reviews). The summary must enumerate:
**capture base SHA → create tasks → per-task (implement → parallel spec+code review → dispatch fixes
→ mark complete) → final whole-implementation review → hand off to `finishing-a-development-branch`
(which squashes + summarizes).**

### 3b. Capture base SHA, then create tasks (relocated from writing-plans)

1. **Capture the base SHA:** run `git rev-parse HEAD` and record it as `baseSha`. This is HEAD before
   any task work and is the squash anchor (Change 4). It is distinct from the per-task `BASE_SHA`
   already used in `code-quality-reviewer-prompt.md`.
2. **Create the native tasks** from the plan document:
   - `TaskCreate` for each task with the full structured body (Goal / Files / Acceptance Criteria /
     Verify) and the embedded `json:metadata` fence.
   - Apply the **user-gate mechanical detection + tagging** logic (moved verbatim from writing-plans).
   - Set `blockedBy` dependencies.
   - Write the co-located `<plan-path>.tasks.json`, including a top-level **`"baseSha"`** field so the
     value survives `/compact` and the separate `finishing-a-development-branch` invocation.

This is the single point where tasks now come into existence.

### 3c. Branch handling

- Work on the **current branch**, whatever it is (usually `master`/`main`). **Never switch branches.**
  If work belongs on a different branch, assume the user switched manually before invoking SDD.
- **Remove** the red flag *"Start implementation on main/master branch without explicit user
  consent"* (SDD ~line 252) — committing to master is now the default.
- **Remove** the `using-git-worktrees` "REQUIRED: Set up isolated workspace" integration line
  (SDD ~line 304) and scrub SDD's own **Integration** block of `using-git-worktrees` and
  `executing-plans` entries.

### 3d. Parallel per-task review (replaces sequential spec-then-code gate)

After the implementer subagent reports `DONE`:
- Dispatch the **spec compliance reviewer** and the **code quality reviewer** **concurrently** (both
  read-only → parallel-safe).
- **Spec reviewer model tier:** cheap / mechanical / haiku, via explicit model override at dispatch.
- **Code reviewer model tier:** same tier as the orchestrator (no override — inherit). **May be
  downgraded or skipped entirely** for small, mechanical, or trivial tasks (orchestrator judgment).
- **Routing-gate exemption (required):** modify `hooks/pre-agent-model-routing` so that
  **directly-dispatched reviewer agents are exempt** from the model-tier gate. Without this, an
  active routing file would block the haiku spec-reviewer (and an inherit code-reviewer) while a
  tiered task is `in_progress`. The exemption must reliably identify reviewer dispatches (e.g. by a
  marker in the dispatch/agent metadata or prompt) and let them through at any tier. Implementers and
  the existing tier routing are unaffected.
- **Remove** the red flags / prose enforcing spec-before-code ordering (*"Start code quality review
  before spec compliance is ✅ (wrong order)"* and the strict sequencing in the process diagram).

### 3e. Fix loop convergence (re-run only the addressed reviewer)

Any follow-up work required by either review is **dispatched to a subagent** — the orchestrator never
performs review follow-up itself **unless it is truly tiny and mechanical**.

After a fix, **re-dispatch only the reviewer whose issues were addressed** (not both). Mark the task
`completed` once each reviewer that ran has approved. (Accepted tradeoff: code approved before a
later spec-driven change is not automatically re-checked against the new diff — chosen for cost.)
Then `TaskUpdate` → completed and sync `.tasks.json`.

### 3f. Autonomy

Execute all tasks start-to-finish without check-ins. Stop only for: an unresolvable `BLOCKED` status,
or a genuinely critical question that prevents progress.

### 3g. End of run

After the last task:
1. Dispatch the **final whole-implementation code reviewer** (orchestrator tier).
2. Fold any final-review fixes **via a subagent**.
3. Hand off to `finishing-a-development-branch`, passing **both the `baseSha`** (or the
   `.tasks.json` path that holds it) **and the plan/spec path** (needed for the squash message).

### 3h. Parallelism red-flag reconciliation

The existing "never dispatch parallel implementers with overlapping files" rule **stays** — it is
about *writers*. The new parallel **reviewers** are read-only and explicitly permitted, consistent
with the existing "Bounded Parallel Dispatch / read-only agents are always parallel-safe" section.

---

## Change 4 — `finishing-a-development-branch`: squash + summary only

**File:** `skills/finishing-a-development-branch/SKILL.md`

Gut the current skill (merge/PR/keep/discard menu, environment/worktree detection, base-branch
detection, worktree cleanup). Replace with:

1. **Verify tests pass.** If failing, stop and report — do not squash.
2. **Resolve the base SHA:** read `baseSha` from `<plan-path>.tasks.json`. Fallback if absent:
   ask the user or skip the squash (never guess).
3. **Squash safety + linearity checks.** The work's commits are `baseSha..HEAD`. **Auto-squash into a
   single commit (via `git reset --soft <baseSha>` + one commit) ONLY when all hold:**
   - `baseSha..HEAD` is **linear** (no merge commits), AND
   - it contains **only this work's commits** (no foreign/interleaved commits), AND
   - **no commit in the range is already on the upstream tracking ref** (check with
     `git merge-base --is-ancestor` against the branch's `@{upstream}` when one exists). Squashing
     already-pushed commits would rewrite published history.

   The squash message is derived from the spec/plan passed in the handoff.
4. **Otherwise (interleaved/foreign commits, or already-pushed work), ask the user** via
   `AskUserQuestion`: (a) perform the squash anyway? and (b) should the squashed message mention the
   other work? **Never force-push** as part of this skill without an explicit user request.
5. **Summarize what was done overall. Nothing else.** No menu, no push offer, no further prompts.

The skill is **kept** (not deleted) because both SDD and the documented main workflow reference it.

---

## Change 5 — Remove git worktrees and `executing-plans` everywhere

### Deletions

- `skills/using-git-worktrees/` — entire skill.
- `skills/executing-plans/` — entire skill.
- `hooks/pre-askuser-handoff-guard` — **entire hook + its settings registration.** Its sole purpose
  was enforcing the writing-plans two-option Execution Handoff `AskUserQuestion`, which Change 2
  removes; nothing remains for it to guard, and removing it prevents it from blocking the new
  `AskUserQuestion` calls (brainstorming decisions, the Change-4 squash prompt).
- `tests/claude-code/test-worktree-native-preference.sh` — entire test.
- `tests/claude-code/test-handoff-guard.sh` — entire test (asserts the removed handoff structure).
- `tests/skill-triggering/prompts/executing-plans.txt` — fixture for the deleted skill.

### Reference scrubbing (repoint `executing-plans` → `subagent-driven-development`; remove worktree refs)

- `skills/checking-gates/SKILL.md` — ~7 `executing-plans` references ("Returns to: executing-plans").
- `skills/specifying-gates/SKILL.md` — ~7 `executing-plans` references.
- `docs/user-gate-flow.md` — built around `executing-plans` as the host flow; repoint to SDD (or
  rewrite the affected sections around SDD).
- `commands/specify-gate.md` — frontmatter "returns control to executing-plans".
- `commands/onboard.md` — drop `executing-plans` from the example skill list (~line 171).
- `commands/execute-plan.md` — currently invokes `executing-plans`; **repoint to
  `subagent-driven-development`.**
- `tests/skill-triggering/run-all.sh` — remove `executing-plans` from the `SKILLS=()` array.
- `hooks/examples/pre-commit-check-tasks.sh` — stale `executing-plans` comment.
- `skills/using-superpowers/references/codex-tools.md` — remove the whole **"Environment Detection"**
  section (lines ~78–96), which is premised on worktree creation and ends "See `using-git-worktrees`".
- `docs/model-routing-flow.md` — reword the future-work bullet (~line 52) that mentions "per-agent
  worktrees" (reword the sentence, don't just delete the clause).
- `tests/claude-code/test-subagent-driven-development.sh` — drop the worktree-requirement assertion;
  add an assertion for parallel spec+code review behavior.

### Keep (do NOT remove — defensive build hygiene, not workflow references)

- `.gitignore` `.worktrees/` entry.
- `scripts/sync-to-codex-plugin.sh` `"/.worktrees/"` rsync exclude.

### Cross-reference sweep

After all edits, `grep -rn 'worktree\|executing-plans\|using-git-worktrees' --include='*.md'
--include='*.sh' --include='*.json'` over the repo (plus the no-extension `hooks/` files) should
return only: the `systematic-debugging` illustrative examples, and the two intentionally-kept
`.worktrees/` build-hygiene entries above.

---

## Change 6 — Documentation rewrite

### `README.md` — full personal-fork rewrite

- Reframe "Why this fork exists" around the maintainer's personal workflow.
- Rewrite "The Basic Workflow" to: brainstorm → adversarial spec review → write-plan (commit + halt)
  → `/compact` → SDD (task creation + parallel per-task review) → final review → squash + summary.
- Keep install instructions, pointing at this fork.
- Drop the vanilla-vs-extended comparison table and all upstream-contribution sections.
- Remove the `using-git-worktrees` workflow/skill-list entries and the `executing-plans` mention in
  the `json:metadata` explanation (~line 143).
- **Keep MIT attribution** to `obra/superpowers` and `pcvelz/superpowers`.

### `CLAUDE.md` — minimal identifier

Replace the entire contents (PR template, 94%-rejection warning, `dev`-branch targeting, "what we
won't accept", new-harness rules) with a **minimal identifier**: a short statement that this is the
maintainer's personal fork of superpowers, plus a pointer to `skills/`. No contribution rules, no PR
machinery, no workflow conventions. `AGENTS.md` is a symlink to `CLAUDE.md` and follows automatically.

### Version bump

Bump the plugin version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

---

## Change 7 — Transient artifacts + final documentation step

The spec (`docs/superpowers/specs/`) and plan (`docs/superpowers/plans/`) are **transient**: they are
typically deleted shortly after the feature ships. Two consequences must be encoded in the skills:

1. **They are never the shipped feature's documentation, and nothing outside `docs/superpowers/` may
   reference them.** Code, comments, docstrings, README, `CLAUDE.md`, durable `docs/` — none may link
   to or depend on a spec/plan file. Internal references *within* `docs/superpowers/` are fine (e.g.
   the plan-doc header pointing at its own execution skill).
2. **The final step of a plan is generally to update any relevant durable documentation** — but
   **most features need none**. This is a conditional step, not a mandate to write docs for trivial
   changes.

### `skills/writing-plans/SKILL.md`

- Add a short principle: specs/plans are transient; the plan must not instruct anyone to reference
  them from outside `docs/superpowers/`, and durable feature documentation (when warranted) lives in
  README / `docs/` outside `docs/superpowers/` / code, never as a pointer to the spec or plan.
- When warranted, the plan's **final task** is "Update relevant documentation." If the feature needs
  no documentation, the plan says so explicitly rather than inventing a doc task.

### `skills/subagent-driven-development/SKILL.md`

- The documentation task (when present) is the last plan task, executed in the normal per-task loop
  (its commit is part of the work that gets squashed in Change 4). Reinforce: do not add external
  references to the spec/plan when updating docs.

### `skills/brainstorming/SKILL.md`

- Note (briefly) that the written spec is a transient design artifact, not the feature's durable
  documentation — so it should not be linked from shipped code or docs.

---

## Model-tier mechanism (cross-cutting reference)

Reviewer model tiers are set **at dispatch time** via the agent/Task `model` parameter. Because this
fork keeps the opt-in routing hooks, `pre-agent-model-routing` is modified to **exempt
directly-dispatched reviewers** (Change 3d) so their tiers apply even when a routing file is active.

| Reviewer | Where | Model tier | Gate |
|----------|-------|-----------|------|
| Adversarial spec reviewers | brainstorming, parallel | Same as main conversation (inherit) | exempt |
| Per-task spec compliance reviewer | SDD, per task | Cheap / mechanical / haiku (override) | exempt |
| Per-task code quality reviewer | SDD, per task | Same as orchestrator (inherit); may downgrade/skip | exempt |
| Final code reviewer | SDD, end of run | Same as orchestrator (inherit) | exempt |

The `pre-taskcreate-model-tier` hook and implementer tier routing are unaffected — they govern plan
*task* implementers, not these directly-dispatched reviewers.

---

## Affected files (summary)

**Skills (edit):** `brainstorming/SKILL.md`, `brainstorming/spec-document-reviewer-prompt.md`,
`writing-plans/SKILL.md`, `subagent-driven-development/SKILL.md`,
`finishing-a-development-branch/SKILL.md`, `checking-gates/SKILL.md`, `specifying-gates/SKILL.md`,
`using-superpowers/references/codex-tools.md`.
**Skills (delete):** `using-git-worktrees/`, `executing-plans/`.
**Hooks:** delete `pre-askuser-handoff-guard` (+ registration); edit `pre-agent-model-routing`
(reviewer exemption); edit `examples/pre-commit-check-tasks.sh` (comment).
**Docs:** `README.md` (rewrite), `CLAUDE.md` (rewrite), `docs/user-gate-flow.md`,
`docs/model-routing-flow.md`.
**Commands:** `execute-plan.md` (repoint), `specify-gate.md`, `onboard.md`.
**Config:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (version bump).
**Tests:** delete `test-worktree-native-preference.sh`, `test-handoff-guard.sh`,
`skill-triggering/prompts/executing-plans.txt`; edit `test-subagent-driven-development.sh`,
`skill-triggering/run-all.sh`.
**Keep untouched:** `.gitignore` + `scripts/sync-to-codex-plugin.sh` `.worktrees/` entries;
`systematic-debugging` illustrative "WorktreeManager" mentions.

## Open risks / verification

- **Base-SHA survival:** `baseSha` MUST be persisted in `.tasks.json` at SDD start (3b) and read by
  finishing (Change 4) — in-memory will not survive `/compact` or the separate skill invocation.
- **Squash on pushed history:** the upstream-tracking check (Change 4 step 3) is the safeguard
  against rewriting published commits; verify it triggers the prompt path and never force-pushes.
- **Routing-gate exemption:** verify reviewers dispatch at their intended tiers with a routing file
  present and active (a tiered task `in_progress`) — i.e. the exemption actually fires.
- **Handoff-guard removal:** deleting the hook + test must leave the suite green; confirm no other
  test references the handoff guard.
- **Reference sweep:** the closing grep (Change 5) should return only the two kept build-hygiene
  entries and the `systematic-debugging` examples.
