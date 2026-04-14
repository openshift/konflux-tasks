#!/usr/bin/env bash
#
# Unit tests for ci-operator config modifications.
# Validates build_root cleanup, images/operator removal, dockerfile injection,
# and external_images patching.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract the config modification block (from "# Modifying ci-op config" to "# Filter tests").
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Modifying ci-op config/,/^[[:space:]]*# Filter tests/{
    /# Filter tests/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract config modifications snippet"; exit 2; }

SAMPLE_CONFIG='build_root:
  project_image:
    dockerfile_path: Dockerfile
  from_repository: true
images:
  - name: test-image
operator:
  bundles:
    - name: test-bundle
tests:
  - as: e2e-aws
    steps:
      cluster_profile: aws
'

run_snippet() {
  (
    export CI_OPERATOR_CONFIG="$1"
    export INCLUDE_IMAGES="${2:-0}"
    export INCLUDE_OPERATOR="${3:-0}"
    export DOCKERFILE_LITERAL="${4:-}"
    export IMAGE_IN_CONFIG="${5:-}"
    export REGISTRY="${6:-}" NAMESPACE="${7:-}" NAME="${8:-}" TAG="${9:-}"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: build_root entries removed ==="
run_snippet "$SAMPLE_CONFIG"
assert_eq "project_image removed" "null" "$(cfg '.build_root.project_image')"
assert_eq "from_repository removed" "null" "$(cfg '.build_root.from_repository')"

echo "=== Test: images removed by default ==="
run_snippet "$SAMPLE_CONFIG"
assert_eq "images removed" "null" "$(cfg '.images')"

echo "=== Test: images kept when INCLUDE_IMAGES=1 ==="
run_snippet "$SAMPLE_CONFIG" "1"
assert_eq "images present" "test-image" "$(cfg '.images[0].name')"

echo "=== Test: operator removed by default ==="
run_snippet "$SAMPLE_CONFIG"
assert_eq "operator removed" "null" "$(cfg '.operator')"

echo "=== Test: operator kept when INCLUDE_OPERATOR=1 ==="
run_snippet "$SAMPLE_CONFIG" "0" "1"
assert_eq "operator present" "test-bundle" "$(cfg '.operator.bundles[0].name')"

echo "=== Test: dockerfile_literal added when set ==="
run_snippet "$SAMPLE_CONFIG" "0" "0" "FROM centos:7"
assert_eq "dockerfile_literal set" "FROM centos:7" "$(cfg '.build_root.project_image.dockerfile_literal')"

echo "=== Test: no dockerfile_literal when empty ==="
run_snippet "$SAMPLE_CONFIG" "0" "0" ""
assert_eq "project_image stays null" "null" "$(cfg '.build_root.project_image')"

echo "=== Test: external_images set with IMAGE_IN_CONFIG ==="
run_snippet "$SAMPLE_CONFIG" "0" "0" "" "konflux" "quay.io" "myns" "myimage" "abc123"
assert_eq "registry"  "quay.io"  "$(cfg '.external_images.konflux.registry')"
assert_eq "namespace" "myns"     "$(cfg '.external_images.konflux.namespace')"
assert_eq "name"      "myimage"  "$(cfg '.external_images.konflux.name')"
assert_eq "tag"       "abc123"   "$(cfg '.external_images.konflux.tag')"

echo "=== Test: no external_images when IMAGE_IN_CONFIG empty ==="
run_snippet "$SAMPLE_CONFIG" "0" "0" "" ""
assert_eq "external_images absent" "null" "$(cfg '.external_images')"

print_results
