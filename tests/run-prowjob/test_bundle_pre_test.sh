#!/usr/bin/env bash
#
# Unit tests for run-prowjob bundle pre-test command injection.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract from "# Bundle pre-test command" to "# Querying config resolver".
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Bundle pre-test command/,/^[[:space:]]*# Querying config resolver/{
    /# Querying config resolver/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract bundle pre-test snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: bundle-test
    steps:
      test:
        - as: deploy
          commands: "deploy command"
EOF
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: no modifications when BUNDLE_PRE_TEST_COMMAND empty ==="
create_config
(
  export BUNDLE_PRE_TEST_COMMAND="" CLOUD_PROVIDER="aws"
  cd "$TMPDIR"
  eval "$SNIPPET"
)
assert_eq "no pre steps" "null" "$(cfg '.tests[0].steps.pre')"

echo "=== Test: pre steps added when command set ==="
create_config
(
  export BUNDLE_PRE_TEST_COMMAND="oc apply -f manifests/" CLOUD_PROVIDER="aws"
  cd "$TMPDIR"
  eval "$SNIPPET"
)
assert_eq "3 pre steps"       "3"                                "$(cfg '.tests[0].steps.pre | length')"
assert_eq "first is ipi chain" "ipi-aws-pre"                    "$(cfg '.tests[0].steps.pre[0].chain')"
assert_eq "second is konflux-pre" "konflux-pre"                 "$(cfg '.tests[0].steps.pre[1].as')"
assert_eq "pre-test command"   "oc apply -f manifests/"         "$(cfg '.tests[0].steps.pre[1].commands')"
assert_eq "third is operator-sdk" "optional-operators-operator-sdk" "$(cfg '.tests[0].steps.pre[2].ref')"

echo "=== Test: ipi chain uses cloud provider ==="
create_config
(
  export BUNDLE_PRE_TEST_COMMAND="echo test" CLOUD_PROVIDER="gcp"
  cd "$TMPDIR"
  eval "$SNIPPET"
)
assert_eq "ipi chain for gcp" "ipi-gcp-pre" "$(cfg '.tests[0].steps.pre[0].chain')"

print_results
