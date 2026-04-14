#!/usr/bin/env bash
#
# Unit tests for the provide-prowjob test filtering logic.
# The filtering code is extracted directly from the task YAML so the
# test always exercises the real implementation.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Filter tests to only include/,/^[[:space:]]*# ENV var modifications/{ /# ENV var modifications/d; p; }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract filter snippet"; exit 2; }

# --- helpers ---

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: e2e-aws
    steps:
      cluster_profile: aws
  - as: e2e-gcp
    steps:
      cluster_profile: gcp
  - as: e2e-azure
    steps:
      cluster_profile: azure
EOF
}

run_filter() {
  (
    export PROWJOB_NAME="$1" ORG="$2" REPO="$3" TARGET_BRANCH="$4" VARIANT="${5:-}"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

count_tests() { yq '.tests | length' "$TMPDIR/config.yaml"; }
remaining_test_name() { yq '.tests[0].as' "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: filter without variant ==="
create_config
run_filter "periodic-ci-openshift-myrepo-main-e2e-gcp" "openshift" "myrepo" "main" ""
assert_eq "only 1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-gcp" "e2e-gcp" "$(remaining_test_name)"

echo "=== Test: filter with variant ==="
create_config
run_filter "periodic-ci-openshift-myrepo-main__ocp416-e2e-azure" "openshift" "myrepo" "main" "ocp416"
assert_eq "only 1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-azure" "e2e-azure" "$(remaining_test_name)"

echo "=== Test: filter keeps first test (e2e-aws) ==="
create_config
run_filter "periodic-ci-openshift-myrepo-main-e2e-aws" "openshift" "myrepo" "main" ""
assert_eq "only 1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-aws" "e2e-aws" "$(remaining_test_name)"

echo "=== Test: pull-ci prefix works ==="
create_config
run_filter "pull-ci-openshift-myrepo-main-e2e-gcp" "openshift" "myrepo" "main" ""
assert_eq "only 1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-gcp" "e2e-gcp" "$(remaining_test_name)"

echo "=== Test: no filtering when prefix does not match ==="
create_config
run_filter "some-unrelated-job-name" "openshift" "myrepo" "main" ""
assert_eq "all 3 tests remain" "3" "$(count_tests)"

echo "=== Test: repo name with dashes ==="
create_config
run_filter "periodic-ci-openshift-my-cool-repo-main-e2e-aws" "openshift" "my-cool-repo" "main" ""
assert_eq "only 1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-aws" "e2e-aws" "$(remaining_test_name)"

echo "=== Test: single test config (no extra tests to remove) ==="
cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: e2e-aws
    steps:
      cluster_profile: aws
EOF
run_filter "periodic-ci-openshift-myrepo-main-e2e-aws" "openshift" "myrepo" "main" ""
assert_eq "1 test remains" "1" "$(count_tests)"
assert_eq "kept test is e2e-aws" "e2e-aws" "$(remaining_test_name)"

echo "=== Test: no matching test removes all ==="
create_config
run_filter "periodic-ci-openshift-myrepo-main-e2e-nonexistent" "openshift" "myrepo" "main" ""
assert_eq "0 tests remain" "0" "$(count_tests)"

print_results
