#!/usr/bin/env bash
#
# Unit tests for run-prowjob ci-operator config modifications.
# Tests build_root cleanup, cli deletion, and dockerfile_literal injection.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract the config modification block, excluding the curl download line.
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Modifying ci-op config/,/^[[:space:]]*# Konflux Image/{
    /# Modifying ci-op config/d
    /# Konflux Image/d
    /curl/d
    p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract config modifications snippet"; exit 2; }

SAMPLE_CONFIG='build_root:
  project_image:
    dockerfile_path: Dockerfile
tests:
  - as: e2e-test
    steps:
      test:
        - as: deploy
          commands: "test cmd"
          cli: latest
'

run_snippet() {
  (
    export DOCKERFILE_LITERAL="${1:-FROM scratch}"
    cat > "$TMPDIR/config.yaml" <<< "$SAMPLE_CONFIG"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: build_root.project_image replaced ==="
run_snippet "FROM centos:7"
assert_eq "original project_image removed" "null" "$(cfg '.build_root.project_image.dockerfile_path')"
assert_eq "dockerfile_literal set" "FROM centos:7" "$(cfg '.build_root.project_image.dockerfile_literal')"

echo "=== Test: cli removed from test steps ==="
run_snippet
assert_eq "cli removed" "null" "$(cfg '.tests[0].steps.test[0].cli')"

echo "=== Test: test commands preserved ==="
run_snippet
assert_eq "commands preserved" "test cmd" "$(cfg '.tests[0].steps.test[0].commands')"

print_results
