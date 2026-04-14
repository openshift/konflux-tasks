#!/usr/bin/env bash
#
# Unit tests for run-prowjob release configuration.
# Tests all channel/stream types: stable/fast/candidate, 4-stable, nightly/ci,
# and invalid channel.
#
# Requires: yq (mikefarah/yq v4+)

set -eo pipefail
source "$(dirname "$0")/helpers.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract from "# Release" to "# Placeholders modifications".
SNIPPET=$(echo "$FULL_SCRIPT" | \
  sed -n '/^[[:space:]]*# Release/,/^[[:space:]]*# Placeholders modifications/{
    /# Placeholders modifications/d; p
  }')
[[ -n "$SNIPPET" ]] || { echo "FATAL: could not extract release snippet"; exit 2; }

create_config() {
  cat > "$TMPDIR/config.yaml" <<'EOF'
releases:
  latest:
    release:
      channel: placeholder
      version: placeholder
EOF
}

run_snippet() {
  (
    export CHANNEL_STREAM="$1" OPENSHIFT_VERSION="$2"
    cd "$TMPDIR"
    eval "$SNIPPET"
  )
}

cfg() { yq "$1" "$TMPDIR/config.yaml"; }

# --- tests ---

echo "=== Test: stable channel ==="
create_config
run_snippet "stable" "4.18"
assert_eq "channel"      "stable" "$(cfg '.releases.latest.release.channel')"
assert_eq "version"      "4.18"   "$(cfg '.releases.latest.release.version')"
assert_eq "architecture" "amd64"  "$(cfg '.releases.latest.release.architecture')"

echo "=== Test: fast channel ==="
create_config
run_snippet "fast" "4.17.3"
assert_eq "channel" "fast"   "$(cfg '.releases.latest.release.channel')"
assert_eq "version" "4.17.3" "$(cfg '.releases.latest.release.version')"

echo "=== Test: candidate channel ==="
create_config
run_snippet "candidate" "4.16"
assert_eq "channel" "candidate" "$(cfg '.releases.latest.release.channel')"

echo "=== Test: 4-stable prerelease ==="
create_config
run_snippet "4-stable" "4.18"
assert_eq "product"     "ocp"      "$(cfg '.releases.latest.prerelease.product')"
assert_eq "architecture" "amd64"   "$(cfg '.releases.latest.prerelease.architecture')"
assert_eq "lower bound" "4.18.0-0" "$(cfg '.releases.latest.prerelease.version_bounds.lower')"
assert_eq "upper bound" "4.19.0-0" "$(cfg '.releases.latest.prerelease.version_bounds.upper')"
assert_eq "stream"      "4-stable" "$(cfg '.releases.latest.prerelease.version_bounds.stream')"
assert_eq "release deleted" "null" "$(cfg '.releases.latest.release')"

echo "=== Test: nightly stream ==="
create_config
run_snippet "nightly" "4.18"
assert_eq "product"      "ocp"     "$(cfg '.releases.latest.candidate.product')"
assert_eq "stream"       "nightly" "$(cfg '.releases.latest.candidate.stream')"
assert_eq "version"      "4.18"    "$(cfg '.releases.latest.candidate.version')"
assert_eq "architecture" "amd64"   "$(cfg '.releases.latest.candidate.architecture')"
assert_eq "release deleted" "null" "$(cfg '.releases.latest.release')"

echo "=== Test: ci stream ==="
create_config
run_snippet "ci" "4.17"
assert_eq "stream" "ci" "$(cfg '.releases.latest.candidate.stream')"

echo "=== Test: konflux-nightly stream ==="
create_config
run_snippet "konflux-nightly" "4.18"
assert_eq "stream" "konflux-nightly" "$(cfg '.releases.latest.candidate.stream')"

echo "=== Test: invalid channel fails ==="
create_config
if run_snippet "invalid-channel" "4.18" 2>/dev/null; then
  assert_eq "should have failed" "fail" "pass"
else
  assert_eq "exits with error" "true" "true"
fi

print_results
