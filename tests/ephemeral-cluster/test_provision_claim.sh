#!/usr/bin/env bash
# Exercise claim generation with an optional timeout for waiting for the tearDown signal.

set -eo pipefail
source "$(dirname "$0")/../helpers.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

TASK_YAML="$REPO_ROOT/tasks/provision-ephemeral-cluster/0.1/provision-ephemeral-cluster.yaml"
CLAIM_SCRIPT=$(yq '.spec.steps[0].script' "$TASK_YAML" | sed -n '/^cat <<EOF >testplatformcluster_claim.yaml/,/^echo "Creating TestPlatformCluster claim..."/{
  /^echo "Creating TestPlatformCluster claim..."/d; p
}')
[[ -n "$CLAIM_SCRIPT" ]] || { echo "FATAL: claim generation script not found"; exit 2; }
printf '%s\n' '#!/usr/bin/env bash' 'set -eo pipefail' "$CLAIM_SCRIPT" >"$TEST_DIR/generate-claim.sh"

WAIT_FOR_TEAR_DOWN_TIMEOUT_DEFAULT=$(yq -r '.spec.params[] | select(.name == "waitForTearDownTimeout") | .default' "$TASK_YAML")
WAIT_FOR_TEAR_DOWN_TIMEOUT_ENV=$(yq -r '.spec.steps[0].env[] | select(.value == "$(params.waitForTearDownTimeout)") | .name' "$TASK_YAML")
[[ -n "$WAIT_FOR_TEAR_DOWN_TIMEOUT_ENV" ]] || { echo "FATAL: waitForTearDownTimeout environment binding not found"; exit 2; }

export BUILD_ROOT='{}' BASE_IMAGES='{}' EXTERNAL_IMAGES='{}' RELEASES='{}' ENV='{}'
export WORKFLOW=ipi-aws CLUSTER_PROFILE=aws CLUSTER_CLAIM='{}' RESOURCES=''
export TASK_RUN_NAME=task-run CLAIM_NAME=cluster-claim NAMESPACE=tenant
export OWNER_KIND=PipelineRun OWNER_NAME=pipeline-run OWNER_UID=pipeline-uid SECRET=cluster-credentials

generate_claim() {
  (
    export "$WAIT_FOR_TEAR_DOWN_TIMEOUT_ENV=$1"
    cd "$TEST_DIR"
    bash generate-claim.sh >/dev/null
  )
}

claim() { yq -r "$1" "$TEST_DIR/testplatformcluster_claim.yaml"; }

assert_eq 'waitForTearDownTimeout is optional by default' '' "$WAIT_FOR_TEAR_DOWN_TIMEOUT_DEFAULT"
generate_claim "$WAIT_FOR_TEAR_DOWN_TIMEOUT_DEFAULT"
assert_eq 'default claim omits waitForTearDownTimeout' false "$(claim '.spec.ciOperator.test | has("waitForTearDownTimeout")')"
assert_eq 'cluster profile preserved' aws "$(claim '.spec.ciOperator.test.clusterProfile')"

generate_claim 4h30m
assert_eq 'custom timeout forwarded' 4h30m "$(claim '.spec.ciOperator.test.waitForTearDownTimeout')"
assert_eq 'timeout remains a string' '!!str' "$(claim '.spec.ciOperator.test.waitForTearDownTimeout | tag')"
assert_eq 'workflow preserved' ipi-aws "$(claim '.spec.ciOperator.test.workflow')"

export CLUSTER_PROFILE='' CLUSTER_CLAIM='{"cloud":"aws","owner":"openshift-ci","version":"4.20"}' WORKFLOW=generic-claim
generate_claim 6h
assert_eq 'Hive claim timeout forwarded' 6h "$(claim '.spec.ciOperator.test.waitForTearDownTimeout')"
assert_eq 'Hive claim preserved' aws "$(claim '.spec.ciOperator.test.clusterClaim.cloud')"
assert_eq 'Hive claim omits cluster profile' false "$(claim '.spec.ciOperator.test | has("clusterProfile")')"

print_results
