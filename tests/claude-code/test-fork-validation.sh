#!/usr/bin/env bash
# Pins the behaviours this fork re-applies on top of obra/superpowers, so an
# upstream merge that silently reverts one fails here. Fast and LLM-free.
# Greps only the swept scope; obra's historical docs are deliberately excluded.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

failures=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; failures=$((failures + 1)); }

has() { grep -qiE "$2" "$1"; }
check_has() { if has "$1" "$2"; then pass "$3"; else fail "$3"; fi; }
check_lacks() { if has "$1" "$2"; then fail "$3"; else pass "$3"; fi; }

SCOPE=(skills hooks tests scripts .claude-plugin package.json README.md CLAUDE.md AGENTS.md docs/testing.md)
BRAIN=skills/brainstorming/SKILL.md
PLANS=skills/writing-plans/SKILL.md
SDD=skills/subagent-driven-development/SKILL.md
NATIVE=skills/executing-plans/SKILL.md
FINISH=skills/finishing-a-development-branch/SKILL.md

echo "=== Fork validation ==="

echo "Worktrees"
if git grep -qI 'using-git-worktrees' -- "${SCOPE[@]}" ':!tests/claude-code/test-fork-validation.sh' ':!tests/claude-code/test-subagent-driven-development.sh' ':!README.md'; then
    fail "no reference to using-git-worktrees in the swept scope"
else
    pass "no reference to using-git-worktrees in the swept scope"
fi
[ -e skills/using-git-worktrees ] && fail "using-git-worktrees skill is deleted" || pass "using-git-worktrees skill is deleted"

echo "brainstorming"
[ -f skills/brainstorming/spec-panel-prompt.md ] && pass "spec-panel-prompt.md exists" || fail "spec-panel-prompt.md exists"
[ -e skills/brainstorming/builder-check-prompt.md ] && fail "builder-check-prompt.md is gone" || pass "builder-check-prompt.md is gone"
check_has "$BRAIN" 'builder lens' "panel always includes the builder lens"
check_has "$BRAIN" 'parallel' "panel reviewers run in parallel"
check_lacks "$BRAIN" 'please review' "no 'please review' stop"
check_lacks "$BRAIN" 'spec self-review|self-review (step|checklist)' "no self-review step"

echo "writing-plans"
check_lacks "$PLANS" 'bite-sized' "no 'bite-sized'"
check_lacks "$PLANS" 'frequent commits' "no 'Frequent commits'"
check_has "$PLANS" 'one task per outcome|each task is one outcome' "one task per outcome"
check_has "$PLANS" '/compact' "ends recommending /compact"
check_has "$PLANS" '^## Invariants' "plan header has an Invariants section"
check_has "$PLANS" 'anchor' "invariants carry search anchors"
check_has "$PLANS" 'reviewers will check across the codebase' "ending lists the invariants"
check_lacks "$PLANS" 'please review the plan[.?]' "no 'please review the plan'"
check_lacks "$PLANS" 'Merge Pass' "no Merge Pass"

echo "subagent-driven-development and executing-plans"
for f in "$SDD" "$NATIVE"; do
    name=$(basename "$(dirname "$f")")
    check_lacks "$f" 'stop and ask' "$name: no 'stop and ask'"
    check_lacks "$f" 'stop only' "$name: no 'stop only'"
    check_lacks "$f" 'merge-base main|MERGE_BASE' "$name: no merge-base against main"
    check_has "$f" 'Base:' "$name: records Base: in the ledger"
    check_has "$f" 'left for you' "$name: leaves unrecoverable actions for the user"
    check_has "$f" 'opus' "$name: names opus for the whole-branch review"
done
for f in "$SDD" "$NATIVE"; do
    name=$(basename "$(dirname "$f")")
    check_has "$f" '^## Steps \(' "$name: carries a Steps block for the ledger"
    check_has "$f" 'FIRST action' "$name: writes the step list first"
    check_has "$f" 'invariants\.md' "$name: writes invariants for plans without them"
    check_has "$f" 'not fixed — ' "$name: an unfixed final finding needs a ruling"
done
check_lacks "$SDD" '1-2 files' "SDD model selection ignores file count"
[ -f skills/subagent-driven-development/spec-reviewer-prompt.md ] && pass "spec-reviewer-prompt.md exists" || fail "spec-reviewer-prompt.md exists"
[ -f skills/subagent-driven-development/code-quality-reviewer-prompt.md ] && pass "code-quality-reviewer-prompt.md exists" || fail "code-quality-reviewer-prompt.md exists"
[ -e skills/subagent-driven-development/task-reviewer-prompt.md ] && fail "task-reviewer-prompt.md stays deleted" || pass "task-reviewer-prompt.md stays deleted"
check_has "$SDD" "orchestrator's own model" "SDD reviewers run on the orchestrator's model"
check_has "$SDD" 'in PARALLEL|in one message' "SDD dispatches both reviewers in parallel"
check_lacks "$SDD" 'so it can triage' "SDD final review fixes deferred Minors, not triages them"
check_lacks "$NATIVE" 'never enter[[:space:]]+the fix pass|Minors never enter' "Native fix pass includes Minors"
check_has "$NATIVE" 'no behaviour change' "Native verifies no-behaviour fixes by a green suite"
SPECREV=skills/subagent-driven-development/spec-reviewer-prompt.md
check_has "$SPECREV" 'invariant' "spec reviewer checks invariants"
check_has "$SPECREV" 'not only the' "spec reviewer searches beyond the diff"
check_has "$SPECREV" 'search terms' "spec reviewer reports its search terms"
check_has "$SPECREV" 'authority over the brief' "spec reviewer treats the spec as the authority"
check_has skills/requesting-code-review/code-reviewer.md '\[INVARIANTS\]' "final reviewer receives the invariants"
if git grep -qI 'task-reviewer-prompt' -- skills tests ':!tests/claude-code/test-fork-validation.sh'; then
    fail "no reference to task-reviewer-prompt.md"
else
    pass "no reference to task-reviewer-prompt.md"
fi
if sed -n '/^## Steps (/,/^```/p' "$SDD" "$NATIVE" | grep -qE 'Ruling:|\(commits|^Task [0-9N]|^Final review:'; then
    fail "step lists avoid ledger-parsed patterns"
else
    pass "step lists avoid ledger-parsed patterns"
fi
check_lacks skills/subagent-driven-development/implementer-prompt.md 'ask them now|ask questions' "implementer decides instead of asking"
check_has skills/subagent-driven-development/implementer-prompt.md 'Decisions' "implementer reports Decisions"

echo "finishing-a-development-branch"
check_lacks "$FINISH" 'worktree' "no worktree handling"
check_lacks "$FINISH" 'Create a Pull Request|Merge back to' "no merge/PR/keep menu"
check_lacks "$FINISH" 'AskUserQuestion' "never asks"
check_has "$FINISH" 'Base:' "reads Base: from the ledger"
check_has "$FINISH" 'reset --soft' "squashes with reset --soft"

echo "review-package"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(
    cd "$tmp" && git init -q && git config user.email t@t && git config user.name t
    echo a > a && git add a && git commit -qm one
    echo b > b && git add b && git commit -qm two
) >/dev/null 2>&1
out=$(cd "$tmp" && bash "$REPO_ROOT/skills/subagent-driven-development/scripts/review-package" HEAD~1 HEAD 2>&1)
pkg=$(printf '%s\n' "$out" | sed -n 's/^wrote \(.*\): .*$/\1/p')
if [ -n "$pkg" ] && [ -f "$pkg" ]; then
    total=$(wc -l < "$pkg" | tr -d ' ')
    if head -n 1 "$pkg" | grep -qE "^# Review package: .*\(${total} lines\)$"; then
        pass "line 1 carries the package's line count"
    else
        fail "line 1 carries the package's line count (got: $(head -n 1 "$pkg"), total $total)"
    fi
    rm -f "$pkg"
else
    fail "review-package runs without a plan file (output: $out)"
fi

echo "Identity and version"
for f in package.json .claude-plugin/plugin.json; do
    check_has "$f" '"name": "superpowers-ross"' "$f names superpowers-ross"
done
check_has .claude-plugin/marketplace.json '"name": "superpowers-ross-marketplace"' "marketplace is superpowers-ross-marketplace"
versions=$(bash scripts/bump-version.sh --check 2>&1)
if printf '%s\n' "$versions" | grep -qE 'in sync at [0-9]+\.[0-9]+\.[0-9]+-ross\.[0-9]+$'; then
    pass "manifests in sync on a -ross.N version"
else
    fail "manifests in sync on a -ross.N version"
fi
if git grep -qIE '\bsuperpowers:[a-z]' -- skills hooks tests scripts .claude-plugin package.json CLAUDE.md AGENTS.md docs/testing.md ':!tests/claude-code/test-fork-validation.sh'; then
    fail "no un-swept superpowers: prefix"
else
    pass "no un-swept superpowers: prefix"
fi
if grep -q 'no-sweep' README.md; then pass "README sweep guard intact"; else fail "README sweep guard intact"; fi

echo
if [ "$failures" -eq 0 ]; then
    echo "STATUS: PASSED"
else
    echo "STATUS: FAILED ($failures)"
    exit 1
fi
