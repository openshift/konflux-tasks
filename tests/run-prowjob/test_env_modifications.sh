#!/usr/bin/env bash
#
# Unit tests for run-prowjob environment variable injection.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract from "# ENV var modifications" to "# Chosing prowjob".
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# ENV var modifications/,/^[[:space:]]*# Chosing prowjob/{
    /# Chosing prowjob/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract env modifications snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
tests:
  - as: e2e-aws
    steps:
      cluster_profile: aws
      env: {}
  - as: e2e-gcp
    steps:
      cluster_profile: gcp
      env: {}
EOF
}

run_snippet() {
  (
    export ENVS="$1"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: single env var ==="
create_config
run_snippet "MY_VAR=hello"
assert_eq "set on first test"  "hello" "$(cfg '.tests[0].steps.env.MY_VAR')"
assert_eq "set on second test" "hello" "$(cfg '.tests[1].steps.env.MY_VAR')"

echo "=== Test: multiple env vars ==="
create_config
run_snippet "VAR1=val1,VAR2=val2"
assert_eq "VAR1" "val1" "$(cfg '.tests[0].steps.env.VAR1')"
assert_eq "VAR2" "val2" "$(cfg '.tests[0].steps.env.VAR2')"

echo "=== Test: env var with = in value ==="
create_config
run_snippet "KEY=a=b=c"
assert_eq "value preserved" "a=b=c" "$(cfg '.tests[0].steps.env.KEY')"

echo "=== Test: empty ENVS does nothing ==="
create_config
run_snippet ""
assert_eq "no env added" "{}" "$(cfg '.tests[0].steps.env')"

print_results
