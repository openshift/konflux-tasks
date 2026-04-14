#!/usr/bin/env bash
#
# Unit tests for CI operator config URL construction.
# Validates URL is built correctly with and without variant.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

# Extract the URL construction block (between "export DOCKERFILE_LITERAL" and the curl call).
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*export DOCKERFILE_LITERAL/,/^[[:space:]]*CI_OPERATOR_CONFIG=\$(curl/{
    /export DOCKERFILE_LITERAL/d
    /CI_OPERATOR_CONFIG=\$(curl/d
    /^[[:space:]]*$/d
    p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract config URL snippet"; exit 2; }

run_snippet() {
  (
    export ORG="$1" REPO="$2" TARGET_BRANCH="$3" VARIANT="${4:-}"
    eval "$SNIPPET"
    echo "$CI_OPERATOR_CONFIG_URL"
  )
}

BASE="https://raw.githubusercontent.com/openshift/release/master/ci-operator/config"

# --- tests ---

echo "=== Test: URL without variant ==="
URL=$(run_snippet "openshift" "myrepo" "main" "")
assert_eq "correct URL" \
  "$BASE/openshift/myrepo/openshift-myrepo-main.yaml" "$URL"

echo "=== Test: URL with variant ==="
URL=$(run_snippet "openshift" "myrepo" "main" "ocp416")
assert_eq "correct URL" \
  "$BASE/openshift/myrepo/openshift-myrepo-main__ocp416.yaml" "$URL"

echo "=== Test: URL with dashes in org/repo/branch ==="
URL=$(run_snippet "my-org" "my-cool-repo" "release-4.16" "")
assert_eq "correct URL" \
  "$BASE/my-org/my-cool-repo/my-org-my-cool-repo-release-4.16.yaml" "$URL"

echo "=== Test: URL with variant and complex names ==="
URL=$(run_snippet "my-org" "my-repo" "release-4.16" "v2-nightly")
assert_eq "correct URL" \
  "$BASE/my-org/my-repo/my-org-my-repo-release-4.16__v2-nightly.yaml" "$URL"

print_results
