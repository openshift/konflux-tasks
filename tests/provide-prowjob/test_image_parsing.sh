#!/usr/bin/env bash
#
# Unit tests for Konflux image parsing.
# Validates extraction of registry, namespace, name, and tag from snapshot.
#
# Requires: yq (mikefarah/yq v4+), jq

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

# Extract the image parsing block (from "# Konflux Image" to "# Modifying ci-op config").
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Konflux Image/,/^[[:space:]]*# Modifying ci-op config/{
    /# Modifying ci-op config/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract image parsing snippet"; exit 2; }

# Run the snippet and return REGISTRY|NAMESPACE|NAME|TAG.
run_snippet() {
  (
    export SNAPSHOT="$1" COMPONENT_NAME="$2"
    eval "$SNIPPET"
    echo "${REGISTRY}|${NAMESPACE}|${NAME}|${TAG}"
  )
}

# --- tests ---

echo "=== Test: standard quay.io image ==="
SNAPSHOT='{"components":[{"name":"my-comp","containerImage":"quay.io/myns/myimage:abc123"}]}'
RESULT=$(run_snippet "$SNAPSHOT" "my-comp")
assert_eq "registry"  "quay.io"  "$(echo "$RESULT" | cut -d'|' -f1)"
assert_eq "namespace" "myns"     "$(echo "$RESULT" | cut -d'|' -f2)"
assert_eq "name"      "myimage"  "$(echo "$RESULT" | cut -d'|' -f3)"
assert_eq "tag"       "abc123"   "$(echo "$RESULT" | cut -d'|' -f4)"

echo "=== Test: registry.redhat.io image ==="
SNAPSHOT='{"components":[{"name":"comp","containerImage":"registry.redhat.io/product/image:v1.0"}]}'
RESULT=$(run_snippet "$SNAPSHOT" "comp")
assert_eq "registry"  "registry.redhat.io" "$(echo "$RESULT" | cut -d'|' -f1)"
assert_eq "namespace" "product"            "$(echo "$RESULT" | cut -d'|' -f2)"
assert_eq "name"      "image"              "$(echo "$RESULT" | cut -d'|' -f3)"
assert_eq "tag"       "v1.0"               "$(echo "$RESULT" | cut -d'|' -f4)"

echo "=== Test: selects correct component from multiple ==="
SNAPSHOT='{"components":[
  {"name":"other","containerImage":"quay.io/ns/other:v1"},
  {"name":"target","containerImage":"quay.io/ns/target:v2"}
]}'
RESULT=$(run_snippet "$SNAPSHOT" "target")
assert_eq "name" "target" "$(echo "$RESULT" | cut -d'|' -f3)"
assert_eq "tag"  "v2"     "$(echo "$RESULT" | cut -d'|' -f4)"

echo "=== Test: sha-style tag ==="
SNAPSHOT='{"components":[{"name":"c","containerImage":"quay.io/ns/img:sha256-deadbeef1234"}]}'
RESULT=$(run_snippet "$SNAPSHOT" "c")
assert_eq "tag" "sha256-deadbeef1234" "$(echo "$RESULT" | cut -d'|' -f4)"

print_results
