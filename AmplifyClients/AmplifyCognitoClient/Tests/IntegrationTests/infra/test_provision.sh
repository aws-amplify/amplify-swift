#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for provision.sh's region rule, its name lookup and its state records. A fake `aws` on PATH logs each
# call and refuses it, so no AWS call is made and provision.sh stops at its first one; the lookup and the records
# run on their own, over a fake `aws` function with placeholder ids.
#
#   bash infra/test_provision.sh
#
# It checks that a region other than the one state.json records is refused before any AWS call; that without an
# argument the recorded region wins over AWS_REGION; that with no state.json yet, a run without AWS_PROFILE is refused
# before any AWS call, and so is one with it while AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY or AWS_SESSION_TOKEN is
# exported (the CLI would take the keys over the profile), or AWS_ROLE_ARN, AWS_WEB_IDENTITY_TOKEN_FILE or an
# AWS_CONTAINER_CREDENTIALS_* variable (its web identity and container providers), and one with it and none of them
# goes on; that once state.json records the account, exported keys go on to the caller's identity, which the account
# check compares; that the region refusal points at a teardown, and a sandbox in another region (its global role's
# identity pool) is refused before any change, with no region recorded and with one recorded (another state directory's
# sandbox); that find_by_name follows NextToken to the
# page that has the name, and stops at the last page without it; and that record_state merges into state.json (mode
# 600), keeping what it does not set (the parity section).
set -euo pipefail
INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$INFRA_DIR/provision.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/state"
cat > "$WORK/bin/aws" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_LOG"
# FAKE_ACCOUNT and FAKE_ROLE_AUDIENCE answer the caller's identity and the authenticated role's audience (the only
# reads the region guard needs); every other call is refused.
case "$*" in
    *"sts get-caller-identity"*) [[ -z "${FAKE_ACCOUNT:-}" ]] || { echo "$FAKE_ACCOUNT"; exit 0; } ;;
    *"iam get-role"*) [[ -z "${FAKE_ROLE_AUDIENCE:-}" ]] || { echo "$FAKE_ROLE_AUDIENCE"; exit 0; } ;;
esac
echo "An error occurred (AccessDeniedException) when calling the operation: refused by the fake" >&2
exit 254
EOF
chmod +x "$WORK/bin/aws"
export PATH="$WORK/bin:$PATH" FAKE_LOG="$WORK/calls.log" COGNITO_CLIENT_INTEG_DIR="$WORK/state"
export COGNITO_CLIENT_INTEG_MIN_FREE_GIB=0 AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null
unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE
for variable in $(compgen -e | grep '^AWS_CONTAINER_CREDENTIALS_' || true); do
    unset "$variable"
done
[[ "$(command -v aws)" == "$WORK/bin/aws" ]] || { echo "FAIL: the fake aws is not first on PATH"; exit 1; }
printf '{"account": "000000000000", "region": "us-west-2", "parity": {"kmsKeyId": "placeholder-key"}}\n' \
    > "$WORK/state/state.json"

failures=0
check() {
    local name="$1"
    shift
    if "$@"; then echo "ok - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}

# Runs provision.sh; sets OUT (stdout and stderr) and STATUS.
run() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$("$SCRIPT" "$@" 2>&1) || STATUS=$?
}

another_region_is_refused_before_any_aws_call() {
    run us-east-1
    (( STATUS == 1 )) && [[ "$OUT" == *"state.json records region us-west-2"* ]] && [[ ! -s "$FAKE_LOG" ]]
}

the_recorded_region_wins_over_aws_region() {
    AWS_REGION=us-east-1 run
    # The first AWS call (the caller's identity), refused by the fake, is in the recorded region.
    (( STATUS != 0 )) && grep -q -- '--region us-west-2 .*sts get-caller-identity' "$FAKE_LOG" \
        && ! grep -q -- '--region us-east-1' "$FAKE_LOG"
}

# With no state.json yet, nothing records the account, so a run without AWS_PROFILE must stop before its first AWS
# call (the CLI's own `configure get` is local), and one with AWS_PROFILE goes on to the caller's identity.
a_first_run_without_aws_profile_is_refused_before_any_aws_call() {
    COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" run us-west-2
    (( STATUS == 1 )) && [[ "$OUT" == *"no account is recorded"*"Set AWS_PROFILE"* ]] \
        && ! grep -v '^configure ' "$FAKE_LOG" | grep -q .
}

a_first_run_with_aws_profile_goes_on_to_the_callers_identity() {
    AWS_PROFILE=sandbox COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" run us-west-2
    (( STATUS != 0 )) && [[ "$OUT" != *"no account is recorded"* ]] && grep -q -- 'sts get-caller-identity' "$FAKE_LOG"
}

# The AWS CLI takes exported keys over AWS_PROFILE, so with no account recorded a run with AWS_PROFILE and any one of
# the three key variables exported must stop before its first AWS call too, and name the variable, never its value.
a_first_run_with_exported_keys_is_refused_before_any_aws_call() {
    local variable
    for variable in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
        : > "$FAKE_LOG"
        STATUS=0
        OUT=$(env "$variable=placeholder-key-value" AWS_PROFILE=sandbox COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" \
            "$SCRIPT" us-west-2 2>&1) || STATUS=$?
        (( STATUS == 1 )) && [[ "$OUT" == *"no account is recorded"*"exports $variable"* ]] \
            && [[ "$OUT" == *"would use those credentials"*"instead of the profile"* ]] \
            && [[ "$OUT" != *placeholder-key-value* ]] && ! grep -v '^configure ' "$FAKE_LOG" | grep -q . \
            || { echo "$variable: $OUT"; return 1; }
    done
}

# The CLI's web identity and container providers can take over AWS_PROFILE too, so with no account recorded a run
# with AWS_PROFILE and AWS_ROLE_ARN, AWS_WEB_IDENTITY_TOKEN_FILE or an AWS_CONTAINER_CREDENTIALS_* variable exported
# must stop before its first AWS call as well, and name the variable, never its value.
a_first_run_with_web_identity_or_container_credentials_is_refused_before_any_aws_call() {
    local variable
    for variable in AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_CONTAINER_CREDENTIALS_RELATIVE_URI \
        AWS_CONTAINER_CREDENTIALS_FULL_URI; do
        : > "$FAKE_LOG"
        STATUS=0
        OUT=$(env "$variable=placeholder-credential-value" AWS_PROFILE=sandbox COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" \
            "$SCRIPT" us-west-2 2>&1) || STATUS=$?
        (( STATUS == 1 )) && [[ "$OUT" == *"no account is recorded"*"exports $variable."* ]] \
            && [[ "$OUT" == *"a web identity role, container credentials"* ]] \
            && [[ "$OUT" != *placeholder-credential-value* ]] && ! grep -v '^configure ' "$FAKE_LOG" | grep -q . \
            || { echo "$variable: $OUT"; return 1; }
    done
}

# Once state.json records the account, the caller's identity is compared with it, so exported keys may be used.
a_recorded_account_lets_exported_keys_go_on_to_the_callers_identity() {
    AWS_ACCESS_KEY_ID=placeholder-key-value run
    (( STATUS != 0 )) && [[ "$OUT" != *"exports AWS_ACCESS_KEY_ID"* ]] && grep -q -- 'sts get-caller-identity' "$FAKE_LOG"
}

# The region refusal points at a teardown, not at another state directory, which would build the second sandbox.
the_region_refusal_does_not_advise_another_state_directory() {
    run us-east-1
    (( STATUS == 1 )) && [[ "$OUT" == *"run infra/teardown.sh first"* ]] && [[ "$OUT" != *"point COGNITO_CLIENT_INTEG_DIR"* ]]
}

# With no region recorded, a sandbox already in another region (its global authenticated role trusts an identity pool
# there) is refused before any change; one in this region, or no role, goes on.
a_first_run_beside_a_sandbox_in_another_region_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(AWS_PROFILE=sandbox FAKE_ACCOUNT=000000000000 \
        FAKE_ROLE_AUDIENCE="us-east-1:00000000-0000-4000-8000-000000000000" COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" \
        "$SCRIPT" us-west-2 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"trusts an identity pool in us-east-1, not us-west-2"* ]] \
        && [[ "$OUT" != *00000000-0000-4000* ]] && grep -q -- 'iam get-role' "$FAKE_LOG" \
        && ! grep -vE 'configure |sts get-caller-identity|iam get-role' "$FAKE_LOG" | grep -q . \
        || { echo "$OUT"; return 1; }
    local audience
    for audience in "us-west-2:00000000-0000-4000-8000-000000000000" ""; do
        : > "$FAKE_LOG"
        STATUS=0
        OUT=$(AWS_PROFILE=sandbox FAKE_ACCOUNT=000000000000 FAKE_ROLE_AUDIENCE="$audience" \
            COGNITO_CLIENT_INTEG_DIR="$WORK/fresh" "$SCRIPT" us-west-2 2>&1) || STATUS=$?
        [[ "$OUT" != *"trusts an identity pool"* ]] && grep -q -- 'iam get-role' "$FAKE_LOG" \
            || { echo "audience '$audience': $OUT"; return 1; }
    done
}

# A region recorded in this state directory does not rule out a sandbox in another region under another one: its
# global role's identity pool there is refused before any change too, and one in the recorded region goes on.
a_recorded_region_beside_a_sandbox_in_another_region_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_ACCOUNT=000000000000 FAKE_ROLE_AUDIENCE="us-east-1:00000000-0000-4000-8000-000000000000" \
        "$SCRIPT" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"trusts an identity pool in us-east-1, not us-west-2"* ]] \
        && [[ "$OUT" != *00000000-0000-4000* ]] && grep -q -- '--region us-west-2 .*iam get-role' "$FAKE_LOG" \
        && ! grep -vE 'configure |sts get-caller-identity|iam get-role' "$FAKE_LOG" | grep -q . \
        || { echo "$OUT"; return 1; }
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_ACCOUNT=000000000000 FAKE_ROLE_AUDIENCE="us-west-2:00000000-0000-4000-8000-000000000000" \
        "$SCRIPT" 2>&1) || STATUS=$?
    [[ "$OUT" != *"trusts an identity pool"* ]] && grep -q -- 'iam get-role' "$FAKE_LOG" || { echo "$OUT"; return 1; }
}

# provision.sh's helpers, run over a fake `aws` function that pages its items two at a time.
eval "$(python3 - "$SCRIPT" <<'PY'
import sys
s = open(sys.argv[1]).read()
for name in ("find_by_name() {", "record_state() {"):
    start = s.index(name)
    print(s[start:s.index("\n}\n", start) + 3])
PY
)"
# shellcheck disable=SC2034  # read by record_state, defined by the eval above
STATE_DIR="$WORK/state"
aws() {
    local token=0
    [[ "${*: -2:1}" == "--next-token" ]] && token="${*: -1}"
    echo "page $token" >> "$FAKE_LOG"
    python3 -c '
import json, sys
start = int(sys.argv[1])
items = [{"Name": f"pool-{i}", "Id": f"us-west-2_Placeholder{i}"} for i in range(5)]
page = {"UserPools": items[start:start + 2]}
if start + 2 < len(items):
    page["NextToken"] = str(start + 2)
print(json.dumps(page))
' "$token"
}

find_by_name_reads_every_page() {
    local found
    : > "$FAKE_LOG"
    found=$(find_by_name UserPools Name Id pool-3 cognito-idp list-user-pools)
    [[ "$found" == "us-west-2_Placeholder3" && "$(wc -l < "$FAKE_LOG" | tr -d ' ')" == 2 ]] || return 1
    : > "$FAKE_LOG"
    found=$(find_by_name UserPools Name Id pool-9 cognito-idp list-user-pools)
    [[ -z "$found" && "$(wc -l < "$FAKE_LOG" | tr -d ' ')" == 3 ]]
}

record_state_merges_and_keeps_the_rest() {
    record_state userPoolId us-west-2_Placeholder0 appClientId placeholder-client
    [[ "$(stat -c '%a' "$WORK/state/state.json" 2>/dev/null || stat -f '%Lp' "$WORK/state/state.json")" == 600 ]] \
        && python3 -c '
import json, sys
state = json.load(open(sys.argv[1]))
assert state["userPoolId"] == "us-west-2_Placeholder0" and state["appClientId"] == "placeholder-client", state
assert state["region"] == "us-west-2" and state["parity"] == {"kmsKeyId": "placeholder-key"}, state
' "$WORK/state/state.json"
}

check "a region other than the recorded one is refused before any AWS call" another_region_is_refused_before_any_aws_call
check "without an argument, the recorded region wins over AWS_REGION" the_recorded_region_wins_over_aws_region
check "with no account recorded, a run without AWS_PROFILE is refused before any AWS call" \
    a_first_run_without_aws_profile_is_refused_before_any_aws_call
check "with no account recorded, a run with AWS_PROFILE goes on to the caller's identity" \
    a_first_run_with_aws_profile_goes_on_to_the_callers_identity
check "with no account recorded, a run with AWS_PROFILE and exported access keys is refused before any AWS call" \
    a_first_run_with_exported_keys_is_refused_before_any_aws_call
check "with no account recorded, a run with AWS_PROFILE and web identity or container credentials is refused" \
    a_first_run_with_web_identity_or_container_credentials_is_refused_before_any_aws_call
check "with an account recorded, a run with exported access keys goes on to the caller's identity" \
    a_recorded_account_lets_exported_keys_go_on_to_the_callers_identity
check "the region refusal points at a teardown, not at another state directory" \
    the_region_refusal_does_not_advise_another_state_directory
check "with no region recorded, a sandbox already in another region is refused before any change" \
    a_first_run_beside_a_sandbox_in_another_region_is_refused
check "with a region recorded, a sandbox in another region (another state directory's) is refused before any change" \
    a_recorded_region_beside_a_sandbox_in_another_region_is_refused
check "find_by_name follows NextToken to the name's page, and reads to the last page without it" \
    find_by_name_reads_every_page
check "record_state merges into state.json (mode 600) and keeps the parity section" record_state_merges_and_keeps_the_rest

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
