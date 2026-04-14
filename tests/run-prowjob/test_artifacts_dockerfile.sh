#!/usr/bin/env bash
#
# Unit tests for the run-prowjob artifacts Dockerfile literal construction.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Artifacts Dockerfile/,/^[[:space:]]*export DOCKERFILE_LITERAL/p')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract artifacts dockerfile snippet"; exit 2; }

run_snippet() {
  (
    export ARTIFACTS_BUILD_ROOT="$1" DOCKERFILE_ADDITIONS="${2:-}"
    export ORG="${3:-myorg}" REPO="${4:-myrepo}" COMMIT="${5:-abc123}"
    eval "$SNIPPET"
    echo "$DOCKERFILE_LITERAL"
  )
}

# --- tests ---

echo "=== Test: contains FROM with build root image ==="
RESULT=$(run_snippet "centos:7")
assert_contains "has FROM" "$RESULT" "FROM centos:7"

echo "=== Test: copies oc and kubectl from cli image ==="
RESULT=$(run_snippet "centos:7")
assert_contains "copies oc"      "$RESULT" "COPY --from=quay-proxy.ci.openshift.org/openshift/ci:ocp_4.18_cli /bin/oc"
assert_contains "copies kubectl" "$RESULT" "COPY --from=quay-proxy.ci.openshift.org/openshift/ci:ocp_4.18_cli /bin/kubectl"

echo "=== Test: contains repo download URL ==="
RESULT=$(run_snippet "centos:7" "" "myorg" "myrepo" "sha1")
assert_contains "has download URL" "$RESULT" "https://github.com/myorg/myrepo/archive/sha1.zip"

echo "=== Test: contains WORKDIR with repo-commit ==="
RESULT=$(run_snippet "centos:7" "" "org" "repo" "abc")
assert_contains "has workdir" "$RESULT" "WORKDIR /workspace/repo-abc"

echo "=== Test: includes DOCKERFILE_ADDITIONS ==="
RESULT=$(run_snippet "centos:7" "RUN make build")
assert_contains "has additions" "$RESULT" "RUN make build"

echo "=== Test: includes permission fix commands ==="
RESULT=$(run_snippet "centos:7")
assert_contains "fixes /workspace dirs" "$RESULT" "find /workspace -type d"
assert_contains "fixes /go dirs"        "$RESULT" "find /go -type d"

print_results
