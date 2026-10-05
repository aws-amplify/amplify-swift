#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for provision-ci.sh, end to end over a fake `aws` (fake_aws.py) and a fake `npm` on PATH, which keep
# a fake account in a JSON file: the plugin's resources (a pool with a client and a trigger, an identity pool, a
# role, a Lambda, the auth/ objects) as placeholders, never real identifiers. No AWS call is made: the fake is
# checked to be the `aws` the script finds before anything runs, and the CLI's config and credential files are
# /dev/null.
#
#   bash infra/ci/test_provision_ci.sh
#
# It checks that a dry run (the default) makes only get/list/describe/head calls, plans every resource, names only
# ccit-ci- resources and prints no identifier; that --scope email-alias plans only the device-alias pool and what it
# needs; that a ccit-ci- name without the purpose tag is refused before any change, by a dry run and by --apply;
# that --apply creates everything, tagged, leaves the plugin's resources exactly as they were, narrows the key, the
# sender's decrypt and the SMS role to the two pools, and writes the four files (mode 600, in a mode-700
# directory) with what the client reads; that a second --apply makes no call; that --upload puts only new keys under
# auth/cognito-client-ci/ and refuses, with no upload, once one exists; that snapshot and verify-unchanged ignore a
# user count, and fail on a changed, removed or foreign added resource, but not on a ccit-ci- one; that teardown is a
# dry run by default, deletes only the ccit-ci- resources with --apply, and refuses an untagged one; and that the
# library's guards refuse a name that is not ccit-ci- and a mutating call in a dry run.
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CI_DIR/provision-ci.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/tmp"
# The fake, run by the interpreter itself rather than through /usr/bin/python3's shim: one process per call.
{ printf '#!%s -S\n' "$(python3 -c 'import sys; print(sys.executable)')"; tail -n +2 "$CI_DIR/fake_aws.py"; } > "$BIN/aws"
chmod +x "$BIN/aws"
cat > "$BIN/npm" <<'EOF'
#!/usr/bin/env bash
# A fake npm: `npm ci` makes a node_modules with one file, and nothing is fetched.
mkdir -p node_modules/fake && echo 'export {};' > node_modules/fake/index.js
EOF
chmod +x "$BIN/npm"
export PATH="$BIN:$PATH" FAKE_STATE="$WORK/state.json" FAKE_LOG="$WORK/calls.log" TMPDIR="$WORK/tmp"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null CCIT_CI_DISCOVERY_DIR="$WORK/disc"
export COGNITO_CLIENT_INTEG_CI_CONFIG_URL="s3://fake-ci-bucket.example/v2/testconfiguration"
unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN CCIT_CI_REGION
[[ "$(command -v aws)" == "$BIN/aws" ]] || { echo "FAIL: the fake aws is not first on PATH"; exit 1; }
ACCOUNT=123456789012
BUCKET=fake-ci-bucket.example
PLUGIN_POOL=us-east-1_PluginPool01

failures=0
pass() { echo "ok - $1"; }
fail() { echo "FAIL - $1"; failures=$((failures + 1)); }
check() {
    local name="$1"
    shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

# The fake account: the plugin's resources, which nothing may change.
fresh_state() {
    local key
    jq -n --arg a "$ACCOUNT" --arg b "$BUCKET" --arg p "$PLUGIN_POOL" '{
      account: $a, bucket: $b,
      pools: {($p): {UserPool: {Id: $p, Name: "amplify-plugin-default", EstimatedNumberOfUsers: 116854,
                                MfaConfiguration: "OPTIONAL", LastModifiedDate: "2025-01-01T00:00:00Z",
                                LambdaConfig: {PreSignUp: "arn:aws:lambda:us-east-1:\($a):function:plugin-pre-sign-up"},
                                UserPoolTags: {}},
                     clients: {"pluginclient0000000000000a": {ClientId: "pluginclient0000000000000a", ClientName: "plugin",
                                                            UserPoolId: $p}},
                     mfa: {MfaConfiguration: "OPTIONAL"}}},
      identity_pools: {"us-east-1:00000000-0000-4000-8000-000000000001": {
          IdentityPoolId: "us-east-1:00000000-0000-4000-8000-000000000001", IdentityPoolName: "plugin_identity",
          AllowUnauthenticatedIdentities: true, roles: {}}},
      roles: {"plugin-role": {Role: {RoleName: "plugin-role", RoleId: "AROAPLUGIN", Arn: "arn:aws:iam::\($a):role/plugin-role",
                                     AssumeRolePolicyDocument: {Version: "2012-10-17", Statement: []}},
                              tags: [], inline: {}, attached: []}},
      lambdas: {"plugin-pre-sign-up": {config: {FunctionName: "plugin-pre-sign-up", State: "Active",
                                                FunctionArn: "arn:aws:lambda:us-east-1:\($a):function:plugin-pre-sign-up"},
                                       tags: {}, policy: []}},
      s3: {}}' > "$FAKE_STATE"
    for key in AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json \
        AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json; do
        jq --arg k "v2/testconfiguration/auth/$key" '.s3[$k] = {etag: "\"e1\"", size: 10, modified: "2026-01-01T00:00:00Z", tags: {}}' \
            "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    done
}

# The plugin's part of the fake account, to compare before and after.
plugin_part() {
    jq -S --arg p "$PLUGIN_POOL" '{pool: .pools[$p], role: .roles["plugin-role"],
        lambda: .lambdas["plugin-pre-sign-up"],
        s3: (.s3 | with_entries(select(.key | contains("cognito-client-ci") | not))),
        identity_plugin: (.identity_pools["us-east-1:00000000-0000-4000-8000-000000000001"])}' "$FAKE_STATE"
}

# Runs the script; sets OUT (stdout and stderr) and STATUS.
run() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$("$SCRIPT" "$@" 2>&1) || STATUS=$?
}

# The service calls the last run made, as "<service> <verb>".
calls() {
    sed -nE 's/^--region [a-z0-9-]+ --output json ([a-z0-9-]+) ([a-z0-9-]+).*/\1 \2/p' "$FAKE_LOG"
}

only_reads() {
    ! calls | awk '{print $2}' | grep -vqE '^(get|list|describe|head)-'
}

# No identifier the fake knows reaches the output: the account, the bucket, a pool, client, key or API id.
no_identifiers() {
    [[ "$OUT" != *"$ACCOUNT"* && "$OUT" != *"$BUCKET"* && "$OUT" != *"$PLUGIN_POOL"* && "$OUT" != *us-east-1_Fake* ]] \
        && ! grep -qE '[0-9a-f]{26}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|da2-' <<<"$OUT"
}

# Every planned or made call ('+' line) names a ccit-ci- resource.
plus_lines_are_ours() {
    ! grep -E '^  \+ ' <<<"$OUT" | grep -vqE 'ccit-ci-|ccit_ci_|/ccit-ci/|alias/ccit-ci-|cognito-client-ci/|the code sink schema|the tests. read-only API key|the code table|resolver|the KMS key for|expire ccit'
}

usage_is_refused() {
    run --scope bogus
    (( STATUS == 2 )) && [[ ! -s "$FAKE_LOG" ]] || [[ -z "$(calls)" ]]
}

a_missing_config_url_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(env -u COGNITO_CLIENT_INTEG_CI_CONFIG_URL "$SCRIPT" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"COGNITO_CLIENT_INTEG_CI_CONFIG_URL"* ]] && [[ -z "$(calls)" ]]
}

a_config_url_without_a_path_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(COGNITO_CLIENT_INTEG_CI_CONFIG_URL="s3://$BUCKET" "$SCRIPT" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ -z "$(calls)" ]] && [[ "$OUT" != *"$BUCKET"* ]]
}

a_dry_run_plans_everything_and_changes_nothing() {
    fresh_state
    local before
    before=$(jq -S . "$FAKE_STATE")
    run
    (( STATUS == 0 )) && only_reads && no_identifiers && plus_lines_are_ours \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"+ create user pool ccit-ci-default"* && "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] \
        && [[ "$OUT" == *"+ create identity pool ccit_ci_default"* && "$OUT" == *"+ store /ccit-ci/custom-challenge-answer"* ]] \
        && [[ "$OUT" == *"+ set the key policy of alias/ccit-ci-senders to the ccit-ci- pools"* ]] \
        && [[ "$OUT" == *"Nothing was changed."* ]]
}

the_email_alias_scope_plans_only_its_pool() {
    fresh_state
    run --scope email-alias
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] \
        && [[ "$OUT" != *"user pool ccit-ci-default"* && "$OUT" != *"+ create identity pool"* && "$OUT" != *"/ccit-ci/"* ]] \
        && [[ "$OUT" != *"define-auth-challenge"* && "$OUT" != *"cognito-sms"* ]]
}

untagged_name_is_refused() { # mode: "" (dry run) or --apply
    fresh_state
    jq '.pools["us-east-1_Untagged01"] = {UserPool: {Id: "us-east-1_Untagged01", Name: "ccit-ci-email-alias", UserPoolTags: {}},
        clients: {}, mfa: {MfaConfiguration: "OFF"}}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    local before
    before=$(jq -S . "$FAKE_STATE")
    run "$@"
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"exists without purpose=amplify-cognito-client-integ"* ]] \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] && no_identifiers
}

CONFIG=""
apply_creates_everything_and_leaves_the_plugin_alone() {
    fresh_state
    local before modes default rotation
    before=$(plugin_part)
    run --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    no_identifiers || return 1
    plus_lines_are_ours || return 1
    [[ "$(plugin_part)" == "$before" ]] || return 1
    CONFIG=$(sed -nE 's#^Wrote the client.s CI configuration \(mode 600\) into (.*):$#\1#p' <<<"$OUT")
    [[ -d "$CONFIG" && "$(stat -f '%Lp' "$CONFIG")" == 700 ]] || return 1
    modes=$(find "$CONFIG" -type f -exec stat -f '%Lp' {} + | sort -u)
    [[ "$modes" == 600 && "$(find "$CONFIG" -type f | wc -l | tr -d ' ')" == 4 ]] || return 1
    default="$CONFIG/ccit-ci-default-amplify_outputs.json"
    rotation="$CONFIG/ccit-ci-rotation-amplify_outputs.json"
    jq -e '.auth.identity_pool_id and .auth.unauthenticated_identities_enabled and .data.url and .data.api_key
        and (.auth.mfa_methods == ["SMS", "TOTP"]) and (.custom == null)' "$default" >/dev/null || return 1
    [[ "$(jq -r .auth.user_pool_id "$rotation")" == "$(jq -r .auth.user_pool_id "$default")" ]] || return 1
    [[ "$(jq -r .auth.user_pool_client_id "$rotation")" != "$(jq -r .auth.user_pool_client_id "$default")" ]] || return 1
    jq -e '(.auth.username_attributes == ["email"]) and .data.api_key' "$CONFIG/ccit-ci-email-alias-amplify_outputs.json" >/dev/null || return 1
    jq -e '(keys == ["custom_challenge_answer", "new_password_required_temporary_password", "new_password_required_usernames"])
        and all(.[]; type == "string" and length > 0)
        and (.new_password_required_usernames | split(",") | length == 12)' "$CONFIG/ccit-ci-default-credentials.json" >/dev/null || return 1
    # Everything created is ccit-ci- and tagged.
    jq -e '[.pools[] | select(.UserPool.Name | startswith("ccit-ci-")) | .UserPool.UserPoolTags.purpose] == ["amplify-cognito-client-integ", "amplify-cognito-client-integ"]
        and ([.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-default", "ccit-ci-email-alias"])
        and ([.roles | keys[] | select(startswith("ccit-ci-"))] | length == 7)
        and ([.roles[] | select(.Role.RoleName | startswith("ccit-ci-")) | .tags[0].Value] | unique == ["amplify-cognito-client-integ"])
        and ([.lambdas[] | select(.config.FunctionName | startswith("ccit-ci-")) | .tags.purpose] | length == 6 and (unique == ["amplify-cognito-client-integ"]))
        and ([.lambdas[] | .config.FunctionName] | all(startswith("ccit-ci-") or . == "plugin-pre-sign-up"))
        and ([.ssm | keys[]] == ["/ccit-ci/custom-challenge-answer", "/ccit-ci/new-password-temporary"])
        and ([.identity_pools[] | .IdentityPoolName] | sort == ["ccit_ci_default", "plugin_identity"])' "$FAKE_STATE" >/dev/null || return 1
    # Narrowed to the two pools.
    jq -e '([.pools[] | select(.UserPool.Name | startswith("ccit-ci-")) | .UserPool.Arn] | sort) as $arns
        | [.kms.keys[] | .policy.Statement[1].Condition.ArnEquals["aws:SourceArn"]] == [$arns]
        and (.roles["ccit-ci-sender-exec"].inline["ccit-ci-sender-exec-policy"].Statement[1].Condition.StringEquals["kms:EncryptionContext:userpool-id"] | length == 2)
        and (.roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.ArnEquals["aws:SourceArn"] | length == 1)' \
        "$FAKE_STATE" >/dev/null || return 1
    [[ "$OUT" == *"new-password users: created 12"* ]]
}

a_second_apply_makes_no_call() {
    run --apply
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] && only_reads && no_identifiers
}

upload_puts_new_keys_only() {
    run --apply --upload
    (( STATUS == 0 )) || return 1
    [[ "$(calls | grep -c 's3api put-object')" == 4 ]] || return 1
    jq -e '[.s3 | to_entries[] | select(.key | contains("/auth/cognito-client-ci/")) | .value.tags.purpose] | length == 4' \
        "$FAKE_STATE" >/dev/null || return 1
    jq -e '[.s3 | keys[] | select(contains("/auth/cognito-client-ci/"))] | all(test("/auth/cognito-client-ci/ccit-ci-"))' \
        "$FAKE_STATE" >/dev/null || return 1
    no_identifiers
}

a_second_upload_is_refused_with_nothing_uploaded() {
    run --apply --upload
    (( STATUS == 1 )) && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && only_reads && no_identifiers
}

snapshot_and_verify() {
    local first second third out status
    run snapshot
    (( STATUS == 0 )) && only_reads && no_identifiers || return 1
    first=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    [[ -f "$first" && "$(stat -f '%Lp' "$first")" == 600 && "$(stat -f '%Lp' "${first%.json}.docs.json")" == 600 ]] || return 1
    mv "$first" "$WORK/disc/before.json"
    mv "${first%.json}.docs.json" "$WORK/disc/before.docs.json"
    # A user count moving is not a change.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.EstimatedNumberOfUsers = 116999' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run snapshot
    second=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    run verify-unchanged "$WORK/disc/before.json" "$second"
    (( STATUS == 0 )) && [[ "$OUT" == *"OK: every resource"* ]] || { echo "$OUT"; return 1; }
    rm -f "$second" "${second%.json}.docs.json"
    # A changed plugin pool, a removed plugin object, a ccit-ci- addition and a foreign one.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.MfaConfiguration = "OFF"
        | del(.s3["v2/testconfiguration/auth/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json"])
        | .roles["ccit-ci-extra"] = (.roles["plugin-role"] | .Role.RoleName = "ccit-ci-extra" | .Role.RoleId = "AROAEXTRA")
        | .roles["someone-else"] = (.roles["plugin-role"] | .Role.RoleName = "someone-else" | .Role.RoleId = "AROAELSE")' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run snapshot
    third=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/disc/before.json" "$third" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"CHANGED  user-pool amplify-plugin-default: MfaConfiguration"* ]] \
        && [[ "$out" == *"REMOVED  s3-object auth/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json"* ]] \
        && [[ "$out" == *"added    iam-role ccit-ci-extra (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"ADDED    iam-role someone-else"* ]] \
        && [[ "$out" != *"$PLUGIN_POOL"* && "$out" != *"$ACCOUNT"* && "$out" != *116854* ]] || { echo "$out"; return 1; }
    # Only the foreign addition, allowed, leaves the change and the removal failing.
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/disc/before.json" "$third" --allow-foreign-additions 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"someone-else (not ccit-ci-; allowed)"* ]]
}

teardown_is_a_dry_run_by_default() {
    local before
    before=$(jq -S . "$FAKE_STATE")
    run teardown
    (( STATUS == 0 )) && only_reads && no_identifiers && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"+ delete user pool ccit-ci-default"* && "$OUT" == *"+ schedule the key's deletion in 7 days"* ]] \
        && [[ "$OUT" != *"amplify-plugin-default"* && "$OUT" != *"plugin-role"* && "$OUT" != *"someone-else"* ]]
}

teardown_deletes_only_ours() {
    local before
    before=$(plugin_part)
    run teardown --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    no_identifiers && [[ "$(plugin_part)" == "$before" ]] || return 1
    jq -e '([.pools[] | .UserPool.Name] == ["amplify-plugin-default"])
        and ([.lambdas | keys[]] == ["plugin-pre-sign-up"])
        and ([.roles | keys[]] | sort == ["ccit-ci-extra", "plugin-role", "someone-else"])
        and (.ssm == {}) and (.kms.aliases == {}) and ([.kms.keys[] | .state] == ["PendingDeletion"])
        and ([.identity_pools[] | .IdentityPoolName] == ["plugin_identity"]) and (.apis == {}) and (.tables == {})
        and ([.s3 | keys[] | select(contains("cognito-client-ci"))] == [])
        and ([.log_groups | keys[]] == [])' "$FAKE_STATE" >/dev/null
}

teardown_refuses_an_untagged_ccit_ci_resource() {
    fresh_state
    jq '.tables["ccit-ci-codes"] = {tags: [], ttl: true}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    local before
    before=$(jq -S . "$FAKE_STATE")
    run teardown --apply
    (( STATUS == 1 )) && only_reads && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"table ccit-ci-codes exists without purpose"* ]]
}

# The first Lambda's create meets IAM propagation once: it is retried, so the two functions take three calls.
a_propagation_error_is_retried() {
    fresh_state
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="lambda create-function InvalidParameterValueException" "$SCRIPT" --apply --scope email-alias 2>&1) || STATUS=$?
    (( STATUS == 0 )) && [[ "$(calls | grep -c 'lambda create-function')" == 3 ]] && no_identifiers
}

another_error_stops_the_apply_and_a_rerun_finishes_it() {
    fresh_state
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="cognito-idp create-user-pool ServiceUnavailableException" "$SCRIPT" --apply --scope email-alias 2>&1) \
        || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"create user pool ccit-ci-email-alias"*"failed (ServiceUnavailableException)"* ]] \
        && [[ "$(calls | grep -c 'create-user-pool')" == 1 ]] && no_identifiers || return 1
    jq -e '[.pools[] | .UserPool.Name] == ["amplify-plugin-default"]' "$FAKE_STATE" >/dev/null || return 1
    run --apply --scope email-alias
    (( STATUS == 0 )) && [[ "$OUT" == *"= Lambda ccit-ci-pre-sign-up"* && "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] \
        && jq -e '[.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-email-alias"]' "$FAKE_STATE" >/dev/null
}

library_guards() {
    local out status=0
    out=$(bash -c '
        set -euo pipefail
        source "$1/../lib.sh"; source "$1/lib-ci.sh"
        CI_WORK=$(mktemp -d); CI_REGION=us-east-1; CI_MODE=apply
        mutate plugin-role "delete it" -- iam delete-role --role-name plugin-role' _ "$CI_DIR" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"is not a ccit-ci- resource"* ]] && ! calls | grep -q delete-role || return 1
    status=0
    out=$(bash -c '
        set -euo pipefail
        source "$1/../lib.sh"; source "$1/lib-ci.sh"
        CI_WORK=$(mktemp -d); CI_REGION=us-east-1; CI_MODE=plan
        aws_into x iam create-role --role-name ccit-ci-x' _ "$CI_DIR" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"makes read calls only"* ]]
}

check "bad usage is refused" usage_is_refused
check "a missing config URL is refused before any AWS call" a_missing_config_url_is_refused
check "a config URL without a path is refused, unprinted" a_config_url_without_a_path_is_refused
check "a dry run plans every resource, reads only, and prints no identifier" a_dry_run_plans_everything_and_changes_nothing
check "--scope email-alias plans only the device-alias pool and what it needs" the_email_alias_scope_plans_only_its_pool
check "a dry run refuses a ccit-ci- name without the tag" untagged_name_is_refused
check "--apply refuses a ccit-ci- name without the tag before any change" untagged_name_is_refused --apply
check "--apply creates everything tagged, narrowed, and leaves the plugin's resources alone" \
    apply_creates_everything_and_leaves_the_plugin_alone
check "a second --apply makes no call" a_second_apply_makes_no_call
check "--upload puts the four new keys, tagged, under auth/cognito-client-ci/" upload_puts_new_keys_only
check "a second --upload is refused, with nothing uploaded" a_second_upload_is_refused_with_nothing_uploaded
check "snapshot and verify-unchanged: a user count is no change; a change, a removal, a foreign addition fail" \
    snapshot_and_verify
check "teardown is a dry run by default and names only ccit-ci- resources" teardown_is_a_dry_run_by_default
check "teardown --apply deletes only the ccit-ci- resources it made" teardown_deletes_only_ours
check "teardown refuses a ccit-ci- resource without the tag, before any change" teardown_refuses_an_untagged_ccit_ci_resource
check "a role-propagation error is retried" a_propagation_error_is_retried
check "any other error stops --apply, and a second --apply makes only what is missing" \
    another_error_stops_the_apply_and_a_rerun_finishes_it
check "the library refuses a name that is not ccit-ci-, and a mutating call in a dry run" library_guards

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
