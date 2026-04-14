#!/usr/bin/env bash
# Test helpers for provide-prowjob tests.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../helpers.sh"

TASK_YAML="$REPO_ROOT/tasks/provide-prowjob/0.1/provide-prowjob.yaml"
FULL_SCRIPT=$(yq '.spec.steps[0].script' "$TASK_YAML")
