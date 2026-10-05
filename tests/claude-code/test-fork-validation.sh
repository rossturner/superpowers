#!/usr/bin/env bash
# Test: Fork-specific invariants (deterministic, no LLM)
# Catches upstream drift: wrong plugin names, TodoWrite leaks, missing native tasks
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILED=0

echo "=== Test: Fork Validation ==="
echo ""

# 1. Plugin name must be superpowers-ross in metadata
echo "Test 1: Plugin name consistency..."
NAME_FAIL=0
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    if ! grep -q "superpowers-ross" "$REPO_ROOT/$f"; then
        echo "  [FAIL] $f missing superpowers-ross"
        NAME_FAIL=$((NAME_FAIL + 1))
    fi
done
if [ $NAME_FAIL -gt 0 ]; then
    FAILED=$((FAILED + NAME_FAIL))
else
    echo "  [PASS] Plugin name consistent"
fi

# 2. No TodoWrite/TodoRead references in skills (must be TaskCreate/TaskList)
#    Excludes references/ dirs (cross-platform tool mapping tables mention TodoWrite legitimately)
echo "Test 2: No legacy task references in skills..."
LEGACY=$(grep -rn "TodoWrite\|TodoRead" "$REPO_ROOT/skills/" --include="*.md" \
    | grep -v "/references/" \
    || true)
if [ -n "$LEGACY" ]; then
    echo "  [FAIL] Found TodoWrite/TodoRead in skills:"
    echo "$LEGACY"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No legacy task references"
fi

# 3. Skill references use superpowers-ross: prefix (not bare superpowers:)
echo "Test 3: Skill prefix consistency..."
BARE=$(grep -rn "superpowers:" "$REPO_ROOT/skills/" "$REPO_ROOT/commands/" "$REPO_ROOT/hooks/" 2>/dev/null \
    | grep -v "superpowers-ross:" \
    | grep -v "superpowers-ross" \
    | grep -v "obra/superpowers" \
    | grep -v "github.com" \
    | grep -v "\.git" \
    || true)
if [ -n "$BARE" ]; then
    echo "  [FAIL] Found bare 'superpowers:' prefix (should be superpowers-ross:):"
    echo "$BARE"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] All skill refs use correct prefix"
fi

# 4. No RELEASE-NOTES.md (we use GitHub releases)
echo "Test 4: No RELEASE-NOTES.md..."
if [ -f "$REPO_ROOT/RELEASE-NOTES.md" ]; then
    echo "  [FAIL] RELEASE-NOTES.md should not exist in our fork"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No RELEASE-NOTES.md"
fi

# 5. Task creation lives ONLY in subagent-driven-development.
# Fork divergence: brainstorming and writing-plans create no native tasks — that
# role was absorbed into subagent-driven-development. Upstream keeps re-adding a
# "Native Task Integration" section to both on merge, so this asserts both
# directions: absent where the fork removed it, present where the fork moved it.
echo "Test 5: Task creation confined to subagent-driven-development..."
NATIVE_FAIL=0
for skill in writing-plans brainstorming; do
    if grep -q "Native Task" "$REPO_ROOT/skills/$skill/SKILL.md" 2>/dev/null; then
        echo "  [FAIL] skills/$skill/SKILL.md has a Native Task section — upstream's task creation crept back in"
        NATIVE_FAIL=$((NATIVE_FAIL + 1))
    fi
done
for skill in subagent-driven-development dispatching-parallel-agents; do
    if ! grep -qi "TaskCreate\|Native Task" "$REPO_ROOT/skills/$skill/SKILL.md" 2>/dev/null; then
        echo "  [FAIL] skills/$skill/SKILL.md missing task-creation content"
        NATIVE_FAIL=$((NATIVE_FAIL + 1))
    fi
done
if [ $NATIVE_FAIL -gt 0 ]; then
    FAILED=$((FAILED + NATIVE_FAIL))
else
    echo "  [PASS] Task creation confined to subagent-driven-development"
fi

# 6. No docs/plans/ in tracked files (development artifacts)
echo "Test 6: No docs/plans/ in tracked files..."
if git -C "$REPO_ROOT" ls-files | grep -q "^docs/plans/"; then
    echo "  [FAIL] docs/plans/ contains tracked files (should be excluded):"
    git -C "$REPO_ROOT" ls-files | grep "^docs/plans/"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No docs/plans/ in tracked files"
fi

# 7. Coarse task granularity.
# Fork divergence: a task is one outcome, and neither size, file count nor commit
# count bounds it. Upstream sizes a task at one commit and asks for bite-sized
# tasks, so a merge re-introduces the phrases below. No line ceiling either:
# reviewers read the whole package in chunks instead. Anchored on short strings
# so an upstream rewording still trips the check.
echo "Test 7: Coarse task granularity..."
GRANULARITY_FAIL=0
check_absent() {
    if grep -qi "$1" "$REPO_ROOT/$2" 2>/dev/null; then
        echo "  [FAIL] $2 contains '$1' — upstream's fine-grained task sizing crept back in"
        GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
    fi
}
for f in skills/writing-plans/SKILL.md commands/write-plan.md; do
    check_absent "bite-sized" "$f"
done
# README's Divergence section names "bite-sized" on purpose, to say what a merge
# must strip, so assert on the workflow description instead of the whole file.
if ! grep -q "one task per outcome" "$REPO_ROOT/README.md" 2>/dev/null; then
    echo "  [FAIL] README.md no longer describes writing-plans as one task per outcome"
    GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
fi
check_absent "Commit Boundary = Task Boundary" skills/shared/task-format-reference.md
check_absent "more than one concern" skills/shared/task-format-reference.md
check_absent "more than one concern" skills/writing-plans/SKILL.md
check_absent "bullet points" skills/shared/task-format-reference.md
for f in skills/writing-plans/SKILL.md skills/shared/task-format-reference.md; do
    check_absent "**Ceiling.**" "$f"
    check_absent "600 lines" "$f"
    if ! grep -qF "is holding two outcomes" "$REPO_ROOT/$f" 2>/dev/null; then
        echo "  [FAIL] $f lost the one-sentence Goal rule in Split"
        GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
    fi
done
for f in skills/subagent-driven-development/spec-reviewer-prompt.md \
         skills/subagent-driven-development/code-quality-reviewer-prompt.md \
         skills/subagent-driven-development/re-review-prompt.md \
         skills/requesting-code-review/code-reviewer.md; do
    if ! grep -qF "read through line" "$REPO_ROOT/$f" 2>/dev/null; then
        echo "  [FAIL] $f does not require reading the whole review package"
        GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
    fi
done
check_absent "oversize package" skills/subagent-driven-development/SKILL.md
# The two tests and the TDD subsection must survive the same merge.
for phrase in "**Merge.**" "**Split.**" "TDD Within Tasks"; do
    if ! grep -qF "$phrase" "$REPO_ROOT/skills/shared/task-format-reference.md" 2>/dev/null; then
        echo "  [FAIL] skills/shared/task-format-reference.md lost '$phrase'"
        GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
    fi
done
if ! grep -q "Merge Pass" "$REPO_ROOT/skills/writing-plans/SKILL.md" 2>/dev/null; then
    echo "  [FAIL] skills/writing-plans/SKILL.md lost the Merge Pass section"
    GRANULARITY_FAIL=$((GRANULARITY_FAIL + 1))
fi
if [ $GRANULARITY_FAIL -gt 0 ]; then
    FAILED=$((FAILED + GRANULARITY_FAIL))
else
    echo "  [PASS] Task granularity rules intact"
fi

# 8. Autonomous execution.
# Fork divergence: subagent-driven-development never stops mid-run to ask the
# user; it decides, logs the ruling, and reports it at the end. Upstream asks
# which governs, escalates to the human, and tells implementers not to guess.
echo "Test 8: Autonomous execution..."
AUTONOMY_FAIL=0
check_autonomy_absent() {
    if grep -qi "$1" "$REPO_ROOT/$2" 2>/dev/null; then
        echo "  [FAIL] $2 contains '$1' — a mid-run stop crept back in"
        AUTONOMY_FAIL=$((AUTONOMY_FAIL + 1))
    fi
}
for phrase in "which governs" "escalate to the human" "report BLOCKED" "oversize package"; do
    check_autonomy_absent "$phrase" skills/subagent-driven-development/SKILL.md
done
for phrase in "Ask them now" "Don't guess"; do
    check_autonomy_absent "$phrase" skills/subagent-driven-development/implementer-prompt.md
done
if ! grep -q "Never stop mid-run" "$REPO_ROOT/skills/subagent-driven-development/SKILL.md" 2>/dev/null; then
    echo "  [FAIL] skills/subagent-driven-development/SKILL.md lost 'Never stop mid-run'"
    AUTONOMY_FAIL=$((AUTONOMY_FAIL + 1))
fi
if [ $AUTONOMY_FAIL -gt 0 ]; then
    FAILED=$((FAILED + AUTONOMY_FAIL))
else
    echo "  [PASS] Autonomous execution rules intact"
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== All fork validation tests passed ==="
    exit 0
else
    echo "=== FAILED: $FAILED fork validation checks ==="
    exit 1
fi
