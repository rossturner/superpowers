# Superpowers (Ross's fork)

A personal fork of [obra/superpowers](https://github.com/obra/superpowers) (via [pcvelz/superpowers](https://github.com/pcvelz/superpowers)) tuned for Claude Code.

## Why This Fork Exists

This fork shapes Superpowers around a single-developer workflow on Claude Code. The emphasis is on getting a well-specified plan and then letting the session execute it autonomously, with the harness — not model goodwill — keeping things on rails:

- **Adversarial spec review** — once a spec is written and committed, several reviewer subagents critique it in parallel, each from a different perspective, before any code is written.
- **Work on the current branch** — the workflow never switches branches or creates isolated workspaces; everything happens where you already are (usually `master`/`main`).
- **Parallel per-task review** — each task is reviewed by a spec-compliance reviewer and a code-quality reviewer running side by side.
- **Autonomous execution** — once a plan is approved, subagent-driven development runs the whole plan to completion without per-task check-ins.
- **Squash on finish** — completed work is squashed into a single reviewable commit.

### Current Enhancements

| Feature | Description |
|---------|-------------|
| Native Task Management | Dependency tracking, real-time progress visibility |
| Structured Task Metadata | Goal/Files/AC/Verify structure with embedded `json:metadata` |
| Pre-commit Task Gate | Plugin hook blocks `git commit` when tasks are incomplete |
| User-Thrown Gate Enforcement | `userGate` / `user-gate` tag + opt-in hooks force re-validation when Claude closes a user-ordered verification task (see [Recommended Configuration](#recommended-configuration)) |
| Subagent Model Routing | Opt-in per-task model tiers (`mechanical`/`standard`/`frontier`) route plan-execution subagents to cheaper models (see [Subagent Model Routing](#subagent-model-routing--optional-flow)) |
| Configurable Commit Strategy | Opt-in `workflow.json` switches plan execution from per-task commits to a single commit at plan end (see [Commit Strategy](#commit-strategy)) |
| Adversarial Spec Review | Parallel reviewer subagents critique the committed spec from multiple perspectives before planning |
| Parallel Per-Task Review | Spec-compliance and code-quality reviewers run side by side on every task |
| Squash on Finish | Completed work is squashed into a single commit with a summary |

## Installation

### Option 1: Via Marketplace (recommended)

```bash
# Register marketplace
/plugin marketplace add rossturner/superpowers

# Install plugin
/plugin install superpowers-ross@superpowers-ross-marketplace
```

### Option 2: Direct URL

```bash
/plugin install --source url https://github.com/rossturner/superpowers.git
```

### Stay Updated (recommended)

Third-party marketplaces don't auto-update by default — installs stay frozen on the installed version until you refresh. To get future fixes and new optional hooks automatically:

1. Run `/plugin`
2. Open the **Marketplaces** tab
3. Toggle **Enable auto-update** on `superpowers-ross-marketplace`

Or refresh manually any time:

```
/plugin marketplace update superpowers-ross-marketplace
```

### Verify Installation

Run `/superpowers-ross:onboard` for a guided walkthrough of the optional features (model routing, user-gate enforcement, commit strategy). One scope choice governs every write; manual setup is documented below.

## The Basic Workflow

1. **brainstorming** — Activates before writing code. Refines a rough idea through questions, explores alternatives, and presents the design in sections for validation. Writes and commits the spec, then runs an adversarial spec review: several reviewer subagents critique the committed spec in parallel, each from a different perspective. Real fixes are folded in; genuine open decisions are surfaced back to you.

2. **writing-plans** — Activates with the approved design. Breaks the work into one task per outcome the plan names, each with exact file paths, complete code, and verification steps, then runs a merge pass over the finished list to fold together tasks serving the same outcome. Commits the plan document and halts so you can run `/compact` and then invoke subagent-driven-development.

3. **subagent-driven-development** — Activates with the committed plan. Captures the base SHA, builds the native task list from the plan, then for each task: dispatches an implementer, dispatches a spec-compliance reviewer (cheap/haiku tier) and a code-quality reviewer (orchestrator tier) in parallel, dispatches a fix subagent for any findings (re-running only the reviewer whose findings were addressed), and marks the task complete. Runs autonomously to completion.

4. **test-driven-development** — Activates during implementation. Subagents follow RED-GREEN-REFACTOR within each task: write a failing test, watch it fail, write minimal code, watch it pass, commit. Code written before its test is deleted.

5. **finishing-a-development-branch** — Activates when all tasks complete. Dispatches the final whole-implementation review, then squashes the work into a single commit and summarizes it.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## How Native Tasks Work

When `subagent-driven-development` builds the task list from the plan, each task carries structured metadata that survives across sessions and subagent dispatch:

```yaml
TaskCreate:
  subject: "Task 1: Add price validation to optimizer"
  description: |
    **Goal:** Validate input prices before optimization runs.

    **Files:**
    - Modify: `src/optimizer.py:45-60`
    - Create: `tests/test_price_validation.py`

    **Acceptance Criteria:**
    - [ ] Negative prices raise ValueError
    - [ ] Empty price list raises ValueError
    - [ ] Valid prices pass through unchanged

    **Verify:** `pytest tests/test_price_validation.py -v`

    ```json:metadata
    {"files": ["src/optimizer.py", "tests/test_price_validation.py"],
     "verifyCommand": "pytest tests/test_price_validation.py -v",
     "acceptanceCriteria": ["Negative prices raise ValueError",
       "Empty price list raises ValueError",
       "Valid prices pass through unchanged"]}
    ```
```

The `json:metadata` block is embedded in the description because `TaskGet` returns the description but not the `metadata` parameter. This ensures metadata is always available — for `subagent-driven-development` dispatch and `.tasks.json` cross-session resume.

## User-Thrown Gate Enforcement — Optional Flow

*Canonical design doc: [`docs/user-gate-flow.md`](docs/user-gate-flow.md). The section below is a reader-facing summary.*

This flow addresses a recurring failure: the user says "add a gate" or "verify it works" without specifying **how**, the agent invents a verification method, then finds it expensive at execution time and walks around it — closing the gate with an inline shortcut. The fix is a three-layer architecture that *never bothers the user during planning* and only surfaces a forced question when the agent genuinely can't proceed without one.

**The whole flow is opt-in.** It activates only when you register the hooks below in `.claude/settings.json`. The slash command sits dormant without the hook — installing it alone does nothing.

### Design principle — don't bombard the user during planning

Users who want questions will say "brainstorm". Users who ask for a gate during planning just want the work done, they don't want a four-question interrogation. So task-list creation is silent here: it applies the **stricter definition** of a gate and tags liberally. Better to over-tag and let the execution-time hook filter than to over-question the user mid-plan.

### The three layers

| Layer | When | What it does |
|-------|------|--------------|
| **Task creation (silent tagging)** | `subagent-driven-development` builds the task list | Detects gate-language in the brief ("verify", "prove", "gate", "first on one then all", "make sure", "don't proceed until"). Tags the resulting task with `userGate: true` + `tags: ["user-gate"]`. No user questions. Uses the stricter definition: strict user gates AND strict agent gates AND gray-in-between all get tagged. |
| **Gate check (hard trigger via hook)** | Task close / stop | The PostToolUse + Stop hooks fire when a tagged task is closed. The agent must then assess each criterion and choose one of two paths (below). |
| **`/specify-gate` slash command (dormant unless hook active)** | At gate-check time, only when the agent cannot proceed | Asks 3-4 structured questions to the user that lock down the HOW: observable outcome, proof mechanism, scope, failure policy. Produces a structured verify spec the agent consumes. |

### Agent decision at gate-check time

When a tagged task comes up, the agent asks itself: **do I know *how* to verify this?**

- **"Verify the `/health` endpoint returns 200"** → the HOW is self-evident. Agent just hits the endpoint, captures the output, posts `AC: <criterion> — PROVEN BY <evidence>`. No slash command needed. The hook sees the proof and passes.
- **"Check it works"** → the HOW is vague. Agent invokes `/specify-gate`, which asks the user the 3-4 minimal questions, then uses the answers to execute real verification. No silent invention, no inline shortcut.
- **Task tagged `requiresUserSpecification: true`** → same path: invoke `/specify-gate`, ask the user.

The user is only interrupted at gate-check time, and only when the alternative is the agent making something up.

### Activation

Register both hooks in `.claude/settings.json` (see "Recommended Configuration" below for the exact JSON). Without them:
- Task-list creation still tags gates (harmless extra metadata).
- `/specify-gate` still exists but is never triggered automatically.
- Nothing enforces evidence at close — behavior is identical to vanilla.

Install one hook or both. The PostToolUse hook catches per-task closures; the Stop hook catches end-of-plan "everything done" claims. They compose — both firing on the same session is fine.

### Escape hatches

Both hooks fail-open on errors and have env-var kill switches (`SUPERPOWERS_USERGATE_GUARD=0`, `SUPERPOWERS_USERGATE_STOP_GUARD=0`) for one-off session bypasses without editing settings.

### Verify it's working

Tail the hook trace log while a tagged gate task is closing: `tail -F /tmp/claude-hooks/user-gate-trace.log`. See [Hook Trace Logging](#hook-trace-logging) for the full schema.

---

## Subagent Model Routing — Optional Flow

*Canonical design doc: [`docs/model-routing-flow.md`](docs/model-routing-flow.md). The section below is a reader-facing summary.*

This flow addresses a cost problem that frontier-priced models (Opus, Fable) made acute: plan execution via `subagent-driven-development` spawns an implementer plus two reviewers per task — plus re-dispatches for fixes and escalations — and every one of them inherits the session model by default. On a top-tier session, a ten-task plan means thirty-plus top-tier subagent dispatches, most doing work a cheaper model handles fine when the plan is well-specified. Prompt caching does not help here: caching discounts input tokens, while fan-out cost is dominated by freshly generated output. Routing lowers the per-token rate of dispatches; it does not impose token budgets or spend ceilings (see the design doc for boundaries).

**The whole flow is opt-in, with a single switch: `docs/superpowers/model-routing.json` in your project.** The enforcement gates ship with the plugin but are dormant — without that file every check no-ops and behavior is byte-identical to vanilla. No settings to edit, no hooks to register.

### How it works — three harness-enforced layers

Skills prose is not enforcement; agents skip instructions under load. So every layer here is executed by Claude Code's hook system, not volunteered by the model:

| Layer | When | What it does |
|-------|------|--------------|
| **Session notice** (`session-start` hook) | Session start | Routing file detected → the tier rules and your mapping are injected into context. The agent starts the session already knowing the rules. |
| **Plan gate** (`pre-taskcreate-model-tier` hook) | Every `TaskCreate` | A plan task without a valid `"modelTier"` in its `json:metadata` fence is blocked — including plan-shaped tasks (template headers or numbered subjects) that omit the fence entirely; the block message contains the full tier table, so the agent fixes and re-issues without reading anything. |
| **Dispatch gate** (`pre-agent-model-routing` hook) | Every `Agent` dispatch | While tiered tasks are in progress, allows the union of the in-progress tasks' tier models plus the `standard` reviewer model; blocks anything else and names the correct dispatch per role. A concrete `"model"` pin in task metadata overrides the tier (pin enforcement: see [Recommended Configuration](#recommended-configuration)). The spec reviewer (cheap/haiku tier) and code-quality reviewer (session/orchestrator tier) are exempt: `subagent-driven-development` marks their dispatches with `[sdd-review]` in the Agent call description, and the gate lets those through at their own tiers. |

All three gates fail open (parse errors never brick a session) and share a kill switch: `SUPERPOWERS_ROUTING_GUARD=0`.

### The tiers

| Tier | Meaning |
|------|---------|
| `"mechanical"` | The steps hold the code to write, so the task is transcription plus testing. No design judgment. True at any size — file count does not decide this. Most tasks in a well-specified plan. |
| `"standard"` | The steps describe the change in prose. Integration concerns, pattern matching, debugging. |
| `"frontier"` | Design judgment, architecture decisions, broad codebase understanding. |

Tiers are abstract on purpose — plans survive model generations; the routing file decides what they mean today.

### Setup

Prefer a guided setup? Run `/superpowers-ross:onboard` — it asks one multiple-choice question per optional feature and writes the files for you. Manual setup below achieves exactly the same.

Create `docs/superpowers/model-routing.json` in your project:

```json
{"mechanical": "haiku", "standard": "sonnet", "frontier": "inherit"}
```

- Keys are the three tiers; values are Agent `model` values (`haiku`, `sonnet`, `opus`, `fable`).
- `"inherit"` means: omit the model parameter — that tier runs on the session model.
- Mapping all tiers to one model gives a flat cost cap with no per-task gradation.
- Delete the file to switch routing off — the gates go dormant instantly; existing tier annotations become inert metadata.
- **User-level default:** the file may instead live at `~/.claude/superpowers/model-routing.json`, applying to every project that has no project-level file. Lookup is project first, then user — the first file found wins entirely (no merging). A project file of all-`"inherit"` values switches routing off for that project while a user-level default exists.

### Role assignments when routing is on

Implementers (and fix re-dispatches) run at their task's tier. The spec reviewer (cheap/haiku tier) and the code-quality reviewer (session/orchestrator tier) are dispatched at their own tiers and are exempt from the dispatch gate, because `subagent-driven-development` marks their dispatches with `[sdd-review]` in the Agent call description. The final whole-plan reviewer runs after all tasks complete — there is no task in progress, so the dispatch gate does not fire — and should stay at session level: one frontier judgment pass per plan. When an implementer reports BLOCKED and needs more reasoning, escalate one tier up by updating the task's metadata transparently — never silently down.

---

## Workflow Configuration — Optional Flow

*Canonical design doc: [`docs/workflow-config-flow.md`](docs/workflow-config-flow.md). The section below is a reader-facing summary.*

### Commit Strategy

By default, plan execution commits per task: every plan task ends with its own Commit step, and implementer subagents commit their work before review. That default is recommended — frequent commits give fine-grained history and per-task rollback. Projects that prefer a single reviewable commit per plan can opt in to an at-end strategy.

**The whole flow is opt-in, with a single switch: `docs/superpowers/workflow.json` in your project.** Without that file (or without the key), behavior is byte-identical to the default.

```json
{"commitStrategy": "at-end"}
```

When `at-end` is set, a notice injected at session start instructs the agent to:

- write plans without per-task Commit steps;
- end every plan with one final task — "Commit the full implementation" — blocked by all implementation tasks;
- tell implementer subagents not to commit (the coordinator runs that final task, making the single commit), with reviewers reading the uncommitted working-tree diff.

Setup notes:

- Prefer a guided setup? Run `/superpowers-ross:onboard` — it covers this feature alongside the other optional flows.
- Valid values are `"per-task"` (the default) and `"at-end"`; anything else falls back to per-task.
- **User-level default:** the file may instead live at `~/.claude/superpowers/workflow.json`, applying to every project that has no project-level file. Lookup is project first, then user — the first file found wins entirely (no merging). A project file of `{"commitStrategy": "per-task"}` restores per-task commits for that project while a user-level default exists.
- The plan-time side is enforced: a TaskCreate gate blocks plan tasks that carry per-task commit steps while `at-end` is configured (fail-open, kill switch `SUPERPOWERS_WORKFLOW_GUARD=0`). Dispatch-time stays advisory, and the notice takes effect from the next session on (see the design doc for this boundary).
- Undo: delete the file or remove the `commitStrategy` key — per-task commits resume at the next session start.

---

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**
- **brainstorming** - Socratic design refinement + adversarial spec review
- **writing-plans** - Detailed implementation plans, commit and halt
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **finishing-a-development-branch** - Squash + summary
- **subagent-driven-development** - Parallel spec + code review per task, squash on finish

**User-Thrown Gates** (optional flow, see "User-Thrown Gate Enforcement" above)
- **checking-gates** - Do-I-know-HOW self-check for user-gate tasks; runs verify + posts `AC:…PROVEN BY` evidence, or hands off to specifying-gates
- **specifying-gates** - Interactive 4-question AskUserQuestion flow that locks down the HOW for a vague user-gate

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read more: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## Recommended Configuration

### Disable Auto Plan Mode

Claude Code may automatically enter Plan mode during planning tasks, which conflicts with the structured skill workflows in this plugin. To prevent this, add `EnterPlanMode` to your permission deny list.

**In your project's `.claude/settings.json`:**

```json
{
  "permissions": {
    "deny": ["EnterPlanMode"]
  }
}
```

This blocks the model from calling `EnterPlanMode`, ensuring the brainstorming and writing-plans skills operate correctly in normal mode. See [upstream discussion](https://github.com/anthropics/claude-code/issues/23384) for context.

### Block Commits With Incomplete Tasks

Optional `PreToolUse` hook that blocks `git commit` while a native task is `in_progress`. Pending tasks pass through, so per-task commit flows work as intended.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/pre-commit-check-tasks.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/pre-commit-check-tasks.sh` for how it parses the session transcript and which task states count as open.

### Force Re-Validation on User-Thrown Gate Close

Optional `PostToolUse` hook that blocks when Claude closes a **user-thrown gate** task without capturing concrete evidence for every acceptance criterion. A user-thrown gate is any task that carries `"userGate": true` or a `"user-gate"` entry in `tags` inside its `json:metadata` fence — set during task-list creation when the user explicitly asked for a verification step ("make sure to verify X", "add a gate", "prove it on one, then all").

Non-gate tasks pass through silently. The hook only fires when `TaskUpdate` sets status to `completed`.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "TaskUpdate",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/post-task-complete-revalidate.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/post-task-complete-revalidate.sh` for how it parses `json:metadata` and the `USER-ORDERED GATE` banner, and how the `SUPERPOWERS_USERGATE_GUARD=0` escape hatch works.

### Re-Validate Gates on "Plan Complete" Claims

Optional `Stop` hook that complements the PostToolUse hook above. It fires when Claude signals plan completion ("plan complete", "both gates passed", "implementation complete", etc.) but the transcript shows user-thrown gate tasks were closed without subsequent per-criterion proof. Requires Claude to post evidence in the form `AC: <criterion> — PROVEN BY <evidence>` before it can stop.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/stop-revalidate-user-gates.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/stop-revalidate-user-gates.sh` for the full list of completion keywords and the `SUPERPOWERS_USERGATE_STOP_GUARD=0` escape hatch.

### Enforce blockedBy Ordering on in_progress

Optional `PreToolUse` hook on `TaskUpdate` that refuses to move a task into `status=in_progress` while its `blockedBy` list still points at tasks that are not yet `completed`. Motivation: observed failure mode — a coordinator jumps to a later task ("this one is simpler, zero setup") even though its declared prerequisites feed it. The plan meant V0.x to catalog state before V1.x replays consume it; without the catalog, the replay runs blind.

The hook does not silently refuse. Its stderr invites self-assessment first ("is this a hallucination — did you already do this work informally?"), offers three escalation paths (do the blocker, cancel it if truly obsolete, or raise the ordering to the user with AskUserQuestion), and explicitly warns against the bypass move of closing the blocker with status=completed without doing the work.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "TaskUpdate",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/pre-task-blockedby-enforce.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/pre-task-blockedby-enforce.sh` for the transcript-walking logic and the `SUPERPOWERS_BLOCKEDBY_GUARD=0` escape hatch.

### Enforce per-task LLM/dispatch requirements

Optional `PreToolUse` hook on `Agent` that reads the currently in_progress task's `json:metadata` fence and refuses Agent calls that disagree with its `subagentType`, `model`, or `dispatchBrief`. Use when a plan's tasks are sensitive to which tier runs them — empirical measurements, coordinator-quality work, zero-cost batches.

If a task's metadata carries `{"model": "haiku"}` and the coordinator dispatches `model: "opus"`, this hook blocks the call with a stderr explaining the mismatch and three response options (retry with the required params, update metadata transparently, or escalate via AskUserQuestion).

When the task has no dispatch requirement in metadata, the hook passes silently.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/pre-agent-task-dispatch-validate.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/pre-agent-task-dispatch-validate.sh` for the transcript-walking logic and the `SUPERPOWERS_DISPATCH_GUARD=0` escape hatch. Metadata keys are documented in `skills/shared/task-format-reference.md`.

### Force Subagent Evidence on Return

Optional `PostToolUse` hook on `Agent` that fires the moment a subagent's `tool_result` arrives — before the coordinator absorbs it and reports upward. If the in_progress task carries `requireEvidenceTokens` (multi-axis evidence requirement) or the `requireABCompare: true` shortcut, the hook checks that the subagent's report contains at least one token from each axis. Missing axes → block with stderr naming them, forcing immediate re-dispatch rather than "looks good" at close time.

When the task has no evidence requirement in metadata, the hook passes silently.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/post-agent-return-validate.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/post-agent-return-validate.sh` for the metadata schema and the `SUPERPOWERS_AGENT_RETURN_GUARD=0` escape hatch.

### Hook trace log

All three user-gate hooks (post-complete revalidate, stop revalidate, pre-blockedby enforce) write one-line decision traces to `/tmp/claude-hooks/user-gate-trace.log` (override via `SUPERPOWERS_USERGATE_TRACE_LOG`). Tail during development with:

```
tail -F /tmp/claude-hooks/user-gate-trace.log
```

Each line is pipe-separated: `TIMESTAMP | hook-name | task=N | event | reason`. Events include `enter`, `skip`, `parsed`, `scanned`, `pass`, `block`, `error`. Skip reasons identify the short-circuit (e.g. `tool=Bash`, `status=pending`, `superpowers-active`, `guard=0`). This is the fastest way to see why a hook did or did not fire on a specific task.

### Block Low-Context Stop Excuses

Optional `Stop`-event hook that blocks "fresh session later" / "context is full" deflections when real context usage is below 50%.

Opt in via `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/superpowers-ross-marketplace/hooks/examples/stop-deflection-guard.sh"
          }
        ]
      }
    ]
  }
}
```

See the header of `hooks/examples/stop-deflection-guard.sh` for the full list of blocked phrases, configuration environment variables, and fail-open behavior.

## Updating

Skills update automatically when you update the plugin:

```bash
/plugin update superpowers-ross@superpowers-ross-marketplace
```

## Divergence from Upstream

Built on [obra/superpowers](https://github.com/obra/superpowers); the immediate upstream is [pcvelz/superpowers](https://github.com/pcvelz/superpowers). The core Superpowers workflow and skills system come from upstream; the changes below are layered on top.

To pull upstream updates:

```bash
git remote add upstream https://github.com/pcvelz/superpowers.git   # one-time
git fetch upstream
git merge upstream/main   # resolve conflicts with the per-area policy below
```

Every area lists the files it touches and how to resolve a conflict when upstream changes the same file. The `git diff --stat upstream/main..HEAD` is the authoritative full list; this section is the map.

**Resolution stance.** Upstream's structure is the base. When upstream reworks a skill this fork has diverged on, take their rewrite and re-apply the fork behaviors listed below onto it, rather than keeping the fork's older file wholesale. The exception is `finishing-a-development-branch`, where the fork's design is a deliberate replacement for upstream's (see below). The fork versions on its own `7.x` line; upstream's version number never wins a conflict.

### Behavioral changes — re-apply these on top of upstream's structure

**Brainstorming — adversarial spec review.** After the spec is written and committed, parallel reviewer subagents critique it from perspectives the spec-writer chooses, at the main-conversation model tier; clear fixes are folded in, genuine decisions surfaced via AskUserQuestion. There is no manual user spec-review step, and no task creation here — discard upstream's "Native Task Integration" section every time it returns.
- `skills/brainstorming/SKILL.md`, `skills/brainstorming/spec-document-reviewer-prompt.md`

**Writing-plans — write, commit, halt.** The plan is written and committed, then the skill stops (the expectation is `/compact`, then subagent-driven-development). It creates no native tasks and no `.tasks.json`, and has no execution-handoff `AskUserQuestion`; the final plan task updates durable docs where needed. Spec and plan are transient artifacts. Also re-applied: the coarse task granularity below, a **Merge Pass** section that folds adjacent same-outcome tasks after the list is written, and a statement of what a task costs to execute.
- `skills/writing-plans/SKILL.md`

**Task granularity — one task per outcome.** A task is one outcome the plan's Architecture paragraph names, bounded by two tests (Merge, Split). Neither size, file count nor commit count bounds a task, and a task is a range of commits. Upstream sizes a task at one commit and calls a task too big when its commit message needs bullet points; that framing is removed here, because this fork squashes the whole branch at finish and per-task commit size has no effect afterwards. The rationale is that every task costs an implementer dispatch plus two reviewer dispatches in series, so a decomposition finer than the plan's outcomes is paid for in wall-clock time. Upstream's granularity examples table is deleted; the `TDD Within Tasks` subsection is kept verbatim. There is no line ceiling: reviewers read the whole review package in chunks and confirm they reached its last line, so a large task gets a complete review instead of being split to fit one Read call.
- `skills/shared/task-format-reference.md` (Task Granularity section; the `Commit Boundary = Task Boundary` subsection stays deleted)
- `skills/writing-plans/SKILL.md`, `commands/write-plan.md` (the word "bite-sized" stays out of both)
- Pinned by Test 7 in `tests/claude-code/test-fork-validation.sh`

**Subagent-driven-development — fork behaviors on upstream's machinery.** The fork keeps upstream's plan-scoped `.superpowers/sdd/<plan>` workspace and progress ledger, the `scripts/{sdd-workspace,task-brief,review-package}` helpers, the five-round fix loop with its breaker and adjudication rules, and the scoped re-review. Re-applied on top: prints a numbered self-summary of its own steps at start; captures the base SHA into `.tasks.json`; builds the native task list from the plan here, including the user-gate detection and tagging (not in earlier skills); works on the current branch and never switches or creates a worktree; dispatches the spec-compliance reviewer (cheap tier) and code-quality reviewer (orchestrator tier) **in parallel** rather than upstream's single merged task reviewer; re-runs only the reviewer whose findings were addressed; dispatches a subagent for any review follow-up; selects an implementer's model tier on what the task's steps contain rather than on how many files it touches; records the per-task BASE in the ledger so a compaction mid-task cannot truncate the review package; never stops mid-run to ask — it decides plan-vs-finding conflicts, implementer questions and BLOCKED returns itself (re-tier, amend the task once, else abandon it), logs each ruling in the ledger, and reports them at the end as Decisions made; runs autonomously to completion.
- `skills/subagent-driven-development/SKILL.md` (the most-diverged file — merge carefully)
- `spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md` are the fork's split of upstream's `task-reviewer-prompt.md`; keep them in sync with upstream's shared preamble (diff-as-file, don't-trust-the-report, test hygiene, calibration).

**Finishing-a-development-branch — squash on the current branch.** Verifies tests, reads `baseSha` from `.tasks.json`, auto-squashes the work to one commit when the commits are linear/unpushed and the run abandoned no task and parked no load-bearing finding, otherwise asks once. No worktree teardown, and no merge/PR/keep/discard menu. Upstream's version is built entirely around worktrees and that menu, so here the fork's file is a replacement, not a re-application — keep it and graft across only the rationalizations that still apply.
- `skills/finishing-a-development-branch/SKILL.md`

### Removals — keep deleted; discard upstream edits to these paths

**Git worktrees — removed entirely.** This fork never uses worktrees; it works on the current branch.
- Deleted: `skills/using-git-worktrees/SKILL.md`, `tests/claude-code/test-worktree-native-preference.sh`, `tests/claude-code/test-worktree-path-policy.sh`
- If upstream adds worktree references elsewhere, strip them.

**executing-plans skill — removed.** Its task-creation role moved into subagent-driven-development.
- Deleted: `skills/executing-plans/SKILL.md`
- Repointed to subagent-driven-development: `commands/execute-plan.md`, `skills/checking-gates/SKILL.md`, `skills/specifying-gates/SKILL.md`, `docs/user-gate-flow.md`

**AskUserQuestion handoff guard — removed.** Reviewers are exempted from model routing via a `[sdd-review]` dispatch-description marker instead of a handoff hook.
- Deleted: `hooks/pre-askuser-handoff-guard`, `tests/claude-code/test-handoff-guard.sh`
- Modified: `hooks/hooks.json` (dropped the AskUserQuestion matcher), `hooks/pre-agent-model-routing` (added the `[sdd-review]` exemption), `docs/model-routing-flow.md`
- The marker check runs **before** the routing file is read, so it exempts the reviewer from the `enforceEffort` dial as well as the model dial. Test 34 in `tests/claude-code/test-model-routing-hook.sh` pins both, with controls.

**Merged task reviewer — removed.** `skills/subagent-driven-development/task-reviewer-prompt.md` is upstream's single reviewer returning both verdicts; this fork dispatches the split pair in parallel instead.

**Non-Claude-Code harness surface — removed**, in step with upstream, which purged it too.
- Deleted: `.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `.opencode/`, `skills/using-superpowers/references/codex-tools.md`

### Identity & branding — keep this fork's values; re-apply the rename after merging

The plugin is renamed `superpowers-extended:no-sweep:-cc` → `superpowers-ross` (marketplace likewise), with "Superpowers (Ross's fork)" display names. Because the plugin name is also the `superpowers-ross:` skill-invocation prefix, it appears throughout `skills/`, `commands/`, and docs.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `package.json`, `README.md`, `CLAUDE.md`, plus every `superpowers-ross:` reference
- After merging upstream, re-apply the rename in one sweep. **The old name is written below with a `:no-sweep:` marker spliced into it** — strip the marker before running the command. Without the splice, the sweep rewrites this very instruction into `s/superpowers-ross/superpowers-ross/g`, a silent no-op that looks like it worked:
  ```bash
  # remove ':no-sweep:' from both halves before running
  OLD=superpowers-extended:no-sweep:-cc; OLD=${OLD/:no-sweep:/}
  git grep -Il "$OLD" | xargs sed -i "s/$OLD/superpowers-ross/g"
  ```
- After sweeping, re-check this block: `grep -n 'no-sweep' README.md` must still return these lines.

### Additive / mechanical — low conflict risk

- **`.gitignore`**: adds `.idea/`.
- **Fork design spec**: `docs/superpowers/specs/2026-06-13-personal-workflow-fork-design.md` — the original fork design, kept as a historical record. It predates this merge and still describes the pre-merge subagent-driven-development; read it for intent, not for current behavior.
- **Tests updated to match the behavior above**: `tests/claude-code/test-subagent-driven-development.sh` (parallel-review + current-branch assertions), `test-model-routing-hook.sh` (`[sdd-review]` exemption on both dials), `test-fork-validation.sh`.
- **Rename-only edits** elsewhere: `commands/*`, `hooks/session-start`, `hooks/pre-taskcreate-model-tier`, `skills/writing-skills/*` — conflicts here are almost always just the prefix; re-run the sweep above.
- **Upstream test migrations to accept**: upstream replaced `tests/skill-triggering/` and `tests/subagent-driven-dev/` with external "drill" scenarios that do not live in this repo. The deletions were taken; that coverage now sits in [superpowers-evals](https://github.com/prime-radiant-inc/superpowers-evals/).

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: https://github.com/rossturner/superpowers/issues
- **Upstream**: https://github.com/obra/superpowers (via https://github.com/pcvelz/superpowers)
