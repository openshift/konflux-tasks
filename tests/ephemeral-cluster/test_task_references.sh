#!/usr/bin/env bash
# Check that the ephemeral-cluster examples resolve tasks present in this repo.

set -eo pipefail
source "$(dirname "$0")/../helpers.sh"

for pipeline in "$REPO_ROOT"/examples/ephemeral-cluster/*.yaml; do
  while IFS= read -r task_path; do
    exists=false
    if [[ -f "$REPO_ROOT/$task_path" ]]; then
      exists=true
    fi
    assert_eq "$(basename "$pipeline"): $task_path exists" true "$exists"
  done < <(yq -r '(.spec.tasks[], .spec.finally[]) | .taskRef.params[] | select(.name == "pathInRepo") | .value' "$pipeline")
done

print_results
