#!/usr/bin/env bash
# Run the deprovisioning script against a fake oc client and controller statuses.

set -eo pipefail
source "$(dirname "$0")/../helpers.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

TASK_YAML="$REPO_ROOT/tasks/deprovision-ephemeral-cluster/0.1/deprovision-ephemeral-cluster.yaml"
yq '.spec.steps[0].script' "$TASK_YAML" >"$TEST_DIR/deprovision.sh"

oc() {
  printf '%s\n' "$*" >>"$OC_CALLS"
  if [[ "$1" != '-n' || "$2" != "$NAMESPACE" ]]; then
    echo 'Unexpected namespace' >&2
    return 1
  fi
  shift 2
  case "$1" in
    patch)
      jq -e 'any(.[]; .op == "add" and .path == "/spec/tearDownCluster" and .value == true)' deprovision-patch.json >/dev/null
      ;;
    wait)
      [[ "$*" == *'--for=condition=ProwJobCompleted=true'* ]] || return 1
      jq -e 'any((.status.conditions // [])[]; .type == "ProwJobCompleted" and .status == "True")' <<<"$CLAIM_SNAPSHOT" >/dev/null
      ;;
    get)
      printf '%s\n' "$CLAIM_SNAPSHOT"
      ;;
    *)
      echo "Unexpected oc command: $*" >&2
      return 1
      ;;
  esac
}
export -f oc
export CLAIM_NAME=cluster-claim NAMESPACE=tenant CLUSTER_DEPROVISIONING_TIMEOUT=1s
export OC_CALLS="$TEST_DIR/oc-calls"

check_outcome() {
  local phase="$1" reason="$2" completed="$3" expected_status="$4"
  local output status=0
  export CLAIM_SNAPSHOT
  CLAIM_SNAPSHOT=$(jq -nc --arg phase "$phase" --arg reason "$reason" --arg completed "$completed" '
    {status: {conditions: [
      {type: "_EphemeralClusterPhase", status: "True", message: $phase},
      {type: "ProwJobCompleted", status: $completed, reason: $reason}
    ]}}')
  : >"$OC_CALLS"
  output=$(cd "$TEST_DIR" && bash deprovision.sh 2>&1) || status=$?
  assert_eq "$phase / $reason / $completed: exit status" "$expected_status" "$status"
  assert_contains 'claim patched in its namespace' "$(cat "$OC_CALLS")" '-n tenant patch testplatformclusters.ci.openshift.org cluster-claim'
  assert_contains 'wait for job completion' "$(cat "$OC_CALLS")" '--for=condition=ProwJobCompleted=true'
  if [[ "$expected_status" == 0 ]]; then
    assert_contains 'successful teardown reported' "$output" 'The cluster has been properly deprovisioned'
  elif [[ "$completed" == True ]]; then
    assert_contains 'failed teardown reported' "$output" 'Error: failed to deprovision the cluster'
  fi
}

check_outcome Deprovisioned ProwJobCompleted True 0
check_outcome '' ProwJobCompleted True 0
check_outcome Failed ProwJobCompleted True 0
check_outcome Failed ProwJobFailure True 1
check_outcome DeprovisioningFailure ProwJobFailure True 1
check_outcome ProvisioningFailed ProwJobFailure True 1
check_outcome Deprovisioning ProwJobCompleted False 1
check_outcome InitializationFailed '' False 1

print_results
