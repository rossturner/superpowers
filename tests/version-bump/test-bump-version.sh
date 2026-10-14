#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_SOURCE="$REPO_ROOT/scripts/bump-version.sh"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_fixture() {
  local repo="$1"

  mkdir -p "$repo/scripts" "$repo/.claude-plugin"
  cp "$SCRIPT_SOURCE" "$repo/scripts/bump-version.sh"
  cat >"$repo/.version-bump.json" <<'JSON'
{
  "files": [
    { "path": "package.json", "field": "version" },
    { "path": ".claude-plugin/marketplace.json", "field": "plugins.0.version" }
  ],
  "audit": { "exclude": [] }
}
JSON
  cat >"$repo/package.json" <<'JSON'
{
  "name": "fixture",
  "version": "1.2.3-ross.1"
}
JSON
  cat >"$repo/.claude-plugin/marketplace.json" <<'JSON'
{
  "name": "fixture-marketplace",
  "plugins": [{ "name": "fixture", "version": "1.2.3-ross.1" }]
}
JSON
}

happy_repo="$TEST_ROOT/happy"
make_fixture "$happy_repo"

/bin/bash "$happy_repo/scripts/bump-version.sh" --check >"$TEST_ROOT/check.out"
/bin/bash "$happy_repo/scripts/bump-version.sh" --audit >"$TEST_ROOT/audit.out"
/bin/bash "$happy_repo/scripts/bump-version.sh" 2.3.4-ross.1 >"$TEST_ROOT/bump.out"

[[ "$(jq -r '.version' "$happy_repo/package.json")" == "2.3.4-ross.1" ]] \
  || fail "top-level version was not bumped"
[[ "$(jq -r '.plugins[0].version' "$happy_repo/.claude-plugin/marketplace.json")" == "2.3.4-ross.1" ]] \
  || fail "nested marketplace version was not bumped"

for bad in 2.3.4 2.3.4-ross 2.3.4-dev.1 2.3.4-ross.1x; do
  invalid_repo="$TEST_ROOT/invalid-$bad"
  make_fixture "$invalid_repo"
  cp "$invalid_repo/package.json" "$TEST_ROOT/package.before"
  if /bin/bash "$invalid_repo/scripts/bump-version.sh" "$bad" >"$TEST_ROOT/invalid.out" 2>&1; then
    fail "bump accepted '$bad', which is not X.Y.Z-ross.N"
  fi
  cmp -s "$TEST_ROOT/package.before" "$invalid_repo/package.json" \
    || fail "manifest changed after rejecting '$bad'"
done

jq -e '[.files[].path] | sort == [".claude-plugin/marketplace.json", ".claude-plugin/plugin.json", "package.json"]' \
  "$REPO_ROOT/.version-bump.json" >/dev/null \
  || fail ".version-bump.json must list exactly the Claude Code manifests"

audit_repo="$TEST_ROOT/audit-boundaries"
make_fixture "$audit_repo"
/bin/bash "$audit_repo/scripts/bump-version.sh" 4.0.0-ross.2 >/dev/null
printf 'pin: superpowers.git#v4.0.0-ross.2\n' >"$audit_repo/INSTALL.md"
printf 'Built on obra v4.0.0.\n' >"$audit_repo/NOTES.md"
/bin/bash "$audit_repo/scripts/bump-version.sh" --audit >"$TEST_ROOT/audit-boundaries.out"

grep -q 'INSTALL.md' "$TEST_ROOT/audit-boundaries.out" \
  || fail "audit missed an undeclared #v4.0.0-ross.2 pin"
if grep -q 'NOTES.md' "$TEST_ROOT/audit-boundaries.out"; then
  fail "audit flagged the obra base version 4.0.0 as 4.0.0-ross.2"
fi

echo "Version-bump tests passed"
