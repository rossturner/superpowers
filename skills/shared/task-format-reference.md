# Native Task Format Reference

Skills that create native tasks (TaskCreate) MUST follow this format.

## Subject

Keep subjects compact (aim for ≤ 60 characters, no trailing detail). The harness re-injects every task's subject line into context during periodic reminders, so long subjects are paid for repeatedly. Details belong in the description.

## Task Description Template

Every TaskCreate description MUST follow this structure:

### Required Sections

**Goal:** One sentence — what this task produces (not how).

**Files:**
- Create/Modify/Delete: `exact/path/to/file.py` (with line ranges for modifications)

**Acceptance Criteria:**
- [ ] Concrete, testable criterion
- [ ] Another criterion

**Verify:** `exact command to run` → expected output summary

### Optional Sections (include when relevant)

**Context:** Why this task exists, what depends on it, architectural notes.
Only needed when the task can't be understood from Goal + Files alone.

**Steps:** Ordered implementation steps (only for multi-step tasks where order matters).
TDD cycles happen WITHIN steps, not as separate steps.

## Metadata Schema

Embed metadata as a `json:metadata` code fence at the end of the TaskCreate description. The `metadata` parameter on TaskCreate is accepted but **not returned by TaskGet** — embedding in the description is the only reliable way.

| Key | Type | Required | Purpose |
|-----|------|----------|---------|
| `files` | string[] | yes | Paths to create/modify/delete |
| `verifyCommand` | string | yes | Command to verify task completion |
| `acceptanceCriteria` | string[] | yes | List of testable criteria |
| `estimatedScope` | "small" \| "medium" \| "large" | no | Relative effort indicator |
| `userGate` | boolean | no | `true` when the user explicitly requested this task as a verification gate. Signals to hooks and reviewers that the task is USER-ORDERED and MUST NOT be closed until its `acceptanceCriteria` have been re-validated independently. See "User-Thrown Gates" below. |
| `tags` | string[] | no | Free-form tags (e.g. `["user-gate", "verification"]`). Opt-in hooks key off tags like `user-gate` to trigger re-validation on close. |
| `requiresUserSpecification` | boolean | no | Set by `writing-plans` when the user's brief says WHAT should be verified but not HOW. Signals to `/gate-check` that it must hand off to `/specify-gate` before running verification. Removed automatically once `/specify-gate` has captured the HOW. |
| `gateScope` | "once" \| "per-target" \| "one-then-all" \| string | no | How many times / across how many targets the gate should run. Set by `/specify-gate` (Q3). Free-form string allowed for custom rules. |
| `failurePolicy` | "stop-plan" \| "reopen-continue" \| "log-continue" | no | What happens if the gate fails. Set by `/specify-gate` (Q4). |
| `subagentBrief` | string | no | Exact prompt/briefing for the dispatch subagent when the gate's proof mechanism is "subagent". Set by `/specify-gate` (Q5). Agent MUST pass this verbatim at dispatch — substituting a shorter version defeats the purpose. |
| `subagentType` | string | no | Required `subagent_type` value for Agent dispatches during this task (e.g. `general-purpose`, `local`, `Explore`). The `pre-agent-task-dispatch-validate` hook blocks Agent calls that disagree. |
| `model` | string | no | Required `model` value for Agent dispatches during this task (e.g. `haiku`, `sonnet`, `opus`). Use when the task is sensitive to tier choice — empirical A/B measurements need a pinned model, coordinator quality calls need Opus, cheap bulk work needs Haiku. Enforced by `pre-agent-task-dispatch-validate` when the hook is registered. Overrides `modelTier`. |
| `modelTier` | "mechanical" \| "standard" \| "frontier" | no | Abstract capability tier for subagents executing this task. Belongs to the opt-in model-routing flow: when the routing file exists (project `docs/superpowers/model-routing.json`, else user-level `~/.claude/superpowers/model-routing.json`), plugin gates require it on every plan task (`pre-taskcreate-model-tier`) and enforce the resolved Agent `model` at dispatch (`pre-agent-model-routing`); the session-start notice carries the rules. File absent → gates are dormant, the key is inert metadata, and every subagent inherits the session model. `"inherit"` as a mapping value means omit the Agent `model` param. A concrete `model` pin (above) always wins over the tier. Full design: `docs/model-routing-flow.md`. |
| `dispatchBrief` | string | no | Substring that the Agent `prompt` MUST contain verbatim. Use for dispatches where a specific preamble is mandatory (e.g. `COMMIT EXECUTOR SUBAGENT`, `local 35`). Checked as a substring match — stricter than `subagentBrief` which is prescriptive for a specific gate-check dispatch. |
| `requireEvidenceTokens` | string[][] | no | List of evidence axes. Each axis is a list of alternative tokens; the close window (assistant text + tool_result content) must contain at least one token from EACH axis. Fully generic: 2 axes for A/B, 3+ for multi-arm experiments, arbitrary tokens for domain-specific pairs (`v2`/`v3` for migration, `control`/`variant-a`/`variant-b` for 3-arm perf, `vulnerable`/`patched` for security, etc.). Enforced by `post-task-complete-revalidate`. |
| `requireABCompare` | boolean | no | Shortcut for the canonical before/after pair. Equivalent to `requireEvidenceTokens: [["baseline","old","before","v0","v1","iter-0","iter0","original","pre"], ["new","refactored","after","v2","iter-1","iter1","post","updated","replacement"]]`. Use for empirical refactors where the default tokens match your vocabulary. For any other domain, use `requireEvidenceTokens` directly. |

## User-Thrown Gates

A **user-thrown gate** is a verification task the user *explicitly asked for in the conversation* — not a check you invented while decomposing the plan. Typical signals in the user's message: "make sure to verify X before moving on", "add a gate", "run the full end-to-end before closing", "don't proceed until Y is proven", "first on one, then on all".

When you create such a task, set BOTH:
- `userGate: true`
- `tags: ["user-gate"]` (append, do not replace existing tags)

And add a mandatory line in the task description, verbatim:

> **USER-ORDERED GATE — NON-SKIPPABLE.** This task was requested by the user in the current conversation. It MUST NOT be closed by walking around it, by declaring it "verified inline", or by substituting a cheaper check. Close only after every item in `acceptanceCriteria` has been re-validated independently, with output captured.

Why both the flag and the prose: the prose protects the current session (visible to TaskGet), the flag protects future hooks and subagents that parse metadata.

### Example — user-thrown gate

```yaml
TaskCreate:
  subject: "Gate 1: End-to-end verification on one instance"
  description: |
    **Goal:** Prove the full pipeline works on exactly ONE instance before scaling to all.

    **USER-ORDERED GATE — NON-SKIPPABLE.** This task was requested by the user in the current conversation. It MUST NOT be closed by walking around it, by declaring it "verified inline", or by substituting a cheaper check. Close only after every item in `acceptanceCriteria` has been re-validated independently, with output captured.

    **Acceptance Criteria:**
    - [ ] Fresh instance spun up from scratch
    - [ ] Sonnet subagent dispatched with its briefing (no inline shortcut)
    - [ ] JIT event captured in notification_message
    - [ ] Manager scrape shows the event

    **Verify:** `./zoo.sh status <tag>` + `cat logs/<tag>.jsonl | tail -1`

    ```json:metadata
    {"files": [], "verifyCommand": "./zoo.sh status v0.1.15 && cat logs/v0.1.15.jsonl | tail -1", "acceptanceCriteria": ["Fresh instance spun up from scratch", "Sonnet subagent dispatched with its briefing", "JIT event captured in notification_message", "Manager scrape shows the event"], "userGate": true, "tags": ["user-gate", "verification"]}
    ```
```

### Example

```yaml
TaskCreate:
  subject: "Add JIT selection prompt to /hame Pre-flight"
  description: |
    **Goal:** Replace auto-latest JIT selection with interactive 3-option prompt.

    **Files:**
    - Modify: `.claude/commands/hame-optimal-cycle-inspection.md:45-60`

    **Acceptance Criteria:**
    - [ ] AskUserQuestion presents 3 most recent JIT messages
    - [ ] Selected JIT's SOC and schedule are parsed into variables
    - [ ] --jit override bypasses the prompt (backwards compat)

    **Verify:** Read the Pre-flight Step 2 section and confirm AskUserQuestion block with 3 JIT options

    ```json:metadata
    {"files": [".claude/commands/hame-optimal-cycle-inspection.md"], "verifyCommand": "grep -A 20 'Step 2' .claude/commands/hame-optimal-cycle-inspection.md", "acceptanceCriteria": ["AskUserQuestion with 3 JIT options", "SOC + schedule parsed from selection", "--jit override bypasses prompt"]}
    ```
```

## Task Granularity

### The Right Scope

A task is **one outcome**. A plan names its outcomes in the Architecture paragraph of its header, and that paragraph is the authority on what counts as one. The File Structure section lists the files each outcome touches.

Three tests decide where a task begins and ends.

**Merge.** Adjacent tasks serving one outcome are one task. A task that cannot be verified on its own serves another task's outcome, and it merges into that task.

**Split.** A task holding two outcomes is two tasks, where each outcome stands on its own and the plan makes sense with either one built alone.

**Ceiling.** A task is too large when its Goal needs more than one sentence to state the outcome, or when the code in its steps runs past roughly 600 lines. A reviewer reads its diff as one file, and `git diff -U10` turns one changed line into about three lines of that file, so past 600 lines of code the reviewer reads part of the change and returns a verdict on the part it read.

A task spans as many files and as many commits as its outcome takes. Neither file count nor commit count bounds a task. Every task costs a brief file, an implementer dispatch, a review package and two reviewer dispatches at execution, and those dispatches run in series, so a decomposition finer than the outcomes buys nothing and is paid for in wall-clock time.

### TDD Within Tasks (Not Across Tasks)

TDD cycles (write test → verify fail → implement → verify pass) happen WITHIN a single task, not as separate tasks. The task is "Implement X with tests" — the TDD steps are execution detail, not task boundaries.
