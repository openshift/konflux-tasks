#!/usr/bin/env bash
# Exercise the readiness check embedded in the provisioning task.

set -eo pipefail
source "$(dirname "$0")/../helpers.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

TASK_YAML="$REPO_ROOT/tasks/provision-ephemeral-cluster/0.1/provision-ephemeral-cluster.yaml"
READY_FUNCTION=$(yq '.spec.steps[0].script' "$TASK_YAML" | sed -n '/^check_cluster_ready() {/,/^watch_ephemeral_cluster() {/{
  /^watch_ephemeral_cluster() {/d; p
}')
[[ -n "$READY_FUNCTION" ]] || { echo "FATAL: readiness function not found"; exit 2; }
READY_FUNCTION=${READY_FUNCTION//'$(results.secretRef.path)'/"$TEST_DIR/secret-ref"}
READY_FUNCTION=${READY_FUNCTION//'$(results.testPlatformClusterClaimName.path)'/"$TEST_DIR/claim-name"}
READY_FUNCTION=${READY_FUNCTION//'$(results.testPlatformClusterClaimNamespace.path)'/"$TEST_DIR/claim-namespace"}

printf '%s\n' '#!/usr/bin/env bash' 'set -eo pipefail' \
  'URL_DUMPED=0' 'CLUSTER_READY=0' "$READY_FUNCTION" \
  'check_cluster_ready "$CLAIM_SNAPSHOT"' \
  'exit 2 # Still waiting for readiness.' >"$TEST_DIR/check-ready.sh"

export SECRET=cluster-credentials CLAIM_NAME=cluster-claim NAMESPACE=tenant

check_snapshot() {
  local description="$1" snapshot="$2" expected_status="$3"
  local output status=0
  rm -f "$TEST_DIR/secret-ref" "$TEST_DIR/claim-name" "$TEST_DIR/claim-namespace"
  output=$(CLAIM_SNAPSHOT="$snapshot" bash "$TEST_DIR/check-ready.sh" 2>&1) || status=$?
  assert_eq "$description: exit status" "$expected_status" "$status"
  if [[ "$expected_status" == 0 ]]; then
    assert_contains "$description: ready message" "$output" 'The cluster is ready'
    assert_eq "$description: secret result" "$SECRET" "$(cat "$TEST_DIR/secret-ref" 2>/dev/null || true)"
    assert_eq "$description: claim result" "$CLAIM_NAME" "$(cat "$TEST_DIR/claim-name" 2>/dev/null || true)"
    assert_eq "$description: namespace result" "$NAMESPACE" "$(cat "$TEST_DIR/claim-namespace" 2>/dev/null || true)"
  else
    local result_written=false
    if [[ -e "$TEST_DIR/secret-ref" || -e "$TEST_DIR/claim-name" || -e "$TEST_DIR/claim-namespace" ]]; then
      result_written=true
    fi
    assert_eq "$description: no successful results" false "$result_written"
    if [[ "$expected_status" == 1 ]]; then
      assert_contains "$description: error message" "$output" 'Error:'
    fi
  fi
}

check_phase() {
  local phase="$1" claim_ready="$2" cluster_ready="$3" expected_status="$4"
  local snapshot
  snapshot=$(jq -nc --arg phase "$phase" --arg claim_ready "$claim_ready" --arg cluster_ready "$cluster_ready" '
    {status: {conditions: [
      {type: "_EphemeralClusterPhase", status: "True", message: $phase},
      {type: "Ready", status: $claim_ready},
      {type: "ClusterReady", status: $cluster_ready}
    ]}}')
  check_snapshot "$phase / claim=$claim_ready / cluster=$cluster_ready" "$snapshot" "$expected_status"
}

check_phase Ready True True 0
check_phase Ready False True 2
check_phase Ready True False 2
check_phase Initializing False False 2
check_phase Provisioning False False 2
check_phase Provisioning True True 0
check_phase '' True True 0
check_snapshot 'status not reported yet' '{}' 2
check_snapshot 'conditions not reported yet' '{"status":{}}' 2
check_snapshot 'phase not reported yet' '{"status":{"conditions":[{"type":"Ready","status":"True"},{"type":"ClusterReady","status":"True"}]}}' 0

for job_condition in ProwJobCreating ProwJobCreated; do
  if [[ "$job_condition" == ProwJobCreating ]]; then
    job_status=False
  else
    job_status=True
  fi
  snapshot=$(jq -nc --arg job_condition "$job_condition" --arg job_status "$job_status" '
    {status: {conditions: [
      {type: "_EphemeralClusterPhase", status: "True", message: "Ready"},
      {type: "Ready", status: "True"},
      {type: "ClusterReady", status: "True", reason: "CredentialsReady"},
      {type: $job_condition, status: $job_status, reason: "ProwJobProperlyCreated"}
    ]}}')
  check_snapshot "ready cluster with $job_condition" "$snapshot" 0
done

for phase in InitializationFailed ProvisioningFailed DeprovisioningFailure Failed Deprovisioning Deprovisioned; do
  check_phase "$phase" False False 1
  check_phase "$phase" True True 1
done

print_results
