#!/usr/bin/env bash
#
# Unit tests for run-prowjob prowjob selection and test filtering.
# Tests all branches: aws, gcp, azure, bundle, catalog.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract from "# Chosing prowjob" to "# Bundle pre-test command".
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Chosing prowjob/,/^[[:space:]]*# Bundle pre-test command/{
    /# Bundle pre-test command/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract prowjob selection snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: konflux-test-aws
    steps:
      cluster_profile: aws
  - as: konflux-test-gcp
    steps:
      cluster_profile: gcp
  - as: konflux-test-azure
    steps:
      cluster_profile: azure
  - as: konflux-test-bundle
    steps:
      cluster_profile: aws
  - as: konflux-test-catalog
    steps:
      cluster_profile: aws
EOF
}

run_snippet() {
  (
    export CLOUD_PROVIDER="${1:-aws}" BUNDLE_NS="${2:-}" CATALOG_NS="${3:-}"
    cd "$TMPDIR"
    eval "$SNIPPET"
    echo "$PROWJOB_NAME"
  )
}

count_tests() { yq '.tests | length' "$TMPDIR/config.yaml"; }
remaining_test_name() { yq '.tests[0].as' "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: aws (default) ==="
create_config
PJNAME=$(run_snippet "aws" "" "")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-aws" "$PJNAME"
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept aws test" "konflux-test-aws" "$(remaining_test_name)"

echo "=== Test: gcp ==="
create_config
PJNAME=$(run_snippet "gcp" "" "")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-gcp" "$PJNAME"
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept gcp test" "konflux-test-gcp" "$(remaining_test_name)"

echo "=== Test: azure ==="
create_config
PJNAME=$(run_snippet "azure" "" "")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-azure" "$PJNAME"
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept azure test" "konflux-test-azure" "$(remaining_test_name)"

echo "=== Test: bundle (BUNDLE_NS set) ==="
create_config
PJNAME=$(run_snippet "aws" "my-ns" "")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-bundle" "$PJNAME"
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept bundle test" "konflux-test-bundle" "$(remaining_test_name)"

echo "=== Test: catalog (CATALOG_NS set) ==="
create_config
PJNAME=$(run_snippet "aws" "" "catalog-ns")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-catalog" "$PJNAME"
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept catalog test" "konflux-test-catalog" "$(remaining_test_name)"

echo "=== Test: bundle takes precedence over cloud provider ==="
create_config
PJNAME=$(run_snippet "gcp" "my-ns" "")
assert_eq "prowjob name" "periodic-ci-openshift-konflux-tasks-main-konflux-test-bundle" "$PJNAME"

print_results
