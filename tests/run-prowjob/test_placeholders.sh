#!/usr/bin/env bash
#
# Unit tests for run-prowjob placeholder and architecture modifications.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract placeholder modifications block.
PLACEHOLDER_SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Placeholders modifications/,/^[[:space:]]*# Arch specific modifications/{
    /# Arch specific modifications/d; p
  }')
[[ -n "$PLACEHOLDER_SNIPPET" ]] || { echo "FATAL: could not extract placeholders snippet"; exit 2; }

# Extract arch modifications block.
ARCH_SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Arch specific modifications/,/^[[:space:]]*# ENV var modifications/{
    /# ENV var modifications/d; p
  }')
[[ -n "$ARCH_SNIPPET" ]] || { echo "FATAL: could not extract arch snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: e2e-test
    steps:
      test:
        - as: deploy
          commands: "command-placeholder"
          from: "operator-placeholder"
releases:
  latest:
    release:
      architecture: amd64
EOF
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- placeholder tests ---

echo "=== Test: operator-placeholder replaced ==="
create_config
(
  export DEPLOY_TEST_COMMAND="make deploy && make test"
  cd "$TMPDIR"
  eval "$PLACEHOLDER_SNIPPET"
)
assert_eq "operator replaced" "pipeline:konflux" "$(cfg '.tests[0].steps.test[0].from')"

echo "=== Test: command-placeholder replaced ==="
create_config
(
  export DEPLOY_TEST_COMMAND="make deploy test"
  cd "$TMPDIR"
  eval "$PLACEHOLDER_SNIPPET"
)
assert_eq "command replaced" "make deploy test" "$(cfg '.tests[0].steps.test[0].commands')"

# --- arch tests ---

echo "=== Test: amd64 is unchanged (default) ==="
create_config
(
  export ARCHITECTURE="amd64"
  cd "$TMPDIR"
  eval "$ARCH_SNIPPET"
)
assert_eq "architecture unchanged" "amd64" "$(cfg '.releases.latest.release.architecture')"

echo "=== Test: arm64 modifies architecture ==="
create_config
(
  export ARCHITECTURE="arm64"
  cd "$TMPDIR"
  eval "$ARCH_SNIPPET"
)
assert_eq "release arch set to multi" "multi" "$(cfg '.releases.latest.release.architecture')"
# The sed also replaces amd64->arm64 in string values, but yq set multi first

print_results
