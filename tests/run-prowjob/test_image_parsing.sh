#!/usr/bin/env bash
#
# Unit tests for run-prowjob Konflux image parsing and external_images patching.
# Includes pull_secret support.
#
# Requires: yq (mikefarah/yq v4+), jq

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract from "# Konflux Image" to "# Release".
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Konflux Image/,/^[[:space:]]*# Release/{
    /# Release/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract image parsing snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: e2e-test
    steps:
      cluster_profile: aws
EOF
}

run_snippet() {
  (
    export SNAPSHOT="$1" COMPONENT_NAME="$2" PULL_SECRET="${3:-}"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: external_images set from snapshot ==="
SNAPSHOT='{"components":[{"name":"my-comp","containerImage":"quay.io/myns/myimage:abc123"}]}'
create_config
run_snippet "$SNAPSHOT" "my-comp"
assert_eq "registry"  "quay.io"  "$(cfg '.external_images.konflux.registry')"
assert_eq "namespace" "myns"     "$(cfg '.external_images.konflux.namespace')"
assert_eq "name"      "myimage"  "$(cfg '.external_images.konflux.name')"
assert_eq "tag"       "abc123"   "$(cfg '.external_images.konflux.tag')"

echo "=== Test: pull_secret added when set ==="
create_config
run_snippet "$SNAPSHOT" "my-comp" "my-pull-secret"
assert_eq "pull_secret set" "my-pull-secret" "$(cfg '.external_images.konflux.pull_secret')"

echo "=== Test: no pull_secret when empty ==="
create_config
run_snippet "$SNAPSHOT" "my-comp" ""
assert_eq "pull_secret absent" "null" "$(cfg '.external_images.konflux.pull_secret')"

echo "=== Test: selects correct component ==="
SNAPSHOT='{"components":[
  {"name":"other","containerImage":"quay.io/ns/other:v1"},
  {"name":"target","containerImage":"registry.redhat.io/prod/target:v2"}
]}'
create_config
run_snippet "$SNAPSHOT" "target"
assert_eq "registry" "registry.redhat.io" "$(cfg '.external_images.konflux.registry')"
assert_eq "name"     "target"             "$(cfg '.external_images.konflux.name')"
assert_eq "tag"      "v2"                 "$(cfg '.external_images.konflux.tag')"

print_results
