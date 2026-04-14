#!/usr/bin/env bash
# Common test helpers shared across all task tests.
# Sourced by task-specific helpers.sh files.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description (expected '$expected', got '$actual')"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local description="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description (expected to contain '$needle')"
    FAIL=$((FAIL + 1))
  fi
}

print_results() {
  echo ""
  echo "--- Results: $PASS passed, $FAIL failed ---"
  [[ $FAIL -eq 0 ]]
}
